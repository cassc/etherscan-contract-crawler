// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import {
    IUniswapV3Factory
} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {
    IUniswapV3Pool
} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IArrakisV2Helper} from "./interfaces/IArrakisV2Helper.sol";
import {IArrakisV2} from "./interfaces/IArrakisV2.sol";
import {Underlying as UnderlyingHelper} from "./libraries/Underlying.sol";
import {
    UnderlyingPayload,
    UnderlyingOutput,
    Range,
    RangeData
} from "./structs/SArrakisV2.sol";
import {Amount} from "./structs/SArrakisV2Helper.sol";

/// @title ArrakisV2Helper helpers for querying common info about ArrakisV2 vaults
contract ArrakisV2Helper is IArrakisV2Helper {
    IUniswapV3Factory public immutable factory;

    constructor(IUniswapV3Factory factory_) {
        factory = factory_;
    }

    /// @notice get total underlying, also returns uncollected fees and leftover separatly.
    /// @param vault_ Arrakis V2 vault to get underlying info about.
    /// @return underlying struct containing underlying amounts of
    /// token0 and token1, fees of token0 and token1, finally leftover
    /// on vault of token0 and token1.
    function totalUnderlyingWithFeesAndLeftOver(IArrakisV2 vault_)
        external
        view
        returns (UnderlyingOutput memory underlying)
    {
        UnderlyingPayload memory underlyingPayload = UnderlyingPayload({
            ranges: vault_.getRanges(),
            factory: factory,
            token0: address(vault_.token0()),
            token1: address(vault_.token1()),
            self: address(vault_)
        });

        (
            underlying.amount0,
            underlying.amount1,
            underlying.fee0,
            underlying.fee1
        ) = UnderlyingHelper.totalUnderlyingWithFees(underlyingPayload);

        underlying.leftOver0 =
            IERC20(underlyingPayload.token0).balanceOf(underlyingPayload.self) -
            IArrakisV2(underlyingPayload.self).managerBalance0();
        underlying.leftOver1 =
            IERC20(underlyingPayload.token1).balanceOf(underlyingPayload.self) -
            IArrakisV2(underlyingPayload.self).managerBalance1();
    }

    /// @notice get total underlying, also returns uncollected fees separately.
    /// @param vault_ Arrakis V2 vault to get underlying info about.
    /// @return amount0 amount of underlying of token 0 of LPs.
    /// @return amount1 amount of underlying of token 1 of LPs.
    /// @return fee0 amount of fee of token 0 of LPs.
    /// @return fee1 amount of fee of token 0 of LPs.
    function totalUnderlyingWithFees(IArrakisV2 vault_)
        external
        view
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 fee0,
            uint256 fee1
        )
    {
        UnderlyingPayload memory underlyingPayload = UnderlyingPayload({
            ranges: vault_.getRanges(),
            factory: factory,
            token0: address(vault_.token0()),
            token1: address(vault_.token1()),
            self: address(vault_)
        });

        (amount0, amount1, fee0, fee1) = UnderlyingHelper
            .totalUnderlyingWithFees(underlyingPayload);
    }

    /// @notice get underlying.
    /// @param vault_ Arrakis V2 vault to get underlying info about.
    /// @return amount0 amount of underlying of token 0 of LPs.
    /// @return amount1 amount of underlying of token 1 of LPs.
    function totalUnderlying(IArrakisV2 vault_)
        external
        view
        returns (uint256 amount0, uint256 amount1)
    {
        UnderlyingPayload memory underlyingPayload = UnderlyingPayload({
            ranges: vault_.getRanges(),
            factory: factory,
            token0: address(vault_.token0()),
            token1: address(vault_.token1()),
            self: address(vault_)
        });

        (amount0, amount1, , ) = UnderlyingHelper.totalUnderlyingWithFees(
            underlyingPayload
        );
    }

    // #region Rebalance helper functions

    /// @notice get underlyings of token0 and token1 in two lists.
    /// @param ranges_ list of range to get underlying info about.
    /// @param token0_ address of first token.
    /// @param token1_ address of second token.
    /// @param vaultV2_ address of Arrakis V2 vault.
    /// @return amount0s amounts of underlying of token 0 of LPs.
    /// @return amount1s amounts of underlying of token 1 of LPs.
    function token0AndToken1ByRange(
        Range[] calldata ranges_,
        address token0_,
        address token1_,
        address vaultV2_
    )
        external
        view
        returns (Amount[] memory amount0s, Amount[] memory amount1s)
    {
        amount0s = new Amount[](ranges_.length);
        amount1s = new Amount[](ranges_.length);
        for (uint256 i = 0; i < ranges_.length; i++) {
            (
                uint256 amount0,
                uint256 amount1,
                ,

            ) = _getAmountsAndFeesFromLiquidity(
                    token0_,
                    token1_,
                    ranges_[i],
                    vaultV2_
                );

            amount0s[i] = Amount({range: ranges_[i], amount: amount0});
            amount1s[i] = Amount({range: ranges_[i], amount: amount1});
        }
    }

    /// @notice get underlyings and fees of token0 and token1 in two lists.
    /// @param ranges_ list of range to get underlying info about.
    /// @param token0_ address of first token.
    /// @param token1_ address of second token.
    /// @param vaultV2_ address of Arrakis V2 vault.
    /// @return amount0s amounts of underlying of token 1 of LPs.
    /// @return amount1s amounts of underlying of token 1 of LPs.
    /// @return fee0s amounts of fees of token 0 of LPs.
    /// @return fee1s amounts of fees of token 1 of LPs.
    function token0AndToken1PlusFeesByRange(
        Range[] calldata ranges_,
        address token0_,
        address token1_,
        address vaultV2_
    )
        external
        view
        returns (
            Amount[] memory amount0s,
            Amount[] memory amount1s,
            Amount[] memory fee0s,
            Amount[] memory fee1s
        )
    {
        amount0s = new Amount[](ranges_.length);
        amount1s = new Amount[](ranges_.length);
        fee0s = new Amount[](ranges_.length);
        fee1s = new Amount[](ranges_.length);
        for (uint256 i = 0; i < ranges_.length; i++) {
            amount0s[i].range = ranges_[i];
            amount1s[i].range = ranges_[i];
            fee0s[i].range = ranges_[i];
            fee1s[i].range = ranges_[i];
            (
                amount0s[i].amount,
                amount1s[i].amount,
                fee0s[i].amount,
                fee1s[i].amount
            ) = _getAmountsAndFeesFromLiquidity(
                token0_,
                token1_,
                ranges_[i],
                vaultV2_
            );
        }
    }

    // #endregion Rebalance helper functions

    // #region internal functions

    function _getAmountsAndFeesFromLiquidity(
        address token0_,
        address token1_,
        Range calldata range_,
        address vaultV2_
    )
        internal
        view
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 fee0,
            uint256 fee1
        )
    {
        (token0_, token1_) = token0_ < token1_
            ? (token0_, token1_)
            : (token1_, token0_);

        IUniswapV3Pool pool = IUniswapV3Pool(
            factory.getPool(token0_, token1_, range_.feeTier)
        );

        (amount0, amount1, fee0, fee1) = UnderlyingHelper.underlying(
            RangeData({self: vaultV2_, range: range_, pool: pool})
        );

        amount0 += fee0;
        amount1 += fee1;
    }

    // #endregion internal functions
}