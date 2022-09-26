// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./StringUtils.sol";
import "./Structs.sol";
import "./Base64.sol";

library NogBuilder {
    using StringUtils for string;
    using Strings for uint160;
    using Strings for uint256;    

    /* 
    ⌐◨—————————————————————————————————————————————————————————————◨
                            nog colors
    ⌐◨—————————————————————————————————————————————————————————————◨ 
    */  

    function getColorPalette(Structs.Seed memory seed) internal view returns (string memory colorMetadata) {
        bytes memory list;
        for (uint i; i < seed.colors.length; ++i) {
            if (i < seed.colors.length - 1) {
                list = abi.encodePacked(list, string.concat('"#', seed.colors[seed.colorPalette[i]],'", '));
            } else {
                list = abi.encodePacked(list, string.concat('"#', seed.colors[seed.colorPalette[i]],'"'));
            }
        }
        return string(list);
    }

    function getNogColorStyles(Structs.Seed memory seed) internal view returns (string memory nogColorStyles) {
        string memory bg = seed.colors[seed.colorPalette[0]];
        if (seed.backgroundStyle == 1) {
            bg = 'd5d7e1';
        }
        if (seed.backgroundStyle == 2) {
            bg = 'e1d7d5';
        }
        if (seed.backgroundStyle == 3) {
            bg = seed.colors[seed.colorPalette[1]];
        }
        
        return string(
            abi.encodePacked(
                '<style>.shade{fill:',
                seed.shade,
                '}.bg{fill:#',
                bg,
                '}.a{fill:#',
                seed.colors[seed.colorPalette[1]],
                '}.b{fill:#',
                seed.colors[seed.colorPalette[2]],
                '}.c{fill:#',
                seed.colors[seed.colorPalette[3]],
                ';}.d{fill:#',
                seed.colors[seed.colorPalette[4]],
                ';}.e{fill:#',
                seed.colors[seed.colorPalette[5]],
                ';}.y{fill:#',
                'fff',
                '}.p{fill:#',
                '000',
                '}</style>'
            )
        );
    }

    function getColorMetadata(uint frameColorLength, uint16[7] memory colorPalette, string[7] memory colors) internal view returns (string memory colorMetadata) {
        bytes memory list;
        for (uint i; i < frameColorLength; ++i) {
            list = abi.encodePacked(list, string.concat('{"trait_type":"Nog color", "value":"#', colors[colorPalette[i + 1]],'"},'));
        }
        return string(list);
    }
    
    function getColors(address minterAddress) public view returns (string[7] memory) {
        string memory addr = Strings.toHexString(minterAddress);
        string memory color;
        string[7] memory list;
        for (uint i; i < 7; ++i) {
            if (i == 0) {
                color = addr._substring(6, 2);
            } else if (i == 1) {
                color = addr._substring(6, int(i) * 8);
            } else {
                color = addr._substring(6, int(i) * 6);
            }
            list[i] = color;
        }    
        return list;
    }

    /* 
    ⌐◨—————————————————————————————————————————————————————————————◨
                            create nogs
    ⌐◨—————————————————————————————————————————————————————————————◨ 
    */  

    function getTokenIdSvg(Structs.Seed memory seed) internal view returns (string memory svg) {
        string memory backgroundGradient = getBackground(seed);
        string memory shade = string(abi.encodePacked('<path class="shade" d="M0 0h100v100H0z"/>'));
        string memory nogs = string(abi.encodePacked(seed.nogShape));
        string memory shadow;
        if (seed.backgroundStyle == 1 || seed.backgroundStyle == 2) {
            shade = '';
        }
        if (isStringEmpty(seed.shadow) == false) {
            shadow = string(abi.encodePacked(seed.shadow));
        }
        if (isStringEmpty(seed.shadow) == false && seed.hasAnimation == true) {
            // bounce nogs
            nogs = string(abi.encodePacked(
                '<g shape-rendering="optimizeSpeed" transform="translate(-55 -42)">',
                    seed.nogShape,
                    '<defs><path xmlns="http://www.w3.org/2000/svg" id="nogs" d="M53.5 41.2c-.2.7-.3 1.8 0 1.8s.2-1 0-1.8zm0 0c-.2-.8-.3-1.7 0-1.7s.2 1 0 1.7z"/></defs><animateMotion xmlns="http://www.w3.org/2000/svg" dur="8s" repeatCount="indefinite" calcMode="linear"><mpath xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="#nogs"/></animateMotion>',
                '</g>'
            ));
            shadow = string(abi.encodePacked(seed.shadowAnimation));
        }

        return
            string(
                abi.encodePacked(
                    '<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg" style="shape-rendering:crispedges">',
                        '<defs>',
                            string(abi.encodePacked(getNogColorStyles(seed))),
                        '</defs>',
                        '<svg viewBox="0 0 100 100"><path class="bg" d="M0 0h100v100H0z"/>',
                        shade, 
                            string(abi.encodePacked(backgroundGradient)),
                            string(abi.encodePacked(shadow)),
                        '</svg>',
                        '<svg viewBox="0 0 100 100" class="nogs">',
                            string(abi.encodePacked(nogs)),
                        '</svg>',
                    '</svg>'
                )
            );
    }    

    function buildParts(Structs.Seed memory seed) public view returns (Structs.NogParts memory parts) {
        parts = Structs.NogParts({
            image: string(abi.encodePacked(Base64.encode(bytes(getTokenIdSvg(seed))))),
            colorMetadata: getColorMetadata(seed.frameColorLength, seed.colorPalette, seed.colors),
            colorPalette: getColorPalette(seed)
        });
    }

    function getBackground(Structs.Seed memory seed) public view returns (string memory backgroundGradient) {
        string[5] memory vals = ["22", "33", "44", "55", "66"];
        string[8] memory animations = [
            '',
            '',
            '',
            '',
            string(abi.encodePacked('<animateTransform attributeType="xml" attributeName="transform" type="rotate" from="360 50 50" to="0 50 50" dur="22s" additive="sum" repeatCount="indefinite"/><animateTransform xmlns="http://www.w3.org/2000/svg" attributeType="xml" attributeName="transform" type="scale" values="0.8; 1.8; 0.8" dur="33s" additive="sum" repeatCount="indefinite"/>')),
            string(abi.encodePacked('<animate attributeName="r" values="1; 1.66; 1" dur="18s" repeatCount="indefinite"></animate>')),
            string(abi.encodePacked('<animate attributeName="x2" values="100;',vals[getPseudorandomness(seed.tokenId, 17) % 5],';100" dur="28s" repeatCount="indefinite"></animate><animate attributeName="y2" values="10;85;10" dur="17s" repeatCount="indefinite"></animate>')),
            string(abi.encodePacked('<animate attributeName="x1" values="',vals[getPseudorandomness(seed.tokenId, 17) % 5], ';100;',vals[getPseudorandomness(seed.tokenId, 23) % 5], '" dur="42s" repeatCount="indefinite"></animate><animate attributeName="y1" values="10;66;10" dur="22s" repeatCount="indefinite"></animate>'))
        ];
        
        string memory animation;
        if (seed.hasAnimation == true) {
            animation = animations[seed.backgroundStyle];
        }

        if (isStringEmpty(seed.shadow) == false && seed.hasAnimation == true) {
            animation = '';
        }

        string memory meshGradient = string(abi.encodePacked(
            '<path d="M0 0h100v100H0z" fill="#fff" opacity="0.', vals[getPseudorandomness(seed.tokenId, 13) % 5], '"/>',
            '<g filter="url(#grad)" transform="scale(1.', vals[getPseudorandomness(seed.tokenId, 17) % 5], ') translate(-25 -25)" opacity="0.', vals[getPseudorandomness(seed.tokenId, 23) % 5], '">',
                '<path d="M32.15 0H0v80.55L71 66 32.15 0Z" fill="#', seed.colors[2], '"/><path d="M0 80.55V100h80l-9-34L0 80.55Z" fill="#', seed.colors[3], '"/><path d="M80 100h20V19.687L71 66l9 34Z" fill="#', seed.colors[5], '"/><path d="M100 0H32.15L71 66l29-46.313V0Z" fill="#', seed.colors[2], '"/>',
                '<defs><filter id="grad" x="-50" y="-50" width="200" height="200" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feBlend result="shape"/><feGaussianBlur stdDeviation="10"/></filter></defs>',
                animation,
            '</g>'
        ));

        string memory gradientRadial = string(abi.encodePacked(
            '<path fill="url(#grad)" d="M-73-17h246v246H-73z" opacity="0.8"  /><defs><radialGradient id="grad" cx="0" cy="0" r="1" gradientTransform="rotate(44.737 -114.098 135.14) scale(165.905)" gradientUnits="userSpaceOnUse"><stop stop-color="#', seed.colors[seed.nogStyle], '"/><stop offset=".6" stop-color="#', seed.colors[seed.nogStyle], '" stop-opacity="0"/>', animation, '</radialGradient></defs>'
        ));

        string memory linearGradient = string(abi.encodePacked(
            '<path fill="url(#grad)" opacity=".66" d="M0 0h100v100H0z"/><defs><linearGradient id="grad" x1="7" y1="8" x2="100" y2="100" gradientUnits="userSpaceOnUse"><stop stop-color="#', seed.colors[seed.nogStyle], '"/><stop offset="1" stop-color="#', seed.colors[seed.nogStyle], '" stop-opacity=".2"/>', animation,'</linearGradient></defs>'
        ));

        string memory lightGradient = string(abi.encodePacked(
            '<path fill="url(#grad)" opacity=".44" d="M0 0h100v100H0z"/><defs><linearGradient id="grad" x1="7" y1="8" x2="100" y2="100" gradientUnits="userSpaceOnUse"><stop stop-color="#fff" stop-opacity=".67"/><stop offset="1" stop-color="#fff" stop-opacity=".21"/>', animation, '</linearGradient></defs>'
        ));
    
        string[8] memory backgrounds = ['', '', '', '', meshGradient, gradientRadial, linearGradient, lightGradient];

        backgroundGradient = string (
            abi.encodePacked(backgrounds[seed.backgroundStyle])
        );
    }

    function getAttributesMetadata(Structs.Seed memory seed) public view returns (string memory extraMetadata) {
        string memory animatedMetadata;
        string memory floatingMetadata;
        string memory bg = string(abi.encodePacked('#',seed.colors[seed.colorPalette[0]]));
        if (seed.hasAnimation && seed.backgroundStyle > 1) {
            animatedMetadata = string(abi.encodePacked(
                '{"trait_type":"Animated", "value":"Animated"},'
            ));
        }
        if (isStringEmpty(seed.shadow) == false) {
            floatingMetadata = string(abi.encodePacked(
                '{"trait_type":"Floating", "value":"Floating"},'
            ));
        }
        if (seed.backgroundStyle == 1) {
            bg = string(abi.encodePacked('Cool'));
        }
        if (seed.backgroundStyle == 2) {
            bg = string(abi.encodePacked('Warm'));
        }
        if (seed.backgroundStyle == 3) {
            bg = string(abi.encodePacked('#',seed.colors[seed.colorPalette[1]]));
        }
        
        return string(abi.encodePacked(
            '{"trait_type":"Nog type", "value":"',
                abi.encodePacked(string(seed.nogStyleName)),
            '"},',
                abi.encodePacked(string(getColorMetadata(seed.frameColorLength, seed.colorPalette, seed.colors))),
            '{"trait_type":"Background type", "value":"',
                abi.encodePacked(string(seed.backgroundStyleName)),
            '"},',    
            '{"trait_type":"Background color", "value":"',
                bg,
            '"},',
            animatedMetadata, 
            floatingMetadata,
            '{"trait_type":"Minted by", "value":"',
                abi.encodePacked(string(uint160(seed.minterAddress).toHexString(20))),
            '"}'
        ));
    }

    /*
    ⌐◨—————————————————————————————————————————————————————————————◨
                           utility functions
    ⌐◨—————————————————————————————————————————————————————————————◨ 
    */  

    function isStringEmpty(string memory val) public view returns(bool) {
        bytes memory checkString = bytes(val);
        if (checkString.length > 0) {
            return false;
        } else {
            return true;
        }
    }

    function getPseudorandomness(uint tokenId, uint num) public view returns (uint256 pseudorandomness) {        
        return uint256(keccak256(abi.encodePacked(num * tokenId * tokenId + 1, msg.sender)));
    }
}