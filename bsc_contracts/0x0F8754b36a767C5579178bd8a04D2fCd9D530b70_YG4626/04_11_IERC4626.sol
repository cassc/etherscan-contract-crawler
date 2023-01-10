// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;
import "IERC20.sol";
import "ERC20.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC4626 is IERC20 {

    /* EVENTS */

    /// @notice Emitted after a successful deposit.
    /// @param sender The address that deposited into the Vault.
    /// @param receiver The address that received deposit shares.
    /// @param assets The amount of underlying assets that were deposited.
    /// @param shares The amount of shares minted in exchange for the assets.
    event Deposit(address indexed sender, address indexed receiver, uint256 assets, uint256 shares);

    /// @notice Emitted after a successful withdrawal.
    /// @param caller The address that withdrew from the Vault.
    /// @param receiver The destination for withdrawn tokens.
    /// @param owner The address from which tokens were withdrawn.
    /// @param assets The amount of underlying assets that were withdrawn.
    /// @param shares The amount of shares burnt in exchange for the assets.
    event Withdraw(address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);

    function asset() external view returns (address);
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);
    function convertToShares(uint256 assets) external view returns (uint256 shares);
    function previewDeposit(uint256 assets) external view returns (uint256 shares);
    function deposit(uint256 assets, address receiver) external  returns (uint256 shares);
    function maxMint(address caller) external view returns (uint256 maxShares);
    function convertToAssets(uint256 shares) external view returns (uint256 assets);
    function previewMint(uint256 shares) external view returns (uint256 assets);
    function mint(uint256 shares, address receiver) external  returns (uint256 assets);
    function maxWithdraw(address user) external view returns (uint256 maxAssets);
    function previewWithdraw(uint256 assets) external view  returns (uint256 shares);
    function withdraw(uint256 assets, address receiver, address owner) external  returns (uint256 shares);
    function maxRedeem(address owner) external view returns (uint256 maxShares);
    function previewRedeem(uint256 shares) external view  returns (uint256 assets);
    function redeem(uint256 shares, address to, address from) external returns (uint256 amount);
    function assetsOf(address depositor) external view returns (uint256 assets);
    function assetsPerShare() external view returns (uint256 assetsPerUnitShare);
    function totalAssets() external view returns (uint256);
    function addFunds(uint256 original_amount, uint256 repaid_amount) external returns (uint256);
    function removeFunds(uint256 amount) external ;
    function apy() external view returns (uint256 _apy, uint256 precision, uint256 duration);

}