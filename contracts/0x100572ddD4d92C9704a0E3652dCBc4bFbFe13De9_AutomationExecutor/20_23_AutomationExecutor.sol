// SPDX-License-Identifier: AGPL-3.0-or-later

/// AutomationExecutor.sol

// Copyright (C) 2023 Oazo Apps Limited

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

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IWETH } from "./interfaces/IWETH.sol";
import { BotLike } from "./interfaces/BotLike.sol";
import "./ServiceRegistry.sol";

import { TickMath } from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import { IUniswapV3Factory } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import { IUniswapV3Pool } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {
    IV3SwapRouter
} from "@uniswap/swap-router-contracts/contracts/interfaces/IV3SwapRouter.sol";

contract AutomationExecutor {
    using SafeERC20 for ERC20;

    event CallerAdded(address indexed caller);
    event CallerRemoved(address indexed caller);
    string private constant UNISWAP_ROUTER_KEY = "UNISWAP_ROUTER";
    string private constant UNISWAP_FACTORY_KEY = "UNISWAP_FACTORY";

    IV3SwapRouter public immutable uniswapRouter;
    IUniswapV3Factory public immutable uniswapFactory;
    BotLike public immutable bot;
    IWETH public immutable weth;
    address public owner;

    mapping(address => bool) public callers;

    constructor(BotLike _bot, IWETH _weth, ServiceRegistry _serviceRegistry) {
        bot = _bot;
        weth = _weth;
        owner = msg.sender;
        callers[owner] = true;
        uniswapRouter = IV3SwapRouter(_serviceRegistry.getRegisteredService(UNISWAP_ROUTER_KEY));
        uniswapFactory = IUniswapV3Factory(
            _serviceRegistry.getRegisteredService(UNISWAP_FACTORY_KEY)
        );
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
            require(callers[caller], "executor/absent-caller");
            callers[caller] = false;
            emit CallerRemoved(caller);
        }
    }

    function execute(
        bytes calldata executionData,
        bytes calldata triggerData,
        address commandAddress,
        uint256 triggerId,
        uint256 txCoverage,
        uint256 minerBribe,
        int256 gasRefund,
        address coverageToken
    ) external auth(msg.sender) {
        require(gasRefund < 10 ** 12, "executor/gas-refund-too-high");

        uint256 initialGasAvailable = gasleft();
        bot.execute(
            executionData,
            triggerData,
            commandAddress,
            triggerId,
            txCoverage,
            coverageToken
        );

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

    // token 1 / token0
    function getTick(
        address uniswapV3Pool,
        uint32 twapInterval
    ) public view returns (uint160 sqrtPriceX96) {
        if (twapInterval == 0) {
            // return the current price if twapInterval == 0
            (sqrtPriceX96, , , , , , ) = IUniswapV3Pool(uniswapV3Pool).slot0();
        } else {
            uint32[] memory secondsAgos = new uint32[](2);
            // past ---secondsAgo---> present
            secondsAgos[0] = 1 + twapInterval; // secondsAgo
            secondsAgos[1] = 1; // now

            (int56[] memory tickCumulatives, ) = IUniswapV3Pool(uniswapV3Pool).observe(secondsAgos);

            sqrtPriceX96 = TickMath.getSqrtRatioAtTick(
                int24((tickCumulatives[1] - tickCumulatives[0]) / int56(uint56(twapInterval)))
            );
        }
        return sqrtPriceX96;
    }

    function getPrice(
        address tokenIn,
        uint24[] memory fees
    ) public view returns (uint256 price, uint24 fee) {
        uint24 biggestPoolFee;
        IUniswapV3Pool biggestPool;
        uint256 highestPoolBalance;
        uint256 currentPoolBalance;
        for (uint8 i; i < fees.length; i++) {
            IUniswapV3Pool pool = IUniswapV3Pool(
                uniswapFactory.getPool(tokenIn, address(weth), fees[i])
            );
            currentPoolBalance = weth.balanceOf(address(pool));
            if (currentPoolBalance > highestPoolBalance) {
                biggestPoolFee = fees[i];
                biggestPool = pool;
                highestPoolBalance = currentPoolBalance;
            }
        }

        uint160 sqrtPriceX96 = getTick(address(biggestPool), 60);
        address token0 = biggestPool.token0();
        uint256 decimals = ERC20(tokenIn).decimals();

        if (token0 == tokenIn) {
            return (
                (uint256(sqrtPriceX96) * (uint256(sqrtPriceX96)) * (10 ** decimals)) / 2 ** 192,
                biggestPoolFee
            );
        } else {
            return (
                (((2 ** 192) * (10 ** decimals)) /
                    ((uint256(sqrtPriceX96) * (uint256(sqrtPriceX96))))),
                biggestPoolFee
            );
        }
    }

    function swapToEth(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        uint24 fee
    ) external auth(msg.sender) returns (uint256) {
        require(
            amountIn > 0 && amountIn <= ERC20(tokenIn).balanceOf(address(this)),
            "executor/invalid-amount"
        );
        if (tokenIn == address(weth)) {
            weth.withdraw(amountIn);
            return amountIn;
        }
        ERC20(tokenIn).safeApprove(address(uniswapRouter), amountIn);

        bytes memory path = abi.encodePacked(tokenIn, uint24(fee), address(weth));

        IV3SwapRouter.ExactInputParams memory params = IV3SwapRouter.ExactInputParams({
            path: path,
            recipient: address(this),
            amountIn: amountIn,
            amountOutMinimum: amountOutMin
        });

        uint256 amount = uniswapRouter.exactInput(params);
        weth.withdraw(amount);
        return amount;
    }

    function withdraw(address asset, uint256 amount) external onlyOwner {
        if (asset == address(0)) {
            require(amount <= address(this).balance, "executor/invalid-amount");
            (bool sent, ) = payable(owner).call{ value: amount }("");
            require(sent, "executor/withdrawal-failed");
        } else {
            ERC20(asset).safeTransfer(owner, amount);
        }
    }

    function revokeAllowance(ERC20 token, address target) external onlyOwner {
        token.safeApprove(target, 0);
    }

    receive() external payable {}
}