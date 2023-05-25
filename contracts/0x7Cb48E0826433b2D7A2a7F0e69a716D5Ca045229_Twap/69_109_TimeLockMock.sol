// SPDX-License-Identifier: BSD-3-Clause
// Copyright 2020 Compound Labs, Inc.

pragma solidity ^0.7.6;

import "../TimeLock.sol";

contract TimeLockMock is TimeLock {
  constructor(address admin_, uint256 delay_)
    TimeLock(admin_, TimeLock.MINIMUM_DELAY)
  {
    admin = admin_;
    delay = delay_;
  }
}