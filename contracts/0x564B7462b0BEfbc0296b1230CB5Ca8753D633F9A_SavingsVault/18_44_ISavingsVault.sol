// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

import "../external/notional/interfaces/IWrappedfCashFactory.sol";
import { IWrappedfCashComplete } from "../external/notional/interfaces/IWrappedfCash.sol";

/// @title Savings vault interface
/// @notice Describes functions for setting the vault state
interface ISavingsVault {
    struct NotionalMarket {
        uint maturity;
        uint oracleRate;
    }

    /// @dev Emitted when minting fCash during harvest
    /// @param _fCashPosition Address of wrappedFCash token
    /// @param _assetAmount Amount of asset spent
    /// @param _fCashAmount Amount of fCash minted
    event FCashMinted(IWrappedfCashComplete indexed _fCashPosition, uint _assetAmount, uint _fCashAmount);

    /// @notice Initializes SavingsVault
    /// @param _name Name of the vault
    /// @param _symbol Symbol of the vault
    /// @param _asset Underlying asset which the vault holds
    /// @param _currencyId Currency id of the asset at Notional
    /// @param _wrappedfCashFactory Address of the deployed fCashFactory
    /// @param _notionalRouter Address of the deployed notional router
    /// @param _maxLoss Maximum loss allowed
    /// @param _feeRecipient Address of the feeRecipient
    function initialize(
        string memory _name,
        string memory _symbol,
        address _asset,
        uint16 _currencyId,
        IWrappedfCashFactory _wrappedfCashFactory,
        address _notionalRouter,
        uint16 _maxLoss,
        address _feeRecipient
    ) external;

    /// @notice Sets maxLoss
    /// @dev Max loss range is [0 - 10_000]
    /// @param _maxLoss Maximum loss allowed
    function setMaxLoss(uint16 _maxLoss) external;

    /// @notice Sets feeRecipient
    /// @param _feeRecipient Address of new feeRecipient
    function setFeeRecipient(address _feeRecipient) external;

    /// @notice Mints savings vault shares in exchange for assets withdrawn from the sender
    /// @param _assets Amount of assets to deposit
    /// @param _receiver Address which receives the minted shares
    /// @param _deadline Maximum unix timestamp at which the signature is still valid
    /// @param _v Last byte of the signed data
    /// @param _r The first 64 bytes of the signed data
    /// @param _s Bytes [64…128] of the signed data
    /// @return Amount of savings vault shares to be minted for the given assets
    function depositWithPermit(
        uint _assets,
        address _receiver,
        uint _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external returns (uint);

    /// @notice Redeems savings vault shares in exchange for assets
    /// @param _shares Amount shares to burn
    /// @param _receiver Address which receives the assets
    /// @param _owner Address which owns the shares
    /// @param _minOutputAmount Minimum amount of assets to receive
    /// @return Amount of assets received for the given shares
    function redeemWithMinOutputAmount(
        uint _shares,
        address _receiver,
        address _owner,
        uint _minOutputAmount
    ) external returns (uint);

    /// @notice Settles any fCash positions if they have matured
    function settleAccount() external;
}