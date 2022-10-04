// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "../ERC20.sol";

/** 
* @title A Token Smart Contract
* @author Lunar Defi, Inc. Copyright © 2022. All rights reserved. 
* @notice This is an upgrade to LunarNFT contract
*/
contract LunarV3 is Lunar {
  /**
  * @notice shows the version of the contract being used
  * @dev the value represents the curreent version of the contract should be updated and overriden with new implementations
  * @return version -the current version of the contract
  */
  function version() external pure override returns(string memory)
  {
    return "2.0.2";
  }
}