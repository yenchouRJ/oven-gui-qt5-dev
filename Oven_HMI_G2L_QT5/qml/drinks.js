// Bake/roast configuration data
.pragma library

var drinks = [
  {
    id: "pizza",
    label: "Stone-Baked Pizza",
    desc: "Crispy crust",
    notes: ["12\" pie", "Preheat tray", "Rotate halfway"],
    image: "qrc:/assets/media/pizza.png",
    defaults: {
      strength: 6, grind: 4,
      quantity: { value: 1, max: 2, unit: "pcs" },
      contactTime: { value: 15, max: 30, unit: "min" },
      temperature: { value: 220, max: 260, unit: "C" }
    }
  },
  {
    id: "bread",
    label: "Artisan Bread",
    desc: "Golden loaf",
    notes: ["Steam boost optional", "Score before bake", "Rest 10 min"],
    image: "qrc:/assets/media/bread.png",
    defaults: {
      strength: 5, grind: 3,
      quantity: { value: 1, max: 2, unit: "loaf" },
      contactTime: { value: 35, max: 60, unit: "min" },
      temperature: { value: 200, max: 240, unit: "C" }
    }
  },
  {
    id: "fish",
    label: "Herb Roasted Fish",
    desc: "Lemon & dill",
    notes: ["400 g fillet", "Foil cover first 10 min", "Middle rack"],
    image: "qrc:/assets/media/fish.png",
    defaults: {
      strength: 6, grind: 4,
      quantity: { value: 2, max: 4, unit: "fillets" },
      contactTime: { value: 20, max: 35, unit: "min" },
      temperature: { value: 190, max: 230, unit: "C" }
    }
  },
  {
    id: "meatball",
    label: "Baked Meatballs",
    desc: "Juicy & crisp",
    notes: ["Preheated pan", "Rotate tray halfway", "Serve with sauce"],
    image: "qrc:/assets/media/meatball.png",
    defaults: {
      strength: 6, grind: 4,
      quantity: { value: 12, max: 24, unit: "pcs" },
      contactTime: { value: 18, max: 30, unit: "min" },
      temperature: { value: 200, max: 230, unit: "C" }
    }
  },
  {
    id: "chicken",
    label: "Roast Chicken",
    desc: "Herb butter",
    notes: ["1.5 kg whole", "Baste at 20 min", "Rest before carving"],
    image: "qrc:/assets/media/chicken.png",
    defaults: {
      strength: 7, grind: 4,
      quantity: { value: 1500, max: 3000, unit: "g" },
      contactTime: { value: 55, max: 90, unit: "min" },
      temperature: { value: 190, max: 220, unit: "C" }
    }
  }
];

var currentBrewSettings = {
    "drinkName": "Stone-Baked Pizza",
    "strength": 6,
    "grind": 4,
    "quantity": 1,
    "quantityUnit": "pcs",
    "time": 15,
    "contactTime": 15,
    "timeUnit": "min",
    "temp": 220,
    "temperature": 220,
    "tempUnit": "C"
};
