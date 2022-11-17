// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;


/// @title Interface to retrieve the number of burned NFTs
/// @author Martin Wawrusch
/// @notice This interface is used to retrieve the number of burned NFTs
interface INumberBurned {
  function numberBurned(address adr) external view returns (uint256);
}