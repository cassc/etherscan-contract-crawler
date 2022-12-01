// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {Owned} from "solmate/auth/Owned.sol";
import {IBentoBoxMinimal} from "../interfaces/IBentoBoxMinimal.sol";

interface IExtractStrategy {
    function setLossValue(int256 _val) external;

    function strategyToken() external returns (address);

    function safeHarvest(
        uint256 maxBalanceInBentoBox,
        bool rebalance,
        uint256 maxChangeAmount,
        bool harvestRewards
    ) external;
}

contract AbraExtract is Owned {
    IBentoBoxMinimal bentoBox;
    IExtractStrategy strategy;
    address strategyToken;

    constructor(
        address _owner,
        address _bentoBox,
        address _strategy
    ) Owned(_owner) {
        bentoBox = IBentoBoxMinimal(_bentoBox);
        strategy = IExtractStrategy(_strategy);
        strategyToken = strategy.strategyToken();
    }

    function loopHarvest() external {
        for (uint256 i; i < 10; i++) {
            (, , uint256 balance) = bentoBox.strategyData(strategyToken);
            strategy.setLossValue(-int256(balance));
            uint256 elastic = bentoBox.totals(strategyToken).elastic;
            strategy.safeHarvest(elastic, true, 0, false);
        }
    }
}