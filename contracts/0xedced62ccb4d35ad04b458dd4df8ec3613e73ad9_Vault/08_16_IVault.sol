// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../../utils/DataTypes.sol";

/// @title NF3 Vault Interface
/// @author NF3 Exchange
/// @dev This interface defines all the functions related to assets transfer and assets escrow.

interface IVault {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    enum VaultErrorCodes {
        CALLER_NOT_APPROVED,
        FAILED_TO_SEND_ETH,
        ETH_NOT_ALLOWED,
        INVALID_ASSET_TYPE,
        COULD_NOT_RECEIVE_KITTY,
        COULD_NOT_SEND_KITTY,
        INVALID_PUNK,
        COULD_NOT_RECEIVE_PUNK,
        COULD_NOT_SEND_PUNK,
        INVALID_ADDRESS,
        COULD_NOT_TRANSFER_SELLER_FEES,
        COULD_NOT_TRANSFER_BUYER_FEES
    }

    error VaultError(VaultErrorCodes code);

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /// @dev Emits when the assets have transferred.
    /// @param assets Assets
    /// @param from Sender address
    /// @param to Receiver address
    event AssetsTransferred(Assets assets, address from, address to);

    /// @dev Emits when the assets have been received by the vault.
    /// @param assets Assets
    /// @param from Sender address
    event AssetsReceived(Assets assets, address from);

    /// @dev Emits when the assets have been sent by the vault.
    /// @param assets Assets
    /// @param to Receiver address
    event AssetsSent(Assets assets, address to);

    /// @dev Emits when new storage registry address has set.
    /// @param oldStorageRegistryAddress Previous storage registry contract address
    /// @param newStorageRegistryAddress New storage registry contract address
    event StorageRegistrySet(
        address oldStorageRegistryAddress,
        address newStorageRegistryAddress
    );

    /// @dev Emits when fee is paid in a trade or reservation
    /// @param sellerFee Fee paid from seller's end
    /// @param seller address of the seller
    /// @param buyerFee Fee paid from buyer's end
    /// @param buyer address of the buyer
    event FeesPaid(
        Fees sellerFee,
        address seller,
        Fees buyerFee,
        address buyer
    );

    /// -----------------------------------------------------------------------
    /// Transfer actions
    /// -----------------------------------------------------------------------

    /// @dev Transfer the assets "assets" from "from" to "to".
    /// @param assets Assets to be transfered
    /// @param from Sender address
    /// @param to Receiver address
    /// @param royalty Royalty info
    /// @param allowEth Bool variable if can send ETH or not
    function transferAssets(
        Assets calldata assets,
        address from,
        address to,
        Royalty calldata royalty,
        bool allowEth
    ) external;

    /// @dev Receive assets "assets" from "from" address to the vault
    /// @param assets Assets to be transfered
    /// @param from Sender address
    function receiveAssets(
        Assets calldata assets,
        address from,
        bool allowEth
    ) external;

    /// @dev Send assets "assets" from the vault to "_to" address
    /// @param assets Assets to be transfered
    /// @param to Receiver address
    /// @param royalty Royalty info
    function sendAssets(
        Assets calldata assets,
        address to,
        Royalty calldata royalty,
        bool allowEth
    ) external;

    /// @dev Transfer fees from seller and buyer to the mentioned addresses
    /// @param sellerFees Fees to be taken from the seller
    /// @param buyerFees Fees to be taken from the buyer
    /// @param seller Seller's address
    /// @param buyer Buyer's address
    function transferFees(
        Fees calldata sellerFees,
        address seller,
        Fees calldata buyerFees,
        address buyer
    ) external;

    /// -----------------------------------------------------------------------
    /// Owner actions
    /// -----------------------------------------------------------------------

    /// @dev Set Storage registry contract address
    /// @param _storageRegistryAddress storage registry contract address
    function setStorageRegistry(address _storageRegistryAddress) external;

    /// @dev Set upper limit for fee that can be deducted
    /// @param tokens Addresses of payment tokens for fees
    /// @param caps Upper limit for payment tokens respectively
    function setFeeCap(address[] memory tokens, uint256[] memory caps) external;
}