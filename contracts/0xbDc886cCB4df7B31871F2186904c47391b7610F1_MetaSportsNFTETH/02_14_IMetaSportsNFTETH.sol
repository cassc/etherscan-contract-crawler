// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMetaSportsNFTETH is IERC721 {
    function exisit(uint256) external view  returns (bool);

    function safeMint(address _to, uint256 _tokenId) external;
}