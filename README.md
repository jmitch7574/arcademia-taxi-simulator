# Arcademia Taxi Simulator

Arcademia taxi simulator is a game made for the University of Lincoln's Computer Science Society's Arcademia Jam 2025. Using mapping data from Open Street Map, you can play as a taxi driver throughout real life cities.

## Running the game

Please clone the source code onto your machine and open the project using Godot 4.4.x, or download a release binary (.exe) from the releases page.

## Want to add your own cities?

It is fully possible for you to add any city you want into this game. However please note that I cannot guarantee that it will function properly. I am slowly adding more and more features as time goes on to hopefully support more, however there will always be edge cases I cannot account for.

### Steps

1. Obtain a copy of osm.pbf data for your city or area
2. Use a tool such as osmium to convert your data to GeoJSON
3. Add the following properties into the root of the GeoJSON folder

   1. a bounding box property called "BBOX", can be found using osmium

   ```
       "bbox": [ -0.8054517, 53.000605, -0.3466943, 53.3586167 ]
   ```

   2. a reference coord, which can be any latitude and longitude coordinate within your city

   ```
       "referenceCoords": [ 52.299999999999997, -0.5 ],
   ```
4. Add a spawn point feature to your Feature Collection

```
    { "type": "Feature", "properties": { "name": "SPAWN_POINT" }, "geometry": { "type": "Point", "coordinates": [ -0.537702722823083, 53.22638512661095 ] } }
```

5. Place this file into the GeoJson-Files folder within the project
   - It may become a feature in future where this can be done from the binary however that is not a high priority at the moment

## How to contribute

I intend for this game to remain a full solo project, however any and all contributions are welcome given I believe they are suitable. If you wish to contribute, please PM me with details and use a pull request.

## Credits

This game would not be possible without the data avaiable from [Open Street Map](https://www.openstreetmap.org/), and the use of assets from [Kenny](https://kenney.nl/). I would also like to thank Jam for making the logo :>
