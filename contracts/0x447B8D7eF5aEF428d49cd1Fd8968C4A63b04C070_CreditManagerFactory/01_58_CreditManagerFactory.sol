// SPDX-License-Identifier: BUSL-1.1
// Gearbox. Generalized leverage protocol that allows to take leverage and then use it across other DeFi protocols and platforms in a composable way.
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { CreditManagerFactoryBase } from "@gearbox-protocol/core-v2/contracts/factories/CreditManagerFactoryBase.sol";

import { PriceOracle } from "@gearbox-protocol/core-v2/contracts/oracles/PriceOracle.sol";

import { IConvexV1BaseRewardPoolAdapter } from "../interfaces/convex/IConvexV1BaseRewardPoolAdapter.sol";
import { IConvexV1BoosterAdapter } from "../interfaces/convex/IConvexV1BoosterAdapter.sol";

import { CreditConfigurator, CreditManagerOpts } from "@gearbox-protocol/core-v2/contracts/credit/CreditConfigurator.sol";

import "@gearbox-protocol/core-v2/contracts/interfaces/adapters/IAdapter.sol";
import { Adapter } from "@gearbox-protocol/core-v2/contracts/factories/CreditManagerFactoryBase.sol";

contract CreditManagerFactory is CreditManagerFactoryBase {
    constructor(
        address _pool,
        CreditManagerOpts memory opts,
        uint256 salt
    ) CreditManagerFactoryBase(_pool, opts, salt) {}

    function _postInstall() internal override {
        PriceOracle priceOracle = PriceOracle(addressProvider.getPriceOracle());

        address[] memory allowedContracts = creditConfigurator
            .allowedContracts();
        uint256 len = allowedContracts.length;

        for (uint256 i = 0; i < len; ) {
            address allowedContract = allowedContracts[i];
            address adapter = creditManager.contractToAdapter(allowedContract);
            AdapterType aType = IAdapter(adapter)._gearboxAdapterType();

            if (aType == AdapterType.CONVEX_V1_BASE_REWARD_POOL) {
                address stakedPhantomToken = IConvexV1BaseRewardPoolAdapter(
                    adapter
                ).stakedPhantomToken();

                address curveLPtoken = IConvexV1BaseRewardPoolAdapter(adapter)
                    .curveLPtoken();
                address cvxLPToken = address(
                    IConvexV1BaseRewardPoolAdapter(adapter).stakingToken()
                );

                priceOracle.addPriceFeed(
                    cvxLPToken,
                    priceOracle.priceFeeds(curveLPtoken)
                );

                priceOracle.addPriceFeed(
                    stakedPhantomToken,
                    priceOracle.priceFeeds(curveLPtoken)
                );

                creditConfigurator.addCollateralToken(
                    stakedPhantomToken,
                    creditManager.liquidationThresholds(curveLPtoken)
                ); // F:
            }

            if (aType == AdapterType.CONVEX_V1_BOOSTER) {
                IConvexV1BoosterAdapter(adapter).updateStakedPhantomTokensMap();
            }

            unchecked {
                ++i;
            }
        }
    }
}