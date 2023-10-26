// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC721A} from "ERC721A/ERC721A.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";
import {Base64} from "openzeppelin/utils/Base64.sol";

contract TeamHexBlue is ERC721A {
    constructor() ERC721A("#036AFD", "#036AFD") {}

    error AlreadyMinted();

    function goTeamBlue() public {
        if (_getAux(msg.sender) != 0) revert AlreadyMinted();
        _setAux(msg.sender, 1);
        _mint(msg.sender, 5);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory image = Base64.encode(
            bytes(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 800"><rect width="800" height="800" fill="#036AFD"/></svg>'
            )
        );
        string memory metadataJSON =
            string.concat('{"name":"#mintBlue","image":"data:image/svg+xml;base64,', image, '"}');
        return string.concat("data:application/json;base64,", Base64.encode(bytes(metadataJSON)));
    }
}