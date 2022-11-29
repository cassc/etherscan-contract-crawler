// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;
import {ChainlinkLib} from "../lib/Lib.sol";

interface IPoolExtras {
    event RequestRateFulfilled(bytes32 indexed requestRate, uint256 rate);
    event ApiInfoChanged(string newUrl, string newBuyPath, string newSellPath);
    event ChainlinkTokenddressChanged(address newcommodityTokenddress);
    event ChainlinkOracleAddressChanged(address newOracleAddress);
    event RateTimeoutChanged(uint256 newDuration);
    event ChainlinkReqFeeUpdated(uint256 newFees);
    event OracleJobIdUpdated(bytes32);
    event FeedAddressChanged(address);
    event LinkRequestDelayChanged(uint256);
    function initChainlinkAndPriceInfo(
        ChainlinkLib.ChainlinkApiInfo calldata _chainlinkInfo,
        ChainlinkLib.ApiInfo calldata _apiInfo
    ) external;
}