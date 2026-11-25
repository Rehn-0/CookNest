const express = require('express');
const cors = require('cors');
const { buildSchema } = require('graphql');
const { createHandler } = require('graphql-http/lib/use/express');

const app = express();
app.use(cors());
app.use(express.json());

// Sample data (will be replaced by a real database later)
const recipes = [
  { id: 1, title: 'Chicken Biryani', category: 'Dinner', difficulty: 'Hard', cookTime: 90 },
  { id: 2, title: 'Pancakes', category: 'Breakfast', difficulty: 'Easy', cookTime: 20 },
  { id: 3, title: 'Beef Bhuna', category: 'Dinner', difficulty: 'Medium', cookTime: 75 },
  { id: 4, title: 'Vegetable Khichuri', category: 'Lunch', difficulty: 'Easy', cookTime: 40 },
  { id: 5, title: 'Chocolate Brownies', category: 'Dessert', difficulty: 'Medium', cookTime: 45 },
  { id: 6, title: 'Egg Paratha Roll', category: 'Snack', difficulty: 'Easy', cookTime: 25 },
  { id: 7, title: 'Mango Lassi', category: 'Drinks', difficulty: 'Easy', cookTime: 5 },
  { id: 8, title: 'Shahi Tukra', category: 'Dessert', difficulty: 'Medium', cookTime: 50 },
  { id: 9, title: 'Fish Curry', category: 'Lunch', difficulty: 'Medium', cookTime: 45 },
  { id: 10, title: 'Omelette', category: 'Breakfast', difficulty: 'Easy', cookTime: 10 },
  { id: 11, title: 'Chicken Tikka', category: 'Snack', difficulty: 'Medium', cookTime: 60 },
  { id: 12, title: 'Falooda', category: 'Drinks', difficulty: 'Medium', cookTime: 30 },
  { id: 13, title: 'Dal Tadka', category: 'Lunch', difficulty: 'Easy', cookTime: 35 },
  { id: 14, title: 'Kacchi Biryani', category: 'Dinner', difficulty: 'Hard', cookTime: 120 },
  { id: 15, title: 'Semai', category: 'Dessert', difficulty: 'Easy', cookTime: 25 },
  { id: 16, title: 'French Toast', category: 'Breakfast', difficulty: 'Easy', cookTime: 15 },
  { id: 17, title: 'Samosa', category: 'Snack', difficulty: 'Hard', cookTime: 70 },
  { id: 18, title: 'Lemon Mint Cooler', category: 'Drinks', difficulty: 'Easy', cookTime: 5 },
  { id: 19, title: 'Prawn Malai Curry', category: 'Dinner', difficulty: 'Hard', cookTime: 55 },
  { id: 20, title: 'Cheese Sandwich', category: 'Snack', difficulty: 'Easy', cookTime: 10 },
];

// Shared pagination logic, used by both REST and GraphQL
function paginate(pageArg, limitArg) {
  const page = Math.max(parseInt(pageArg) || 1, 1);
  const limit = Math.min(Math.max(parseInt(limitArg) || 5, 1), 50);
  const start = (page - 1) * limit;
  return {
    page,
    limit,
    total: recipes.length,
    totalPages: Math.ceil(recipes.length / limit),
    data: recipes.slice(start, start + limit),
  };
}

// ---------- REST: GET /recipes?page=1&limit=5 ----------
app.get('/recipes', (req, res) => {
  res.json(paginate(req.query.page, req.query.limit));
});

// ---------- GraphQL: /graphql ----------
const schema = buildSchema(`
  type Recipe {
    id: Int!
    title: String!
    category: String!
    difficulty: String!
    cookTime: Int!
  }

  type RecipePage {
    page: Int!
    limit: Int!
    total: Int!
    totalPages: Int!
    data: [Recipe!]!
  }

  type Query {
    recipes(page: Int = 1, limit: Int = 5): RecipePage!
    recipe(id: Int!): Recipe
  }
`);

const root = {
  recipes: ({ page, limit }) => paginate(page, limit),
  recipe: ({ id }) => recipes.find((r) => r.id === id) || null,
};

app.all('/graphql', createHandler({ schema, rootValue: root }));

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`CookNest API running on http://localhost:${PORT}`);
});