pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

library Garden {
    using Strings for uint256;

    uint256 constant probDaisyCutoff = 65;
    uint256 constant probLilyCutoff = 98;

   function getFlowerSVG(bytes32 flowerHash) internal view returns (string memory){

        uint256 saltedSeed = uint256(keccak256(abi.encodePacked(flowerHash, address(this))));
        uint256 flowerType = uint256(flowerHash) % 100;

        string memory svg = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">'
            )
        );

        // Background
        svg = string(abi.encodePacked(svg, '<rect x="0" y="0" width="200" height="200" fill="lightblue"/>'));

        // Add the stem
        svg = string(abi.encodePacked(svg, '<rect x="97" y="100" width="6" height="100" fill="green" stroke="black" stroke-width="1"/>'));

        // Add the flower
        if(flowerType <= probDaisyCutoff){
            svg = string(abi.encodePacked(svg, generateDaisy(saltedSeed)));
        } else if (flowerType > probDaisyCutoff && flowerType <= probLilyCutoff){
            svg = string(abi.encodePacked(svg, generateLily(saltedSeed)));
        } else {
            svg = string(abi.encodePacked(svg, generateCamellia(saltedSeed)));
        }
    
        svg = string(abi.encodePacked(svg, "</svg>"));        
        return svg;
    }

    function getFlowerTraits(bytes32 flowerHash) internal view returns (string memory){
        
        uint256 saltedSeed = uint256(keccak256(abi.encodePacked(flowerHash, address(this))));
        uint256 flowerType = uint256(flowerHash) % 100;

        return string(
            abi.encodePacked(
                '[{"trait_type":"Flower","value":"', 
                getFlowerTypeString(flowerType),
                '"},{"trait_type":"Color","value":"',
                getPetalColor(saltedSeed),'"}]'
            ));
    }

    function getFlowerTypeString(uint256 flowerType) internal pure returns (string memory){

        string memory flowerTypeString = "camellia";
        if(flowerType <= probDaisyCutoff){
            flowerTypeString = "daisy";
        } else if (flowerType > probDaisyCutoff && flowerType <= probLilyCutoff){
            flowerTypeString = "lily";
        }

        return flowerTypeString;
    }

    function getPetalColor(
        uint256 seed
    ) private pure returns (string memory) {
        string[] memory colors = new string[](25);
        colors[0] = "gold";
        colors[1] = "yellow";
        colors[2] = "moccasin";
        colors[3] = "peachpuff";
        colors[4] = "lavender";
        colors[5] = "thistle";
        colors[6] = "orchid";
        colors[7] = "lavender";
        colors[8] = "mediumpurple";
        colors[9] = "blueviolet";
        colors[10] = "indigo";
        colors[11] = "slateblue";
        colors[12] = "midnightblue";
        colors[13] = "rosybrown";
        colors[14] = "white";
        colors[15] = "aliceblue";
        colors[16] = "azure";
        colors[17] = "mistyrose";
        colors[18] = "lightcoral";
        colors[19] = "crimson";
        colors[20] = "salmon";
        colors[21] = "pink";
        colors[22] = "mediumvioletred";
        colors[23] = "tomato";
        colors[24] = "lightsalmon";


        uint256 colorIndex = seed % 25;
        return colors[colorIndex];
    }

    function getDaisyCenterColor(
        uint256 seed
    ) private pure returns (string memory) {
        string memory color = seed % 25 < 3 ? "black" : "yellow";
        return color;
    }

    function generateDaisy(uint256 seed) internal pure returns (string memory) {
        uint256 numPetals = (seed % 8) + 16;
        uint256 rotation = 360 / numPetals;
        string memory svg;
        
        string memory color = getPetalColor(seed);
        // Add petals using radial symmetry
        for (uint256 i = 0; i < numPetals; i++) {
            uint256 petalRadius = ((seed % 10) + 10) / 2;

            string memory petal = string(
                abi.encodePacked(
                    '<ellipse cx="100" cy="75" rx="',
                    petalRadius.toString(),
                    '" ry="25" fill="',
                    color,
                    '" stroke="black" stroke-width="1" transform="rotate(',
                    ((rotation * i)+195).toString(),
                    ' 100 100)"/>'
                )
            );
            svg = string(abi.encodePacked(svg, petal));
        }

        // Add the central circle
        svg = string(
            abi.encodePacked(
                svg,
                '<circle cx="100" cy="100" r="15" fill="',
                getDaisyCenterColor(seed),
                '" stroke="black" stroke-width="1"/>'
            )
        );

        return svg;
    }

    function generateCamellia(uint256 seed) internal pure returns (string memory) {
        string memory svg;

        // Choose a random color for the petals
        string memory petalColor = getPetalColor(seed);

        // Generate Camellia petals using radial symmetry and layers
        for (uint256 layer = 0; layer < 7; layer++) {
            uint256 petalWidth =  50 - 5 * layer;
            uint256 petalHeight = (seed % 15) + 60 - 5 * layer;
            uint256 petalRadius = petalWidth / 2;

            for (uint256 i = 0; i < 12; i++) {
                string memory petal = string(
                    abi.encodePacked(
                        '<ellipse cx="100" cy="',
                        (100 - petalHeight / 2 + 5 * layer).toString(),
                        '" rx="',
                        petalRadius.toString(),
                        '" ry="',
                        (petalHeight / 2).toString(),
                        '" fill="',
                        petalColor,
                        '" transform="rotate(',
                        (30 * i + ((layer % 2) * 30) / 2).toString(),
                        ' 100 100)" stroke="black" stroke-width="1"/>'
                    )
                );
                svg = string(abi.encodePacked(svg, petal));
            }
        }

        return svg;
    }

    function generateLily(uint256 seed) internal pure returns (string memory) {
        string memory svg;

        // Petal dimensions
        uint256 petalWidth = (seed % 20) + 40;
        uint256 petalHeight = ((seed / 2) % 30) + 60;
        uint256 petalRadius = petalWidth / 2;
        // Create a radial gradient for the petals
        string memory gradient = string(
            abi.encodePacked(
                '<defs><radialGradient id="petalGradient" x1="0%" y1="0%" x2="100%" y2="0%"><stop offset="50%" style="stop-color:',
                getPetalColor(seed),
                '"/><stop offset="100%" style="stop-color:white"/></radialGradient></defs>'
            )
        );
        svg = string(abi.encodePacked(svg, gradient));

        // Generate 6 petals using radial symmetry
        for (uint256 i = 0; i < 6; i++) {
            string memory petal = string(
                abi.encodePacked(
                    '<ellipse cx="100" cy="',
                    (100 - petalHeight / 2).toString(),
                    '" rx="',
                    petalRadius.toString(),
                    '" ry="',
                    (petalHeight / 2).toString(),
                    '" fill="url(#petalGradient)" transform="rotate(',
                    ((60 * i) + 30).toString(),
                    ' 100 100)" stroke="black" stroke-width="1"/>'
                )
            );
            svg = string(abi.encodePacked(svg, petal));
        }

        // Add the stamen
        string memory stamen = string(
            abi.encodePacked(
                '<ellipse cx="100" cy="100" rx="10" ry="20" fill="orange" stroke="black" stroke-width="1"/>'
            )
        );
        svg = string(abi.encodePacked(svg, stamen));

        return svg;
    }

}