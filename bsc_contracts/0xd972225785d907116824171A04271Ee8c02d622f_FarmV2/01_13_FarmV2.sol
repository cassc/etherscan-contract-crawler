// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./FarmV2Factory.sol";
import "./extensions/FarmV2Depositable.sol";
import "./extensions/FarmV2Withdrawable.sol";

contract FarmV2 is FarmV2Depositable, FarmV2Withdrawable, FarmV2Factory {
    /**
     * @dev The contract constructor.
     *
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor(Configuration memory config_) {
        _config = config_;
    }
}