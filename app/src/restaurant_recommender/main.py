from .models import (
    DatabaseConfig,
    Restaurant
)
from .database import (
    Database,
    DatabaseError
)
from fastapi import FastAPI, status, Query
from starlette.responses import JSONResponse
from datetime import datetime
from typing import Optional
import logging
import os

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)


db_config = DatabaseConfig(
    # Get connection details from environment variables with defaults
    user=os.getenv("DB_USER", "postgres"),
    # password = os.getenv("DB_PASSWORD", "postgres"),
    database=os.getenv("DB_NAME", "restaurant_db"),
    host=os.getenv("DB_HOST", "localhost"),
    port=os.getenv("DB_PORT", "5432")
)

db = Database(db_config)

app = FastAPI()


@app.on_event("startup")
async def startup():
    await db.connect()
    await db.init_db()


@app.get("/healthz")
async def health_check():
    return JSONResponse(
        status_code=status.HTTP_200_OK,
        content={"status": "healthy"}
    )


@app.get("/readyz")
async def readiness_check():
    try:
        # Test database connection
        async with db.pool.acquire() as conn:
            await conn.fetchval("SELECT 1")

        return JSONResponse(
            status_code=status.HTTP_200_OK,
            content={"status": "ready"}
        )
    except Exception:
        return JSONResponse(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            content={"status": "not ready"}
        )


@app.get("/recommend")
async def recommend_restaurant(
    style: Optional[str] = None,
    vegetarian: Optional[bool] = Query(
        None,
        description="Filter for vegetarian restaurants")):
    current_time = datetime.now().time()
    restaurant = await db.get_matching_restaurant(
        style=style if style else None,
        vegetarian=vegetarian,
        current_time=current_time
    )

    if not restaurant:
        return JSONResponse(
            status_code=status.HTTP_404_NOT_FOUND,
            content={"error": "No matching restaurant found"}
        )

    restaurant_dict = dict(restaurant)
    restaurant_dict['open_hour'] = restaurant_dict['open_hour'].strftime(
        '%H:%M:%S')
    restaurant_dict['close_hour'] = restaurant_dict['close_hour'].strftime(
        '%H:%M:%S')
    return JSONResponse(
        status_code=status.HTTP_200_OK,
        content={"recommendation": restaurant_dict}
    )


@app.post("/restaurants")
async def create_restaurant(data: Restaurant):
    logger.debug(f"Received request data: {data}")

    try:
        validated_open_hour = Restaurant.validate_time_format(data.open_hour)
        validated_close_hour = Restaurant.validate_time_format(data.close_hour)
    except ValueError as e:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={
                "status": "error",
                "message": str(e)
            }
        )
    try:
        result = await db.add_restaurant(
            data.name,
            data.style,
            data.address,
            validated_open_hour,
            validated_close_hour,
            data.vegetarian,
            data.delivers
        )
        logger.debug(f"Created restaurant: {result}")
        return JSONResponse(
            status_code=status.HTTP_201_CREATED,
            content={"message": "Restaurant created successfully"}
        )

    except DatabaseError as e:
        logger.debug(f"Error creating restaurant: {str(e)}")
        return JSONResponse(
            status_code=status.HTTP_409_CONFLICT,
            content={
                "status": "conflict",
                "message": str(e)
            }
        )


@app.get("/restaurants")
async def list_restaurants():
    try:
        records = await db.get_all_restaurants()
        restaurants = []
        for record in records:
            restaurant = {
                "name": record['name'],
                "style": record['style'],
                "address": record['address'],
                "open_hour": record['open_hour'].strftime("%H:%M:%S"),
                "close_hour": record['close_hour'].strftime("%H:%M:%S"),
                "vegetarian": record['vegetarian'],
                "delivers": record['delivers']
            }
            restaurants.append(restaurant)
        # return restaurants
        return JSONResponse(
            content={
                "status": "success",
                "restaurants": restaurants,
            }
        )
    except Exception as e:
        logger.debug(f"Error getting restaurants: {str(e)}")
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "status": "error",
                "message": str(e)
            }
        )
