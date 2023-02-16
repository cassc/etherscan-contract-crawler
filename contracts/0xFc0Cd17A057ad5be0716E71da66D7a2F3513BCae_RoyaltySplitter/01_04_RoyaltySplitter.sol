// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../utils/Splitter.sol";

/*
 * @title RoyaltySplitter
 * @author MAJR, Inc.
 * @notice This contract splits the incoming (received) ETH to the royalty split addresses
 */
contract RoyaltySplitter is Splitter {
  /// @notice The name of this royalty splitter contract for reference
  string public nameForReference;

  /**
   * @notice Constructor
   * @param _splitAddresses address payable[] memory
   * @param _splitAmounts uint256[] memory
   * @param _referralAddresses address payable[] memory
   * @param _referralAmounts uint256[] memory
   * @param _cap uint256
   * @param _nameForReference string memory
   */
  constructor(
    address payable[] memory _splitAddresses,
    uint256[] memory _splitAmounts,
    address payable[] memory _referralAddresses,
    uint256[] memory _referralAmounts,
    uint256 _cap,
    string memory _nameForReference
  )
    Splitter(
      _splitAddresses,
      _splitAmounts,
      _referralAddresses,
      _referralAmounts,
      _cap
    )
  {
    nameForReference = _nameForReference;
  }

  /**
   * @notice Receive function to split the incoming ETH
   * @dev This function is called when the contract receives ETH
   */
  receive() external payable {
    this.split{ value: msg.value }();
  }
}