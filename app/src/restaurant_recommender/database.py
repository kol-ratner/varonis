import asyncpg
from datetime import time
from typing import Optional

from .models import (
    DatabaseConfig
)


class DatabaseError(Exception):
    pass


class Database:
    def __init__(self, config: DatabaseConfig):
        self.config = config
        self.pool: Optional[asyncpg.Pool] = None

    async def connect(self):
        if not self.pool:
            dsn = f"postgresql://{self.config.user}:{self.config.password}@{self.config.host}:{self.config.port}/{self.config.database}"
            self.pool = await asyncpg.create_pool(
                dsn=dsn,
                min_size=self.config.min_pool_size,
                max_size=self.config.max_pool_size
            )

    async def get_connection(self):
        if not self.pool:
            await self.connect()
        return await self.pool.acquire()

    async def release_connection(self, connection):
        await self.pool.release(connection)

    async def init_db(self):
        async with self.pool.acquire() as conn:
            await conn.execute('''
                CREATE TABLE IF NOT EXISTS restaurants (
                    id SERIAL PRIMARY KEY,
                    name VARCHAR NOT NULL,
                    style VARCHAR NOT NULL,
                    address VARCHAR NOT NULL,
                    open_hour TIME NOT NULL,
                    close_hour TIME NOT NULL,
                    vegetarian BOOLEAN NOT NULL,
                    delivers BOOLEAN NOT NULL
                )
            ''')

    async def get_matching_restaurant(
            self,
            style: str = None,
            vegetarian: bool = None,
            current_time: time = None):
        conn = await self.get_connection()
        try:
            query = '''
                SELECT * FROM restaurants
                WHERE ($1::varchar IS NULL OR style ILIKE $1)
                AND ($2::boolean IS NULL OR vegetarian = $2)
                AND ($3::time IS NULL OR (
                    (close_hour > open_hour AND open_hour <= $3 AND close_hour >= $3)
                    OR
                    (close_hour < open_hour AND (open_hour <= $3 OR close_hour >= $3))
                ))
                ORDER BY RANDOM()
                LIMIT 1
            '''
            return await conn.fetchrow(query, style, vegetarian, current_time)
        finally:
            await self.release_connection(conn)

    async def add_restaurant(self, name: str, style: str, address: str,
                             open_hour: str, close_hour: str,
                             vegetarian: bool, delivers: bool):

        if await self.restaurant_exists(name, address):
            raise DatabaseError(
                "Restaurant with this name and address already exists")

        open_time = time.fromisoformat(open_hour)
        close_time = time.fromisoformat(close_hour)

        conn = await self.get_connection()
        try:
            return await conn.fetchrow('''
                INSERT INTO restaurants (name, style, address, open_hour, close_hour, vegetarian, delivers)
                VALUES ($1, $2, $3, $4, $5, $6, $7)
                RETURNING *
            ''', name, style, address, open_time, close_time, vegetarian, delivers)
        except asyncpg.exceptions.PostgresError as e:
            raise DatabaseError(f"Failed to insert restaurant: {str(e)}")
        finally:
            await self.release_connection(conn)

    async def get_all_restaurants(self):
        conn = await self.get_connection()
        try:
            return await conn.fetch('SELECT * FROM restaurants')
        except asyncpg.exceptions.PostgresError as e:
            raise DatabaseError(f"Failed to get all restaurants: {str(e)}")
        finally:
            await self.release_connection(conn)

    async def restaurant_exists(self, name: str, address: str) -> bool:
        conn = await self.get_connection()
        try:
            query = '''
                SELECT EXISTS(
                    SELECT 1 FROM restaurants
                    WHERE name = $1 AND address = $2
                )
            '''
            return await conn.fetchval(query, name, address)
        except asyncpg.exceptions.PostgresError as e:
            raise DatabaseError(
                f"Failed to check if restaurant exists: {str(e)}")
        finally:
            await self.release_connection(conn)
