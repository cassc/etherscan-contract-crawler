// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./MintableERC721.sol";

contract TestDTKGenesis is MintableERC721 {
    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseUri_,
        string memory contractURI_,
        uint256 maxSupply_
    ) MintableERC721(name_, symbol_, baseUri_, contractURI_, maxSupply_) {}
}