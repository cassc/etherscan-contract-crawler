// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./StringUtils.sol";
import "./Random.sol";

library WorldBuilder {
    struct PlanetDetails {
        uint i;
        string iStr;
        uint radius;
        uint randomSeed;
    } 
    
    function build(uint randomSeed) internal pure returns (string memory) {
        string memory bgGradient = string(abi.encodePacked(
            "linear-gradient(", 
            Random.randomIntStr(randomSeed, 0, 360), 
            "deg, ", Random.randomColour(randomSeed + 1), " 0%, ", 
            Random.randomColour(randomSeed + 2), " 35%, ", 
            Random.randomColour(randomSeed + 3), " 100%)"));

        string memory defs = string(abi.encodePacked("<defs><clipPath id='mcp'><rect x='0' y='0' width='1e3' height='1e3'/></clipPath></defs>"));
        string memory shapes = string(abi.encodePacked(
            getStars(randomSeed),
            getPlanets(randomSeed), 
            getMountains(randomSeed), 
            getWater(randomSeed),
            getClouds(randomSeed)
        ));

        return string(abi.encodePacked("<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 1e3 1e3' style='background-image:", bgGradient, "'>", defs, "<g clip-path='url(#mcp)'>", shapes, "</g></svg>"));
    }

// STARS 

    function getStars(uint randomSeed) private pure returns (string memory) {
        return string(abi.encodePacked(
            "<filter id='sf'>"
                "<feTurbulence baseFrequency='0.", Random.randomIntStr(randomSeed, 15, 40), "' seed='", StringUtils.uintToString(randomSeed), "'/>"
                "<feColorMatrix values='0 0 0 9 -4 "
                    "0 0 0 9 -4 "
                    "0 0 0 9 -4 "
                    "0 0 0 0 1'/>"
            "</filter>"
            "<rect width='100%' height='100%' opacity='50%' filter='url(#sf)'/>"
        ));
    }

// PLANETS

    function getPlanetCount(uint planetSeed) private pure returns (uint)  {
        uint percent = Random.randomInt(planetSeed * 2, 0, 100);

        if (percent < 5) {
            return 0;
        } else if (percent < 15) {
            return 1;
        } else if (percent < 40) {
            return 2;
        } else if (percent < 85) {
            return 3;
        } else if (percent < 95) {
            return 4;
        } else {
            return 5;
        }
    }

    function getPlanets(uint planetSeed) private pure returns (string memory) {
        string memory planets = "";

        for (uint i = 0; i < getPlanetCount(planetSeed); i++) {
            PlanetDetails memory details = PlanetDetails(i, StringUtils.uintToString(i), Random.randomInt(planetSeed * 2 + i, 20, 200), planetSeed * 2 + i);

            planets = string(abi.encodePacked(planets,
                                    getPlanetGradient(details),
                                    getPlanetFilter(details),
                                    getPlanetCircle(details)
            )); 
        }

        return planets;
    }

    function getPlanetGradient(PlanetDetails memory details) private pure returns (string memory) {
        return string(abi.encodePacked(
            "<defs><radialGradient id='pg", details.iStr, "' fx='50%' fy='50%'>",
                stopOffset(Random.randomIntStr(details.randomSeed, 3, 25), Random.randomColour(details.randomSeed + details.i)),
                stopOffset(Random.randomIntStr(details.randomSeed, 75, 97), Random.randomColour(details.randomSeed + details.i + 10)),
            "</radialGradient></defs>"));
    }

    function getPlanetFilter(PlanetDetails memory details) private pure returns (string memory) {
            return string(abi.encodePacked(
                "<filter id='pf", details.iStr, "' x='-25%' y='-25%' width='150%' height='150%'>", 
                    getTurbulence(details), 
                    getLighting(details),
                    "<feComposite result='p' operator='in' in2='SourceGraphic'/>"
                    "<feGaussianBlur stdDeviation='8' result='cb'/>"
                    "<feMerge>"
                        "<feMergeNode in='cb'/>"
                        "<feMergeNode in='p'/>"
                    "</feMerge>"
                "</filter>"
            ));
    }

    function getTurbulence(PlanetDetails memory details) private pure returns (string memory) {
        string memory turbulenceType = Random.randomInt(details.randomSeed, 0, 10) > 5 ? 'fractalNoise' : 'turbulence';
        return string(abi.encodePacked(
            "<feTurbulence type='", turbulenceType,"' baseFrequency='", getBaseFrequency(details),"' seed='", StringUtils.uintToString(details.randomSeed), "' numOctaves='", Random.randomIntStr(details.randomSeed, 3, 10), "'/>"
        ));
    }
    
    function getBaseFrequency(PlanetDetails memory details) private pure returns (string memory) {
        // Intentionally make the baseFrequency y value larger than the x value
        // to create horizontal striping patterns
        return string(abi.encodePacked(
            "0.00",  StringUtils.uintToString(Random.randomInt(details.randomSeed, 1, 3) * 1e3 / (details.radius * 2)), 
            " 0.0", StringUtils.uintToString(Random.randomInt(details.randomSeed, 2, 3) * 1e3 / details.radius)
        ));
    }    

    function getLighting(PlanetDetails memory details) private pure returns (string memory) {
        return string(abi.encodePacked(
            "<feDiffuseLighting lighting-color='", Random.randomColour(details.randomSeed + details.i), "' surfaceScale='", Random.randomIntStr(details.randomSeed, 5, 10), "'>"
                "<feDistantLight elevation='", Random.randomIntStr(details.randomSeed, 30, 100), "'/>"
            "</feDiffuseLighting>"        
        ));
    }

    function getPlanetCircle(PlanetDetails memory details) private pure returns (string memory) {
        string memory x = Random.randomIntStr(details.randomSeed, 50, 950);
        string memory y = Random.randomIntStr(details.randomSeed, 0, 500);

        return string(abi.encodePacked(
            getTextureCircle(x, y, details),
            getGradientCircle(x, y, details)
        ));
    }
    function getTextureCircle(string memory x, string memory y, PlanetDetails memory details) private pure returns (string memory) {
        return string(abi.encodePacked(
            "<circle cx='", x, "' cy='", y, "' r='", StringUtils.uintToString(details.radius), "' filter='url(#pf", details.iStr, ")'/>"
        ));

    }
    function getGradientCircle(string memory x, string memory y, PlanetDetails memory details) private pure returns (string memory) {
        return string(abi.encodePacked(
            "<circle cx='", x, "' cy='", y, "' r='", StringUtils.uintToString(details.radius),  "' fill='url(#pg", details.iStr, ")' opacity='40%'/>"                                
        ));        
    }

// MOUNTAINS

    function getMountains(uint randomSeed) private pure returns (string memory) {
        uint[2][51] memory polygonPoints = buildLine(randomSeed, 1e3, 51);
        string memory polygonPointsStr;

        for (uint i; i < 51; i++) {
            uint[2] memory point = polygonPoints[i];
            polygonPointsStr = string(abi.encodePacked(polygonPointsStr, " ", StringUtils.uintToString(point[0]), ",", StringUtils.uintToString(point[1])));    
        }
        polygonPointsStr = string(abi.encodePacked(polygonPointsStr, " 1e3,1e3 -1,1e3"));    

        string memory filter = string(abi.encodePacked(
                "<filter id='mf'>"
                        "<feTurbulence type='fractalNoise' baseFrequency='0.0", Random.randomIntStr(randomSeed, 10, 30), "' numOctaves='15'/>"
                        "<feDiffuseLighting lighting-color='white' surfaceScale='", Random.randomIntStr(randomSeed, 1, 3), "'>"
                            "<feDistantLight azimuth='45' elevation='10'/>"
                        "</feDiffuseLighting>"
                    "<feComposite result='m' operator='in' in2='SourceGraphic'/>"
                    "<feGaussianBlur stdDeviation='8'/>"
                    "<feColorMatrix type='matrix' values='"
                        "0 0 0 0 0 "
                        "0 0 0 0 0 "
                        "0 0 0 0 0 "
                        "0 0 0 0.5 0' "
                        "result='b'"
                        "/>"
                    "<feMerge>"
                        "<feMergeNode in='m'/>"
                        "<feMergeNode in='b'/>"
                    "</feMerge>"
                "</filter>"));

        string memory mountainColour = Random.randomColour(randomSeed + 3);
        string memory gradient = string(abi.encodePacked(
            "<defs>"
                "<linearGradient id='mg'>",
                    stopOffset('5', mountainColour),
                    stopOffset(Random.randomIntStr(randomSeed, 20, 80), Random.randomColour(randomSeed + 5)),
                    stopOffset('95', mountainColour),
                "</linearGradient>"
            "</defs>"));
        string memory opacity = Random.randomIntStr(randomSeed, 30, 60);    

        string memory shadingFilter = string(abi.encodePacked(
             "<filter id='msf'>"
                "<feTurbulence type='fractalNoise' baseFrequency='0.004 0.01' numOctaves='2' seed='", StringUtils.uintToString(randomSeed), "'/>"
                "<feColorMatrix values='0 1 0 0 -4 "
                                        "1 1 0 0 -4 "
                                        "1 0 0 0 -4 "
                                        "0 1 1 0 -1'/>"
                "<feComposite operator='in' in2='SourceGraphic'/>"
                "</filter>"
        ));

        return string(abi.encodePacked(
            filter, 
            gradient, 
            shadingFilter,
            "<polygon points='", polygonPointsStr, "' filter='url(#mf)'/>"
            "<polygon points='", polygonPointsStr, "' fill='url(#mg)' opacity='", opacity, "%'/>"
            "<polygon points='", polygonPointsStr, "' filter='url(#msf)'/>"
        )); 
    }
    
    function stopOffset(string memory offset, string memory color)  private pure returns (string memory) {
        return string(abi.encodePacked("<stop offset='", offset, "%' stop-color='", color, "'/>"));
    }

    function buildLine(uint randomSeed, uint width, uint pointCount) private pure returns (uint[2][51] memory) {
        uint interval = width / (pointCount - 1);
        uint[2][51] memory points;
        uint currentY = 500; // starting currentY is yOffset

        for (uint i = 0; i < pointCount; i++) {
            uint x = i * interval;
            uint pointSeed = (randomSeed + i) + 1e3;
            uint yChange = Random.randomInt(pointSeed, 0, 20);
            bool up = Random.randomInt(pointSeed, 0, 100) > 50;

            currentY = up ? currentY + yChange : currentY - yChange;

            points[i] = [x, currentY];
        }
        // console.log("POINTS: " + points);
        return points;
    }

// CLOUDS

    function getClouds(uint randomSeed) private pure returns (string memory) {
        string memory baseFrequency1 = Random.randomIntStr(randomSeed * 2, 1, 8);
        string memory r = Random.randomIntStr(randomSeed + 10, 0, 9);
        string memory g = Random.randomIntStr(randomSeed + 20, 0, 9);
        string memory b = Random.randomIntStr(randomSeed + 30, 0, 9);
    
        return string(abi.encodePacked(
            "<filter id='cf'>",
                "<feTurbulence type='fractalNoise' baseFrequency='0.00", baseFrequency1, " 0.02' numOctaves='2' seed='", StringUtils.uintToString(randomSeed), "'/>"
                "<feColorMatrix type='matrix' values='"
                          "0 0 0 0.", r, " 0 "
                          "0 0 0 0.", g, " 0 "
                          "0 0 0 0.", b, " 0 "
                          "0 0 0 1 0'"
            "/>"
            "</filter>"
            "<rect width='100%' height='100%' opacity='", Random.randomIntStr(randomSeed * 5, 60, 80), "%' filter='url(#cf)'/>"));
    }

// WATER

    function getWater(uint randomSeed) private pure returns (string memory) {
        string memory shorelineCurves = "";
        uint xPos;
        bool up = Random.randomInt(randomSeed, 0, 1) > 0;

        while (xPos < 1e3) {
            uint segmentWidth = Random.randomInt(randomSeed + xPos, 150, 300);
            
            if (segmentWidth > 1e3 - xPos) {
                segmentWidth = 1e3 - xPos;
            } else if ((1e3 - xPos) - segmentWidth < 100) {
                segmentWidth += (1e3 - xPos) - segmentWidth;
            }

            uint yDelta = Random.randomInt(randomSeed + xPos, 10, 30);
            uint yPos = (up ? 800 - yDelta : 800 + yDelta);
            
            shorelineCurves = string(abi.encodePacked(shorelineCurves,
                "C ", StringUtils.uintToString(xPos), " 800, ", 
                StringUtils.uintToString(xPos + segmentWidth / 2), " ", StringUtils.uintToString(yPos), ", ", 
                StringUtils.uintToString(xPos + segmentWidth), " 800 "
            ));
            
            xPos += segmentWidth;
            up = !up;
        }
        // // console.log("SHORELINE CURVES: " + shorelineCurves);

        string memory floodColor = Random.randomColour(randomSeed * 4);
        string memory waterBlur = Random.randomIntStr(randomSeed, 1, 3);

        return string(abi.encodePacked(
            "<filter id='wf'>"
                "<feTurbulence baseFrequency='0.00", Random.randomIntStr(randomSeed * 2, 2, 9), " .11' numOctaves='4' seed='", StringUtils.uintToString(randomSeed), "'/>"
                "<feComponentTransfer result='wave'>"
                    "<feFuncR type='linear' slope='0.1' intercept='-0.05'/>"
                    "<feFuncG type='gamma' amplitude='0.75' exponent='0.6' offset='0.05'/>"
                    "<feFuncB type='gamma' amplitude='0.8' exponent='0.4' offset='0.05'/>"
                    "<feFuncA type='linear' slope='", Random.randomIntStr(randomSeed, 1, 10), "'/>"
                "</feComponentTransfer>"
                "<feFlood flood-color='", floodColor, "'/>"
                "<feComposite in='wave'/>"
                "<feComposite in2='SourceAlpha' operator='in'/>"
                "<feGaussianBlur stdDeviation='", waterBlur, "' result='glow'/>"
                "<feComposite in2='glow' operator='atop' result='g' />"
                "<feMerge>"
                    "<feMergeNode/>"
                    "<feMergeNode/>"
                "</feMerge>"

            "</filter>"
            "<path d='M 0 1e3 L 0 800 ", shorelineCurves, " L 1e3 800 L 1e3 1e3' filter='url(#wf)' fill-opacity='70%'/>"
        )); 
    }
 
    function getTraits(uint seed) internal pure returns (string memory) {
        return string(abi.encodePacked('"attributes": '
            '[{"trait_type": "seed", "value": ', StringUtils.uintToString(seed), '},'
            '{"trait_type": "stars", "value": "', getStarType(seed),'"},'
            '{"trait_type": "planets", "value": ', StringUtils.uintToString(getPlanetCount(seed)), '},'
            '{"trait_type": "mountains", "value": "', getMountainType(seed),'"},'
            '{"trait_type": "water", "value": "', getWaterType(seed),'"},'
            '{"trait_type": "clouds", "value": "', getCloudType(seed),'"}'
            ']'));
    }

    function getStarType(uint seed) internal pure returns (string memory) {
        uint density = Random.randomInt(seed, 15, 40);
        if (density < 22) {
            return "sparse";
        } else if (density > 33) {
            return "dense";
        } else {
            return "distributed";
        }
    }
    
    function getMountainType(uint seed) internal pure returns (string memory) {
        uint mountainFrequency = Random.randomInt(seed, 10, 30);
        uint mountainScale = Random.randomInt(seed, 1, 3);
        if (mountainFrequency < 20 && mountainScale < 2) {
            return "soft";
        } else if (mountainFrequency > 20 && mountainScale > 2) {
            return "rocky";
        } else {
            return "rugged";
        }
    }

    function getWaterType(uint seed) internal pure returns (string memory) {
        uint choppiness = Random.randomInt(seed * 2, 2, 9);
        if (choppiness < 4) {
            return "calm";
        } else if (choppiness > 6) {
            return "rough";
        } else {
            return "choppy";
        }
    }

    function getCloudType(uint seed) internal pure returns (string memory) {
        uint cloud = Random.randomInt(seed * 2, 1, 8);
        if (cloud < 3) {
            return "stratus";
        } else if ( cloud > 6) {
            return "cumulus";
        } else {
            return "stratocumulus";
        }
    }
}