// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Base64.sol";
import "./PartCombis.sol";
import "./Attributes.sol";

contract GenerativePudding is ERC721, Ownable, PartCombis, Attributes {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint256 private constant CLEAR_FOR_PARTS =
        0x000000000000000000000000000000000000000000000000000000000000ffff;
    uint256 private constant CLEAR_FOR_A_PART = 0x000f;
    string private constant SVG_HEAD =
        "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz48c3ZnIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgd2lkdGg9IjMyMCIgaGVpZ2h0PSIzMjAiIHZpZXdCb3g9IjAgMCAzMjAgMzIwIj4g";
    string private constant SVG_TAIL = "PC9zdmc+";
    string[] private BASE_COLORS = [
        "PHJlY3Qgd2lkdGg9IjMyMCIgaGVpZ2h0PSIzMjAiIHN0eWxlPSJmaWxsOiNlMWZmZmY7Ii8+",
        "PHJlY3Qgd2lkdGg9IjMyMCIgaGVpZ2h0PSIzMjAiIHN0eWxlPSJmaWxsOiNmZmUxZmY7Ii8+",
        "PHJlY3Qgd2lkdGg9IjMyMCIgaGVpZ2h0PSIzMjAiIHN0eWxlPSJmaWxsOiNmZmZmZTE7Ii8+"
    ];
    string[] private PARTS_BOTTOM;
    string[] private PARTS_FACE;
    string[] private PARTS_PUDDING;
    string[] private PARTS_TOP;
    mapping(uint256 => Pudding) private puddingsToTokenId;
    struct Pudding {
        uint256 baseColor;
        uint256 bottom;
        uint256 face;
        uint256 pudding;
        uint256 top;
    }

    constructor() ERC721("Generative Pudding", "GSP") {}

    function safeMint(address to) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        Pudding memory pudding = cookPudding();
        puddingsToTokenId[tokenId] = pudding;
        _safeMint(to, tokenId);
    }

    function safeBatchMint(address to, uint8 num) public onlyOwner {
        for (uint8 i = 0; i < num; i++) {
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();
            Pudding memory pudding = cookPudding();
            puddingsToTokenId[tokenId] = pudding;
            _safeMint(to, tokenId);
        }
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return buildMetadata(_tokenId);
    }

    function setBottom(string memory bottom) public onlyOwner {
        PARTS_BOTTOM.push(bottom);
    }

    function setFace(string memory bottom) public onlyOwner {
        PARTS_FACE.push(bottom);
    }

    function setPudding(string memory bottom) public onlyOwner {
        PARTS_PUDDING.push(bottom);
    }

    function setTop(string memory bottom) public onlyOwner {
        PARTS_TOP.push(bottom);
    }

    function getLength() public view onlyOwner returns (uint256[4] memory) {
        return [
            PARTS_BOTTOM.length,
            PARTS_FACE.length,
            PARTS_PUDDING.length,
            PARTS_TOP.length
        ];
    }

    // private
    function cookPudding() private returns (Pudding memory) {
        uint256 index = randomNum(PART_COMBIS.length);
        uint256 partCombis = PART_COMBIS[index];
        uint256 parts = partCombis & CLEAR_FOR_PARTS;
        (
            uint256 bottom,
            uint256 face,
            uint256 pudding,
            uint256 top
        ) = getPartsIndexes(parts);
        uint256 baseColor = randomNum(BASE_COLORS.length);
        partCombis >>= 16;
        PART_COMBIS[index] = partCombis;
        if (partCombis == 0) {
            deleteCombiArray(index);
        }
        return Pudding(baseColor, bottom, face, pudding, top);
    }

    function getPartsIndexes(uint256 parts)
        private
        pure
        returns (
            uint256 bottom,
            uint256 face,
            uint256 pudding,
            uint256 top
        )
    {
        top = parts & CLEAR_FOR_A_PART;
        parts >>= 4;
        pudding = parts & CLEAR_FOR_A_PART;
        parts >>= 4;
        face = parts & CLEAR_FOR_A_PART;
        parts >>= 4;
        bottom = parts & CLEAR_FOR_A_PART;
    }

    function randomNum(uint256 _mod) private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        msg.sender,
                        _tokenIdCounter.current()
                    )
                )
            ) % _mod;
    }

    function deleteCombiArray(uint256 index) private {
        uint256 last = PART_COMBIS[PART_COMBIS.length - 1];
        PART_COMBIS[index] = last;
        PART_COMBIS.pop();
    }

    function buildMetadata(uint256 _tokenId)
        private
        view
        returns (string memory)
    {
        Pudding memory pudding = puddingsToTokenId[_tokenId];
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"Generative Pudding #',
                                Strings.toString(_tokenId),
                                '", "description":"NFT collection of puddings made by an engineer who used to be a pastry chef. It is a full on chain NFT. There are various combinations of parts and the number of the collection is 11760.',
                                '", "image": "',
                                "data:image/svg+xml;base64,",
                                buildImage(_tokenId),
                                '", "attributes": ',
                                "[",
                                '{"trait_type": "Back Ground",',
                                '"value":"',
                                metadataBackground(pudding.baseColor),
                                '"},',
                                '{"trait_type": "Bottom",',
                                '"value":"',
                                metadataBottom(pudding.bottom),
                                '"},',
                                '{"trait_type": "Face",',
                                '"value":"',
                                metadataFace(pudding.face),
                                '"},',
                                '{"trait_type": "Pudding",',
                                '"value":"',
                                metadataPudding(pudding.pudding),
                                '"},',
                                '{"trait_type": "Top",',
                                '"value":"',
                                metadataTop(pudding.top),
                                '"}',
                                "]",
                                "}"
                            )
                        )
                    )
                )
            );
    }

    function buildImage(uint256 _tokenId) private view returns (string memory) {
        Pudding memory pudding = puddingsToTokenId[_tokenId];
        return
            string(
                abi.encodePacked(
                    SVG_HEAD,
                    BASE_COLORS[pudding.baseColor],
                    PARTS_BOTTOM[pudding.bottom],
                    PARTS_PUDDING[pudding.pudding],
                    PARTS_FACE[pudding.face],
                    PARTS_TOP[pudding.top],
                    SVG_TAIL
                )
            );
    }
}