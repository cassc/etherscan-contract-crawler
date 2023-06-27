// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

interface ITokenCreatorPaymentAddress {
  function getTokenCreatorPaymentAddress(uint256 tokenId)
    external
    view
    returns (address payable tokenCreatorPaymentAddress);
}