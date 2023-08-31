//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface iFeather {
    function infos(uint256 id)
        external
        view
        returns (
            uint256 blocknumber,
            address creator,
            string memory name,
            uint256 x,
            uint256 y,
            uint256 background,
            bool isFree,
            uint256 leafs
        );

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    function ownerOf(uint256 index) external view returns (address);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256 balance);
}

contract EVM is ERC721, ERC721Enumerable, Ownable {
    mapping(uint256 => bool) public claimed;

    /* [ Name, background, primary, secondary ] */
    string[4][16] colorPalettes = [
        ["White", "FFFFFF", "000000", "FFFFF"],
        ["Starry Night", "0B1E38", "DB901C", "7FC5DC"],
        ["Retro", "5EF230", "FF00A1", "F8FF00"],
        ["Lava", "F8FF00", "FFFA27", "B33607"],
        ["Carribean Sunrise", "B33607", "E5AE1F", "E18330"],
        ["Future Of France", "ffffff", "0050a4", "ef4135"],
        ["Hot Koala", "ecf0f1", "333333", "c99d66"],
        ["Black", "000000", "FFFFFF", "EEEEEE"],
        ["Marine", "104F7E", "ADD5E1", "248AB9"],
        ["EGirl", "ff5d8f", "f9f9f9", "ffe45e"],
        ["Jungle", "e1bb80", "352208", "018e42"],
        ["Cyber", "000411", "FF0000", "aeb7b3"],
        ["Orange Mechanic", "FF9F1C", "FFFFFF", "2EC4B6"],
        ["English Violet", "5C415D", "DBD053", "74526C"],
        ["Up Only", "4F9D69", "BCFFDB", "68D89B"],
        ["Yellow Submarine", "E0FF4F", "E0FF4F", "A51080"]
    ];

    string[12] level = [
        "0.3",
        "0.6",
        "0.8",
        "1",
        "1.2",
        "1.420",
        "2",
        "2.4",
        "2.69",
        "3",
        "3.5",
        "4"
    ];

    string[7] rotate = [
        "90", //normal
        "45",
        "1",
        "34",
        "69",
        "27",
        "42"
    ];

    iFeather feather;

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
        Ownable()
    {
        feather = iFeather(0x51d0B69886DcDe7a4fb9b39722868056804AFbca); //Feather
    }

    /* Begin Utils */

    // @title Base64
    // @author Brecht Devos - <[email protected]>
    // @notice Provides a function for encoding some bytes in base64
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encodeBase64(bytes memory data)
        internal
        pure
        returns (string memory)
    {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    function random(
        uint256 min,
        uint256 max,
        uint256 seed
    ) public pure returns (uint256) {
        uint256 randomnumber = uint256(keccak256(abi.encodePacked(seed))) %
            (max - min);
        return randomnumber + min;
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /* End Utils */

    function getDropIfYouOwnFeather(uint256 id) public {
        require(feather.ownerOf(id) == msg.sender);
        require(!claimed[id]);
        require(id < 1000);
        claimed[id] = true;

        bool isFree;
        (, , , , , , isFree, ) = feather.infos(id);
        require(!isFree);
        _mint(msg.sender, id);
    }

    function getColor(uint256 id) public view returns (string[4] memory) {
        return (colorPalettes[random(0, colorPalettes.length, id)]);
    }

    function getLevel(uint256 id) public view returns (string memory) {
        return (level[random(0, level.length, id)]);
    }

    function getRotate(uint256 id) public view returns (string memory) {
        return (rotate[random(0, rotate.length, id)]);
    }

    function generateSVG(uint256 id) public view returns (string memory) {
        string[4] memory color = getColor(id);
        string memory level = getLevel(id);
        string memory rotate = getRotate(id);

        string memory svg = string(
            abi.encodePacked(
                "<svg version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' viewBox='0 0 1000 1000' width='1000' height='1000' fill='#",
                color[1],
                "'><defs><filter id='f1' x='0' y='0'><feGaussianBlur in='SourceGraphic' stdDeviation='0.2' /></filter><linearGradient id='gr' gradientTransform='rotate(90)'><stop offset='5%'><animate attributeName='stop-color' values='#",
                color[3],
                "; #",
                color[2],
                "; #",
                color[3]
            )
        );
        svg = string(
            abi.encodePacked(
                svg,
                "' dur='10' repeatCount='indefinite'></animate></stop><stop offset='70%'><animate attributeName='stop-color' values='#",
                color[2],
                "; #",
                color[3],
                "; #",
                color[2]
            )
        );
        svg = string(
            abi.encodePacked(
                svg,
                "' dur='9s' repeatCount='indefinite'></animate></stop></linearGradient><pattern id='t' patternUnits='userSpaceOnUse' width='562.6' height='325' patternTransform='scale(",
                level,
                ")' stroke='url(#gr)'  stroke-width='8'><animateTransform attributeName='patternTransform' type='scale' dur='70s' values='",
                level,
                "; 0.7; ",
                level,
                "' repeatCount='indefinite'/><animate attributeName='stroke-width' values='2; 10; 2' dur='15s' repeatCount='indefinite'/><g id='g'><polygon points='281.4,0 375.2, 162.5 281.4, 325 187, 161.5'  id='b'/><g id='B'><use xlink:href='#b' transform='rotate(",
                rotate,
                " 280 162.5) translate(116, 67) scale(.58)' id='b1'/><g id='d'><use xlink:href='#b' transform='translate(188.85, 108) scale(.33)' id='b2'/><g id='sd'><use xlink:href='#b1' transform='translate(189.85, 108) scale(.33)' id='b3'/><use xlink:href='#b2' transform='translate(188.85, 108) scale(.33)' id='b4'/><use xlink:href='#b3' transform='translate(188.85, 108) scale(.33)'/><use xlink:href='#b4' transform='translate(188.85, 108) scale(.33)'/></g></g><use xlink:href='#sd' transform='translate(62,0)'/><use xlink:href='#sd' transform='translate(-62,0)'/><use xlink:href='#d' transform='translate(0,-107)'/><use xlink:href='#d' transform='translate(0, 107)'/></g></g><g id='t'><use xlink:href='#g'/><use xlink:href='#g' transform='rotate(60 281 0)'/><use xlink:href='#g' transform='rotate(-60 281 0)'/><use xlink:href='#g' transform='rotate(-60 281 325)'/><use xlink:href='#g' transform='rotate(60 281 325)'/><g id='v'><use xlink:href='#g' transform='translate(-282, -162)'/><use xlink:href='#g' transform='translate(-282, 162)'/></g><use xlink:href='#v' transform='translate(564, 0)'/></g></pattern></defs><rect width='100%' height='100%' fill='#",
                color[1],
                "'/><rect width='980' x='10' y='10' height='980' fill='url(#t)'/><line x1='0' y1='10' x2='1000' y2='10' stroke='#"
            )
        );
        // frame
        svg = string(
            abi.encodePacked(
                svg,
                color[2],
                "' /><line x1='0' y1='990' x2='1000' y2='990' stroke='#",
                color[2],
                "' /><line x1='10' y1='0' x2='10' y2='1000' stroke='#",
                color[2],
                "' /><line x1='990' y1='0' x2='990' y2='1000' stroke='#",
                color[2],
                "' /><text x='12' y='999' class='small' font-family='monospace' font-size='10' fill='#",
                color[2],
                "'>EVM Dreams #",
                uint2str(id),
                " | Can t be described in the same way that one might point to a cloud or an ocean wave, but it does exist as one single entity</text></svg>"
            )
        );
        return svg;
    }

    function generateMetadata(uint256 id) public view returns (string memory) {
        string[4] memory color = getColor(id);
        string memory level = getLevel(id);
        string memory rotate = getRotate(id);

        string memory metadata = string(
            abi.encodePacked(
                '{"trait_type": "Color","value":"',
                color[0],
                '"},{"trait_type": "Level","value":"',
                level,
                '"},{"trait_type": "Rotate","value":"',
                rotate,
                '"}'
            )
        );
        return metadata;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory image = generateSVG(_tokenId);
        string memory attributes = string(
            abi.encodePacked(
                '", "attributes":[',
                generateMetadata(_tokenId),
                "]}"
            )
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;utf8,",
                    (
                        (
                            abi.encodePacked(
                                '{"name":"Dreams of EVM #',
                                uint2str(_tokenId),
                                '","image": ',
                                '"',
                                "data:image/svg+xml;utf8,",
                                (abi.encodePacked(image)),
                                attributes
                            )
                        )
                    )
                )
            );
    }

    receive() external payable {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC721)
        returns (bool)
    {
        return ERC721Enumerable.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}