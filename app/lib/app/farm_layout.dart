// Written by design/art/farm.py (do not edit by hand): where things are on the
// home page's farm (assets/art/farm/home.svg), as fractions of its width and
// height (390 x 620).

/// The aspect of the farm picture.
const farmAspect = 0.62903;

/// The middle of each place's picture (by Place.name); its sign goes under it.
const farmSpots = {'chicks': (0.236, 0.358), 'eggs': (0.749, 0.352), 'fruit': (0.246, 0.568), 'share': (0.749, 0.568), 'garden': (0.246, 0.771), 'market': (0.738, 0.771)};

/// Where the hatched chicks wander (the first ten).
const hatchSpots = [(0.385, 0.423), (0.441, 0.403), (0.503, 0.423), (0.410, 0.455), (0.549, 0.452), (0.477, 0.471), (0.354, 0.484), (0.579, 0.484), (0.523, 0.503), (0.431, 0.510)];

/// The fruit that grows on the home tree.
const treeFruitSpots = [(0.200, 0.510), (0.282, 0.503), (0.241, 0.535), (0.164, 0.548), (0.318, 0.545), (0.256, 0.484)];

/// New vegetables in the patch.
const sproutSpots = [(0.092, 0.839), (0.154, 0.848), (0.215, 0.839), (0.277, 0.848), (0.338, 0.839), (0.400, 0.848)];

/// Melons waiting by the truck.
const melonSpots = [(0.851, 0.858), (0.903, 0.871), (0.800, 0.871), (0.954, 0.858)];
