// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IDebtInstrument} from "IDebtInstrument.sol";
import {IFlexiblePortfolio} from "IFlexiblePortfolio.sol";

interface IValuationStrategy {
    function onInstrumentFunded(
        IFlexiblePortfolio portfolio,
        IDebtInstrument instrument,
        uint256 instrumentId
    ) external;

    function onInstrumentUpdated(
        IFlexiblePortfolio portfolio,
        IDebtInstrument instrument,
        uint256 instrumentId
    ) external;

    function calculateValue(IFlexiblePortfolio portfolio) external view returns (uint256);
}