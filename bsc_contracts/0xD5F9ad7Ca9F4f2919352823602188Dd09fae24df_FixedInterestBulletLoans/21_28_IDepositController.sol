// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

interface IDepositController {
    /// @notice Handle deposit of assets and distribute shares and fees accordingly
    /// @param sender The address of the sender depositing assets
    /// @param assets The amount of assets being deposited
    /// @param receiver The address receiving the shares
    /// @return shares The amount of shares minted for the deposit
    /// @return fees The amount of fees collected during the deposit
    function onDeposit(
        address sender,
        uint256 assets,
        address receiver
    )
        external
        returns (uint256 shares, uint256 fees);

    /// @notice Handle minting of shares and distribute assets and fees accordingly
    /// @param sender The address of the sender minting shares
    /// @param shares The amount of shares being minted
    /// @param receiver The address receiving the assets
    /// @return assets The amount of assets corresponding to the minted shares
    /// @return fees The amount of fees collected during the minting
    function onMint(address sender, uint256 shares, address receiver) external returns (uint256 assets, uint256 fees);

    /// @notice Preview the number of shares that will be minted for a given amount of assets
    /// @param assets The amount of assets to be deposited
    /// @return shares The estimated number of shares to be minted
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /// @notice Preview the total amount of assets (including fees) for a given number of shares
    /// @param shares The amount of shares to be minted
    /// @return assets The estimated total amount of assets (including fees) for the given shares
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /// @notice Calculate the maximum deposit amount based on the given ceiling
    /// @param receiver The address receiving the shares
    /// @param ceiling The maximum allowed total assets
    /// @return assets The maximum deposit amount under the given ceiling
    function maxDeposit(address receiver, uint256 ceiling) external view returns (uint256 assets);

    /// @notice Calculate the maximum number of shares that can be minted based on the given ceiling
    /// @param receiver The address receiving the assets
    /// @param ceiling The maximum allowed total assets
    /// @return shares The maximum number of shares that can be minted under the given ceiling
    function maxMint(address receiver, uint256 ceiling) external view returns (uint256 shares);

    /// @notice Set the deposit fee rate
    /// @param _depositFeeRate The new deposit fee rate
    function setDepositFeeRate(uint256 _depositFeeRate) external;
}