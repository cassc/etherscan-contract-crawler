// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface IKeys is IERC721 {
  function forge(address to) external;
}