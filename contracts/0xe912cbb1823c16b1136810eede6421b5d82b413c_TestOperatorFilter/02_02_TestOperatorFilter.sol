// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721} from "solmate/tokens/ERC721.sol";

contract TestOperatorFilter is ERC721("TestOperatorFilter", "TEST") {
    error OperatorNotAllowed();

    modifier onlyAllowedOperator(address addr) virtual {
        if (
            addr == 0x00000000000111AbE46ff893f3B2fdF1F759a8A8 ||
            addr == 0xF849de01B080aDC3A814FaBE1E2087475cF2E354 ||
            addr == 0xFED24eC7E22f573c2e08AEF55aA6797Ca2b3A051 ||
            addr == 0x2B2e8cDA09bBA9660dCA5cB6233787738Ad68329 ||
            addr == 0x024aC22ACdB367a3ae52A3D94aC6649fdc1f0779 ||
            addr == 0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e
        ) {
            revert OperatorNotAllowed();
        }
        _;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(msg.sender) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) public override {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function tokenURI(uint256) public pure override returns (string memory) {
        return "";
    }

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}