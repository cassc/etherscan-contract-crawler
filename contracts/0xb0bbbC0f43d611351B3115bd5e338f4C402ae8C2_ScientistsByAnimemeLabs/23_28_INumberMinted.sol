// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title Interface to retrieve the number of minted NFTs
/// @author Martin Wawrusch
/// @notice This interface is used to retrieve the number of minted NFTs
interface INumberMinted {
  function numberMinted(address adr) external view returns (uint256);
}