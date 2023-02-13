// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Base64.sol";

/// @title OnChainTalkingPepeSvg
/// @notice Provides a function for the svg of OnChainTalkingPepes
library OnChainTalkingPepeSvg {

    struct ImageData {
        string name;
        string speechBubbleText1;
        string speechBubbleText2;
        string speechBubbleTextColor;
        string pepeColor;
        string eyeColor;
        string eyeBlinkTime;
        string textBlinkTime;
        string mouthColor;
    }

    function buildImage(ImageData memory imageData) private pure returns (string memory) {

        string memory svg = string.concat('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 120 837 407"><style><![CDATA[.E{fill:none}.F{stroke:#000}.G{stroke-miterlimit:10}.H{stroke-width:2}.I{font-family:Yu Gothic UI}.J{font-variant:normal}.K{text-anchor:middle}]]></style><g class="F G H"><path fill="#',
        imageData.pepeColor,
        '" d="M497 262c3 29-14 37-28 43-5 11-28 27-38 28 13 4 41 46 36 67 9 3 17 17 1 27-30 20 17 30-50 46-91 78-193 49-321 29-62-8-88-66-87-137-3-11 34-132 76-132 31-101 103-133 200-83 48-32 129-29 137 42 14 4 34 15 44 24-3 11 10 11 18 16-4 15 6 14 12 30z"/><path d="M180 297c13 16 178 36 155-9" class="E"/><path fill="#fff" d="m344 258-7 29c-15 13-122 28-161-12 36-43 122-55 168-17zm152 13c-20 38-122 36-158 17 13-62 125-64 158-17z"/></g><g><animate attributeName="fill" dur="',
        imageData.eyeBlinkTime,
        '" repeatCount="indefinite" values="#000;#',
        imageData.eyeColor,
        ';#000"/><path id="A" d="M256 241c45-1 45 60 0 60s-45-61 0-60z"/><use href="#A" class="E F G H"/><path id="B" d="M444 268c0 39-63 39-63 0s63-39 63 0z"/><g class="F G H"><use href="#B" class="E"/><path fill="#fff" d="M237 258c7 0 7 11 0 11s-8-11 0-11zm33 1c8-1 8 13 0 13-9 0-9-13 0-13zm-24 20c3 0 3 5 0 5-4 0-4-5 0-5zm182-21c9 0 9 12 0 13-9 0-9-12 0-13zm-29-5c7-1 7 10 0 10s-7-11 0-10zm0 23c4 0 4 6 0 6s-4-6 0-6z"/></g></g><path d="M242 350c18-3 49-16 65-28m122 11c-26 11-55 14-77-1m41 30c1-7-12-20-17-20m-38-101c49-13 90-23 147 4" class="E F G H"/><path id="C" fill="#',
        imageData.mouthColor,
        '" d="M419 472c-59 1-305-11-268-91 37-25 52 17 93 23 104 31 158 19 225-4 21 7 3 28-13 39 19 20-34 34-37 33z"/><g class="F"><g class="G H"><use href="#C"/><path d="M172 399c55 57 250 42 284 39M81 273l9-37m86 38c-24 2-45-19-4-14 26-9 49-30 86-34 34-1 43 1 76 12 31-27 82-23 132-16m-130 11c-6-29-83-20-79-20-29 1-62 29-92 33m-10-49c44-34 128-32 160 17m-29-63c7 6 17 30 14 44 32-7 85-10 123-4" class="E"/></g><path stroke-miterlimit="11.3" stroke-width="9" d="M548 163c24 11 282-31 274 24l-13 101c-2 15-102 24-124 23l-85 1-62 63c29-107-2-47-14-104 5-26-26-111 24-108z" class="E"/></g><text xml:space="preserve" x="673" y="223" class="I J K" font-size="37" font-weight="700" fill="#000"><tspan x="670" y="'); 
        
        if (bytes(imageData.speechBubbleText2).length == 0) {
            svg = string.concat(svg, '246">', imageData.speechBubbleText1);
        }
        else {
            svg = string.concat(svg, '223">', imageData.speechBubbleText1, '</tspan><tspan x="670" y="270">', imageData.speechBubbleText2);
        }

        svg = string.concat(svg, '</tspan><animate attributeName="fill" values="#000;#', imageData.speechBubbleTextColor, ';#000;#000" dur="', imageData.textBlinkTime, '" repeatCount="indefinite"/></text></svg>');

        return
        Base64.encode(
            bytes(
                abi.encodePacked(svg)
            )
        );
    }

    function buildMetadata(ImageData memory imageData)
    internal
    pure
    returns (string memory)
    {
        return
        string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes.concat(
                        abi.encodePacked(
                            '{"name":"',
                            imageData.name,
                            '", "description":"On Chain Talking Pepes.", "image": "data:image/svg+xml;base64,',
                            buildImage(imageData),
                            '", "attributes": [{"trait_type": "Upper text","value":"',
                            imageData.speechBubbleText1,
                            '"},{"trait_type": "Lower text","value":"'
                        ),
                        abi.encodePacked(
                            imageData.speechBubbleText2,
                            '"},{"trait_type": "Head color","value":"#',
                            imageData.pepeColor,
                            '"},{"trait_type": "Text color","value":"#',
                            imageData.speechBubbleTextColor,
                            '"},{"trait_type": "Eye color", "value":"#',
                            imageData.eyeColor,
                            '"},{"trait_type": "Mouth color", "value":"#',
                            imageData.mouthColor,
                            '"}]}'
                        )
                    )
                )
            )
        );
    }


}