//SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract BalajisBet {
    using SafeERC20 for IERC20;

    IERC20 public wbtc = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    IERC20 public usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address public wbtcSide;
    address public balajis;
    uint public deadline;
    AggregatorV3Interface internal priceFeed;

    constructor() {
        priceFeed = AggregatorV3Interface(
            0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c
        );
    }

    function getLatestPrice() public view returns (int) {
        (
            ,
            /* uint80 roundID */ int price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = priceFeed.latestRoundData();
        return price;
    }

    function betWbtc() external {
        require(wbtcSide == address(0));
        wbtcSide = msg.sender;
        wbtc.safeTransferFrom(msg.sender, address(this), 1e8);
    }

    // In case balajis never takes the other side of the bet, allow pulling out the funds so they dont get stuck
    function pullWbtc() external {
        require(balajis == address(0) && wbtcSide == msg.sender); // balajis has not taken the other side
        wbtc.safeTransfer(wbtcSide, wbtc.balanceOf(address(this)));
    }

    // For balajis to call
    function betUsdc() external {
        require(balajis == address(0)); // can only be called once
        require(wbtc.balanceOf(address(this)) >= 1e8); // avoid funds being pulled through mev right before this call is made
        balajis = msg.sender;
        deadline = block.timestamp + 90 days;
        usdc.safeTransferFrom(msg.sender, address(this), 1e6 * 1e6); // 1M usdc
    }

    function settle() external {
        // anyone can settle this to ensure it gets settled asap
        require((block.timestamp > deadline) && (balajis != address(0)));
        int price = getLatestPrice();
        if (price >= 1e14) {
            // uses 8 decimals, can check by calling latestRoundData() on https://etherscan.io/address/0xf4030086522a5beea4988f8ca5b36dbc97bee88c#readContract
            wbtc.safeTransfer(balajis, wbtc.balanceOf(address(this)));
            usdc.safeTransfer(balajis, usdc.balanceOf(address(this)));
        } else {
            wbtc.safeTransfer(wbtcSide, wbtc.balanceOf(address(this)));
            usdc.safeTransfer(wbtcSide, usdc.balanceOf(address(this)));
        }
    }

    // In case there's a bug in the contracts
    // or if hyperinflation breaks society and chainlink feeds stop working
    // after 10 days of not settling its possible to just withdraw all money to both parties
    // can be called multiple times so amounts can be arbitrary
    // separated into two functions in case one of the tokens stop working (eg bitgo rugs the contracts because society collapses)
    function emergencyWithdrawUsdc(uint amountUsdc) external {
        require(
            block.timestamp > (deadline + 10 days) &&
                (balajis == msg.sender) &&
                deadline > 0
        );
        usdc.safeTransfer(balajis, amountUsdc);
    }

    function emergencyWithdrawWbtc(uint amountWbtc) external {
        require(
            block.timestamp > (deadline + 10 days) &&
                (wbtcSide == msg.sender) &&
                deadline > 0
        );
        wbtc.safeTransfer(wbtcSide, amountWbtc);
    }
}