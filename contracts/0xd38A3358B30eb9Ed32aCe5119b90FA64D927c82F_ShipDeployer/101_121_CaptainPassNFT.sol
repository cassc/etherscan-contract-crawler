// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {ERC721PresetMinterPauserAutoId} from "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract CaptainPassNFT is
    ERC721PresetMinterPauserAutoId("CaptainPass NFT", "CPNFT", "")
{
    string private _baseTokenURI;

    constructor(address sznsdao, string memory baseURI) {
        _baseTokenURI = baseURI;
        grantRole(MINTER_ROLE, sznsdao);
    }

    function setBaseURI(
        string calldata baseURI
    ) external onlyRole(MINTER_ROLE) {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function safeMint(
        address to,
        uint256 tokenId
    ) public onlyRole(MINTER_ROLE) {
        _safeMint(to, tokenId);
    }
}