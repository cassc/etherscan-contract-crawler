// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@minteeble/smart-contracts/contracts/token/ERC721/IMinteebleStaticMutation.sol";
import "@minteeble/smart-contracts/contracts/token/ERC721/MinteebleERC721A.sol";

contract SerumMAYC is MinteebleERC721A {
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _maxSupply,
        uint256 _mintPrice
    ) MinteebleERC721A(_tokenName, _tokenSymbol, _maxSupply, _mintPrice) {}
}