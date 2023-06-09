// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.1;

/**
 * @dev On-chain art generation for MoonCatLootprints
 * Takes individual trait values as parameters, and outputs complete representations of them.
 */
contract MoonCatLootprintsMetadata {

    string[5] internal class_names =
        [
         "Mech",
         "Sub",
         "Tank",
         "Cruiser",
         "Unknown"
         ];

    /**
     * @dev Convert a Classification ID number into a string name
     */
    function getClassName(uint8 classId) public view returns (string memory) {
        return class_names[classId];
    }

    string[15] internal color_names =
        ["Hero Silver",
         "Genesis White",
         "Genesis Black",
         "Red",
         "Orange",
         "Yellow",
         "Chartreuse",
         "Green",
         "Teal",
         "Cyan",
         "SkyBlue",
         "Blue",
         "Purple",
         "Magenta",
         "Fuchsia"];

    /**
     * @dev Convert a Color ID number into a string name
     */
    function getColorName(uint8 colorId) public view returns (string memory) {
        return color_names[colorId];
    }

    // Color codes used for the background color of an image representation
    string[15] internal color_codes =
        ["#777777", // Silver
         "#cccccc", // White
         "#111111", // Black
         "hsl(0,60%,38%)", // Red
         "hsl(30,60%,38%)", // Orange
         "hsl(60,60%,38%)", // Yellow
         "hsl(80,60%,38%)", // Chartreuse
         "hsl(120,60%,38%)", // Green
         "hsl(150,60%,38%)", // Teal
         "hsl(180,60%,38%)", // Cyan
         "hsl(210,60%,38%)", // SkyBlue
         "hsl(240,60%,38%)", // Blue
         "hsl(270,60%,38%)", // Purple
         "hsl(300,60%,38%)", // Magenta
         "hsl(330,60%,38%)"]; // Fuchsia

    // SVG codes for the different icons for each ship classification
    string[4] public ship_images =
        ["<path class=\"s\" d=\"M-61.74,77.79h-12.61V32.32h12.61V77.79z M-28.03,26.64l-7.58-12.63v44.12h7.58V26.64z M-0.65,52.52h10.99 L41.41,1.36L24.74-12.66H-0.65h-25.39L-42.72,1.36l31.07,51.16H-0.65z M60.43,77.79h12.61V32.32H60.43V77.79z M26.73,58.14h7.58 V14.02l-7.58,12.63V58.14z\"/><path class=\"s\" d=\"M-23.89,32.56v4.77h-44.15V8.75h29.81 M-58.76,13.76h-18.55v18.55h18.55V13.76z M22.59,32.56v4.77h44.15V8.75 H36.92 M57.46,32.32h18.55V13.76H57.46V32.32z M5.79,46.98L5.79,46.98c0-1.07-0.87-1.94-1.94-1.94h-9c-1.07,0-1.94,0.87-1.94,1.94 v0c0,1.07,0.87,1.94,1.94,1.94h9C4.92,48.93,5.79,48.06,5.79,46.98z\"/><path class=\"s s1\" d=\"M-79.92,94.43V86.1 M-56.04,94.43V86.1 M78.61,94.43V86.1 M54.74,94.43V86.1 M-14.48,5.33h28.04 M-9.45,1.1 H8.52\"/><path class=\"s s1\" d=\"M-44.11,94.43h-47.87V82.76c0-2.76,2.24-5,5-5h37.87c2.76,0,5,2.24,5,5V94.43z M-19.88,57.67v-6.18 c0-1.64-1.33-2.97-2.97-2.97h-9.15v12.13h9.15C-21.22,60.65-19.88,59.32-19.88,57.67z M42.8,94.43h47.87V82.76c0-2.76-2.24-5-5-5 H47.8c-2.76,0-5,2.24-5,5V94.43z M-0.65,31.11h14.08L33.42,3.86L25.39,2.2l-8.96,8.83H-0.65h-17.08l-8.96-8.83l-8.04,1.66 l19.99,27.25H-0.65z M21.55,60.65h9.15V48.52h-9.15c-1.64,0-2.97,1.33-2.97,2.97v6.18C18.58,59.32,19.91,60.65,21.55,60.65z\"/><path class=\"s s1\" d=\"M-26.04-12.66l-11.17,9.4v-27.46h7.51l16.17,18.06H-26.04z M24.74-12.66l11.17,9.4v-27.46H28.4L12.23-12.66 H24.74z\"/><path class=\"s s2\" d=\"M-19.88,52.86h-3.79 M-19.88,56.46h-3.79 M22.37,52.86h-3.79 M18.58,56.46h3.79\"/>  <path class=\"s s2\" d=\"M-39.67,8.41l-1.58,33.83h-11.47l-1.58-33.83c0-4.04,3.28-7.32,7.32-7.32C-42.95,1.1-39.67,4.37-39.67,8.41z M-43.38,42.24h-6.9l-1.01,4.74h8.91L-43.38,42.24z M38.37,8.41l1.58,33.83h11.47L53,8.41c0-4.04-3.28-7.32-7.32-7.32 C41.64,1.1,38.37,4.37,38.37,8.41z M41.06,46.98h8.91l-1.01-4.74h-6.9L41.06,46.98z\"/>", // Mech

         "<path class=\"s\" d=\"M55.52,60.62l-125.85,7.15c-13.35,0.76-24.59-9.86-24.59-23.23v0c0-13.37,11.24-23.99,24.59-23.23l125.85,7.15 V60.62z\"/><path class=\"s\" d=\"M48.39,42.2v10.28l-5.47-1.16v-7.96L48.39,42.2z M63.26,21.92L63.26,21.92c-2.75,0-4.82,2.5-4.31,5.2 l3.33,17.61h1.97l3.33-17.61C68.09,24.42,66.01,21.92,63.26,21.92z M63.26,67.55L63.26,67.55c2.75,0,4.82-2.5,4.31-5.2l-3.33-17.61 h-1.97l-3.33,17.61C58.44,65.05,60.51,67.55,63.26,67.55z M-44.97,43.64L-44.97,43.64c0.76,0.76,1.99,0.76,2.75,0l6.36-6.36 c0.76-0.76,0.76-1.99,0-2.75l0,0c-0.76-0.76-1.99-0.76-2.75,0l-6.36,6.36C-45.72,41.65-45.72,42.88-44.97,43.64z M-34.82,43.64 L-34.82,43.64c0.76,0.76,1.99,0.76,2.75,0l6.36-6.36c0.76-0.76,0.76-1.99,0-2.75l0,0c-0.76-0.76-1.99-0.76-2.75,0l-6.36,6.36 C-35.58,41.65-35.58,42.88-34.82,43.64z M63.26,43.33h-7.74v2.81h7.74V43.33z\"/><path class=\"s\" d=\"M-71.47,62.75v15.73 M-65.61,62.75v22.93\"/> <path class=\"s s1\" d=\"M52.24,60.8l1.72,11.04l19.89,4.4v6.21L38.9,88.39c-8.09,1.37-15.55-4.68-15.87-12.88l-0.51-13.03 M51.24,28.2 L67.16,2.56l-80.25-3.16c-6.16-0.24-12.13,2.16-16.4,6.61l-16.03,16.69\"/><path class=\"s s1\" d=\"M3.89,39.09l39.03,1.83v13.24L3.89,55.98c-4.66,0-8.44-3.78-8.44-8.44C-4.56,42.87-0.78,39.09,3.89,39.09z M-42.74,31.11l-31.49-1.26c-5.73,0-10.75,3.81-12.3,9.33l-0.67,5.36h29.01L-42.74,31.11z M30.03,47.53L30.03,47.53 c0-1.07-0.87-1.94-1.94-1.94h-9c-1.07,0-1.94,0.87-1.94,1.94v0c0,1.07,0.87,1.94,1.94,1.94h9C29.16,49.47,30.03,48.6,30.03,47.53z\"/>", // Sub

         "<path class=\"s\" d=\"M-41.05,64.38H-76.3c-9.83,0-17.79-7.98-17.77-17.8l0.02-7.96l53-31.34V64.38z M-33.49,21.94v36.39l12.96,9.64 c7.01,5.22,15.52,8.03,24.26,8.03h50.54V7.29l-12-2.39C27.98,2.05,13.19,3.4-0.34,8.77L-33.49,21.94z\"/> <path class=\"s\" d=\"M-53.74,49.67l93.8-17.28 M-53.74,96.38h99.86 M-60.37,44.65L-60.37,44.65c0-1.07-0.87-1.94-1.94-1.94h-9 c-1.07,0-1.94,0.87-1.94,1.94v0c0,1.07,0.87,1.94,1.94,1.94h9C-61.24,46.59-60.37,45.72-60.37,44.65z M-60.37,37.78L-60.37,37.78 c0-1.07-0.87-1.94-1.94-1.94h-9c-1.07,0-1.94,0.87-1.94,1.94v0c0,1.07,0.87,1.94,1.94,1.94h9C-61.24,39.72-60.37,38.85-60.37,37.78 z M-33.49,26.33h-7.56v27.92h7.56V26.33z\"/><path class=\"s s1\" d=\"M-0.29,30.83v-9c0-1.07,0.87-1.94,1.94-1.94h0c1.07,0,1.94,0.87,1.94,1.94v9c0,1.07-0.87,1.94-1.94,1.94h0 C0.58,32.77-0.29,31.9-0.29,30.83z M1.47-0.14c-4.66,0-8.44,3.78-8.44,8.44l1.83,39.03H8.08L9.91,8.3 C9.91,3.64,6.13-0.14,1.47-0.14z\"/> <path class=\"s s1\" d=\"M42.26,32.38c-17.67,0-32,14.33-32,32s14.33,32,32,32s32-14.33,32-32S59.94,32.38,42.26,32.38z M42.26,89.98 c-14.14,0-25.6-11.46-25.6-25.6s11.46-25.6,25.6-25.6s25.6,11.46,25.6,25.6S56.4,89.98,42.26,89.98z M-51.74,49.57 c-12.93,0-23.4,10.48-23.4,23.41c0,12.93,10.48,23.4,23.4,23.4s23.4-10.48,23.4-23.4C-28.33,60.05-38.81,49.57-51.74,49.57z M-51.74,91.7c-10.34,0-18.72-8.38-18.72-18.72c0-10.34,8.38-18.72,18.72-18.72s18.72,8.38,18.72,18.72 C-33.01,83.32-41.4,91.7-51.74,91.7z M-46.35,29.02h-14.78l14.4-10.61L-46.35,29.02z M6.8,52.81H-3.49l1.16-5.47h7.96L6.8,52.81z M54.26,20.3l9-3v18.97l-9-3.28 M54.26,53.04l9-3v18.97l-9-3.28\"/>", // Tank

         "<path class=\"s\" d=\"M0.26,93.33h14.33c0,0-0.76-11.46-2.27-32s13.64-76.47,19.95-99.97s-2.52-60.03-32-60.03 s-38.31,36.54-32,60.03s21.46,79.43,19.95,99.97s-2.27,32-2.27,32H0.26\"/><path class=\"s\" d=\"M-12.9,76.57l-47.02,6.06l3.03-18.95l43.64-22.42 M-26.38-18.46l-9.09,14.31v19.33l14.78-10.8 M13.42,76.57 l47.02,6.06l-3.03-18.95L13.77,41.25 M21.22,4.37L36,15.17V-4.15l-9.09-14.31\"/><path class=\"s s1\" d=\"M-33.66,46.63l-1.83,39.03h-13.24l-1.83-39.03c0-4.66,3.78-8.44,8.44-8.44 C-37.44,38.18-33.66,41.96-33.66,46.63z M34.19,46.63l1.83,39.03h13.24l1.83-39.03c0-4.66-3.78-8.44-8.44-8.44 C37.97,38.18,34.19,41.96,34.19,46.63z\"/><path class=\"s s1\" d=\"M-19.18-74.83c1.04,1.8,0.95,17.15,3.03,27c1.51,7.14,4.01,15.92,2.38,18.14c-1.43,1.94-7.59,1.24-9.95-1.37 c-3.41-3.78-4.15-10.56-4.93-16.67C-30.13-59.39-22.35-80.31-19.18-74.83z M-37.94,85.66h-7.96l-1.16,5.47h10.28L-37.94,85.66z M-10.65,93.33l-1.33,8.05H0.26h12.24l-1.33-8.05 M0.26-34.67c0,0,1.82,0,6.12,0s7.45-32,7.04-43S9.28-88.66,0.26-88.66 s-12.75-0.01-13.16,10.99c-0.41,11,2.74,43,7.04,43S0.26-34.67,0.26-34.67z M19.71-74.83c-1.04,1.8-0.95,17.15-3.03,27 c-1.51,7.14-4.01,15.92-2.38,18.14c1.43,1.94,7.59,1.24,9.95-1.37c3.41-3.78,4.15-10.56,4.93-16.67 C30.65-59.39,22.88-80.31,19.71-74.83z M37.3,91.13h10.28l-1.16-5.47h-7.96L37.3,91.13z\"/>" // Cruiser
         ];

    /**
     * @dev Render an SVG of a ship with the specified features.
     */
    function getImage (uint256 lootprintId, uint8 classId, uint8 colorId, uint8 bays, string calldata shipName)
        public
        view
        returns (string memory)
    {

        string memory regStr = uint2str(lootprintId);
        string memory baysStr = uint2str(bays);

        string[15] memory parts;
        parts[0] = "<svg xmlns=\"http://www.w3.org/2000/svg\" preserveAspectRatio=\"xMinYMin meet\" viewBox=\"0 0 600 600\"><style> .s{fill:white;stroke:white;stroke-width:2;stroke-miterlimit:10;fill-opacity:0.1;stroke-linecap:round}.s1{fill-opacity:0.3}.s2{stroke-width:1}.t{ fill:white;font-family:serif;font-size:20px;}.k{font-weight:bold;text-anchor:end;fill:#ddd;}.n{font-size:22px;font-weight:bold;text-anchor:middle}.l{fill:none;stroke:rgb(230,230,230,0.5);stroke-width:1;clip-path:url(#c);}.r{fill:rgba(0,0,0,0.5);stroke:white;stroke-width:3;}.r1{stroke-width: 1} .a{fill:#FFFFFF;fill-opacity:0.1;stroke:#FFFFFF;stroke-width:2;stroke-miterlimit:10;}.b{fill:none;stroke:#FFFFFF;stroke-width:2;stroke-miterlimit:10;} .c{fill:#FFFFFF;fill-opacity:0.2;stroke:#FFFFFF;stroke-width:2;stroke-miterlimit:10;} .d{fill:#FFFFFF;fill-opacity:0.3;stroke:#FFFFFF;stroke-width:2;stroke-miterlimit:10;}</style><defs><clipPath id=\"c\"><rect width=\"600\" height=\"600\" /></clipPath></defs><rect width=\"600\" height=\"600\" fill=\"";
        parts[1] = color_codes[colorId];
        parts[2] = "\"/><polyline class=\"l\" points=\"40,-5 40,605 80,605 80,-5 120,-5 120,605 160,605 160,-5 200,-5 200,605 240,605 240,-5 280,-5 280,605 320,605 320,-5 360,-5 360,605 400,605 400,-5 440,-5 440,605 480,605 480,-5 520,-5 520,605 560,605 560,-5 600,-5 600,605\" /><polyline class=\"l\" points=\"-5,40 605,40 605,80 -5,80 -5,120 605,120 605,160 -5,160 -5,200 605,200 605,240 -5,240 -5,280 605,280 605,320 -5,320 -5,360 605,360 605,400 -5,400 -5,440 605,440 605,480 -5,480 -5,520 605,520 605,560 -5,560 -5,600 605,600\" /><rect class=\"r\" x=\"10\" y=\"10\" width=\"580\" height=\"50\" rx=\"15\" /><rect class=\"l r r1\" x=\"-5\" y=\"80\" width=\"285\" height=\"535\" /><text class=\"t n\" x=\"300\" y=\"42\">";
        parts[3] = shipName;
        parts[4] = "</text><text class=\"t k\" x=\"115\" y=\"147\">Reg:</text><text class=\"t\" x=\"125\" y=\"147\">#";
        parts[5] = regStr;
        parts[6] = "</text><text class=\"t k\" x=\"115\" y=\"187\">Class:</text><text class=\"t\" x=\"125\" y=\"187\">";
        parts[7] = class_names[classId];
        parts[8] = "</text><text class=\"t k\" x=\"115\" y=\"227\">Color:</text><text class=\"t\" x=\"125\" y=\"227\">";
        parts[9] = color_names[colorId];
        parts[10] = "</text><text class=\"t k\" x=\"115\" y=\"267\">Bays:</text><text class=\"t\" x=\"125\" y=\"267\">";
        parts[11] = baysStr;
        parts[12] = "</text><g transform=\"translate(440,440)scale(1.2)\">";
        if (classId < 4) {
            parts[13] = ship_images[classId];
        }
        parts[14] = "</g></svg>";

        bytes memory svg0 = abi.encodePacked(parts[0], parts[1], parts[2],
                                             parts[3], parts[4], parts[5],
                                             parts[6], parts[7], parts[8]);
        bytes memory svg1 = abi.encodePacked(parts[9], parts[10], parts[11],
                                             parts[12], parts[13], parts[14]);

        return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(abi.encodePacked(svg0, svg1))));
    }

    /**
     * @dev Encode a key/value pair as a JSON trait property, where the value is a numeric item (doesn't need quotes)
     */
    function encodeAttribute(string memory key, string memory value) internal pure returns (string memory) {
        return string(abi.encodePacked("{\"trait_type\":\"", key,"\",\"value\":",value,"}"));
    }

    /**
     * @dev Encode a key/value pair as a JSON trait property, where the value is a string item (needs quotes around it)
     */
    function encodeStringAttribute(string memory key, string memory value) internal pure returns (string memory) {
        return string(abi.encodePacked("{\"trait_type\":\"", key,"\",\"value\":\"",value,"\"}"));
    }

    /**
     * @dev Render a JSON metadata object of a ship with the specified features.
     */
    function getJSON(uint256 lootprintId, uint8 classId, uint8 colorId, uint8 bays, string calldata shipName)
        public
        view
        returns (string memory) {
        string memory colorName = color_names[colorId];
        string memory svg = getImage(lootprintId, classId, colorId, bays, shipName);
        bytes memory tokenName = abi.encodePacked("Lootprint #", uint2str(lootprintId), ": ", shipName);
        bytes memory json = abi.encodePacked("{",
                                             "\"attributes\":[",
                                             encodeAttribute("Registration #", uint2str(lootprintId)), ",",
                                             encodeStringAttribute("Class", class_names[classId]), ",",
                                             encodeAttribute("Bays", uint2str(bays)), ",",
                                             encodeStringAttribute("Color", colorName),
                                             "],\"name\":\"", tokenName,
                                             "\",\"description\":\"Build Plans for a MoonCat Spacecraft\",\"image\":\"", svg,
                                             "\"}");
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(json)));

    }

    /* Utilities */

    function uint2str(uint value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
                let resultPtr := add(result, 32)

                for {
                     let i := 0
                } lt(i, len) {

            } {
            i := add(i, 3)
            let input := and(mload(add(data, i)), 0xffffff)

            let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
            out := shl(8, out)
            out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
            out := shl(8, out)
            out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
            out := shl(8, out)
            out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
            out := shl(224, out)

            mstore(resultPtr, out)

            resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
                          case 1 {
                                  mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
                }
            case 2 {
                    mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
                }

        return string(result);
    }
}