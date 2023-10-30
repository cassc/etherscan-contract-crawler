// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.18;

/**
 * @title Declares the interface for initializing an NFTLimitedEditionCollection contract.
 * @author gosseti
 */
interface INFTLimitedEditionCollectionInitializer {
  function initialize(
    address payable _creator,
    string calldata _name,
    string calldata _symbol,
    string calldata _tokenURI,
    uint32 _maxTokenId,
    address _approvedMinter,
    address payable _paymentAddress
  ) external;
}