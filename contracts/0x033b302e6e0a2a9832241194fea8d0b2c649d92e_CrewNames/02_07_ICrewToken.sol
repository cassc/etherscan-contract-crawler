// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


interface ICrewToken is IERC721 {

  function mint(address _to) external returns (uint);

  function ownerOf(uint256 tokenId) external override view returns (address);
}