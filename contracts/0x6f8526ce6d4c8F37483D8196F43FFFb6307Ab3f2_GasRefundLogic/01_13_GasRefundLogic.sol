// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { HumanboundPermissionState, HumanboundPermissionStorage } from "../../storage/HumanboundPermissionStorage.sol";
import { GasRefundState, GasRefundStorage } from "../../storage/GasRefundStorage.sol";
import "./IGasRefundLogic.sol";
import "hardhat/console.sol";

contract GasRefundLogic is GasRefundExtension {
    modifier onlyOperator() virtual {
        HumanboundPermissionState storage state = HumanboundPermissionStorage._getState();
        require(_lastCaller() == state.operator, "GasRefund: unauthorised");
        _;
    }

    function depositFunds() external payable onlyOperator {
        GasRefundState storage state = GasRefundStorage._getState();
        state.funds += msg.value;

        emit Deposited(_lastCaller(), msg.value);
    }

    function withdrawFunds(uint256 amount) external onlyOperator {
        GasRefundState storage state = GasRefundStorage._getState();

        require(amount <= state.funds, "GasRefund: withdraw amount exceeds funds");
        state.funds -= amount;

        (bool success, ) = _lastCaller().call{ value: amount }("");
        require(success, "GasRefund: failed to withdraw eth");

        emit Withdrawn(_lastCaller(), amount);
    }

    /**
     * @notice Refunds an amount of gas spent at the current gas price
     */
    function refundExecution(uint256 gasSpent) external _internal {
        address transactionSender = tx.origin;
        uint256 ethSpent = gasSpent * tx.gasprice;

        require(ethSpent <= address(this).balance, "GasRefund: insufficient funds");

        (bool success, ) = transactionSender.call{ value: ethSpent }("");
        require(success, "GasRefund: failed to send eth back");
    }
}