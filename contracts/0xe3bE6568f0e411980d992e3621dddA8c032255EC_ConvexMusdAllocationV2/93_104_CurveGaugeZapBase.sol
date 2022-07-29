// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IZap} from "contracts/lpaccount/Imports.sol";
import {
    IAssetAllocation,
    IERC20,
    IDetailedERC20
} from "contracts/common/Imports.sol";
import {SafeERC20} from "contracts/libraries/Imports.sol";
import {
    ILiquidityGauge,
    ITokenMinter
} from "contracts/protocols/curve/common/interfaces/Imports.sol";
import {CurveZapBase} from "contracts/protocols/curve/common/CurveZapBase.sol";

abstract contract CurveGaugeZapBase is IZap, CurveZapBase {
    using SafeERC20 for IERC20;

    address internal constant MINTER_ADDRESS =
        0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;

    address internal immutable LP_ADDRESS;
    address internal immutable GAUGE_ADDRESS;

    constructor(
        address swapAddress,
        address lpAddress,
        address gaugeAddress,
        uint256 denominator,
        uint256 slippage,
        uint256 nCoins
    )
        public
        CurveZapBase(swapAddress, denominator, slippage, nCoins)
    // solhint-disable-next-line no-empty-blocks
    {
        LP_ADDRESS = lpAddress;
        GAUGE_ADDRESS = gaugeAddress;
    }

    function getLpTokenBalance(address account)
        external
        view
        override
        returns (uint256)
    {
        return ILiquidityGauge(GAUGE_ADDRESS).balanceOf(account);
    }

    function _depositToGauge() internal override {
        ILiquidityGauge liquidityGauge = ILiquidityGauge(GAUGE_ADDRESS);
        uint256 lpBalance = IERC20(LP_ADDRESS).balanceOf(address(this));
        IERC20(LP_ADDRESS).safeApprove(GAUGE_ADDRESS, 0);
        IERC20(LP_ADDRESS).safeApprove(GAUGE_ADDRESS, lpBalance);
        liquidityGauge.deposit(lpBalance);
    }

    function _withdrawFromGauge(uint256 amount)
        internal
        override
        returns (uint256)
    {
        ILiquidityGauge liquidityGauge = ILiquidityGauge(GAUGE_ADDRESS);
        liquidityGauge.withdraw(amount);
        //lpBalance
        return IERC20(LP_ADDRESS).balanceOf(address(this));
    }

    function _claim() internal override {
        // claim CRV
        ITokenMinter(MINTER_ADDRESS).mint(GAUGE_ADDRESS);

        // claim protocol-specific rewards
        _claimRewards();
    }

    // solhint-disable-next-line no-empty-blocks
    function _claimRewards() internal virtual {}
}