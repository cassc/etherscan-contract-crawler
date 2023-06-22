// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/interfaces/IERC721Receiver.sol';

import './ITreasure.sol';
import './Base64.sol';

contract TreasureUnraveler is ERC1155, IERC721Receiver {
    uint256 private constant ERR_1 =
        uint256(keccak256('Red Feather' 'Snow White Feather'));
    uint256 private constant FIX_1 =
        uint256(keccak256('Red and White Feather'));
    uint256 private constant ERR_2 = uint256(keccak256('Carrage'));
    uint256 private constant FIX_2 = uint256(keccak256('Carriage'));

    address public immutable TREASURE;

    mapping(uint256 => string) private itemNames;

    constructor(address treasure, string[] memory names) ERC1155('') {
        for (uint256 i; i < names.length; i++) {
            itemNames[_nameToId(names[i])] = names[i];
        }

        TREASURE = treasure;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        string[3] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = itemNames[tokenId];

        parts[2] = '</text></svg>';

        string memory output = string(
            abi.encodePacked(parts[0], parts[1], parts[2])
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        itemNames[tokenId],
                        '", "description": "Unraveled Treasures are adventurer gear sourced from Treasures (for Loot) NFTs. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use Treasures in any way you want.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );

        output = string(
            abi.encodePacked('data:application/json;base64,', json)
        );

        return output;
    }

    function unravel(uint256 tokenId) public {
        ITreasure(TREASURE).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            ''
        );

        _mintForSenderByAttribute(ITreasure(TREASURE).getAsset1(tokenId));
        _mintForSenderByAttribute(ITreasure(TREASURE).getAsset2(tokenId));
        _mintForSenderByAttribute(ITreasure(TREASURE).getAsset3(tokenId));
        _mintForSenderByAttribute(ITreasure(TREASURE).getAsset4(tokenId));
        _mintForSenderByAttribute(ITreasure(TREASURE).getAsset5(tokenId));
        _mintForSenderByAttribute(ITreasure(TREASURE).getAsset6(tokenId));
        _mintForSenderByAttribute(ITreasure(TREASURE).getAsset7(tokenId));
        _mintForSenderByAttribute(ITreasure(TREASURE).getAsset8(tokenId));
    }

    function _nameToId(string memory name) private pure returns (uint256 id) {
        id = uint256(keccak256(abi.encodePacked(name)));
        if (id == ERR_1) id = FIX_1;
        if (id == ERR_2) id = FIX_2;
    }

    function _mintForSenderByAttribute(string memory name) private {
        _mint(msg.sender, _nameToId(name), 1, '');
    }
}