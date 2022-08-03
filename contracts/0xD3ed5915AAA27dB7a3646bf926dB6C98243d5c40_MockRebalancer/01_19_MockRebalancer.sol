// https://docs.euler.finance/developers/integration-guide
// https://gist.github.com/abhishekvispute/b0101938489a8b8dc292e3070c27156e
// https://soliditydeveloper.com/uniswap3/

// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IAuction} from "../interfaces/IAuction.sol";
import {IVaultMath} from "../interfaces/IVaultMath.sol";

import "hardhat/console.sol";

contract MockRebalancer is Ownable {
    using SafeMath for uint256;

    address public constant _addressAuction = 0x9Fcca440F19c62CDF7f973eB6DDF218B15d4C71D;
    IAuction public constant vaultAuction = IAuction(_addressAuction);
    IVaultMath public constant vaultMath = IVaultMath(0x01E21d7B8c39dc4C764c19b308Bd8b14B1ba139E);

    struct MyCallbackData {
        uint256 type_of_arbitrage;
        uint256 amount1;
        uint256 amount2;
    }

    constructor() Ownable() {}

    function rebalance() public view onlyOwner returns (uint256) {
        (bool isTimeRebalance, uint256 auctionTriggerTime) = vaultMath.isTimeRebalance();
        console.log(">> isTimeRebalance: %s", isTimeRebalance);
        console.log(">> auctionTriggerTime: %s", auctionTriggerTime);

        (
            uint256 targetEth,
            uint256 targetUsdc,
            uint256 targetOsqth,
            uint256 ethBalance,
            uint256 usdcBalance,
            uint256 osqthBalance
        ) = vaultAuction.getAuctionParams(auctionTriggerTime);

        if (targetEth > ethBalance && targetUsdc > usdcBalance && targetOsqth < osqthBalance) {
            console.log("type_of_arbitrage 1");
            return 1;
        } else if (targetEth < ethBalance && targetUsdc < usdcBalance && targetOsqth > osqthBalance) {
            console.log("type_of_arbitrage 2");
            return 2;
        } else if (targetEth < ethBalance && targetUsdc > usdcBalance && targetOsqth > osqthBalance) {
            console.log("type_of_arbitrage 3");
            return 3;
        } else if (targetEth > ethBalance && targetUsdc < usdcBalance && targetOsqth < osqthBalance) {
            console.log("type_of_arbitrage 4");
            return 4;
        } else if (targetEth > ethBalance && targetUsdc < usdcBalance && targetOsqth > osqthBalance) {
            console.log("type_of_arbitrage 5");
            return 5;
        } else if (targetEth < ethBalance && targetUsdc > usdcBalance && targetOsqth < osqthBalance) {
            console.log("type_of_arbitrage 6");
            return 6;
        }
    }
}