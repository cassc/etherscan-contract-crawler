// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



contract OnZoo is ERC721A, Ownable {
    uint256 private _curLimit = 777;
    bool private _isPublicClaimActive = true;
    uint256 private _tokenPrice = 3000000000000000; //0.003 ETH

    mapping(address => bool) public freeClaimed;

    function toString(uint256 value) internal pure returns (string memory) {
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

    constructor() ERC721A("Onchain Zoo", "OCZ") {}

   
    function setLimit(uint256 amount) public onlyOwner {
        _curLimit = amount;
    }

    function flipPublicClaimState() public onlyOwner {
        _isPublicClaimActive = !_isPublicClaimActive;
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory output;
        uint256 rand = random(string(abi.encodePacked('Zoo',toString(tokenId))));
        uint16 i;
        uint8 pet_type;
        uint8 text_type;
        uint8 nose_type;
        uint8 mouth_type;
        uint8 token_type;

        
        uint8 palette;
        
        string[36] memory bg = [
            'ca45cc',
            '19d19d',
            '46b8c7',
            'ff8a8a',
            'ffde5c',
            '96d957',
            '5f6ecf',
            'a258c7',
            'f05696',
            '7dab9f',
            'ff8e4d',
            '7ba1b8',
            '867abf',
            'cc7a89',
            '8cad5f',
            '7b9977',
            'b0db3b',
            'c4c4c4',
            'Fuchsia Purple',    
            'Ocean Green',    
            'Robin`s Egg Blue',    
            'Coral Pink',    
            'Mustard Yellow',    
            'Pistachio Green',    
            'Blue Violet',    
            'Purple',    
            'Watermelon Pink',    
            'Sea Foam Green',    
            'Tangerine Orange',    
            'Steel Blue',    
            'Bluey Purple',    
            'Dusty Rose',    
            'Sage Green',    
            'Sagebrush Green',    
            'Kiwi Green',    
            'Silver'
        ];

        string[27] memory texts = [
            'Rabbit',
            'Hamster',
            'Cat',
            'Fox', 
            'Mouse',
            'Dog',
            'Hidden',
            "\xE3\x81\x82\xE3\x82\x8C", // あれ
            "\xE3\x81\xA9\xE3\x81\x86", // どう
            "\xE3\x81\x8A\xE3\x81\x86", // おう
            "\xE3\x81\x98\xE3\x82\x83", // じゃ
            "\xE3\x81\x82\xE3\x81\x82", // ああ
            "\xE3\x81\x95\xE3\x81\x82", // さあ
            "\xE3\x81\x8A\xE3\x81\x84", // おい
            "\xE3\x81\x82\xE3\x82\x8C", // あれ
            "\xE3\x81\x82\xE3\x81\xAE", // あの
            "\xE5\xBD\xBC\xE3\x81\xAE", // 彼の
            "\xE5\xBD\xBC\xE3\x82\x8C", // 彼れ
            "\xE7\x8F\xBE\xE9\x87\x91", // 現金
            "\xE7\xA1\xAC\xE8\xB2\xA8", // 硬貨
            "\xE5\x88\xA9\xE7\x9B\x8A", // 利益
            "\xE6\x84\x9F\xE8\xAC\x9D", // 感謝
            "\xE5\xA5\xBD\xE3\x81\x8D", // 好き
            "\xE6\x83\x85\xE7\x86\xB1", // 情熱
            "\xE6\x84\x9B\xE7\x9D\x80", // 愛着
            "\xE6\x84\x9F\xE5\xBF\x83", // 感心
            "\xE6\x86\xA4\xE6\x80\x92"  // 憤怒
        ];


        string[46] memory data = [
            '51,816c0,0,526-167,893,20',
            '331,458c0,0-148-346-0-362c102-11,77,210,76,303',
            '656,462c0,0,35-193,92-214c52-19-211-312-175,149',
            '300,508c-122-51,9-213,95-105',
            '683,508c122-51-9-213-95-105',
            '689,508c0,0,78-279-95-105',
            '303,498c0,0-75-270,98-95',
            '303,500c-36-107,32-573,151-120',
            '687,501c36-107-32-573-151-120',
            '565,396c187-320,253,170,78,50',
            '414,396c-187-320-301,166-68,52',//10
            '442,389c-100-134-219,29-255,71s18,133,108,61',
            '549,389c100-134,219,29,255,71s-18,133-108,61',
            '719,662c30-128-98-281-220-281c-128,0-259,142-213,277',
            '722,645c-169,116-156-43-222-41c-84,2-36,147-217,44c0,0-4,127,216,123C717,766,722,645,722,645z',
            '362,502c0,0,31-34,60-21',
            '630,502c0,0-31-34-60-21',
            '385,623c-30-50,34-134,48-10',
            '605,623c30-50-34-134-48-10',
            '469,609c-1,23,49,26,54,2',
            '485,607c-0,67,62-4,3-1',//20
            '484,612c6,36,50-11,7-1',
            '459,652c14,39,39-5,39-5s14,45,40,3',
            '457,668c30-16,55-18,81-0c6,4-22-14-39-13c-0-9-1-22-1-22',
            '537,654c-24,5-54,3-73-0c-11,17,36,48,53,3c-23-0-18-5-18-24',
            '499,629c0,0,1,30,3,34c17-1,30-2,30-2c-33,79-65,1-65,1c18,2,33,0,33,0l1,16',
            '503,654c-65,15,13,56-1-6',
            '499,633c0,0,0,27,0,31c0-11-2-12,29-16c-12,36-43,40-59,1c0,0,27,7,58-0',
            '461,665c22,0,37-16,37-31c2,30,30,31,43,31',
            '423,573c-26,6-29,31,7,23',
            '572,573c24,6,27,31-6,23',
            '275,788c-45,0-24-60,40-58s66,70,6,65',
            '277,764c-29,43,70,50,54,1',
            '713,789c45,0,24-61-40-59c-65,2-70,70-9,65',
            '710,764c29,43-70,50-54,1',
            
            '371-494c0,0,42,925,3,978s230,27,230,27L560-507',
            '416,612c-116,0-120-158,71-162s211,177,55,163',
            '417,546c-51,124,189,138,143-5',
            '471,646c0,0,18,36,38,0',
            '376,609c0,0,15,44,32,7',
            '571,619c0,0,13,35,32-9',
            '493,726l89-128c0,0-89,52-89,52',
            '493,630c0-0,89-53,89-53L493,434',
            '490,726l-89-128l89,52c0,0,0,72,0,73',
            '490,440c0,2,0,190,0,190l-89-53l89-142',
            '402,578l90-40c0,0,88,39,88,39'
        ];


        
        pet_type = 1 + uint8(rand % 6);
        nose_type = 1 + uint8((rand>>5) % 3);
        mouth_type = 1 + uint8((rand>>10) % 7);
        text_type = 1 + uint8((rand>>15) % 20);
        token_type = 1 + uint8((rand>>20) % 30);


        palette = uint8((rand>>20) % 100);
        if (palette > 17)
            palette = palette % 16;
       
        output = string(abi.encodePacked('<?xml version="1.0" encoding="utf-8"?><svg  xmlns="http://www.w3.org/2000/svg" width="1000px" height="1000px" viewBox="0 0 1000 1000">',
            '<style type="text/css" media="screen"><![CDATA[ svg {margin: 0; background: #',bg[palette],';height: 100vh;width: 100%;}]]></style><g>'
            ));

        if (token_type > 1) {
                for(i=0;i<35;i++) {
                    
                    if (i == 14 ||i == 31 || i == 33) {
                        output = string(abi.encodePacked(output,
                            '<path fill="#fff" stroke="#000000" stroke-width="13" d="M',data[i],'"/>'
                        ));
                    } else {
                        if ((i==0 || (i>12 && i<19) || (i > 28))
                            
                            || (i == pet_type*2 || i==pet_type*2-1)
                            || (i == (18 + nose_type))
                            || (i == (21 + mouth_type))
                            ) {
                            output = string(abi.encodePacked(output,
                                '<path fill="none" stroke="#000000" stroke-width="13" d="M',data[i],'"/>'
                            ));
                        }

                    }



                    if (i == 2 || i == 30 || i == 32) {
                        output = string(abi.encodePacked(output,
                            '</g><g><animateTransform attributeName="transform" type="scale" values="1,1;1,1;1,1;',
                            (i==2?'1,1;1,1;1,1;1,1;1,1.02':(i==30?'0.99,1;1,1;1,1;1,1;0.97,0.99':'1.01,1;1,1;1,1;1,1;1.03,0.99')),
                            ';1,1" begin="0s" dur="4s" repeatCount="indefinite" />'
                        ));
                    }

                    
                }

                output = string(abi.encodePacked(output,
                '</g><ellipse fill="#FFFFFF" stroke="#000000" stroke-width="9" cx="850" cy="319" rx="101" ry="68"/><text transform="matrix(1 0 0 1 771 341)" font-family="Arial Black" font-size="77">',texts[text_type+6],'</text><polyline fill="#FFFFFF" stroke="#000000" stroke-width="9" points="771,356 760,396 804,375"/></svg>'
                ));     
        } else {
            output = string(abi.encodePacked(output,
                '<animateMotion path="M 0 0 V 20 Z" dur="4s" repeatCount="indefinite" /><animate attributeName="opacity" dur="4s" values="0;0.1;0.4;0.6;0.8;1;1;1;1;0;0;0;0;0;0;0;0;0;" repeatCount="indefinite" begin="0"/>'
            ));  

            for(i=41;i<46;i++) {
                output = string(abi.encodePacked(output,
                    '<path opacity="0.',((i==44||i==43)?'99':'7'),'" fill="',(i==45 ? 'none':'#fff'),'" stroke-linecap="round" stroke="#000" stroke-width="11" d="M',data[i],'"/>'
                ));
            }
            output = string(abi.encodePacked(output,
                '</g><g><animateMotion path="M 0 -1000 V -100 Z" dur="4s" repeatCount="indefinite" /><animateTransform attributeName="transform" type="scale" values="1,0.7;1,0.7;1,0.7;1,0.7;1,1.3;1,0.7;1,0.7;1,0.7;1,0.7" begin="0s" dur="4s" repeatCount="indefinite"/>'
            )); 
            for(i=35;i<41;i++) {
                output = string(abi.encodePacked(output,
                    '<path fill="#fff" stroke="#000" stroke-width="13" d="M',data[i],'"/>'
                ));
            }

            output = string(abi.encodePacked(output,
                '</g></svg>'
            ));   
        }

        
        string memory strparams;

        strparams = string(abi.encodePacked('[{ "trait_type": "Pet", "value": "',(token_type==1?texts[6]: texts[pet_type-1]),'" }, { "trait_type": "Palette", "value": "',bg[palette+18],'" }]'));


        output = Base64.encode(bytes(string(abi.encodePacked('{"name": "OnChain Zoo", "description": "Adorable millimeter-sized creatures, completely generated OnChain.","attributes":', strparams, ', "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', output));

        return output;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function buy(uint amount) public payable {
        require(amount > 0, "Wrong amount");
        require(_isPublicClaimActive, "Later");
        require(totalSupply() + amount < _curLimit, "Sale finished");
        require(_tokenPrice * amount <= msg.value, "Need more ETH");

        _safeMint(msg.sender, amount);
    }

    function mint() public {
        require(_isPublicClaimActive, "Later");
        require(totalSupply() < 333, "Claim finished");
        require(freeClaimed[msg.sender] == false, "Done");

        _safeMint(msg.sender, 1);
        freeClaimed[msg.sender] = true;
    }

    function drop(address _address, uint256 amount) public onlyOwner {
        _safeMint(_address, amount);
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