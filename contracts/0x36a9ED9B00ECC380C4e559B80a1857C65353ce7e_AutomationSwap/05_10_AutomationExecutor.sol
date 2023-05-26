// SPDX-License-Identifier: AGPL-3.0-or-later

/// AutomationExecutor.sol

// Copyright (C) 2021-2021 Oazo Apps Limited

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IWETH } from "./interfaces/IWETH.sol";
import { BotLike } from "./interfaces/BotLike.sol";
import { IExchange } from "./interfaces/IExchange.sol";
import { ICommand } from "./interfaces/ICommand.sol";

contract AutomationExecutor {
    using SafeERC20 for IERC20;

    event CallerAdded(address indexed caller);
    event CallerRemoved(address indexed caller);

    BotLike public immutable bot;
    IERC20 public immutable dai;
    IWETH public immutable weth;

    address public exchange;
    address public owner;

    mapping(address => bool) public callers;

    constructor(BotLike _bot, IERC20 _dai, IWETH _weth, address _exchange) {
        bot = _bot;
        weth = _weth;
        dai = _dai;
        exchange = _exchange;
        owner = msg.sender;
        callers[owner] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "executor/only-owner");
        _;
    }

    modifier auth(address caller) {
        require(callers[caller], "executor/not-authorized");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "executor/invalid-new-owner");
        owner = newOwner;
    }

    function setExchange(address newExchange) external onlyOwner {
        require(newExchange != address(0), "executor/invalid-new-exchange");
        exchange = newExchange;
    }

    function addCallers(address[] calldata _callers) external onlyOwner {
        uint256 length = _callers.length;
        for (uint256 i = 0; i < length; ++i) {
            address caller = _callers[i];
            require(!callers[caller], "executor/duplicate-whitelist");
            callers[caller] = true;
            emit CallerAdded(caller);
        }
    }

    function removeCallers(address[] calldata _callers) external onlyOwner {
        uint256 length = _callers.length;
        for (uint256 i = 0; i < length; ++i) {
            address caller = _callers[i];
            callers[caller] = false;
            emit CallerRemoved(caller);
        }
    }

    function execute(
        bytes calldata executionData,
        uint256 cdpId,
        bytes calldata triggerData,
        address commandAddress,
        uint256 triggerId,
        uint256 daiCoverage,
        uint256 minerBribe,
        int256 gasRefund
    ) external auth(msg.sender) {
        uint256 initialGasAvailable = gasleft();
        require(
            ICommand(commandAddress).isExecutionLegal(cdpId, triggerData),
            "executor/illegal-execution"
        );
        require(daiCoverage <= 1500 * 10 ** 18, "executor/coverage-too-high");

        bot.execute(executionData, cdpId, triggerData, commandAddress, triggerId, daiCoverage);

        if (minerBribe > 0) {
            block.coinbase.transfer(minerBribe);
        }
        uint256 finalGasAvailable = gasleft();
        uint256 etherUsed = tx.gasprice *
            uint256(int256(initialGasAvailable - finalGasAvailable) - gasRefund);

        payable(msg.sender).transfer(
            address(this).balance > etherUsed ? etherUsed : address(this).balance
        );
    }

    function swap(
        address otherAsset,
        bool toDai,
        uint256 amount,
        uint256 receiveAtLeast,
        address callee,
        bytes calldata withData
    ) external auth(msg.sender) {
        IERC20 fromToken = toDai ? IERC20(otherAsset) : dai;
        require(
            amount > 0 && amount <= fromToken.balanceOf(address(this)),
            "executor/invalid-amount"
        );

        fromToken.safeApprove(exchange, amount);
        if (toDai) {
            IExchange(exchange).swapTokenForDai(
                otherAsset,
                amount,
                receiveAtLeast,
                callee,
                withData
            );
        } else {
            IExchange(exchange).swapDaiForToken(
                otherAsset,
                amount,
                receiveAtLeast,
                callee,
                withData
            );
        }
    }

    function withdraw(address asset, uint256 amount) external onlyOwner {
        if (asset == address(0)) {
            require(amount <= address(this).balance, "executor/invalid-amount");
            (bool sent, ) = payable(owner).call{ value: amount }("");
            require(sent, "executor/withdrawal-failed");
        } else {
            IERC20(asset).safeTransfer(owner, amount);
        }
    }

    function unwrapWETH(uint256 amount) external onlyOwner {
        weth.withdraw(amount);
    }

    function revokeAllowance(IERC20 token, address target) external onlyOwner {
        token.safeApprove(target, 0);
    }

    receive() external payable {}
}