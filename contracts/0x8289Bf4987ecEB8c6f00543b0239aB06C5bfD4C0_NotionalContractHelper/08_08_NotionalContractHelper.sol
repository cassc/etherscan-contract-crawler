// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../../interfaces/INotionalStrategyContractHelper.sol";
import "../../external/@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "../../external/interfaces/notional/INotional.sol";
import "../../external/interfaces/notional/INToken.sol";

/**
 * @notice This contract serves as a Notional strategy helper.
 * @dev
 *
 * This is done as NOTE rewards are claimed whenever mints or redeems occur,
 * in which case the rewards are returned to the master Spool contract.
 * Having a separate contract for each Notional strategy
 * gves us a way to collect the NOTE token rewards belonging
 * to this particular Spool strategy.
 * There should be one helper contract per Notional strategy.
 *
 * It can only be called by the Spool contract.
 * It should be only be used by NotionalStrategy.
 */
contract NotionalContractHelper is INotionalStrategyContractHelper {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    INotional public immutable notional;
    INToken public immutable nToken;
    IERC20 public immutable note;
    uint16 public immutable id;
    IERC20 public immutable underlying;
    address public immutable spool;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        INotional _notional,
        IERC20 _note,
        INToken _nToken,
        uint16 _id,
        IERC20 _underlying,
        address _spool
    ) {
        require(address(_notional) != address(0), "NotionalContractHelper::constructor: Notional address cannot be 0");
        require(address(_note) != address(0), "NotionalContractHelper::constructor: NOTE address cannot be 0");
        require(address(_nToken) != address(0), "NotionalContractHelper::constructor: Token address cannot be 0");
        require(_id == _nToken.currencyId(), "NotionalContractHelper::constructor: ID is not the same as nToken ID");
        (, Token memory underlyingToken) = _notional.getCurrency(_id);
        require(
            address(_underlying) == underlyingToken.tokenAddress,
            "NotionalContractHelper::constructor: Underlying and notional underlying do not match"
        );
        require(_spool != address(0), "NotionalContractHelper::constructor: Spool address cannot be 0");

        notional = _notional;
        note = _note;
        nToken = _nToken;
        id = _id;
        underlying = _underlying;
        spool = _spool;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Claim NOTE rewards from Notional proxy.
     * @dev
     * Rewards are sent back to the Spool contract
     *
     * @param executeClaim Do execute the claim
     * @return rewards Amount of NOTE tokens claimed
     */
    function claimRewards(bool executeClaim) external override onlySpool returns (uint256 rewards) {
        if (executeClaim) {
            notional.nTokenClaimIncentives();
        }

        rewards = note.balanceOf(address(this));

        IERC20(note).safeTransfer(msg.sender, rewards);
    }

    /**
     * @notice Deposit to Notional market
     * @dev
     * The Spool should send `underlying` token in size of `amount`
     * before calling this contract.
     * The contract deposits the received underlying and returns the
     * newly received nToken amount.
     *
     * @param amount Amount of underlying to deposit
     * @return nTokenBalanceNew Gained nToken amount from depositing
     */
    function deposit(uint256 amount) external override onlySpool returns (uint256) {
        BalanceAction[] memory actions = _buildBalanceAction(
            DepositActionType.DepositUnderlyingAndMintNToken,
            amount,
            false,
            false
        );

        // deposit underlying
        underlying.safeApprove(address(notional), amount);
        uint256 nTokenBalanceBefore = nToken.balanceOf(address(this));
        notional.batchBalanceAction(address(this), actions);
        uint256 nTokenBalanceNew = nToken.balanceOf(address(this)) - nTokenBalanceBefore;

        _resetAllowance(underlying, address(notional));

        return nTokenBalanceNew;
    }

    /**
     * @notice Withdraw from Notional market
     * @dev
     * The withdrawn underlying amount is then send back to the Spool.
     *
     * @param nTokenWithdraw Amount of tokens to withdraw
     * @return underlyingWithdrawn Gained underlying amount from withdrawing
     */
    function withdraw(uint256 nTokenWithdraw) external override onlySpool returns (uint256) {
        BalanceAction[] memory actions = _buildBalanceAction(
            DepositActionType.RedeemNToken,
            nTokenWithdraw,
            true,
            true
        );

        // withdraw nToken tokens from notional
        uint256 underlyingBefore = underlying.balanceOf(address(this));
        notional.batchBalanceAction(address(this), actions);
        uint256 underlyingWithdrawn = underlying.balanceOf(address(this)) - underlyingBefore;
        // transfer withdrawn back to spool
        underlying.safeTransfer(msg.sender, underlyingWithdrawn);
        return underlyingWithdrawn;
    }

    function withdrawAll() external override onlySpool returns (uint256) {
        BalanceAction[] memory actions = _buildBalanceAction(
            DepositActionType.RedeemNToken,
            nToken.balanceOf(address(this)),
            true,
            true
        );

        // withdraw nToken tokens from notional
        notional.batchBalanceAction(address(this), actions);

        uint256 underlyingWithdrawn = underlying.balanceOf(address(this));

        // transfer withdrawn back to spool
        underlying.safeTransfer(msg.sender, underlyingWithdrawn);

        return underlyingWithdrawn;
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /**
     * @notice Reset allowance to zero if previously set to a higher value.
     */
    function _resetAllowance(IERC20 token, address spender) internal {
        if (token.allowance(address(this), spender) > 0) {
            token.safeApprove(spender, 0);
        }
    }

    function _onlySpool() private view {
        require(msg.sender == spool, "NotionalStrategy::_onlySpool: Caller is not the Spool contract");
    }

    function _buildBalanceAction(
        DepositActionType actionType,
        uint256 depositActionAmount,
        bool withdrawEntireCashBalance,
        bool redeemToUnderlying
    ) private view returns (BalanceAction[] memory actions) {
        actions = new BalanceAction[](1);
        actions[0] = BalanceAction({
            actionType: actionType,
            currencyId: id,
            depositActionAmount: depositActionAmount,
            withdrawAmountInternalPrecision: 0,
            withdrawEntireCashBalance: withdrawEntireCashBalance,
            redeemToUnderlying: redeemToUnderlying
        });
    }

    /* ========== MODIFIERS ========== */

    modifier onlySpool() {
        _onlySpool();
        _;
    }
}