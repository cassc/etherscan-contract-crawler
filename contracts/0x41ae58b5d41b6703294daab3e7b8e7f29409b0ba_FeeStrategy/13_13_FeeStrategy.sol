// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IFeeStrategy} from "IFeeStrategy.sol";
import {Initializable} from "Initializable.sol";
import {AccessControlEnumerable} from "AccessControlEnumerable.sol";

contract FeeStrategy is IFeeStrategy, Initializable {
    uint256 public managerFeeRate;

    function initialize(uint256 _managerFeeRate) external initializer {
        managerFeeRate = _managerFeeRate;
    }
}