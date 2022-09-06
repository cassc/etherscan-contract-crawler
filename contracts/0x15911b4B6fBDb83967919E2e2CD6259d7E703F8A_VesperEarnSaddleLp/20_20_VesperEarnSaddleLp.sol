// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./VesperEarn.sol";
import "../../../interfaces/saddle/ISwap.sol";

/// @notice This strategy will deposit collateral in a Vesper Grow Pool and converts the yield to Saddle LP token
contract VesperEarnSaddleLp is VesperEarn {
    using SafeERC20 for IERC20;

    ISwap public immutable saddlePool;
    uint8 private immutable collateralIdx;

    constructor(
        address pool_,
        ISwap saddlePool_,
        address swapper_,
        address receiptToken_,
        address dripToken_,
        address vsp_,
        string memory name_
    ) VesperEarn(pool_, swapper_, receiptToken_, dripToken_, vsp_, name_) {
        saddlePool = saddlePool_;
        collateralIdx = saddlePool.getTokenIndex(address(collateralToken));
    }

    function _approveToken(uint256 amount_) internal override(VesperEarn) {
        super._approveToken(amount_);
        collateralToken.safeApprove(address(saddlePool), amount_);
    }

    function _convertCollateralToDrip(uint256 _collateralAmount) internal override returns (uint256 _amountOut) {
        if (_collateralAmount > 0) {
            uint256[] memory _depositAmounts = new uint256[](collateralIdx + 1);
            _depositAmounts[collateralIdx] = _collateralAmount;

            // Note: Not checking slippage here because we are dealing with small amounts
            _amountOut = saddlePool.addLiquidity(_depositAmounts, 0, block.timestamp);
        }
    }
}