// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.18;

/**
 * @title Declares the interface for initializing an NFTTimedEditionCollection contract.
 * @author cori-grohman
 */
interface INFTTimedEditionCollectionInitializer {
  function initialize(
    address payable _creator,
    string calldata _name,
    string calldata _symbol,
    string calldata tokenURI_,
    uint256 _mintEndTime,
    address _approvedMinter,
    address payable _paymentAddress
  ) external;
}