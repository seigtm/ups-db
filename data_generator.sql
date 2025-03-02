-- Data generation function using plpython3u
CREATE OR REPLACE FUNCTION generate_data()
    RETURNS text
    AS $$

import random
from datetime import datetime, timedelta
import traceback
import time


def generate_retail_centers(num_centers=10):
    retail_center_types = [
        "Distribution Center",
        "Warehouse",
        "Store",
        "Pickup Point",
        "Sorting Facility",
    ]
    addresses = [
        "123 Main St, New York, NY",
        "456 Broad Ave, Los Angeles, CA",
        "789 Oak Dr, Chicago, IL",
        "101 Pine Rd, Houston, TX",
        "202 Maple Ln, Phoenix, AZ",
        "303 Cedar Blvd, Philadelphia, PA",
        "404 Elm St, San Antonio, TX",
        "505 Willow Ave, San Diego, CA",
        "606 Birch Rd, Dallas, TX",
        "707 Spruce Ct, San Jose, CA",
    ]

    for i in range(num_centers):
        plan = plpy.prepare(
            "INSERT INTO retail_center (type, address) VALUES ($1, $2) RETURNING id",
            ["text", "text"],
        )
        plpy.execute(plan, [random.choice(retail_center_types), addresses[i]])


def generate_transport_events(num_events=10):
    transport_types = ["Air", "Ground", "Sea", "Rail", "Express"]
    delivery_routes = [
        "East Coast Route",
        "West Coast Route",
        "Central Route",
        "Northern Route",
        "Southern Route",
        "International Route",
        "Overnight Express",
        "Standard Delivery",
        "Priority Route",
        "Economy Route",
    ]

    for i in range(num_events):
        plan = plpy.prepare(
            "INSERT INTO transport_event (type, delivery_rout) VALUES ($1, $2) RETURNING seq_number",
            ["text", "text"],
        )
        plpy.execute(plan, [random.choice(transport_types), delivery_routes[i]])


def generate_shipped_items(num_items=1_000_000, batch_size=10_000):
    destinations = [
        "New York",
        "Los Angeles",
        "Chicago",
        "Houston",
        "Phoenix",
        "Philadelphia",
        "San Antonio",
        "San Diego",
        "Dallas",
        "San Jose",
        "Austin",
        "Jacksonville",
        "Fort Worth",
        "Columbus",
        "Indianapolis",
        "Charlotte",
        "Seattle",
        "Denver",
        "Washington",
        "Boston",
    ]

    # Current date for final delivery date
    today = datetime.now()

    # Get all retail center IDs - no need for foreign key validation during insert
    retail_center_ids = range(1, 11)  # Assuming we have 10 retail centers with IDs 1-10

    start_time = time.time()
    generated = 0

    for batch in range(0, num_items, batch_size):
        # Prepare batch values
        values = []
        for i in range(batch_size):
            if batch + i >= num_items:
                break

            retail_center_id = random.choice(retail_center_ids)
            weight = round(random.uniform(0.1, 100.0), 2)
            dimension = round(random.uniform(1.0, 50.0), 2)
            insurance_amt = round(random.uniform(10.0, 1_000.0), 2)
            destination = random.choice(destinations)
            days_to_add = random.randint(1, 120)
            final_delivery_date = (today + timedelta(days=days_to_add)).strftime(
                "%Y-%m-%d"
            )

            values.append(
                f"({retail_center_id}, {weight}, {dimension}, {insurance_amt}, '{destination}', '{final_delivery_date}')"
            )

        # Execute batch insert
        sql = f"INSERT INTO shipped_item (retail_center_id, weight, dimension, insurance_amt, destination, final_delivery_date) VALUES {','.join(values)};"
        plpy.execute(sql)

        generated += len(values)
        elapsed = time.time() - start_time
        rate = generated / elapsed if elapsed > 0 else 0

        if batch % 100_000 == 0 or batch + batch_size >= num_items:
            plpy.info(
                f"Generated {generated}/{num_items} shipped items. Rate: {int(rate)} rows/sec"
            )


def generate_item_transportation(num_records=10_000_000, batch_size=50_000):
    # Generate comments for full-text search
    comment_templates = [
        "Package {status} at {location} on {date}",
        "Shipment {status} and {action} at {time}",
        "Item {status} for delivery on {date}",
        "Delivery {status} at {location}, reason: {reason}",
        "Package {status} by carrier, {action} at {location}",
        "Item {action} at {location} for {reason}",
        "Shipment {status} at {time}, {action} needed",
        "Delivery attempt {status}, {action} required",
    ]

    status_options = [
        "received",
        "processed",
        "shipped",
        "delayed",
        "delivered",
        "returned",
        "damaged",
        "lost",
        "on hold",
    ]
    action_options = [
        "signature required",
        "reschedule needed",
        "pickup available",
        "contact customer",
        "verify address",
        "awaiting instructions",
    ]
    location_options = [
        "distribution center",
        "local hub",
        "delivery vehicle",
        "customer address",
        "pickup point",
        "warehouse",
        "sorting facility",
    ]
    reason_options = [
        "weather delay",
        "address issue",
        "customer request",
        "customs clearance",
        "technical problem",
        "carrier delay",
        "missing information",
    ]
    time_options = ["morning", "afternoon", "evening", "overnight"]

    # We'll use a range of item_nums and seq_nums rather than fetching them
    # This is much faster since no foreign key checks during insert
    max_item_num = plpy.execute("SELECT MAX(item_num) as max FROM shipped_item")[0][
        "max"
    ]
    max_seq_num = plpy.execute("SELECT MAX(seq_number) as max FROM transport_event")[0][
        "max"
    ]

    start_time = time.time()
    generated = 0
    today = datetime.now()

    for batch in range(0, num_records, batch_size):
        values = []
        for i in range(batch_size):
            if batch + i >= num_records:
                break

            transportation_event_seq_number = random.randint(1, max_seq_num)
            shipped_item_item_num = random.randint(1, max_item_num)

            # Generate a comment for full-text search
            template = random.choice(comment_templates)
            status = random.choice(status_options)
            action = random.choice(action_options)
            location = random.choice(location_options)
            reason = random.choice(reason_options)
            time_of_day = random.choice(time_options)
            days_offset = random.randint(-30, 30)
            date = (today + timedelta(days=days_offset)).strftime("%Y-%m-%d")

            comment = template.format(
                status=status,
                action=action,
                location=location,
                reason=reason,
                time=time_of_day,
                date=date,
            )

            # Escape single quotes in comment
            comment = comment.replace("'", "''")

            # Note: We don't need to specify the id as it's automatically filled by the serial column
            values.append(
                f"(DEFAULT, {transportation_event_seq_number}, '{comment}', {shipped_item_item_num})"
            )

        # Execute batch insert with DEFAULT for id column
        sql = f"INSERT INTO item_transportation (id, transportation_event_seq_number, comment, shipped_item_item_num) VALUES {','.join(values)};"
        plpy.execute(sql)

        generated += len(values)
        elapsed = time.time() - start_time
        rate = generated / elapsed if elapsed > 0 else 0

        if batch % 1_000_000 == 0 or batch + batch_size >= num_records:
            plpy.info(
                f"Generated {generated}/{num_records} transportation records. Rate: {int(rate)} rows/sec"
            )


def main():
    total_start_time = time.time()
    plpy.info("Starting data generation process...")

    plpy.info("1. Generating retail centers...")
    generate_retail_centers(10)
    plpy.info("Retail centers generated successfully.")

    plpy.info("2. Generating transport events...")
    generate_transport_events(10)
    plpy.info("Transport events generated successfully.")

    plpy.info("3. Generating shipped items (1M records)...")
    generate_shipped_items(num_items=1_000_000, batch_size=10_000)
    plpy.info("Shipped items generated successfully.")

    plpy.info("4. Generating item transportation records (10M records)...")
    generate_item_transportation(num_records=10_000_000, batch_size=50_000)
    plpy.info("Item transportation records generated successfully.")

    plpy.info("5. Adding constraints to tables...")
    plpy.execute("SELECT add_constraints()")
    plpy.info("Constraints added successfully.")

    total_time = time.time() - total_start_time
    return (
        f"Data generation completed successfully! Total time: {total_time:.2f} seconds!"
    )


try:
    return main()

except Exception as e:
    error_details = traceback.format_exc()
    return f"Error during data generation: {str(e)}\n{error_details}"

$$
LANGUAGE plpython3u;

