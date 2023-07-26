// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./IEventNFT.sol";
import "./OrbitProxy.sol";

library BoltLib {
    uint256 public constant MAX_PLANETS = 3;

    struct AIBOLTData {
        string sun;
        string sunSvg;
        uint256 numPlanets;
        Planet[MAX_PLANETS] planets;
    }

    struct Planet {
        OrbitSpeed orbitSpeed;
        PlanetSize size;
        string theme;
        string svg;
    }

    enum OrbitSpeed {
        Crawl,
        Cruise,
        Dash
    }

    enum PlanetSize {
        Speck,
        Globe,
        Titan
    }

    function generateAIBOLTData(
        uint16[5] memory _tokenIds
    ) public pure returns (AIBOLTData memory) {
        uint256 totalHue = 0;
        uint256 totalRotationSpeed = 0;
        uint256 totalNumCircles = 0;
        uint256[] memory totalRadius = new uint256[](5);
        uint256[] memory totalDistance = new uint256[](5);
        uint256[] memory totalStrokeWidth = new uint256[](5);

        for (uint256 j = 0; j < 5; j++) {
            OrbitProxy.CommonValues memory commonValues = OrbitProxy
                .generateAIORBITTraits(_tokenIds[j]);
            totalHue += commonValues.hue;
            totalRotationSpeed += commonValues.rotationSpeed;
            totalNumCircles += commonValues.numCircles;
            for (uint256 i = 0; i < commonValues.numCircles; i++) {
                totalRadius[i] += commonValues.radius[i];
                totalDistance[i] += commonValues.distance[i];
                totalStrokeWidth[i] += commonValues.strokeWidth[i];
            }
        }

        OrbitProxy.CommonValues memory averagedValues = OrbitProxy.CommonValues(
            totalHue / 5,
            totalRotationSpeed / 5,
            totalNumCircles / 5,
            new uint256[](5),
            new uint256[](5),
            new uint256[](5)
        );

        for (uint256 i = 0; i < averagedValues.numCircles; i++) {
            averagedValues.radius[i] = totalRadius[i] / 5;
            averagedValues.distance[i] = totalDistance[i] / 5;
            averagedValues.strokeWidth[i] = totalStrokeWidth[i] / 5;
        }
        uint256 numPlanets;

        if (averagedValues.numCircles >= 1 && averagedValues.numCircles <= 3) {
            numPlanets = 1;
        } else if (
            averagedValues.numCircles > 3 && averagedValues.numCircles <= 4
        ) {
            numPlanets = 2;
        } else if (
            averagedValues.numCircles > 4 && averagedValues.numCircles <= 5
        ) {
            numPlanets = 3;
        }
        uint256[3] memory planetBiomes;

        // Set range for hue
        uint256 hue_start = 0;
        uint256 hue_end = 359;

        // Set range for planetBiomes
        uint256 biome_start = 0;
        uint256 biome_end = 5;

        for (uint256 i = 0; i < 3; i++) {
            // Add an offset to the hue for each planet
            uint256 hue = (averagedValues.hue + i * 60) % 360;

            // Scale hue to biome
            uint256 biome = ((hue - hue_start) * (biome_end - biome_start)) /
                (hue_end - hue_start) +
                biome_start;

            // Ensure biome is within valid range and convert it to an integer
            planetBiomes[i] = biome > biome_end
                ? biome_end
                : (biome < biome_start ? biome_start : uint256(biome));
        }

        Planet[MAX_PLANETS] memory planets = generatePlanetData(
            averagedValues,
            numPlanets,
            planetBiomes
        );

        // Default sun values
        string memory sun = [
            "Pulsar",
            "Red-Giant",
            "White-Dwarf",
            "Neutron-Star"
        ][averagedValues.hue % 4];

        return AIBOLTData(sun, "", numPlanets, planets);
    }

    function generatePlanetData(
        OrbitProxy.CommonValues memory averagedValues,
        uint256 numPlanets,
        uint256[3] memory planetBiomes
    ) public pure returns (Planet[MAX_PLANETS] memory) {
        Planet[MAX_PLANETS] memory planets;

        // Set range for rotationSpeed
        uint256 rotationSpeed_start = 5;
        uint256 rotationSpeed_end = 15;

        // Set range for orbitSpeed
        uint256 orbitSpeed_start = 0;
        uint256 orbitSpeed_end = 2;

        for (uint256 i = 0; i < numPlanets; i++) {
            // Scale rotationSpeed to orbitSpeed
            uint256 orbitSpeed = ((averagedValues.rotationSpeed -
                rotationSpeed_start) * (orbitSpeed_end - orbitSpeed_start)) /
                (rotationSpeed_end - rotationSpeed_start) +
                orbitSpeed_start;

            // Ensure orbitSpeed is within valid range
            orbitSpeed = orbitSpeed > orbitSpeed_end
                ? orbitSpeed_end
                : (
                    orbitSpeed < orbitSpeed_start
                        ? orbitSpeed_start
                        : orbitSpeed
                );

            PlanetSize size = PlanetSize(averagedValues.radius[i] % numPlanets);
            string memory theme = [
                "Habitable",
                "Gas-Giant",
                "Ice-Giant",
                "Artificial",
                "Terraformed"
            ][planetBiomes[i]];

            planets[i] = Planet(OrbitSpeed(orbitSpeed), size, theme, "");
        }
        return planets;
    }

    function generateTraits(
        AIBOLTData memory data,
        uint256[] memory tokenEvents,
        IEventNFT eventNFT
    ) public view returns (string memory) {
        string memory traits = "[";

        if (tokenEvents.length != 0) {
            traits = string(
                abi.encodePacked(
                    traits,
                    '{ "trait_type": "Sun", "value": "',
                    data.sun,
                    '" }'
                )
            );
            for (uint256 i = 0; i < data.numPlanets; i++) {
                traits = string(
                    abi.encodePacked(
                        traits,
                        ',{ "trait_type": "Planet #',
                        Strings.toString(i + 1),
                        '", "value": "',
                        data.planets[i].theme,
                        '" }'
                    )
                );
            }
            for (uint256 i = data.numPlanets; i < MAX_PLANETS; i++) {
                traits = string(
                    abi.encodePacked(
                        traits,
                        ',{ "trait_type": "Planet #',
                        Strings.toString(i + 1),
                        '", "value": "Non-Existent" }'
                    )
                );
            }
            traits = string(
                abi.encodePacked(
                    traits,
                    ',{ "trait_type": "Speed", "value": "',
                    getOrbitSpeed(getAverageOrbitSpeed(data.planets)),
                    '" },',
                    '{ "trait_type": "Size", "value": "',
                    getPlanetSize(
                        getAveragePlanetSize(data.planets, data.numPlanets)
                    ),
                    '" }'
                )
            );
        }

        for (uint256 i = 0; i < tokenEvents.length; i++) {
            string memory eventName = "";

            if (i == 0 || tokenEvents[i] == 1) {
                eventName = "Inception";
            } else {
                eventName = eventNFT.getEvent(tokenEvents[i]).name;
            }

            traits = string(
                abi.encodePacked(
                    traits,
                    i == 0 &&
                        keccak256(abi.encodePacked((traits))) ==
                        keccak256(abi.encodePacked(("[")))
                        ? ""
                        : ",",
                    '{ "trait_type": "Event #',
                    Strings.toString(i + 1),
                    '", "value": "',
                    eventName,
                    '" }'
                )
            );
        }

        if (tokenEvents.length == 0) {
            traits = string(
                abi.encodePacked(
                    traits,
                    keccak256(abi.encodePacked((traits))) ==
                        keccak256(abi.encodePacked(("[")))
                        ? ""
                        : ",",
                    '{ "trait_type": "Event #0", "value": "The Void" }'
                )
            );
        }

        traits = string(abi.encodePacked(traits, "]"));
        return traits;
    }

    function generateSVG(
        BoltLib.AIBOLTData memory data,
        uint256[] memory tokenEvents,
        IEventNFT eventNFT
    ) public view returns (string memory) {
        uint256 tokenEventLength = tokenEvents.length;

        string memory eventName = "The Void";
        string memory eventSVGBottom = "";
        string memory eventSVGTop = "";

        uint256 latestTokenEventId = 0;
        if (tokenEventLength != 0) {
            latestTokenEventId = tokenEvents[tokenEventLength - 1];
        }

        // Generate stars
        string memory starsSVG = "";
        if (tokenEventLength != 0) {
            // Revealed
            for (uint256 i = 0; i < 50; i++) {
                starsSVG = string(
                    abi.encodePacked(starsSVG, generateStar(block.timestamp, i))
                );
            }
        }

        if (tokenEventLength == 1 || latestTokenEventId == 1) {
            eventName = "Inception";
        } else if (tokenEventLength > 1) {
            if (latestTokenEventId != 1) {
                // Event is Inception
                eventName = eventNFT.getEvent(latestTokenEventId).name;
                eventSVGBottom = eventNFT
                    .getEvent(latestTokenEventId)
                    .bottomSvg;
                eventSVGTop = eventNFT.getEvent(latestTokenEventId).topSvg;
            }
        }

        string memory planetsSVG = "";
        for (uint256 i = 0; i < data.numPlanets; i++) {
            planetsSVG = string(
                abi.encodePacked(planetsSVG, getPlanetSVG(data.planets[i], i))
            );
        }

        string memory sunColor = getSunColor(data.sun);
        string memory svg = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 640 640" style="background-color: black;">',
                '<rect width="100%" height="100%" fill="#000" />',
                starsSVG,
                eventSVGBottom,
                '<g transform="translate(320,320)">'
            )
        );

        if (tokenEventLength == 0) {
            svg = string(
                abi.encodePacked(
                    svg,
                    '<circle cx="0" cy="0" r="0">',
                    '<animate attributeName="r" values="0;800" dur="5s" repeatCount="indefinite" />',
                    '<animate attributeName="opacity" values="0.3;0;0" dur="5s" repeatCount="indefinite" />',
                    '<animate attributeName="fill" values="#FFFFFF; #EDE7F6; #D1C4E9; #FFFFFF;" dur="2s" repeatCount="indefinite" />',
                    "</circle>"
                )
            );
        }

        if (bytes(data.sunSvg).length != 0) {
            svg = string(abi.encodePacked(svg, data.sunSvg));
        } else {
            svg = string(
                abi.encodePacked(
                    svg,
                    '<circle r="40" className="sun">',
                    '<animate attributeName="fill" values="',
                    sunColor,
                    '" dur="3s" repeatCount="indefinite"/>',
                    "</circle>",
                    '<g transform="translate(-40,-40) scale(0.08)" className="bolt"> <path d="M624 267.629L615.767 252L533.433 256.935L377 503.701L385.233 519.33H475.8L385.233 738.129L401.7 748L611.65 462.574L603.417 446.945H508.733L624 267.629Z" fill="black" stroke="black" stroke-width="25" stroke-linejoin="round" /> </g>'
                )
            );
        }

        if (tokenEventLength != 0) {
            svg = string(abi.encodePacked(svg, planetsSVG));
        }

        svg = string(
            abi.encodePacked(
                svg,
                "</g>",
                eventSVGTop,
                '<text x="60" y="590" fill="white" font-family="Monospace" font-size="24" opacity="0">',
                "Event #",
                Strings.toString(tokenEventLength),
                ": ",
                eventName,
                '<animate attributeName="opacity" from="0" to="1" begin="1s" dur="2s" fill="freeze"/>',
                "</text>"
                "</svg>"
            )
        );

        return svg;
    }

    function getPlanetSVG(
        Planet memory planet,
        uint256 index
    ) public pure returns (string memory) {
        if (bytes(planet.svg).length != 0) {
            return string(abi.encodePacked(planet.svg));
        }

        string memory color = getPlanetColor(planet.theme);

        // Adjust planet size based on size trait
        uint256 r;
        if (planet.size == PlanetSize.Speck) {
            r = 5 * 3;
        } else if (planet.size == PlanetSize.Globe) {
            r = 10 * 3;
        } else if (planet.size == PlanetSize.Titan) {
            r = 15 * 3;
        }

        uint256 cy = (index + 1) * 100;

        string memory orbitTrails = generateTrails(index, cy);

        string memory orbitDuration;
        string memory planetColorDuration;
        if (planet.orbitSpeed == OrbitSpeed.Crawl) {
            orbitDuration = "10";
            planetColorDuration = "8s";
        } else if (planet.orbitSpeed == OrbitSpeed.Cruise) {
            orbitDuration = "7";
            planetColorDuration = "5s";
        } else if (planet.orbitSpeed == OrbitSpeed.Dash) {
            orbitDuration = "4";
            planetColorDuration = "3s";
        }

        return
            string(
                abi.encodePacked(
                    "<g>",
                    orbitTrails,
                    '<circle cx="0" cy="-',
                    Strings.toString(cy),
                    '" r="',
                    Strings.toString(r),
                    '" className="planet',
                    Strings.toString(index),
                    '">',
                    '<animate attributeName="fill" dur="',
                    planetColorDuration,
                    '" repeatCount="indefinite" values="',
                    color,
                    '"/></circle>',
                    '<animateTransform attributeName="transform" type="rotate" from="0" to="360" dur="',
                    orbitDuration,
                    's" repeatCount="indefinite"/>',
                    "</g>"
                )
            );
    }

    function generateTrails(
        uint256 index,
        uint256 cy
    ) public pure returns (string memory) {
        string memory begin;
        string memory values;
        if (index == 0) {
            begin = "0s";
            values = "1;0;0;1";
        } else if (index == 1) {
            begin = "2s";
            values = "0;1;0;0";
        } else if (index == 2) {
            begin = "4s";
            values = "0;0;1;0";
        }
        return
            string(
                abi.encodePacked(
                    '<circle cx="0" cy="0" r="',
                    Strings.toString(cy),
                    '" className="trail',
                    Strings.toString(index),
                    '" stroke="gray" fill="transparent" stroke-opacity="0">',
                    '<animate attributeName="stroke-opacity" values="',
                    values,
                    '" dur="6s" repeatCount="indefinite" begin="',
                    begin,
                    '"/>',
                    "</circle>"
                )
            );
    }

    function getAverageOrbitSpeed(
        Planet[MAX_PLANETS] memory planets
    ) private pure returns (OrbitSpeed) {
        uint256 total = 0;
        for (uint256 i = 0; i < planets.length; i++) {
            if (planets[i].orbitSpeed == OrbitSpeed.Crawl) {
                total += 10;
            } else if (planets[i].orbitSpeed == OrbitSpeed.Cruise) {
                total += 7;
            } else if (planets[i].orbitSpeed == OrbitSpeed.Dash) {
                total += 4;
            }
        }

        uint256 average = total / planets.length;

        if (average > 8) {
            return OrbitSpeed.Crawl;
        } else if (average > 6) {
            return OrbitSpeed.Cruise;
        } else {
            return OrbitSpeed.Dash;
        }
    }

    function getAveragePlanetSize(
        Planet[MAX_PLANETS] memory planets,
        uint256 numPlanets
    ) private pure returns (PlanetSize) {
        uint256 total = 0;
        for (uint256 i = 0; i < numPlanets; i++) {
            if (planets[i].size == PlanetSize.Speck) {
                total += 5 * 3; // Updated to 3x size
            } else if (planets[i].size == PlanetSize.Globe) {
                total += 10 * 3; // Updated to 3x size
            } else if (planets[i].size == PlanetSize.Titan) {
                total += 15 * 3; // Updated to 3x size
            }
        }

        uint256 average = total / numPlanets;

        if (average <= 5 * 3) {
            // Updated to 3x size
            return PlanetSize.Speck;
        } else if (average <= 10 * 3) {
            // Updated to 3x size
            return PlanetSize.Globe;
        } else {
            return PlanetSize.Titan;
        }
    }

    function getSunColor(
        string memory sun
    ) private pure returns (string memory sunColor) {
        if (Strings.equal(sun, "Pulsar")) {
            return "#808080; #A9A9A9; #C0C0C0; #808080"; // Shades of grey
        } else if (Strings.equal(sun, "Red-Giant")) {
            return "#FF4500; #FF6347; #FF7F50; #FF4500"; // Shades of orange-red
        } else if (Strings.equal(sun, "White-Dwarf")) {
            return "#FFFFFF; #F8F8FF; #F0F8FF; #FFFFFF"; // Shades of white
        } else if (Strings.equal(sun, "Neutron-Star")) {
            return "#2F4F4F; #708090; #778899; #2F4F4F"; // Shades of slate gray
        }
    }

    function getPlanetColor(
        string memory planet
    ) private pure returns (string memory planetColor) {
        if (Strings.equal(planet, "Habitable")) {
            return "#228B22; #006400; #8FBC8F; #228B22"; // Habitable: Shades of Green
        } else if (Strings.equal(planet, "Gas-Giant")) {
            return "#FFA500; #FF8C00; #FF7F50; #FFA500"; // Gas Giant: Shades of Orange
        } else if (Strings.equal(planet, "Ice-Giant")) {
            return "#00BFFF; #1E90FF; #4169E1; #00BFFF"; // Ice Giant: Shades of Blue
        } else if (Strings.equal(planet, "Artificial")) {
            return "#808080; #A9A9A9; #C0C0C0; #808080"; // Artificial: Shades of Grey
        } else if (Strings.equal(planet, "Terraformed")) {
            return "#FFFF00; #FFD700; #FFA500; #FFFF00"; // Terraformed: Shades of Yellow
        }
    }

    function getOrbitSpeed(
        OrbitSpeed _orbitSpeed
    ) private pure returns (string memory) {
        if (OrbitSpeed.Crawl == _orbitSpeed) {
            return "Crawl";
        } else if (OrbitSpeed.Cruise == _orbitSpeed) {
            return "Cruise";
        } else if (OrbitSpeed.Dash == _orbitSpeed) {
            return "Dash";
        }
        return "Undefined";
    }

    function getPlanetSize(
        PlanetSize _planetSize
    ) private pure returns (string memory) {
        if (PlanetSize.Speck == _planetSize) {
            return "Speck";
        } else if (PlanetSize.Globe == _planetSize) {
            return "Globe";
        } else if (PlanetSize.Titan == _planetSize) {
            return "Titan";
        }
        return "Undefined";
    }

    function generateStar(
        uint256 _seed,
        uint256 _index
    ) public pure returns (string memory) {
        uint256 posX = uint256(
            keccak256(abi.encodePacked(_seed, "starPosX", _index))
        ) % 640;
        uint256 posY = uint256(
            keccak256(abi.encodePacked(_seed, "starPosY", _index))
        ) % 640; // Full height now
        uint256 size = (uint256(
            keccak256(abi.encodePacked(_seed, "starSize", _index))
        ) % 3) + 1; // Smaller stars
        uint256 duration = (uint256(
            keccak256(abi.encodePacked(_seed, "starDuration", _index))
        ) % 4) + 1;

        return
            string(
                abi.encodePacked(
                    '<circle cx="',
                    Strings.toString(posX),
                    '" cy="',
                    Strings.toString(posY),
                    '" r="',
                    Strings.toString(size),
                    '" fill="rgba(255,255,255,0.1)">', // Semi-transparent fill
                    '<animate attributeName="r" values="',
                    Strings.toString(size - 1),
                    ";",
                    Strings.toString(size),
                    ";",
                    Strings.toString(size - 1),
                    '" dur="',
                    Strings.toString(duration),
                    's" repeatCount="indefinite"/>',
                    '<animate attributeName="fill" values="rgb(255,255,255);rgb(192,192,192);rgb(128,128,128);rgb(64,64,64);rgb(255,255,255)" dur="5s" repeatCount="indefinite"/>',
                    "</circle>"
                )
            );
    }
}