// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./StratManager.sol";

abstract contract FeeManager is StratManager {
    // Fees are set as a multiple of 0.01%.
    uint constant public FEE_DENOMINATOR = 10000;

    uint constant public MAX_HARVEST_CALL_FEE = 100;
    uint constant public MAX_PERFORMANCE_FEE = 450;
    uint constant public MAX_STRATEGIST_FEE = 450;
    uint constant public MAX_WITHDRAWAL_FEE = 10;

    uint public harvestCallFee = 0;
    uint public performanceFee = 200;
    uint public strategistFee = 0;
    uint public withdrawalFee = 5;

    event FeeUpdate(address indexed updater, string updateType, uint256 newValue);
    event OwnerOperation(address indexed invoker, string method);

    function setHarvestCallFee(uint256 _fee) external onlyOwner {
        require(_fee <= MAX_HARVEST_CALL_FEE, "!cap");

        harvestCallFee = _fee;

        emit FeeUpdate(msg.sender, "HarvestCallFee", _fee);
        emit OwnerOperation(msg.sender, "FeeManager.setHarvestCallFee");
    }

    function setPerformanceFee(uint256 _fee) external onlyOwner {
        require(_fee <= MAX_PERFORMANCE_FEE, "!cap");

        performanceFee = _fee;

        emit FeeUpdate(msg.sender, "PerformanceFee", _fee);
        emit OwnerOperation(msg.sender, "FeeManager.setPerformanceFee");
    }

    function setStrategistFee(uint256 _fee) external onlyOwner {
        require(_fee <= MAX_STRATEGIST_FEE, "!cap");

        strategistFee = _fee;

        emit FeeUpdate(msg.sender, "StrategistFee", _fee);
        emit OwnerOperation(msg.sender, "FeeManager.setStrategistFee");
    }

    function setWithdrawalFee(uint256 _fee) public onlyOwner {
        require(_fee <= MAX_WITHDRAWAL_FEE, "!cap");

        withdrawalFee = _fee;

        emit FeeUpdate(msg.sender, "WithdrawFee", _fee);
        emit OwnerOperation(msg.sender, "FeeManager.setWithdrawalFee");
    }
}