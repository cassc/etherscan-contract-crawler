// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/IKarmaScore.sol";
import "./NilProtocolUtils.sol";
import "../libraries/NilProtocolUtils.sol";

library SeedPhraseUtils {
    using Strings for uint256;
    using Strings for uint16;
    using Strings for uint8;

    struct Random {
        uint256 seed;
        uint256 offsetBit;
    }

    struct Colors {
        string background;
        string panel;
        string panel2;
        string panelStroke;
        string selectedCircleStroke;
        string selectedCircleFill;
        string selectedCircleFill2;
        string negativeCircleStroke;
        string negativeCircleFill;
        string blackOrWhite;
        string dynamicOpacity;
        string backgroundCircle;
    }

    struct Attrs {
        bool showStroke;
        bool border;
        bool showPanel;
        bool backgroundSquare;
        bool bigBackgroundCircle;
        bool showGrid;
        bool backgroundCircles;
        bool greyscale;
        bool doublePanel;
        uint16 bipWordId;
        uint16 secondBipWordId;
    }

    uint8 internal constant strokeWeight = 7;
    uint16 internal constant segmentSize = 100;
    uint16 internal constant radius = 50;
    uint16 internal constant padding = 10;
    uint16 internal constant viewBox = 1600;
    uint16 internal constant panelWidth = segmentSize * 4;
    uint16 internal constant panelHeight = segmentSize * 10;
    uint16 internal constant singlePanelX = (segmentSize * 6);
    uint16 internal constant doublePanel1X = (segmentSize * 3);
    uint16 internal constant doublePanel2X = doublePanel1X + (segmentSize * 6);
    uint16 internal constant panelY = (segmentSize * 3);

    function generateSeed(uint256 tokenId, uint256 vrfRandomValue) external view returns (bytes32) {
        return keccak256(abi.encode(tokenId, block.timestamp, block.difficulty, vrfRandomValue));
    }

    function _shouldAddTrait(
        bool isTrue,
        bytes memory trueName,
        bytes memory falseName,
        uint8 prevRank,
        uint8 newRank,
        bytes memory traits
    ) internal pure returns (bytes memory, uint8) {
        if (isTrue) {
            traits = abi.encodePacked(traits, ',{"value": "', trueName, '"}');
        }
        // Only add the falsy trait if it's named (e.g. there's no negative version of "greyscale")
        else if (falseName.length != 0) {
            traits = abi.encodePacked(traits, ',{"value": "', falseName, '"}');
        }

        // Return new (higher rank if trait is true)
        return (traits, (isTrue ? newRank : prevRank));
    }

    function tokenTraits(Attrs memory attributes) internal pure returns (bytes memory traits, uint8 rarityRating) {
        rarityRating = 0;
        traits = abi.encodePacked("[");
        // Add both words to trait if a double panel
        if (attributes.doublePanel) {
            traits = abi.encodePacked(
                traits,
                '{"trait_type": "Double Panel BIP39 IDs", "value": "',
                attributes.bipWordId.toString(),
                " - ",
                attributes.secondBipWordId.toString(),
                '"},',
                '{"value": "Double Panel"}'
            );
        } else {
            traits = abi.encodePacked(
                traits,
                '{"trait_type": "BIP39 ID",  "display_type": "number", "max_value": 2048, "value": ',
                attributes.bipWordId.toString(),
                "}"
            );
        }
        // Stroke trait - rank 1
        (traits, rarityRating) = _shouldAddTrait(
            !attributes.showStroke,
            "No Stroke",
            "OG Stroke",
            rarityRating,
            1,
            traits
        );
        // Border - rank 2
        (traits, rarityRating) = _shouldAddTrait(attributes.border, "Border", "", rarityRating, 2, traits);
        // No Panel - rank 3
        (traits, rarityRating) = _shouldAddTrait(
            !attributes.showPanel,
            "No Panel",
            "OG Panel",
            rarityRating,
            3,
            traits
        );
        // Symmetry Group Square - rank 4
        (traits, rarityRating) = _shouldAddTrait(
            attributes.backgroundSquare,
            "Group Square",
            "",
            rarityRating,
            4,
            traits
        );
        // Symmetry Group Circle - rank 5
        (traits, rarityRating) = _shouldAddTrait(
            attributes.bigBackgroundCircle,
            "Group Circle",
            "",
            rarityRating,
            5,
            traits
        );
        // Caged - rank 6
        (traits, rarityRating) = _shouldAddTrait(attributes.showGrid, "Caged", "", rarityRating, 6, traits);
        // Bubblewrap - rank 7
        (traits, rarityRating) = _shouldAddTrait(
            attributes.backgroundCircles,
            "Bubblewrap",
            "",
            rarityRating,
            7,
            traits
        );
        // Monochrome - rank 8
        (traits, rarityRating) = _shouldAddTrait(attributes.greyscale, "Monochrome", "", rarityRating, 8, traits);

        traits = abi.encodePacked(traits, "]");
    }

    /**
     * @notice Generates the art defining attributes
     * @param bipWordId bip39 word id
     * @param secondBipWordId ^ only for a double panel
     * @param random RNG
     * @param predefinedRarity double panels trait to carry over
     * @return attributes struct
     */
    function tokenAttributes(
        uint16 bipWordId,
        uint16 secondBipWordId,
        Random memory random,
        uint8 predefinedRarity
    ) internal pure returns (Attrs memory attributes) {
        attributes = Attrs({
            showStroke: (predefinedRarity == 1) ? false : _boolPercentage(random, 70), // rank 1
            border: (predefinedRarity == 2) ? true : _boolPercentage(random, 30), // rank 2
            showPanel: (predefinedRarity == 3) ? false : _boolPercentage(random, 80), // rank 3
            backgroundSquare: (predefinedRarity == 4) ? true : _boolPercentage(random, 18), // rank 4
            bigBackgroundCircle: (predefinedRarity == 5) ? true : _boolPercentage(random, 12), // rank = 5
            showGrid: (predefinedRarity == 6) ? true : _boolPercentage(random, 6), // rank 6
            backgroundCircles: (predefinedRarity == 7) ? true : _boolPercentage(random, 4), // rank 7
            greyscale: (predefinedRarity == 8) ? true : _boolPercentage(random, 2), // rank 8
            bipWordId: bipWordId,
            doublePanel: (secondBipWordId > 0),
            secondBipWordId: secondBipWordId
        });

        // Rare attributes should always superseed less-rare
        // If greyscale OR grid is true then turn on stroke (as it is required)
        if (attributes.showGrid || attributes.greyscale) {
            attributes.showStroke = true;
        }
        // backgroundCircles superseeds grid (they cannot co-exist)
        if (attributes.backgroundCircles) {
            attributes.showGrid = false;
        }
        // Border cannot be on if background shapes are turned on
        if (attributes.bigBackgroundCircle || attributes.backgroundSquare) {
            attributes.border = false;
            // Big Background Shapes cannot co-exist
            if (attributes.bigBackgroundCircle) {
                attributes.backgroundSquare = false;
            }
        }
    }

    /**
     * @notice Converts a tokenId (uint256) into the formats needed to generate the art
     * @param tokenId tokenId (also the BIP39 word)
     * @return tokenArray with prepended 0's (if tokenId is less that 4 digits) also returns in string format
     */
    function _transformTokenId(uint256 tokenId) internal pure returns (uint8[4] memory tokenArray, string memory) {
        bytes memory tokenString;
        uint8 digit;

        for (int8 i = 3; i >= 0; i--) {
            digit = uint8(tokenId % 10); // This returns the final digit in the token
            if (tokenId > 0) {
                tokenId = tokenId / 10; // this removes the last digit from the token as we've grabbed the digit already
                tokenArray[uint8(i)] = digit;
            }
            tokenString = abi.encodePacked(digit.toString(), tokenString);
        }

        return (tokenArray, string(tokenString));
    }

    function _renderText(string memory text, string memory color) internal pure returns (bytes memory svg) {
        svg = abi.encodePacked(
            "<text x='1500' y='1500' text-anchor='end' style='font:700 36px &quot;Courier New&quot;;fill:",
            color,
            ";opacity:.4'>#",
            text,
            "</text>"
        );

        return svg;
    }

    function _backgroundShapeSizing(Random memory random, Attrs memory attributes)
        internal
        pure
        returns (uint16, uint16)
    {
        uint256 idx;
        // If we DON'T have a 'doublePanel' or 'no panel' we can return the default sizing
        if (!attributes.doublePanel && attributes.showPanel) {
            uint16[2][6] memory defaultSizing = [
                [1275, 200],
                [1150, 375],
                [900, 300],
                [925, 225],
                [850, 150],
                [775, 125]
            ];
            idx = SeedPhraseUtils._next(random, 0, defaultSizing.length);
            return (defaultSizing[idx][0], defaultSizing[idx][1]);
        }

        // Otherwise we need to return some slightly different data
        if (attributes.bigBackgroundCircle) {
            uint16[2][4] memory restrictedCircleDimensions = [[1150, 150], [1275, 200], [1300, 100], [1350, 200]];
            idx = SeedPhraseUtils._next(random, 0, restrictedCircleDimensions.length);
            return (restrictedCircleDimensions[idx][0], restrictedCircleDimensions[idx][1]);
        }

        // Else we can assume that it is backgroundSquares
        uint16[2][4] memory restrictedSquareDimensions = [[1150, 50], [1100, 125], [1275, 200], [1300, 150]];
        idx = SeedPhraseUtils._next(random, 0, restrictedSquareDimensions.length);
        return (restrictedSquareDimensions[idx][0], restrictedSquareDimensions[idx][1]);
    }

    function _getStrokeStyle(
        bool showStroke,
        string memory color,
        string memory opacity,
        uint8 customStrokeWeight
    ) internal pure returns (bytes memory strokeStyle) {
        if (showStroke) {
            strokeStyle = abi.encodePacked(
                " style='stroke-opacity:",
                opacity,
                ";stroke:",
                color,
                ";stroke-width:",
                customStrokeWeight.toString(),
                "' "
            );

            return strokeStyle;
        }
    }

    function _getPalette(Random memory random, Attrs memory attributes) internal pure returns (Colors memory) {
        string[6] memory selectedPallet;
        uint8[6] memory lumosity;
        if (attributes.greyscale) {
            selectedPallet = ["#f8f9fa", "#c3c4c4", "#909091", "#606061", "#343435", "#0a0a0b"];
            lumosity = [249, 196, 144, 96, 52, 10];
        } else {
            uint256 randPalette = SeedPhraseUtils._next(random, 0, 25);
            if (randPalette == 0) {
                selectedPallet = ["#ffe74c", "#ff5964", "#ffffff", "#6bf178", "#35a7ff", "#5b3758"];
                lumosity = [225, 125, 255, 204, 149, 65];
            } else if (randPalette == 1) {
                selectedPallet = ["#ff0000", "#ff8700", "#e4ff33", "#a9ff1f", "#0aefff", "#0a33ff"];
                lumosity = [54, 151, 235, 221, 191, 57];
            } else if (randPalette == 2) {
                selectedPallet = ["#f433ab", "#cb04a5", "#934683", "#65334d", "#2d1115", "#e0e2db"];
                lumosity = [101, 58, 91, 64, 23, 225];
            } else if (randPalette == 3) {
                selectedPallet = ["#f08700", "#f6aa28", "#f9d939", "#00a6a6", "#bbdef0", "#23556c"];
                lumosity = [148, 177, 212, 131, 216, 76];
            } else if (randPalette == 4) {
                selectedPallet = ["#f7e6de", "#e5b59e", "#cb7d52", "#bb8f77", "#96624a", "#462b20"];
                lumosity = [233, 190, 138, 151, 107, 48];
            } else if (randPalette == 5) {
                selectedPallet = ["#f61379", "#d91cbc", "#da81ee", "#5011e4", "#4393ef", "#8edef6"];
                lumosity = [75, 80, 156, 46, 137, 207];
            } else if (randPalette == 6) {
                selectedPallet = ["#010228", "#006aa3", "#005566", "#2ac1df", "#82dded", "#dbf5fa"];
                lumosity = [5, 88, 68, 163, 203, 240];
            } else if (randPalette == 7) {
                selectedPallet = ["#f46036", "#5b85aa", "#414770", "#372248", "#171123", "#f7f5fb"];
                lumosity = [124, 127, 73, 41, 20, 246];
            } else if (randPalette == 8) {
                selectedPallet = ["#393d3f", "#fdfdff", "#c6c5b9", "#62929e", "#546a7b", "#c52233"];
                lumosity = [60, 253, 196, 137, 103, 70];
            } else if (randPalette == 9) {
                selectedPallet = ["#002626", "#0e4749", "#95c623", "#e55812", "#efe7da", "#8ddbe0"];
                lumosity = [30, 59, 176, 113, 232, 203];
            } else if (randPalette == 10) {
                selectedPallet = ["#03071e", "#62040d", "#d00000", "#e85d04", "#faa307", "#ffcb47"];
                lumosity = [8, 25, 44, 116, 170, 205];
            } else if (randPalette == 11) {
                selectedPallet = ["#f56a00", "#ff931f", "#ffd085", "#20003d", "#7b2cbf", "#c698eb"];
                lumosity = [128, 162, 213, 11, 71, 168];
            } else if (randPalette == 12) {
                selectedPallet = ["#800016", "#ffffff", "#ff002b", "#407ba7", "#004e89", "#00043a"];
                lumosity = [29, 255, 57, 114, 66, 7];
            } else if (randPalette == 13) {
                selectedPallet = ["#d6d6d6", "#f9f7dc", "#ffee32", "#ffd100", "#202020", "#6c757d"];
                lumosity = [214, 245, 228, 204, 32, 116];
            } else if (randPalette == 14) {
                selectedPallet = ["#fff5d6", "#ccc5b9", "#403d39", "#252422", "#eb5e28", "#bb4111"];
                lumosity = [245, 198, 61, 36, 120, 87];
            } else if (randPalette == 15) {
                selectedPallet = ["#0c0f0a", "#ff206e", "#fbff12", "#41ead4", "#6c20fd", "#ffffff"];
                lumosity = [14, 85, 237, 196, 224, 255];
            } else if (randPalette == 16) {
                selectedPallet = ["#fdd8d8", "#f67979", "#e51010", "#921314", "#531315", "#151315"];
                lumosity = [224, 148, 61, 46, 33, 20];
            } else if (randPalette == 17) {
                selectedPallet = ["#000814", "#002752", "#0066cc", "#f5bc00", "#ffd60a", "#ffee99"];
                lumosity = [7, 34, 88, 187, 208, 235];
            } else if (randPalette == 18) {
                selectedPallet = ["#010b14", "#022d4f", "#fdfffc", "#2ec4b6", "#e71d36", "#ff990a"];
                lumosity = [10, 38, 254, 163, 74, 164];
            } else if (randPalette == 19) {
                selectedPallet = ["#fd650d", "#d90368", "#820263", "#291720", "#06efa9", "#0d5943"];
                lumosity = [127, 56, 36, 27, 184, 71];
            } else if (randPalette == 20) {
                selectedPallet = ["#002914", "#005200", "#34a300", "#70e000", "#aef33f", "#e0ff85"];
                lumosity = [31, 59, 128, 184, 215, 240];
            } else if (randPalette == 21) {
                selectedPallet = ["#001413", "#fafffe", "#6f0301", "#a92d04", "#f6b51d", "#168eb6"];
                lumosity = [16, 254, 26, 68, 184, 119];
            } else if (randPalette == 22) {
                selectedPallet = ["#6a1f10", "#d53e20", "#f7d1ca", "#c4f3fd", "#045362", "#fffbfa"];
                lumosity = [46, 92, 217, 234, 67, 252];
            } else if (randPalette == 23) {
                selectedPallet = ["#6b42ff", "#a270ff", "#dda1f7", "#ffd6eb", "#ff8fb2", "#f56674"];
                lumosity = [88, 133, 180, 224, 169, 133];
            } else if (randPalette == 24) {
                selectedPallet = ["#627132", "#273715", "#99a271", "#fefae1", "#e0a35c", "#bf6b21"];
                lumosity = [105, 49, 157, 249, 171, 120];
            }
        }

        // Randomize pallet order here...
        return _shufflePallet(random, selectedPallet, lumosity, attributes);
    }

    function _shufflePallet(
        Random memory random,
        string[6] memory hexColors,
        uint8[6] memory lumaValues,
        Attrs memory attributes
    ) internal pure returns (Colors memory) {
        // Shuffle colors and luma values with the same index
        for (uint8 i = 0; i < hexColors.length; i++) {
            // n = Pick random i > (array length - i)
            uint256 n = i + SeedPhraseUtils._next(random, 0, (hexColors.length - i));
            // temp = Temporarily store value from array[n]
            string memory tempHex = hexColors[n];
            uint8 tempLuma = lumaValues[n];
            // Swap n value with i value
            hexColors[n] = hexColors[i];
            hexColors[i] = tempHex;
            lumaValues[n] = lumaValues[i];
            lumaValues[i] = tempLuma;
        }

        Colors memory pallet = Colors({
            background: hexColors[0],
            panel: hexColors[1],
            panel2: "", // panel2 should match selected circles
            panelStroke: hexColors[2],
            selectedCircleStroke: hexColors[2], // Match panel stroke
            negativeCircleStroke: hexColors[3],
            negativeCircleFill: hexColors[4],
            selectedCircleFill: hexColors[5],
            selectedCircleFill2: "", // should match panel1
            backgroundCircle: "",
            blackOrWhite: lumaValues[0] < 150 ? "#fff" : "#000",
            dynamicOpacity: lumaValues[0] < 150 ? "0.08" : "0.04"
        });

        if (attributes.doublePanel) {
            pallet.panel2 = pallet.selectedCircleFill;
            pallet.selectedCircleFill2 = pallet.panel;
        }

        if (attributes.bigBackgroundCircle) {
            // Set background circle colors here
            pallet.backgroundCircle = pallet.background;
            pallet.background = pallet.panel;
            // Luma based on 'new background', previous background is used for bgCircleColor)
            pallet.blackOrWhite = lumaValues[1] < 150 ? "#fff" : "#000";
            pallet.dynamicOpacity = lumaValues[1] < 150 ? "0.08" : "0.04";
        }

        return pallet;
    }

    /// @notice get an random number between (min and max) using seed and offseting bits
    ///         this function assumes that max is never bigger than 0xffffff (hex color with opacity included)
    /// @dev this function is simply used to get random number using a seed.
    ///      if does bitshifting operations to try to reuse the same seed as much as possible.
    ///      should be enough for anyth
    /// @param random the randomizer
    /// @param min the minimum
    /// @param max the maximum
    /// @return result the resulting pseudo random number
    function _next(
        Random memory random,
        uint256 min,
        uint256 max
    ) internal pure returns (uint256 result) {
        uint256 newSeed = random.seed;
        uint256 newOffset = random.offsetBit + 3;

        uint256 maxOffset = 4;
        uint256 mask = 0xf;
        if (max > 0xfffff) {
            mask = 0xffffff;
            maxOffset = 24;
        } else if (max > 0xffff) {
            mask = 0xfffff;
            maxOffset = 20;
        } else if (max > 0xfff) {
            mask = 0xffff;
            maxOffset = 16;
        } else if (max > 0xff) {
            mask = 0xfff;
            maxOffset = 12;
        } else if (max > 0xf) {
            mask = 0xff;
            maxOffset = 8;
        }

        // if offsetBit is too high to get the max number
        // just get new seed and restart offset to 0
        if (newOffset > (256 - maxOffset)) {
            newOffset = 0;
            newSeed = uint256(keccak256(abi.encode(newSeed)));
        }

        uint256 offseted = (newSeed >> newOffset);
        uint256 part = offseted & mask;
        result = min + (part % (max - min));

        random.seed = newSeed;
        random.offsetBit = newOffset;
    }

    function _boolPercentage(Random memory random, uint256 percentage) internal pure returns (bool) {
        // E.G. If percentage = 30, and random = 0-29 we return true
        // Percentage = 1, random = 0 (TRUE)
        return (SeedPhraseUtils._next(random, 0, 100) < percentage);
    }

    /// @param random source of randomness (based on tokenSeed)
    /// @param attributes art attributes
    /// @return the json
    function render(SeedPhraseUtils.Random memory random, SeedPhraseUtils.Attrs memory attributes)
        external
        pure
        returns (string memory)
    {
        // Get color pallet
        SeedPhraseUtils.Colors memory pallet = SeedPhraseUtils._getPalette(random, attributes);

        //  Start SVG (viewbox & static patterns)
        bytes memory svg = abi.encodePacked(
            "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 1600 1600'><path fill='",
            pallet.background,
            "' ",
            SeedPhraseUtils._getStrokeStyle(attributes.border, pallet.blackOrWhite, "0.3", 50),
            " d='M0 0h1600v1600H0z'/>",
            "  <pattern id='panelCircles' x='0' y='0' width='.25' height='.1' patternUnits='objectBoundingBox'>",
            "<circle cx='50' cy='50' r='40' fill='",
            pallet.negativeCircleFill,
            "' ",
            SeedPhraseUtils._getStrokeStyle(attributes.showStroke, pallet.negativeCircleStroke, "1", strokeWeight),
            " /></pattern>"
        );
        // Render optional patterns (grid OR background circles)
        if (attributes.backgroundCircles) {
            svg = abi.encodePacked(
                svg,
                "<pattern id='backgroundCircles' x='0' y='0' width='100' height='100'",
                " patternUnits='userSpaceOnUse'><circle cx='50' cy='50' r='40' fill='",
                pallet.blackOrWhite,
                "' style='fill-opacity: ",
                pallet.dynamicOpacity,
                ";'></circle></pattern><path fill='url(#backgroundCircles)' d='M0 0h1600v1600H0z'/>"
            );
        } else if (attributes.showGrid) {
            svg = abi.encodePacked(
                svg,
                "<pattern id='grid' x='0' y='0' width='100' height='100'",
                " patternUnits='userSpaceOnUse'><rect x='0' y='0' width='100' height='100' fill='none' ",
                SeedPhraseUtils._getStrokeStyle(true, pallet.blackOrWhite, pallet.dynamicOpacity, strokeWeight),
                " /></pattern><path fill='url(#grid)' d='M0 0h1600v1600H0z'/>"
            );
        }
        if (attributes.bigBackgroundCircle) {
            (uint16 shapeSize, uint16 stroke) = SeedPhraseUtils._backgroundShapeSizing(random, attributes);
            // uint16 centerCircle = (viewBox / 2); // Viewbox = 1600, Center = 800
            svg = abi.encodePacked(
                svg,
                "<circle cx='800' cy='800' r='",
                (shapeSize / 2).toString(),
                "' fill='",
                pallet.backgroundCircle,
                "' stroke='",
                pallet.negativeCircleStroke,
                "' style='stroke-width:",
                stroke.toString(),
                ";stroke-opacity:0.3'/>"
            );
        } else if (attributes.backgroundSquare) {
            (uint16 shapeSize, uint16 stroke) = SeedPhraseUtils._backgroundShapeSizing(random, attributes);
            uint16 centerSquare = ((viewBox - shapeSize) / 2);
            svg = abi.encodePacked(
                svg,
                "<rect x='",
                centerSquare.toString(),
                "' y='",
                centerSquare.toString(),
                "' width='",
                shapeSize.toString(),
                "' height='",
                shapeSize.toString(),
                "' fill='",
                pallet.backgroundCircle,
                "' stroke='",
                pallet.negativeCircleStroke,
                "' style='stroke-width:",
                stroke.toString(),
                ";stroke-opacity:0.3'/>"
            );
        }

        // Double panel (only if holder has burned two tokens from the defined pairings)
        if (attributes.doublePanel) {
            (uint8[4] memory firstBipIndexArray, string memory firstBipIndexStr) = SeedPhraseUtils._transformTokenId(
                attributes.bipWordId
            );
            (uint8[4] memory secondBipIndexArray, string memory secondBipIndexStr) = SeedPhraseUtils._transformTokenId(
                attributes.secondBipWordId
            );

            svg = abi.encodePacked(
                svg,
                _renderSinglePanel(firstBipIndexArray, attributes, pallet, doublePanel1X, false),
                _renderSinglePanel(secondBipIndexArray, attributes, pallet, doublePanel2X, true)
            );

            // Create text
            bytes memory combinedText = abi.encodePacked(firstBipIndexStr, " - #", secondBipIndexStr);
            svg = abi.encodePacked(
                svg,
                SeedPhraseUtils._renderText(string(combinedText), pallet.blackOrWhite),
                "</svg>"
            );
        }
        // Single Panel
        else {
            (uint8[4] memory bipIndexArray, string memory bipIndexStr) = SeedPhraseUtils._transformTokenId(
                attributes.bipWordId
            );
            svg = abi.encodePacked(svg, _renderSinglePanel(bipIndexArray, attributes, pallet, singlePanelX, false));

            // Add closing text and svg element
            svg = abi.encodePacked(svg, SeedPhraseUtils._renderText(bipIndexStr, pallet.blackOrWhite), "</svg>");
        }

        return string(svg);
    }

    function _renderSinglePanel(
        uint8[4] memory bipIndexArray,
        SeedPhraseUtils.Attrs memory attributes,
        SeedPhraseUtils.Colors memory pallet,
        uint16 panelX,
        bool secondPanel
    ) internal pure returns (bytes memory panelSvg) {
        // Draw panels
        bool squareEdges = (attributes.doublePanel && attributes.backgroundSquare);
        if (attributes.showPanel) {
            panelSvg = abi.encodePacked(
                "<rect x='",
                (panelX - padding).toString(),
                "' y='",
                (panelY - padding).toString(),
                "' width='",
                (panelWidth + (padding * 2)).toString(),
                "' height='",
                (panelHeight + (padding * 2)).toString(),
                "' rx='",
                (squareEdges ? 0 : radius).toString(),
                "' fill='",
                (secondPanel ? pallet.panel2 : pallet.panel),
                "' ",
                SeedPhraseUtils._getStrokeStyle(attributes.showStroke, pallet.panelStroke, "1", strokeWeight),
                "/>"
            );
        }
        // Fill panel with negative circles, should resemble M600 300h400v1000H600z
        panelSvg = abi.encodePacked(
            panelSvg,
            "<path fill='url(#panelCircles)' d='M",
            panelX.toString(),
            " ",
            panelY.toString(),
            "h",
            panelWidth.toString(),
            "v",
            panelHeight.toString(),
            "H",
            panelX.toString(),
            "z'/>"
        );
        // Draw selected circles
        panelSvg = abi.encodePacked(
            panelSvg,
            _renderSelectedCircles(bipIndexArray, pallet, attributes.showStroke, panelX, secondPanel)
        );
    }

    function _renderSelectedCircles(
        uint8[4] memory bipIndexArray,
        SeedPhraseUtils.Colors memory pallet,
        bool showStroke,
        uint16 panelX,
        bool secondPanel
    ) internal pure returns (bytes memory svg) {
        for (uint8 i = 0; i < bipIndexArray.length; i++) {
            svg = abi.encodePacked(
                svg,
                "<circle cx='",
                (panelX + (segmentSize * i) + radius).toString(),
                "' cy='",
                (panelY + (segmentSize * bipIndexArray[i]) + radius).toString(),
                "' r='41' fill='", // Increase the size a tiny bit here (+1) to hide negative circle outline
                (secondPanel ? pallet.selectedCircleFill2 : pallet.selectedCircleFill),
                "' ",
                SeedPhraseUtils._getStrokeStyle(showStroke, pallet.selectedCircleStroke, "1", strokeWeight),
                " />"
            );
        }
    }

    function getRarityRating(bytes32 tokenSeed) external pure returns (uint8) {
        SeedPhraseUtils.Random memory random = SeedPhraseUtils.Random({ seed: uint256(tokenSeed), offsetBit: 0 });
        (, uint8 rarityRating) = SeedPhraseUtils.tokenTraits(SeedPhraseUtils.tokenAttributes(0, 0, random, 0));

        return rarityRating;
    }

    function getTraitsAndAttributes(
        uint16 bipWordId,
        uint16 secondBipWordId,
        uint8 rarityValue,
        SeedPhraseUtils.Random memory random
    ) external pure returns (bytes memory, SeedPhraseUtils.Attrs memory) {
        SeedPhraseUtils.Attrs memory attributes = SeedPhraseUtils.tokenAttributes(
            bipWordId,
            secondBipWordId,
            random,
            rarityValue
        );

        (bytes memory traits, ) = SeedPhraseUtils.tokenTraits(attributes);

        return (traits, attributes);
    }

    function getKarma(IKarmaScore karma, bytes memory data, address account) external view returns (uint256) {
        if (data.length > 0) {
            (, uint256 karmaScore, ) = abi.decode(data, (address, uint256, bytes32[]));
            if (karma.verify(account, karmaScore, data)) {
                return account == address(0) ? 1000 : karmaScore;
            }
        }
        return 1000;
    }

    function shuffleBipWords(uint256 randomValue) external pure returns (uint16[] memory) {
        uint16 size = 2048;
        uint16[] memory result = new uint16[](size);

        // Initialize array.
        for (uint16 i = 0; i < size; i++) {
            result[i] = i + 1;
        }

        // Set the initial randomness based on the provided entropy from VRF.
        bytes32 random = keccak256(abi.encodePacked(randomValue));

        // Set the last item of the array which will be swapped.
        uint16 lastItem = size - 1;

        // We need to do `size - 1` iterations to completely shuffle the array.
        for (uint16 i = 1; i < size - 1; i++) {
            // Select a number based on the randomness.
            uint16 selectedItem = uint16(uint256(random) % lastItem);

            // Swap items `selected_item <> last_item`.
            (result[lastItem], result[selectedItem]) = (result[selectedItem], result[lastItem]);

            // Decrease the size of the possible shuffle
            // to preserve the already shuffled items.
            // The already shuffled items are at the end of the array.
            lastItem--;

            // Generate new randomness.
            random = keccak256(abi.encodePacked(random));
        }

        return result;
    }

    function getDescriptionPt1() internal pure returns (string memory) {
        return "\"Seed Phrase is a 'Crypto Native' *fully* on-chain collection.\\n\\nA '*SEED*' is unique, it represents a single word from the BIP-0039 word list (the most commonly used word list to generate a seed/recovery phrase, think of it as a dictionary that only holds 2048 words).\\n\\n***Your 'SEED*' = *Your 'WORD*' in the list.**  \\nClick [here](https://www.seedphrase.codes/token?id=";

    }

    function getDescriptionPt2() internal pure returns (string memory) {
        return ") to decipher *your 'SEED*' and find out which word it translates to!\\n\\nFor Licensing, T&Cs or any other info, please visit: [www.seedphrase.codes](https://www.seedphrase.codes/).\"";
    }

    function getTokenURI(string memory output, bytes memory traits, uint256 tokenId) external pure returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                    NilProtocolUtils.base64encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                '{"name": "Seed Phrase #',
                                    NilProtocolUtils.stringify(tokenId),
                                '", "image": "data:image/svg+xml;base64,',
                                    NilProtocolUtils.base64encode(bytes(output)),
                                '", "attributes": ',
                                traits,
                                ', "description": ',
                                getDescriptionPt1(),
                                tokenId.toString(),
                                getDescriptionPt2(),
                                "}"
                            )
                        )
                    )
                )
            )
        );
    }

}