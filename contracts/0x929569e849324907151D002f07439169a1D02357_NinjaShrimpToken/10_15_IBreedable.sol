// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import "./IBreedCert.sol";


interface IBreedable is IBreedCert, IERC721 {
  function _totalSupply() external view returns (uint256);
  function breedSafeMint(address _from, uint256 quantity) external;
}