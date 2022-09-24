// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import "../../../interfaces/external/curve/IStableSwapPool.sol";
import "../../../interfaces/external/curve/IMetaPool.sol";
import "../../BaseAMO.sol";

/// @title BaseCurveAMO
/// @author Angle Core Team
/// @notice AMO depositing tokens on a Curve pool and staking the LP tokens on platforms like Convex or StakeDAO
/// @dev This AMO can only invest 1 agToken in a pool
abstract contract BaseCurveAMO is BaseAMO {
    /// @notice Address of the agToken that can be handled by this AMO
    IERC20 public agToken;
    /// @notice Address of the Curve pool on which this AMO invests
    address public mainPool;

    uint256[48] private __gapBaseCurveAMO;

    // =================================== ERRORS ==================================

    error IncompatibleTokens();
    error IncompatibleValues();

    // =============================== INITIALIZATION ==============================

    /// @notice Initializes the `BaseCurveAMO` contract
    /// @param amoMinter_ Address of the `AMOMinter`
    /// @param agToken_ Stablecoin lent by the amoMinter
    /// @param basePool_ Curve pool in which the stablecoin will be invested
    function _initializeBaseCurve(
        address amoMinter_,
        IERC20 agToken_,
        address basePool_
    ) internal {
        if (address(agToken_) == address(0) || basePool_ == address(0)) revert ZeroAddress();
        _initialize(amoMinter_);
        agToken = agToken_;
        mainPool = basePool_;
    }

    // ============================== INTERNAL ACTIONS =============================

    /// @inheritdoc BaseAMO
    function _push(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes[] memory data
    ) internal override {
        (tokens, amounts) = _checkTokensList(tokens, amounts);

        // Checking first for profit / loss made on each token (in this case just the `agToken`)
        for (uint256 i = 0; i < tokens.length; i++) {
            (uint256 netAssets, uint256 idleAssets) = _report(tokens[i], amounts[i]);
            // As the `add_liquidity` function on Curve can only deposit the right amount
            // we can compute directly `lastBalance`
            lastBalances[tokens[i]] = netAssets + idleAssets;
        }

        _curvePoolDeposit(amounts, data);
        _depositLPToken();
    }

    /// @inheritdoc BaseAMO
    /// @dev Returning an amount here is important as the amounts fed are not comparable to the lp amounts
    function _pull(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes[] memory data
    ) internal override returns (uint256[] memory amountsAvailable) {
        (tokens, amounts) = _checkTokensList(tokens, amounts);

        uint256[] memory idleTokens = new uint256[](tokens.length);

        // Check for profit / loss made on each token. This doesn't take into account rewards
        for (uint256 i = 0; i < tokens.length; i++) {
            (uint256 netAssets, uint256 idleAssets) = _report(tokens[i], 0);
            lastBalances[tokens[i]] = netAssets + idleAssets - amounts[i];
            idleTokens[i] = idleAssets;
        }

        // We first need to unstake and withdraw the staker(s) LP token to get the Curve LP token
        // We unstake all from the staker(s) as we don't know how much will be needed to get back `amounts`
        _withdrawLPToken();
        amountsAvailable = _curvePoolWithdraw(tokens, amounts, idleTokens, data);
        // The leftover Curve LP token balance is staked back
        _depositLPToken();

        return amountsAvailable;
    }

    // =========================== VIRTUAL CURVE ACTIONS ===========================

    /// @notice Deposits idle assets into Curve
    /// @param amounts List of amounts of tokens to be deposited
    /// @param data Bytes encoding the minimum amount of lp token to receive
    /// @return lpTokenReceived Amount of lp tokens received for the deposited amounts
    function _curvePoolDeposit(uint256[] memory amounts, bytes[] memory data)
        internal
        virtual
        returns (uint256 lpTokenReceived);

    /// @param tokens List of tokens to be withdrawn
    /// @param amounts List of amounts to be withdrawn
    /// @param idleTokens List of token amounts sitting idle on the contract
    /// @param data Bytes encoding the maximum of LP tokens to be burnt
    /// @return Token amounts received after the withdrawal action
    function _curvePoolWithdraw(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory idleTokens,
        bytes[] memory data
    ) internal virtual returns (uint256[] memory);

    // ========================== INTERNAL STAKER ACTIONS ==========================

    /// @notice Deposits the Curve LP tokens into a staker contract
    function _depositLPToken() internal virtual;

    /// @notice Withdraws the Curve LP tokens from a staker contract
    function _withdrawLPToken() internal virtual;

    /// @notice Gets the balance of the staking protocol LP tokens for the pool
    function _balanceLPStaked() internal view virtual returns (uint256);

    // ========================== Internal Computations ============================

    /// @notice Compute the underlying tokens amount that will be received upon removing liquidity in a balanced manner
    /// @param tokenSupply Token owned by the Curve pool
    /// @param totalLpSupply Total supply of the metaPool
    /// @param myLpSupply Contract supply of the contract
    /// @return tokenWithdrawn Amount of `tokenToWithdraw` that would be received after removing liquidity
    function _calcRemoveLiquidityStablePool(
        uint256 tokenSupply,
        uint256 totalLpSupply,
        uint256 myLpSupply
    ) internal pure returns (uint256 tokenWithdrawn) {
        if (totalLpSupply > 0) tokenWithdrawn = (tokenSupply * myLpSupply) / totalLpSupply;
    }

    // ============================= VIRTUAL FUNCTIONS =============================

    /// @notice Checks on a given `tokens` and `amounts` list that are passed for a `_pull` or `_push` operation,
    /// reverting if the tokens are not supported and filling the arrays if they are missing entries
    /// @param tokens Addresses of tokens to be withdrawn
    /// @param amounts Amounts of each token to be withdrawn
    function _checkTokensList(IERC20[] memory tokens, uint256[] memory amounts)
        internal
        virtual
        returns (IERC20[] memory, uint256[] memory);
}