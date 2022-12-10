// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

/// @author koloz
/// @title ISuperRareMarketplace
/// @notice The interface for the SuperRareMarketplace Functions.
interface ISuperMarketplace {
    /// @notice Place an offer for a given asset
    /// @param _originContract Contract address of the asset being listed.
    /// @param _tokenId Token Id of the asset.
    /// @param _currencyAddress Address of the token being offered.
    /// @param _amount Amount being offered (excluding marketplace fee).
    /// @param _convertible If the offer can be converted into an auction
    function offer(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount,
        bool _convertible
    ) external payable;

    /// @notice Purchases the token for the current sale price.
    /// @param _originContract Contract address for asset being bought.
    /// @param _tokenId TokenId of asset being bought.
    /// @param _currencyAddress Currency address of asset being used to buy.
    /// @param _amount Amount the piece if being bought for (excluding marketplace fee).
    function buy(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount
    ) external payable;

    /// @notice Cancels an existing offer the sender has placed on a piece.
    /// @param _originContract Contract address of token.
    /// @param _tokenId TokenId that has an offer.
    /// @param _currencyAddress Currency address of the offer.
    function cancelOffer(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress
    ) external;

    /// @notice Sets a sale price for the given asset(s) directed at the _target address.
    /// @param _originContract Contract address of the asset being listed.
    /// @param _tokenId Token Id of the asset.
    /// @param _currencyAddress Contract address of the currency asset is being listed for.
    /// @param _listPrice Amount of the currency the asset is being listed for (including all decimal points).
    /// @param _target Address of the person this sale price is target to.
    /// @param _splitAddresses Addresses to split the sellers commission with.
    /// @param _splitRatios The ratio for the split corresponding to each of the addresses being split with.
    function setSalePrice(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _listPrice,
        address _target,
        address payable[] calldata _splitAddresses,
        uint8[] calldata _splitRatios
    ) external;

    /// @notice Removes the current sale price of an asset for _target for the given currency.
    /// @param _originContract The origin contract of the asset.
    /// @param _tokenId The tokenId of the asset within the _originContract.
    /// @param _target The address of the person
    function removeSalePrice(
        address _originContract,
        uint256 _tokenId,
        address _target
    ) external;

    /// @notice Accept an offer placed on _originContract : _tokenId.
    /// @param _originContract Contract of the asset the offer was made on.
    /// @param _tokenId TokenId of the asset.
    /// @param _currencyAddress Address of the currency used for the offer.
    /// @param _amount Amount the offer was for/and is being accepted.
    /// @param _splitAddresses Addresses to split the sellers commission with.
    /// @param _splitRatios The ratio for the split corresponding to each of the addresses being split with.
    function acceptOffer(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount,
        address payable[] calldata _splitAddresses,
        uint8[] calldata _splitRatios
    ) external;
}