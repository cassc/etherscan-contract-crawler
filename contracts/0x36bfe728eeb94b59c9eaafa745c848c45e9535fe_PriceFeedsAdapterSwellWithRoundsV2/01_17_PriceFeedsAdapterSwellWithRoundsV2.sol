// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "./PriceFeedsAdapterSwellWithRounds.sol";

contract PriceFeedsAdapterSwellWithRoundsV2 is PriceFeedsAdapterSwellWithRounds {
  function requireAuthorisedUpdater(address updater) public view override virtual {
    if (updater != 0xFcDE1D8c09C9FE0182Fe37b980B843f6388E12b1 && updater != 0xc4D1AE5E796E6d7561cdc8335F85e6B57a36e097) {
      revert UpdaterNotAuthorised(updater);
    }
  }
}