// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../../external/@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "../NoRewardStrategy.sol";
import "../../external/interfaces/yearn/IYearnTokenVault.sol";
import "../../external/interfaces/yearn/IVaultMigrator.sol";

/**
 * @notice Yearn Strategy implementation
 */
contract YearnStrategyV2 is NoRewardStrategy {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    /// @notice Vault contract
    IYearnTokenVault public immutable vault;

    /// @notice Old vault contract
    IYearnTokenVault private immutable oldVault;

    /// @notice Vault contract
    IVaultMigrator private immutable vaultMigrator;

    /// @notice One yearn vault share amount
    uint256 public immutable oneShare;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice Set initial values
     * @param _vault Vault contract
     * @param _underlying Underlying asset
     */
    constructor(
        IYearnTokenVault _vault,
        IYearnTokenVault _oldVault,
        IVaultMigrator _vaultMigrator,
        IERC20 _underlying,
        address _self
    )
        NoRewardStrategy(_underlying, 1, 1, 1, false, _self)
    {
        require(address(_vault) != address(0), "YearnStrategy::constructor: Vault address cannot be 0");
        vault = _vault;
        oldVault = _oldVault;
        vaultMigrator = _vaultMigrator;
        oneShare = 10**uint256(_vault.decimals());
    }

    /* ========== VIEWS ========== */

    /**
     * @notice Get strategy balance
     * @return Strategy balance
     */
    function getStrategyBalance() public view override returns(uint128) {
        uint256 yearnTokenAmount = vault.balanceOf(address(this));
        return SafeCast.toUint128(_getYearnTokenValue(yearnTokenAmount));
    }

    /* ========== OVERRIDDEN FUNCTIONS ========== */

    /**
     * @notice Deposit
     * @param amount Amount to deposit
     * @param slippages Slippages array
     * @return Minted idle amount
     */
    function _deposit(uint128 amount, uint256[] memory slippages) internal override returns(uint128) {
        (bool isDeposit, uint256 slippage) = _getSlippageAction(slippages[0]);
        require(isDeposit, "YearnStrategy::_deposit: Withdraw slippage provided");

        // deposit underlying
        underlying.safeApprove(address(vault), amount);

        uint256 yearnTokenBefore = vault.balanceOf(address(this));
        vault.deposit(amount, address(this));
        uint256 yearnTokenNew = vault.balanceOf(address(this)) - yearnTokenBefore;
        _resetAllowance(underlying, address(vault));

        require(
            yearnTokenNew >= slippage,
            "YearnStrategy::_deposit: Insufficient Yearn Amount Minted"
        );

        emit Slippage(self, underlying, true, amount, yearnTokenNew);

        return SafeCast.toUint128(_getYearnTokenValue(yearnTokenNew));
    }

    /**
     * @notice Withdraw
     * @param shares Shares to withdraw
     * @param slippages Slippages array
     * @return Underlying withdrawn
     */
    function _withdraw(uint128 shares, uint256[] memory slippages) internal override returns(uint128) {
        (bool isDeposit, uint256 slippage) = _getSlippageAction(slippages[0]);
        require(!isDeposit, "YearnStrategy::_withdraw: Deposit slippage provided");

        uint256 yearnTokenBalance = vault.balanceOf(address(this));
        uint256 yearnTokenWithdraw = (yearnTokenBalance * shares) / strategies[self].totalShares;

        // withdraw idle tokens from vault
        uint256 underlyingBefore = underlying.balanceOf(address(this));
        vault.withdraw(yearnTokenWithdraw, address(this), slippage);
        uint256 underlyingWithdrawn = underlying.balanceOf(address(this)) - underlyingBefore;
        
        emit Slippage(self, underlying, false, shares, underlyingWithdrawn);

        return SafeCast.toUint128(underlyingWithdrawn);
    }

    /**
     * @notice Emergency withdraw
     * @param recipient Address to withdraw to
     * @param data Data to perform emergency withdrawal
     */
    function _emergencyWithdraw(address recipient, uint256[] calldata data) internal override {
        // if no data provided set max loss to 100%
        uint256 maxLoss = data.length > 0 ? data[0] : 100_00;

        vault.withdraw(
            type(uint256).max,
            recipient,
            maxLoss
        );
    }

    /**
     * @notice Process the strategy pending deposits, withdrawals, and collected strategy rewards
     * @dev
     * Deposit amount amd withdrawal shares are matched between eachother, effecively only one of
     * those 2 is called. Shares are converted to the dollar value, based on the current strategy
     * total balance. This ensures the minimum amount of assets are moved around to lower the price
     * drift and total fees paid to the protocols the strategy is interacting with (if there are any)
     * 
     * NOTE: Migrate from old Yearn Vauult to new one on index 108
     *
     * @param slippages Strategy slippage values verifying the validity of the strategy state
     * @param reallocateSharesToWithdraw Reallocation shares to withdraw (non-zero only if reallocation DHW is in progress, otherwise 0)
     */
    function _process(uint256[] memory slippages, uint128 reallocateSharesToWithdraw) internal override {
        // migrate only on index 108
        if (strategies[self].index <= 108) {
            _migrate();
        }

        super._process(slippages, reallocateSharesToWithdraw);
    }

    /**
     * @notice Migrate from the old Yearn Vault to the new one on index 108
     */
    function _migrate() private {
        IERC20(address(oldVault)).safeApprove(address(vaultMigrator), type(uint256).max);
        vaultMigrator.migrateAll(address(oldVault), address(vault));
        _resetAllowance(IERC20(address(oldVault)), address(vaultMigrator));
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _getYearnTokenValue(uint256 yearnTokenAmount) private view returns(uint256) {
        if (yearnTokenAmount == 0)
            return 0;
        return (yearnTokenAmount * vault.pricePerShare()) / oneShare;
    }
}