import pandas as pd
import json

# Load CSV files with dtype=str to avoid mixed type issues
food_df = pd.read_csv("food.csv", dtype=str)
food_nutrient_df = pd.read_csv("food_nutrient.csv", dtype=str)
nutrient_df = pd.read_csv("nutrient.csv", dtype=str)

# Rename columns to lowercase and strip spaces
food_df.rename(columns=lambda x: x.strip().lower(), inplace=True)
food_nutrient_df.rename(columns=lambda x: x.strip().lower(), inplace=True)
nutrient_df.rename(columns=lambda x: x.strip().lower(), inplace=True)

# Rename 'id' in nutrient_df to 'nutrient_id' to match food_nutrient_df
nutrient_df.rename(columns={"id": "nutrient_id"}, inplace=True)

# Print column names to verify they match
print("food_nutrient.csv columns:", food_nutrient_df.columns)
print("nutrient.csv columns:", nutrient_df.columns)

# Merge Nutrient Names into Food Nutrients
food_nutrient_df = food_nutrient_df.merge(nutrient_df, on="nutrient_id", how="left")

# Merge Food Names into Nutrient Data
merged_df = food_nutrient_df.merge(food_df, on="fdc_id", how="left")  # 'food_id' should be 'fdc_id'

# Select relevant columns
final_df = merged_df[["fdc_id", "description", "name", "amount", "unit_name"]]

# Convert to JSON format
grouped = final_df.groupby("fdc_id").apply(
    lambda x: {
        "name": x["description"].values[0],
        "nutrients": [
            {"name": row["name"], "amount": row["amount"], "unit": row["unit_name"]}
            for _, row in x.iterrows()
        ],
    }
).tolist()

# Save as JSON
with open("usda_food_data.json", "w", encoding="utf-8") as f:
    json.dump(grouped, f, indent=4)

print("✅ Processed data saved as 'usda_food_data.json'")
