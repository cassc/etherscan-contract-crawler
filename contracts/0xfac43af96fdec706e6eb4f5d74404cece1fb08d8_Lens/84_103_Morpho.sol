// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import "./MorphoGovernance.sol";

/// @title Morpho.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice Main Morpho contract handling user interactions and pool interactions.
contract Morpho is MorphoGovernance {
    using SafeTransferLib for ERC20;
    using DelegateCall for address;
    using WadRayMath for uint256;

    /// EVENTS ///

    /// @notice Emitted when a user claims rewards.
    /// @param _user The address of the claimer.
    /// @param _amountClaimed The amount of reward token claimed.
    /// @param _traded Whether or not the pool tokens are traded against Morpho tokens.
    event RewardsClaimed(address indexed _user, uint256 _amountClaimed, bool indexed _traded);

    /// ERRORS ///

    /// @notice Thrown when claiming rewards is paused.
    error ClaimRewardsPaused();

    /// EXTERNAL ///

    /// @notice Supplies underlying tokens to a specific market.
    /// @dev `msg.sender` must have approved Morpho's contract to spend the underlying `_amount`.
    /// @param _poolToken The address of the market the user wants to interact with.
    /// @param _amount The amount of token (in underlying) to supply.
    function supply(address _poolToken, uint256 _amount)
        external
        nonReentrant
        isMarketCreatedAndNotPausedNorPartiallyPaused(_poolToken)
    {
        _supply(_poolToken, msg.sender, _amount, defaultMaxGasForMatching.supply);
    }

    /// @notice Supplies underlying tokens to a specific market, on behalf of a given user.
    /// @dev `msg.sender` must have approved Morpho's contract to spend the underlying `_amount`.
    /// @param _poolToken The address of the market the user wants to interact with.
    /// @param _onBehalf The address of the account whose positions will be updated.
    /// @param _amount The amount of token (in underlying) to supply.
    function supply(
        address _poolToken,
        address _onBehalf,
        uint256 _amount
    ) external nonReentrant isMarketCreatedAndNotPausedNorPartiallyPaused(_poolToken) {
        _supply(_poolToken, _onBehalf, _amount, defaultMaxGasForMatching.supply);
    }

    /// @notice Supplies underlying tokens to a specific market, on behalf of a given user,
    ///         specifying a gas threshold at which to cut the matching engine.
    /// @dev `msg.sender` must have approved Morpho's contract to spend the underlying `_amount`.
    /// @param _poolToken The address of the market the user wants to interact with.
    /// @param _onBehalf The address of the account whose positions will be updated.
    /// @param _amount The amount of token (in underlying) to supply.
    /// @param _maxGasForMatching The gas threshold at which to stop the matching engine.
    function supply(
        address _poolToken,
        address _onBehalf,
        uint256 _amount,
        uint256 _maxGasForMatching
    ) external nonReentrant isMarketCreatedAndNotPausedNorPartiallyPaused(_poolToken) {
        _supply(_poolToken, _onBehalf, _amount, _maxGasForMatching);
    }

    /// @notice Borrows underlying tokens from a specific market.
    /// @param _poolToken The address of the market the user wants to interact with.
    /// @param _amount The amount of token (in underlying).
    function borrow(address _poolToken, uint256 _amount)
        external
        nonReentrant
        isMarketCreatedAndNotPausedNorPartiallyPaused(_poolToken)
    {
        _borrow(_poolToken, _amount, defaultMaxGasForMatching.borrow);
    }

    /// @notice Borrows underlying tokens from a specific market, specifying a gas threshold at which to stop the matching engine.
    /// @param _poolToken The address of the market the user wants to interact with.
    /// @param _amount The amount of token (in underlying).
    /// @param _maxGasForMatching The gas threshold at which to stop the matching engine.
    function borrow(
        address _poolToken,
        uint256 _amount,
        uint256 _maxGasForMatching
    ) external nonReentrant isMarketCreatedAndNotPausedNorPartiallyPaused(_poolToken) {
        _borrow(_poolToken, _amount, _maxGasForMatching);
    }

    /// @notice Withdraws underlying tokens from a specific market.
    /// @param _poolToken The address of the market the user wants to interact with.
    /// @param _amount The amount of tokens (in underlying) to withdraw from supply.
    function withdraw(address _poolToken, uint256 _amount)
        external
        nonReentrant
        isMarketCreatedAndNotPaused(_poolToken)
    {
        _withdraw(_poolToken, _amount, msg.sender, defaultMaxGasForMatching.withdraw);
    }

    /// @notice Withdraws underlying tokens from a specific market.
    /// @param _poolToken The address of the market the user wants to interact with.
    /// @param _amount The amount of tokens (in underlying) to withdraw from supply.
    /// @param _receiver The address to send withdrawn tokens to.
    function withdraw(
        address _poolToken,
        uint256 _amount,
        address _receiver
    ) external nonReentrant isMarketCreatedAndNotPaused(_poolToken) {
        _withdraw(_poolToken, _amount, _receiver, defaultMaxGasForMatching.withdraw);
    }

    /// @notice Repays the debt of the sender, up to the amount provided.
    /// @dev `msg.sender` must have approved Morpho's contract to spend the underlying `_amount`.
    /// @param _poolToken The address of the market the user wants to interact with.
    /// @param _amount The amount of token (in underlying) to repay from borrow.
    function repay(address _poolToken, uint256 _amount)
        external
        nonReentrant
        isMarketCreatedAndNotPaused(_poolToken)
    {
        _repay(_poolToken, msg.sender, _amount, defaultMaxGasForMatching.repay);
    }

    /// @notice Repays debt of a given user, up to the amount provided.
    /// @dev `msg.sender` must have approved Morpho's contract to spend the underlying `_amount`.
    /// @param _poolToken The address of the market the user wants to interact with.
    /// @param _onBehalf The address of the account whose positions will be updated.
    /// @param _amount The amount of token (in underlying) to repay from borrow.
    function repay(
        address _poolToken,
        address _onBehalf,
        uint256 _amount
    ) external nonReentrant isMarketCreatedAndNotPaused(_poolToken) {
        _repay(_poolToken, _onBehalf, _amount, defaultMaxGasForMatching.repay);
    }

    /// @notice Liquidates a position.
    /// @param _poolTokenBorrowed The address of the pool token the liquidator wants to repay.
    /// @param _poolTokenCollateral The address of the collateral pool token the liquidator wants to seize.
    /// @param _borrower The address of the borrower to liquidate.
    /// @param _amount The amount of token (in underlying) to repay.
    function liquidate(
        address _poolTokenBorrowed,
        address _poolTokenCollateral,
        address _borrower,
        uint256 _amount
    )
        external
        nonReentrant
        isMarketCreatedAndNotPaused(_poolTokenBorrowed)
        isMarketCreatedAndNotPaused(_poolTokenCollateral)
    {
        address(exitPositionsManager).functionDelegateCall(
            abi.encodeWithSelector(
                IExitPositionsManager.liquidateLogic.selector,
                _poolTokenBorrowed,
                _poolTokenCollateral,
                _borrower,
                _amount
            )
        );
    }

    /// @notice Claims rewards for the given assets.
    /// @param _assets The assets to claim rewards from (aToken or variable debt token).
    /// @param _tradeForMorphoToken Whether or not to trade reward tokens for MORPHO tokens.
    /// @return claimedAmount The amount of rewards claimed (in reward token).
    function claimRewards(address[] calldata _assets, bool _tradeForMorphoToken)
        external
        nonReentrant
        returns (uint256 claimedAmount)
    {
        if (isClaimRewardsPaused) revert ClaimRewardsPaused();
        claimedAmount = rewardsManager.claimRewards(aaveIncentivesController, _assets, msg.sender);

        if (claimedAmount > 0) {
            if (_tradeForMorphoToken) {
                aaveIncentivesController.claimRewards(
                    _assets,
                    claimedAmount,
                    address(incentivesVault)
                );
                incentivesVault.tradeRewardTokensForMorphoTokens(msg.sender, claimedAmount);
            } else aaveIncentivesController.claimRewards(_assets, claimedAmount, msg.sender);

            emit RewardsClaimed(msg.sender, claimedAmount, _tradeForMorphoToken);
        }
    }

    /// INTERNAL ///

    function _supply(
        address _poolToken,
        address _onBehalf,
        uint256 _amount,
        uint256 _maxGasForMatching
    ) internal {
        address(entryPositionsManager).functionDelegateCall(
            abi.encodeWithSelector(
                IEntryPositionsManager.supplyLogic.selector,
                _poolToken,
                msg.sender,
                _onBehalf,
                _amount,
                _maxGasForMatching
            )
        );
    }

    function _borrow(
        address _poolToken,
        uint256 _amount,
        uint256 _maxGasForMatching
    ) internal {
        address(entryPositionsManager).functionDelegateCall(
            abi.encodeWithSelector(
                IEntryPositionsManager.borrowLogic.selector,
                _poolToken,
                _amount,
                _maxGasForMatching
            )
        );
    }

    function _withdraw(
        address _poolToken,
        uint256 _amount,
        address _receiver,
        uint256 _maxGasForMatching
    ) internal {
        address(exitPositionsManager).functionDelegateCall(
            abi.encodeWithSelector(
                IExitPositionsManager.withdrawLogic.selector,
                _poolToken,
                _amount,
                msg.sender,
                _receiver,
                _maxGasForMatching
            )
        );
    }

    function _repay(
        address _poolToken,
        address _onBehalf,
        uint256 _amount,
        uint256 _maxGasForMatching
    ) internal {
        address(exitPositionsManager).functionDelegateCall(
            abi.encodeWithSelector(
                IExitPositionsManager.repayLogic.selector,
                _poolToken,
                msg.sender,
                _onBehalf,
                _amount,
                _maxGasForMatching
            )
        );
    }
}