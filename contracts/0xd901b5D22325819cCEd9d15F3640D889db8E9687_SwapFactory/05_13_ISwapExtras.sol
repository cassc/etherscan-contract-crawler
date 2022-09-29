// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;
import { ChainlinkLib} from "../lib/Lib.sol";

interface ISwapExtras {
    event ChainlinkFeedAddrChanged(address newFeedAddress);
    event RequestRateFulfilled(bytes32 indexed requestRate, uint256 rate);
    event ChainlinkFeedEnabled(bool flag);
    event ApiUrlChanged(string newUrl);
    event ApiBuyPathChanged(string newBuyPath);
    event ApiSellPathChanged(string newSellPath);
    event ChainlinkcommodityTokenddressChanged(address newcommodityTokenddress);
    event ChainlinkOracleAddressChanged(address newOracleAddress);
    event RateTimeoutChanged(uint256 newDuration);
    function initChainlinkAndPriceInfo(
        ChainlinkLib.ChainlinkInfo calldata _chainlinkInfo
    ) external;
}