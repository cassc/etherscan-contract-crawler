// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAssetAllocation} from "contracts/common/Imports.sol";
import {IMetaPool} from "./IMetaPool.sol";
import {IOldDepositor} from "./IOldDepositor.sol";
import {CurveGaugeZapBase} from "contracts/protocols/curve/common/Imports.sol";

abstract contract MetaPoolOldDepositorZap is CurveGaugeZapBase {
    IOldDepositor internal immutable _DEPOSITOR;
    IMetaPool internal immutable _META_POOL;

    constructor(
        IOldDepositor depositor,
        IMetaPool metapool,
        address lpAddress,
        address gaugeAddress,
        uint256 denominator,
        uint256 slippage
    )
        public
        CurveGaugeZapBase(
            address(depositor),
            lpAddress,
            gaugeAddress,
            denominator,
            slippage,
            4
        )
    {
        _DEPOSITOR = depositor;
        _META_POOL = metapool;
    }

    function _addLiquidity(uint256[] calldata amounts, uint256 minAmount)
        internal
        override
    {
        _DEPOSITOR.add_liquidity(
            [amounts[0], amounts[1], amounts[2], amounts[3]],
            minAmount
        );
    }

    function _removeLiquidity(
        uint256 lpBalance,
        uint8 index,
        uint256 minAmount
    ) internal override {
        IERC20(LP_ADDRESS).safeApprove(address(_DEPOSITOR), 0);
        IERC20(LP_ADDRESS).safeApprove(address(_DEPOSITOR), lpBalance);
        _DEPOSITOR.remove_liquidity_one_coin(lpBalance, index, minAmount);
    }

    function _getVirtualPrice() internal view override returns (uint256) {
        return _META_POOL.get_virtual_price();
    }

    function _getCoinAtIndex(uint256 i)
        internal
        view
        override
        returns (address)
    {
        if (i == 0) {
            return _DEPOSITOR.coins(0);
        } else {
            return _DEPOSITOR.base_coins(i.sub(1));
        }
    }
}