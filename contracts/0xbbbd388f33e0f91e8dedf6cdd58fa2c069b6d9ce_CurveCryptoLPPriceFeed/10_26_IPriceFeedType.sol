// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { PriceFeedType } from "@gearbox-protocol/integration-types/contracts/PriceFeedType.sol";

interface IPriceFeedType {
    /// @dev Returns the price feed type
    function priceFeedType() external view returns (PriceFeedType);

    /// @dev Returns whether sanity checks on price feed result should be skipped
    function skipPriceCheck() external view returns (bool);
}