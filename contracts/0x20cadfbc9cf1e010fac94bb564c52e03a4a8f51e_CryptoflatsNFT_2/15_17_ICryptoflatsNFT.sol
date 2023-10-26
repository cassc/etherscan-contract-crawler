// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

enum Type {
    Standart,
    Silver,
    Gold,
    Diamond
}

interface ICryptoflatsNFT is IERC721 
{
    function getNFTType(uint256 _tokenId) external view returns (Type);
}