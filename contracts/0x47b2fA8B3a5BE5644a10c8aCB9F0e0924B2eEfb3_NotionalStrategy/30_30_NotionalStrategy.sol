// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../../interfaces/INotionalStrategyContractHelper.sol";
import "../../external/@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "../../external/@openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import "../ClaimFullSingleRewardStrategy.sol";
import "../../external/interfaces/notional/INotional.sol";
import "../../external/interfaces/notional/INToken.sol";

/**
 * @notice Notional Strategy implementation
 */
contract NotionalStrategy is ClaimFullSingleRewardStrategy {
    using SafeERC20 for IERC20;

    /* ========== CONSTANTS ========== */

    uint256 private constant NTOKEN_DECIMALS_MULTIPLIER = 10**8;

    /* ========== STATE VARIABLES ========== */

    /// @notice Notional proxy contract
    INotional public immutable notional;

    /// @notice nToken for this underlying
    INToken public immutable nToken;

    /// @notice underlying token ID in notional contract
    uint16 public immutable id;

    INotionalStrategyContractHelper public immutable strategyHelper;

    uint256 private immutable underlyingDecimalsMultiplier;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice Set initial values
     * @param _notional Notional proxy contract
     * @param _underlying Underlying asset
     */
    constructor(
        INotional _notional,
        IERC20 _note,
        INToken _nToken,
        uint16 _id,
        IERC20Metadata _underlying,
        INotionalStrategyContractHelper _strategyHelper
    ) BaseStrategy(_underlying, 1, 0, 0, 0, false, false, address(0)) ClaimFullSingleRewardStrategy(_note) {
        require(address(_notional) != address(0), "NotionalStrategy::constructor: Notional address cannot be 0");
        require(address(_nToken) != address(0), "NotionalStrategy::constructor: nToken address cannot be 0");
        require(
            _nToken == _strategyHelper.nToken(),
            "NotionalStrategy::constructor: nToken is not the same as helpers nToken"
        );
        require(_id == _nToken.currencyId(), "NotionalStrategy::constructor: ID is not the same as nToken ID");
        (, Token memory underlyingToken) = _notional.getCurrency(_id);
        require(
            address(_underlying) == underlyingToken.tokenAddress,
            "NotionalStrategy::constructor: Underlying and notional underlying do not match"
        );

        notional = _notional;
        nToken = _nToken;
        id = _id;
        strategyHelper = _strategyHelper;

        underlyingDecimalsMultiplier = 10**_underlying.decimals();
    }

    /* ========== OVERRIDDEN FUNCTIONS ========== */

    function _claimStrategyReward() internal override returns (uint128) {
        // claim NOTE rewards
        uint256 rewardAmount = strategyHelper.claimRewards(true);

        // add already claimed rewards
        rewardAmount += strategies[self].pendingRewards[address(rewardToken)];

        return SafeCast.toUint128(rewardAmount);
    }

    /* ========== VIEWS ========== */

    /**
     * @notice Get strategy balance
     * @return Strategy balance
     */
    function getStrategyBalance() public view override returns (uint128) {
        uint256 nTokenBalance = nToken.balanceOf(address(strategyHelper));
        return SafeCast.toUint128(_getNTokenValue(nTokenBalance));
    }

    /* ========== OVERRIDDEN FUNCTIONS ========== */

    /**
     * @notice Deposit
     * @param amount Amount to deposit
     * @param slippages Slippages array
     * @return Minted nToken amount
     */
    function _deposit(uint128 amount, uint256[] memory slippages) internal override returns (uint128) {
        (bool isDeposit, uint256 slippage) = _getSlippageAction(slippages[0]);
        require(isDeposit, "NotionalStrategy::_deposit: Withdraw slippage provided");

        underlying.safeTransfer(address(strategyHelper), amount);

        uint256 nTokenBalanceNew = strategyHelper.deposit(amount);

        require(nTokenBalanceNew >= slippage, "NotionalStrategy::_deposit: Insufficient nToken Amount Minted");

        emit Slippage(self, underlying, true, amount, nTokenBalanceNew);

        return SafeCast.toUint128(_getNTokenValue(nTokenBalanceNew));
    }

    /**
     * @notice Withdraw
     * @param shares Shares to withdraw
     * @param slippages Slippages array
     * @return Underlying withdrawn
     */
    function _withdraw(uint128 shares, uint256[] memory slippages) internal override returns (uint128) {
        (bool isDeposit, uint256 slippage) = _getSlippageAction(slippages[0]);
        require(!isDeposit, "NotionalStrategy::_withdraw: Deposit slippage provided");

        uint256 nTokenBalance = nToken.balanceOf(address(strategyHelper));
        uint256 nTokenWithdraw = (nTokenBalance * shares) / strategies[self].totalShares;

        uint256 underlyingWithdrawn = strategyHelper.withdraw(nTokenWithdraw);

        require(underlyingWithdrawn >= slippage, "NotionalStrategy::_withdraw: Insufficient withdrawn amount");

        emit Slippage(self, underlying, false, shares, underlyingWithdrawn);

        return SafeCast.toUint128(underlyingWithdrawn);
    }

    /**
     * @notice Emergency withdraw
     */
    function _emergencyWithdraw(address, uint256[] calldata) internal override {
        strategyHelper.withdrawAll();
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _getNTokenValue(uint256 nTokenAmount) private view returns (uint256) {
        if (nTokenAmount == 0) return 0;
        return (nTokenAmount * uint256(nToken.getPresentValueUnderlyingDenominated()) / nToken.totalSupply()) * 
            underlyingDecimalsMultiplier / NTOKEN_DECIMALS_MULTIPLIER;
    }
}