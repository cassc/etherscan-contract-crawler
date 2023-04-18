// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

/**
 * @title IVault
 * @author Spice Finance Inc
 */
interface IVault {
    /**********/
    /* Events */
    /**********/

    /// @notice Emitted when receipt tokens are redeemed
    /// @param account Redeeming account
    /// @param shares Amount of receipt token burned
    /// @param assets Amount of asset tokens
    event Redeemed(address indexed account, uint256 shares, uint256 assets);

    /// @notice Emitted when redeemed asset tokens are withdrawn
    /// @param account Withdrawing account
    /// @param assets Amount of asset tokens withdrawn
    event Withdrawn(address indexed account, uint256 assets);

    /******************/
    /* User Functions */
    /******************/

    /// @notice Deposit with eth
    /// @param receiver The account that will receive shares 
    function depositETH(
        address receiver
    ) external payable returns (uint256 shares);

    /// @notice Mint with eth
    /// @param shares The amount of receipt tokens to mint
    /// @param receiver The account that will receive shares 
    function mintETH(
        uint256 shares,
        address receiver
    ) external payable returns (uint256 assets);

    /// @notice Withdraw eth from the pool
    /// @param shares The amount of shares to redeem
    /// @param receiver The account that will receive eth
    /// @param owner The account that will pay shares
    function redeemETH(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);

    /// @notice Withdraw eth from the pool
    /// @param assets The amount of eth being withdrawn
    /// @param receiver The account that will receive eth
    /// @param owner The account that will pay shares
    function withdrawETH(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);
}