// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import "../../../interfaces/external/curve/IMetaPool2.sol";
import "./BaseCurveAMO.sol";

/// @title BaseCurveBPAmo
/// @author Angle Core Team
/// @notice AMO depositing tokens on a Curve pool and staking the LP tokens on platforms like Convex or StakeDAO
/// @dev This AMO can only invest 1 agToken in a Curve pool in which there are only two tokens and in which
/// the agToken is the first token of the pool (like agEUR in the agEUR/EUROC pool)
abstract contract BaseCurveBPAMO is BaseCurveAMO {
    /// @notice Decimal normalizer between `agToken` and the other token
    uint256 public constant decimalNormalizer = 10**12;

    uint256[50] private __gapBaseCurveBPAMO;

    // =============================== INITIALIZATION ==============================

    /// @notice Initializes the `AMO` contract
    function _initializeBaseCurveBPAMO(
        address amoMinter_,
        IERC20 agToken_,
        address basePool_
    ) internal {
        _initializeBaseCurve(amoMinter_, agToken_, basePool_);
    }

    // =============================== VIEW FUNCTIONS ==============================

    /// @notice Returns info useful to keeper contracts that might be plugged over this contract
    function keeperInfo()
        external
        view
        virtual
        returns (
            address,
            address,
            uint256
        )
    {
        return (mainPool, address(agToken), uint256(0));
    }

    // ========================== Internal Actions =================================

    /// @notice Gets the net amount of stablecoin owned by this AMO
    /// @dev The assets are estimated by considering that we burn all our LP tokens and receive in a balanced way `agToken` and `collateral`
    /// @dev We then consider that the `collateral` is fully tradable at 1:1 against `agToken`
    function _getNavOfInvestedAssets(IERC20) internal view override returns (uint256 netInvested) {
        // Should be null at all times because invested on a staking platform
        uint256 lpTokenOwned = IMetaPool2(mainPool).balanceOf(address(this));
        // Staked LP tokens in Convex or StakeDAO vault
        uint256 stakedLptoken = _balanceLPStaked();
        lpTokenOwned = lpTokenOwned + stakedLptoken;

        if (lpTokenOwned != 0) {
            uint256 lpSupply = IMetaPool2(mainPool).totalSupply();
            uint256[2] memory balances = IMetaPool2(mainPool).get_balances();
            netInvested = _calcRemoveLiquidityStablePool(balances[0], lpSupply, lpTokenOwned);
            // Here we consider that the `collateral` is tradable 1:1 for `agToken`
            netInvested += _calcRemoveLiquidityStablePool(balances[1], lpSupply, lpTokenOwned) * decimalNormalizer;
        }
    }

    /// @inheritdoc BaseCurveAMO
    function _checkTokensList(IERC20[] memory tokens, uint256[] memory amounts)
        internal
        view
        override
        returns (IERC20[] memory, uint256[] memory)
    {
        if (tokens.length != 1) revert IncompatibleLengths();
        if (address(tokens[0]) != address(agToken)) revert IncompatibleTokens();
        return (tokens, amounts);
    }

    // ======================== Internal Curve actions =============================

    /// @inheritdoc BaseCurveAMO
    /// @dev This AMO can only deposit/withdraw 1 token at once
    function _curvePoolDeposit(uint256[] memory amounts, bytes[] memory data)
        internal
        override
        returns (uint256 lpTokenReceived)
    {
        uint256 minLpAmount = abi.decode(data[0], (uint256));
        _changeAllowance(agToken, address(mainPool), amounts[0]);
        lpTokenReceived = IMetaPool2(mainPool).add_liquidity([amounts[0], 0], minLpAmount);
        return lpTokenReceived;
    }

    /// @inheritdoc BaseCurveAMO
    function _curvePoolWithdraw(
        IERC20[] memory,
        uint256[] memory amounts,
        uint256[] memory,
        bytes[] memory data
    ) internal override returns (uint256[] memory) {
        uint256 maxLpBurnt = abi.decode(data[0], (uint256));
        IMetaPool2(mainPool).remove_liquidity_imbalance([amounts[0], 0], maxLpBurnt);
        return amounts;
    }
}