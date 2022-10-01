// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "../Solarity.sol";

/** 
* @title A Token Smart Contract
* @author Solarity Defi, Inc. Copyright © 2022. All rights reserved. 
* @notice This is an upgrade to SolarityNFT contract
*/
contract SolarityV2 is Solarity {
  /**
  * @notice shows the version of the contract being used
  * @dev the value represents the curreent version of the contract should be updated and overriden with new implementations
  * @return version -the current version of the contract
  */
  function version() external pure override returns(string memory)
  {
    return "2.0.1";
  }
}