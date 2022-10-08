// SPDX-License-Identifier: MIT
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

contract ArrakisV2Helper is IArrakisV2Helper {
    IUniswapV3Factory public immutable factory;

    constructor(IUniswapV3Factory factory_) {
        factory = factory_;
    }

    function totalUnderlyingWithFeesAndLeftOver(IArrakisV2 vault_)
        external
        view
        returns (UnderlyingOutput memory underlying)
    {
        UnderlyingPayload memory underlyingPayload = UnderlyingPayload({
            ranges: ranges(vault_),
            factory: vault_.factory(),
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
            IArrakisV2(underlyingPayload.self).managerBalance0() -
            IArrakisV2(underlyingPayload.self).arrakisBalance0();
        underlying.leftOver1 =
            IERC20(underlyingPayload.token1).balanceOf(underlyingPayload.self) -
            IArrakisV2(underlyingPayload.self).managerBalance1() -
            IArrakisV2(underlyingPayload.self).arrakisBalance1();
    }

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
            ranges: ranges(vault_),
            factory: vault_.factory(),
            token0: address(vault_.token0()),
            token1: address(vault_.token1()),
            self: address(vault_)
        });

        (amount0, amount1, fee0, fee1) = UnderlyingHelper
            .totalUnderlyingWithFees(underlyingPayload);
    }

    function totalUnderlying(IArrakisV2 vault_)
        external
        view
        returns (uint256 amount0, uint256 amount1)
    {
        UnderlyingPayload memory underlyingPayload = UnderlyingPayload({
            ranges: ranges(vault_),
            factory: vault_.factory(),
            token0: address(vault_.token0()),
            token1: address(vault_.token1()),
            self: address(vault_)
        });

        (amount0, amount1, , ) = UnderlyingHelper.totalUnderlyingWithFees(
            underlyingPayload
        );
    }

    // #region Rebalance helper functions

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

    function ranges(IArrakisV2 vault_)
        public
        view
        returns (Range[] memory rgs)
    {
        uint256 index;
        while (true) {
            try vault_.ranges(index) returns (Range memory) {
                index++;
            } catch {
                break;
            }
        }

        rgs = new Range[](index);

        for (uint256 i = 0; i < index; i++) {
            rgs[i] = vault_.ranges(i);
        }
    }

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