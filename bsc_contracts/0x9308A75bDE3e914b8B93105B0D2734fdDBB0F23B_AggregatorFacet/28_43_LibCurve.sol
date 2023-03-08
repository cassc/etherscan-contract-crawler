// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {AppStorage, CurveSettings, LibMagpieAggregator} from "../libraries/LibMagpieAggregator.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {IAddressProvider} from "../interfaces/curve/IAddressProvider.sol";
import {ICryptoFactory} from "../interfaces/curve/ICryptoFactory.sol";
import {ICryptoPool} from "../interfaces/curve/ICryptoPool.sol";
import {ICryptoRegistry} from "../interfaces/curve/ICryptoRegistry.sol";
import {ICurvePool} from "../interfaces/curve/ICurvePool.sol";
import {IRegistry} from "../interfaces/curve/IRegistry.sol";
import {LibRouter, Hop} from "./LibRouter.sol";

struct ExchangeArgs {
    address pool;
    address from;
    address to;
    uint256 amount;
}

library LibCurve {
    using LibAsset for address;

    function mainExchange(ExchangeArgs memory exchangeArgs, address registry) private {
        int128 i = 0;
        int128 j = 0;
        bool isUnderlying = false;
        (i, j, isUnderlying) = IRegistry(registry).get_coin_indices(
            exchangeArgs.pool,
            exchangeArgs.from,
            exchangeArgs.to
        );

        if (isUnderlying) {
            ICurvePool(exchangeArgs.pool).exchange_underlying(i, j, exchangeArgs.amount, 0);
        } else {
            ICurvePool(exchangeArgs.pool).exchange(i, j, exchangeArgs.amount, 0);
        }
    }

    function cryptoExchange(ExchangeArgs memory exchangeArgs, address registry) private {
        uint256 i = 0;
        uint256 j = 0;
        address initial = exchangeArgs.from;
        address target = exchangeArgs.to;

        (i, j) = ICryptoRegistry(registry).get_coin_indices(exchangeArgs.pool, initial, target);

        ICryptoPool(exchangeArgs.pool).exchange(i, j, exchangeArgs.amount, 0);
    }

    function swapCurve(Hop memory h) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        address pool = address(uint160(uint256(h.poolData[0])));

        ExchangeArgs memory exchangeArgs = ExchangeArgs({
            pool: pool,
            from: h.path[0],
            to: h.path[1],
            amount: h.amountIn
        });

        h.path[0].approve(exchangeArgs.pool, h.amountIn);

        if (ICryptoRegistry(s.curveSettings.cryptoRegistry).get_decimals(exchangeArgs.pool)[0] > 0) {
            cryptoExchange(exchangeArgs, s.curveSettings.cryptoRegistry);
            // Some networks dont have cryptoFactory
        } else if (ICryptoFactory(s.curveSettings.cryptoFactory).get_decimals(exchangeArgs.pool)[0] > 0) {
            cryptoExchange(exchangeArgs, s.curveSettings.cryptoFactory);
        } else {
            mainExchange(exchangeArgs, s.curveSettings.mainRegistry);
        }
    }

    event UpdateCurveSettings(address indexed sender, CurveSettings curveSettings);

    function updateSettings(address addressProvider) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        s.curveSettings = CurveSettings({
            mainRegistry: IAddressProvider(addressProvider).get_address(0),
            cryptoRegistry: IAddressProvider(addressProvider).get_address(5),
            cryptoFactory: IAddressProvider(addressProvider).get_address(6)
        });

        emit UpdateCurveSettings(msg.sender, s.curveSettings);
    }
}