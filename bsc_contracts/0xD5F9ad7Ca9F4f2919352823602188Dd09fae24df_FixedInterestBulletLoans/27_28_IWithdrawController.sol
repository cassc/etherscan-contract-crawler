// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

/// @title WithdrawController
/// @notice This contract manages the withdrawal and redemption fees for users in the tranches.
/// @dev The contract calculates fees, handles withdrawal, and allows setting of withdrawal fee rates.
interface IWithdrawController {
    // @return Rate of the withdraw fee in Basis point, i.e. decimal 4.
    function withdrawFeeRate() external view returns (uint256);

    /// @dev A user cannot withdraw in the live status.
    /// @return assets The max amount of assets that the user can withdraw.
    function maxWithdraw(address owner) external view returns (uint256 assets);

    /// @dev A user cannot redeem in the live status.
    /// @return shares The max amount of shares that the user can burn to withdraw assets.
    function maxRedeem(address owner) external view returns (uint256 shares);

    /// @notice Preview the amount of shares to burn to withdraw the given amount of assets.
    /// @dev    It always rounds up the result. e.g. 3/4 -> 1.
    /// @param  assets The amount of assets to withdraw.
    /// @return  shares The amount of shares to burn.
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /// @notice Preview the amount of assets to receive after burning the given amount of shares.
    /// @param  shares The amount of shares to burn.
    /// @return assets The amount of assets to receive.
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /// @notice Executes the withdrawal process, returning the amount of shares to burn and fees.
    /// @dev The sender and owner parameters are not used in this implementation.
    /// @param assets The amount of assets to withdraw.
    /// @param receiver The address that will receive the assets.
    /// @param owner The address of the owner of the assets.
    /// @return shares The amount of shares to burn.
    /// @return fees The amount of fees to be paid.
    function onWithdraw(
        address sender,
        uint256 assets,
        address receiver,
        address owner
    )
        external
        returns (uint256 shares, uint256 fees);

    function onRedeem(
        address sender,
        uint256 shares,
        address receiver,
        address owner
    )
        external
        returns (uint256 assets, uint256 fees);
    function setWithdrawFeeRate(uint256 _withdrawFeeRate) external;
}