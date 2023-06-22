// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../BaseBuyAndBurn.sol";

contract HexBuyAndBurn is BaseBuyAndBurn {
  constructor(
    address _producer,
    address _target,
    bool _targetCanBurn,
    address _burnDestination,
    address _router
  )
    BaseBuyAndBurn(
      _producer,
      _target,
      _targetCanBurn,
      _burnDestination,
      _router
    )
  {}
}