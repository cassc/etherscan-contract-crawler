// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface ILayerrToken {
  /**
  * @dev initializes the proxy contract
  * @param data: the data to be passed to the proxy contract is abi encoded
  * @param _LayerrXYZ: the address of the LayerrVariables contract
  */
  function initialize(
    bytes calldata data,
    address _LayerrXYZ
  ) external;
}