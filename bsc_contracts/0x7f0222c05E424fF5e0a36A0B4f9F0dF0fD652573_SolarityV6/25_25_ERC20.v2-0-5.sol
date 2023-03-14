// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../Solarity.sol";

/** 
* @title A Token Smart Contract
* @author Copyright © 2022-2023 Solarity Foundation All rights reserved. 
* @notice This is an upgrade to Solarity Token smart contract.
*/
contract SolarityV6 is Solarity {
  /**
  * @notice shows the version of the contract being used
  * @dev the value represents the curreent version of the contract should be updated and overriden with new implementations
  * @return version -the current version of the contract
  */
  function version() external pure override returns(string memory)
  {
    return "2.0.5";
  }
}