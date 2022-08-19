// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


abstract contract AxxessControl2DATA  {

  /**
   * @notice Master's address FOOBAR
   */
  address[2] MasterAddress;

  /**
   * @notice Admin's address
   */
  address public AdminAddress;

  /**
   * @notice Operator's address
   */
  address[2] OperatorAddress;



  /**
   * @notice peer authorized contrat address
   */
  address PeerContractAddress;

  /**
   * @notice peer authorized contrat address
   */
  address delegate;

  // mem test
  uint8 public xs = 9;


  mapping(address => mapping (address => uint256)) allowed;


}