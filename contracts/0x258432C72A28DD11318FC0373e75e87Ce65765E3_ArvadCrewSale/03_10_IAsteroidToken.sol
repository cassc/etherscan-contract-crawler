// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


interface IAsteroidToken is IERC721 {

  function mint(address _to, uint _tokenId) external;

  function burn(address _owner, uint _tokenId) external;

  function ownerOf(uint tokenId) external override view returns (address);
}