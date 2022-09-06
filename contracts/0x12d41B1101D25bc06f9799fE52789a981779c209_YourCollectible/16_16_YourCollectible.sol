pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";

import "./ToColor.sol";

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

contract YourCollectible is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using Strings for uint160;
    using ToColor for bytes3;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    constructor() ERC721("Oh Pandas", "OPD") {}

    mapping(uint256 => bytes3) public color;
    mapping(uint256 => uint256) public mouthWidth;

    uint256 mintDeadline = block.timestamp + 8 days;

    function mintItem() public returns (uint256) {
        require(block.timestamp < mintDeadline, "DONE MINTING");
        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        _mint(msg.sender, id);

        bytes32 predictableRandom = keccak256(
            abi.encodePacked(
                blockhash(block.number - 1),
                msg.sender,
                address(this),
                block.chainid,
                id
            )
        );
        color[id] =
            bytes2(predictableRandom[0]) |
            (bytes2(predictableRandom[1]) >> 8) |
            (bytes3(predictableRandom[2]) >> 16);
        mouthWidth[id] =
            9 +
            ((50 * uint256(uint8(predictableRandom[3]))) / 255);

        return id;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_exists(id), "!exist");

        string memory name = string(
            abi.encodePacked("Oh Pandas #", id.toString())
        );
        string memory description = string(
            abi.encodePacked(
                "This Oh Pandas borns with genes of color #",
                color[id].toColor(),
                " and size ",
                mouthWidth[id].toString(),
                "!!!"
            )
        );
        string memory image = Base64.encode(bytes(generateSVGofTokenById(id)));
        (
            string memory leftEarColor,
            string memory rightEarColor,
            string memory faceStrokeColor,
            string memory leftEyeColor,
            string memory rightEyeColor,
            string memory noseColor,
            string memory mouthColor,
            uint256 mouthSize,
            uint256 earSize,
            uint256 noseSize
        ) = getPropertiesById(id);
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '","description":"',
                                description,
                                '","external_url":"https://ohpandas.com/token/',
                                id.toString(),
                                '","attributes":[{"trait_type":"left ear color","value":"#',
                                leftEarColor,
                                '"},{"trait_type":"right ear color","value":"#',
                                rightEarColor,
                                '"},{"trait_type":"facial outline color","value":"#',
                                faceStrokeColor,
                                '"},{"trait_type":"left eye color","value":"#',
                                leftEyeColor,
                                '"},{"trait_type":"right eye color","value":"#',
                                rightEyeColor,
                                '"},{"trait_type":"nose color","value":"#',
                                noseColor,
                                '"},{"trait_type":"mouth color","value":"#',
                                mouthColor,
                                '"},{"trait_type":"mouth size","value":"',
                                mouthSize.toString(),
                                '"},{"trait_type":"ear size","value": "',
                                earSize.toString(),
                                '"},{"trait_type":"nose size","value": "',
                                noseSize.toString(),
                                '"}],"owner":"',
                                (uint160(ownerOf(id))).toHexString(20),
                                '","image": "',
                                "data:image/svg+xml;base64,",
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    // function generateSVGofTokenById(uint256 id) internal view returns (string memory) {
    function generateSVGofTokenById(uint256 id)
        internal
        view
        returns (string memory)
    {
        string memory svg = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="300" version="1.1" xmlns:xlink="http://www.w3.org/1999/xlink">',
                renderTokenById(id),
                "</svg>"
            )
        );
        return svg;
    }

    // properties of the token of id
    function getPropertiesById(uint256 id)
        public
        view
        returns (
            string memory leftEarColor,
            string memory rightEarColor,
            string memory faceStrokeColor,
            string memory leftEyeColor,
            string memory rightEyeColor,
            string memory noseColor,
            string memory mouthColor,
            uint256 mouthSize,
            uint256 earSize,
            uint256 noseSize
        )
    {
        uint24 theColor = uint24(color[id]);
        leftEarColor = bytes3(theColor).toColor();
        rightEarColor;
        faceStrokeColor;
        leftEyeColor;
        rightEyeColor;
        noseColor;
        mouthColor;
        mouthSize = mouthWidth[id];
        earSize = 20 + mouthSize / 2;
        noseSize = 17 + mouthSize / 8;
        unchecked {
            rightEarColor = bytes3(theColor + 0xF5F7E3).toColor();
            faceStrokeColor = bytes3(theColor + 0xDDD5ED).toColor();
            leftEyeColor = bytes3(theColor + 0xBCB5DD).toColor();
            rightEyeColor = bytes3(theColor + 0x9079A8).toColor();
            noseColor = bytes3(theColor + 0x625068).toColor();
            mouthColor = bytes3(theColor + 0x8D64A8).toColor();
        }
    }

    // Visibility is `public` to enable it being called by other contracts for composition.
    function renderTokenById(uint256 id) public view returns (string memory) {
        (
            string memory leftEarColor,
            string memory rightEarColor,
            string memory faceStrokeColor,
            string memory leftEyeColor,
            string memory rightEyeColor,
            string memory noseColor,
            string memory mouthColor,
            uint256 mouthSize,
            uint256 earSize,
            uint256 noseSize
        ) = getPropertiesById(id);

        string memory render = string(
            abi.encodePacked(
                // left ear
                '<circle cx="90" cy="80" r="',
                earSize.toString(),
                '" fill="#',
                leftEarColor,
                '" shape-rendering="geometricPrecision"></circle>',
                // right ear
                '<circle cx="210" cy="80" r="',
                earSize.toString(),
                '" fill="#',
                rightEarColor,
                '" shape-rendering="geometricPrecision"></circle>',
                // head(face)
                '<circle cx="150" cy="150" r="97" stroke="#',
                faceStrokeColor,
                '" stroke-width="6.38" fill="white" shape-rendering="geometricPrecision"/>',
                // left eye
                '<circle cx="115" cy="125" r="27.04" fill="#',
                leftEyeColor,
                '" shape-rendering="geometricPrecision"></circle>',
                '<circle cx="115" cy="125" r="10.32" fill="white" shape-rendering="geometricPrecision"></circle>',
                // right eye
                '<circle cx="185" cy="125" r="27.04" fill="black" shape-rendering="geometricPrecision"></circle>',
                '<circle cx="185" cy="125" r="10.32" fill="#',
                rightEyeColor,
                '" shape-rendering="geometricPrecision"></circle>',
                '<circle cx="185" cy="125" r="6.38" fill="black" shape-rendering="geometricPrecision"></circle>',
                // nose
                '<circle cx="150" cy="170" r="',
                noseSize.toString(),
                '" fill="#',
                noseColor,
                '" shape-rendering="geometricPrecision"></circle>',
                // mouse
                '<ellipse cx="150" cy="210" rx="',
                mouthSize.toString(),
                '" ry="9.09" style="fill:#',
                mouthColor,
                ';stroke:black;stroke-width:3.94" shape-rendering="geometricPrecision"/>'
            )
        );

        return render;
    }
}