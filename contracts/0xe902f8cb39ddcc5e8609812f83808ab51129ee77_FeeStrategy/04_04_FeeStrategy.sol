// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IFeeStrategy} from "IFeeStrategy.sol";
import {Initializable} from "Initializable.sol";

contract FeeStrategy is IFeeStrategy, Initializable {
    address public manager;
    uint256 public managerFeeRate;

    event ManagerFeeRateChanged(uint256 newManagerFeeRate);

    function initialize(address _manager, uint256 _managerFeeRate) external initializer {
        manager = _manager;
        managerFeeRate = _managerFeeRate;
    }

    function setManagerFeeRate(uint256 newManagerFeeRate) external {
        require(msg.sender == manager, "FeeStrategy: Only manager can set fee rate");
        managerFeeRate = newManagerFeeRate;
        emit ManagerFeeRateChanged(newManagerFeeRate);
    }
}