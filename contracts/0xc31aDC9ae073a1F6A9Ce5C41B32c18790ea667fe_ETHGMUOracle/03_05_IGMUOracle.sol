//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {IPriceFeed} from "./IPriceFeed.sol";
import {IEpoch} from "./IEpoch.sol";

interface IGMUOracle is IPriceFeed, IEpoch {
    function updatePrice() external;

    function fetchLastGoodPrice() external view returns (uint256);

    event PricesUpdated(
        address indexed who,
        uint256 price30d,
        uint256 price7d,
        uint256 priceIndex,
        uint256 lastPrice
    );
}