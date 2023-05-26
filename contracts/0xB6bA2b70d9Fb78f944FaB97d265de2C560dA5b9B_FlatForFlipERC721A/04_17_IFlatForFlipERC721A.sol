// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IFlatForFlipERC721A is IERC721{
  function safeMint(address to, uint256 numOfTokenPurchased) external;
  function totalMinted() external view returns (uint256);
  function salesEndPeriod() external view returns (uint256);
}