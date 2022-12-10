// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "@openzeppelin/contracts-upgradeable-0.7.2/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable-0.7.2/utils/ReentrancyGuardUpgradeable.sol";
import "./ISuperRareMarketplace.sol";
import "../SuperRareBazaarBase.sol";

/// @author koloz
/// @title SuperRareMarketplace
/// @notice The logic for all functions related to the SuperRareMarketplace.
contract SuperRareMarketplace is
    ISuperMarketplace,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    SuperRareBazaarBase
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /////////////////////////////////////////////////////////////////////////
    // Initializer
    /////////////////////////////////////////////////////////////////////////
    function initialize(
        address _marketplaceSettings,
        address _royaltyEngine,
        address _royaltyRegistry,
        address _spaceOperatorRegistry,
        address _approvedTokenRegistry,
        address _payments,
        address _stakingRegistry,
        address _networkBeneficiary
    ) public initializer {
        require(_marketplaceSettings != address(0));
        require(_royaltyRegistry != address(0));
        require(_royaltyEngine != address(0));
        require(_spaceOperatorRegistry != address(0));
        require(_approvedTokenRegistry != address(0));
        require(_payments != address(0));
        require(_networkBeneficiary != address(0));

        marketplaceSettings = IMarketplaceSettings(_marketplaceSettings);
        royaltyRegistry = IERC721CreatorRoyalty(_royaltyRegistry);
        royaltyEngine = IRoyaltyEngineV1(_royaltyEngine);
        spaceOperatorRegistry = ISpaceOperatorRegistry(_spaceOperatorRegistry);
        approvedTokenRegistry = IApprovedTokenRegistry(_approvedTokenRegistry);
        payments = IPayments(_payments);
        stakingRegistry = _stakingRegistry;
        networkBeneficiary = _networkBeneficiary;

        minimumBidIncreasePercentage = 10;
        maxAuctionLength = 7 days;
        auctionLengthExtension = 15 minutes;
        offerCancelationDelay = 5 minutes;

        __Ownable_init();
        __ReentrancyGuard_init();
    }

    /// @notice Place an offer for a given asset
    /// @dev Notice we need to verify that the msg sender has approved us to move funds on their behalf.
    /// @dev Covers use of any currency (0 address is eth).
    /// @dev _amount is the amount of the offer excluding the marketplace fee.
    /// @dev There can be multiple offers of different currencies, but only 1 per currency.
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
    ) external payable override nonReentrant {
        _checkIfCurrencyIsApproved(_currencyAddress);
        require(_amount > 0, "offer::Amount cannot be 0");

        Offer memory currOffer = tokenCurrentOffers[_originContract][_tokenId][
            _currencyAddress
        ];

        require(
            _amount >=
                currOffer.amount.add(
                    currOffer.amount.mul(minimumBidIncreasePercentage).div(100)
                ),
            "offer::Must be greater than prev offer + min increase"
        );

        uint256 requiredAmount = _amount.add(
            marketplaceSettings.calculateMarketplaceFee(_amount)
        );

        _senderMustHaveMarketplaceApproved(_currencyAddress, requiredAmount);

        _checkAmountAndTransfer(_currencyAddress, requiredAmount);

        IERC721 erc721 = IERC721(_originContract);
        require(
            erc721.ownerOf(_tokenId) != msg.sender,
            "offer::Offer cannot come from owner"
        );

        _refund(
            _currencyAddress,
            currOffer.amount,
            currOffer.marketplaceFee,
            currOffer.buyer
        );

        tokenCurrentOffers[_originContract][_tokenId][_currencyAddress] = Offer(
            msg.sender,
            _amount,
            block.timestamp,
            marketplaceSettings.getMarketplaceFeePercentage(),
            _convertible
        );

        emit OfferPlaced(
            _originContract,
            msg.sender,
            _currencyAddress,
            _amount,
            _tokenId,
            _convertible
        );
    }

    /// @notice Purchases the token for the current sale price.
    /// @dev Covers use of any currency (0 address is eth).
    /// @dev Need to verify that the buyer (if not using eth) has the marketplace approved for _currencyContract.
    /// @dev Need to verify that the seller has the marketplace approved for _originContract.
    /// @param _originContract Contract address for asset being bought.
    /// @param _tokenId TokenId of asset being bought.
    /// @param _currencyAddress Currency address of asset being used to buy.
    /// @param _amount Amount the piece if being bought for (excluding marketplace fee).
    function buy(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount
    ) external payable override nonReentrant {
        _ownerMustHaveMarketplaceApprovedForNFT(_originContract, _tokenId);

        uint256 requiredAmount = _amount.add(
            marketplaceSettings.calculateMarketplaceFee(_amount)
        );

        mapping(address => SalePrice) storage salePrices = tokenSalePrices[
            _originContract
        ][_tokenId];

        SalePrice memory sp = salePrices[msg.sender].amount != 0
            ? salePrices[msg.sender]
            : salePrices[address(0)];

        require(sp.amount > 0, "buy::Token has no buy now price");

        require(
            sp.currencyAddress == _currencyAddress,
            "buy::Currency address mismatch"
        );

        IERC721 erc721 = IERC721(_originContract);
        address tokenOwner = erc721.ownerOf(_tokenId);

        require(tokenOwner == sp.seller, "buy::Price setter not owner");

        require(_amount == sp.amount, "buy::Insufficient amount");

        delete tokenSalePrices[_originContract][_tokenId][msg.sender];
        delete tokenSalePrices[_originContract][_tokenId][address(0)];

        _checkAmountAndTransfer(_currencyAddress, requiredAmount);

        Offer memory currOffer = tokenCurrentOffers[_originContract][_tokenId][
            _currencyAddress
        ];

        if (currOffer.buyer == msg.sender) {
            delete tokenCurrentOffers[_originContract][_tokenId][
                _currencyAddress
            ];

            _refund(
                _currencyAddress,
                currOffer.amount,
                currOffer.marketplaceFee,
                msg.sender
            );
        }

        erc721.safeTransferFrom(tokenOwner, msg.sender, _tokenId);

        _payout(
            _originContract,
            _tokenId,
            _currencyAddress,
            _amount,
            sp.seller,
            sp.splitRecipients,
            sp.splitRatios
        );

        marketplaceSettings.markERC721Token(_originContract, _tokenId, true);

        emit Sold(
            _originContract,
            msg.sender,
            sp.seller,
            _currencyAddress,
            _amount,
            _tokenId
        );
    }

    /// @notice Cancels an existing offer the sender has placed on a piece.
    /// @param _originContract Contract address of token.
    /// @param _tokenId TokenId that has an offer.
    /// @param _currencyAddress Currency address of the offer.
    function cancelOffer(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress
    ) external override nonReentrant {
        Offer memory currOffer = tokenCurrentOffers[_originContract][_tokenId][
            _currencyAddress
        ];

        require(
            currOffer.amount != 0,
            "cancelOffer::No offer for currency exists."
        );

        require(
            currOffer.buyer == msg.sender,
            "cancelOffer::Sender must have placed the offer."
        );

        require(
            block.timestamp - currOffer.timestamp > offerCancelationDelay,
            "Offer placed too recently."
        );

        delete tokenCurrentOffers[_originContract][_tokenId][_currencyAddress];

        _refund(
            _currencyAddress,
            currOffer.amount,
            currOffer.marketplaceFee,
            currOffer.buyer
        );

        emit CancelOffer(
            _originContract,
            msg.sender,
            _currencyAddress,
            currOffer.amount,
            _tokenId
        );
    }

    /// @notice Sets a sale price for the given asset(s) directed at the _target address.
    /// @dev Covers use of any currency (0 address is eth).
    /// @dev Sale price for everyone is denoted as the 0 address.
    /// @dev Only 1 currency can be used for the sale price directed at a speicific target.
    /// @dev _listPrice of 0 signifies removing the list price for the provided currency.
    /// @dev This function can be used for counter offers as well.
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
    ) external override {
        _checkIfCurrencyIsApproved(_currencyAddress);
        _senderMustBeTokenOwner(_originContract, _tokenId);
        _ownerMustHaveMarketplaceApprovedForNFT(_originContract, _tokenId);
        _checkSplits(_splitAddresses, _splitRatios);

        tokenSalePrices[_originContract][_tokenId][_target] = SalePrice(
            payable(msg.sender),
            _currencyAddress,
            _listPrice,
            _splitAddresses,
            _splitRatios
        );

        emit SetSalePrice(
            _originContract,
            _currencyAddress,
            _target,
            _listPrice,
            _tokenId,
            _splitAddresses,
            _splitRatios
        );
    }

    /// @notice Removes the current sale price of an asset for _target for the given currency.
    /// @dev Sale prices could still exist for different currencies.
    /// @dev Sale prices could still exist for different targets.
    /// @dev Zero address for _currency means that its listed in ether.
    /// @dev _target of zero address is the general sale price.
    /// @param _originContract The origin contract of the asset.
    /// @param _tokenId The tokenId of the asset within the _originContract.
    /// @param _target The address of the person
    function removeSalePrice(
        address _originContract,
        uint256 _tokenId,
        address _target
    ) external override {
        IERC721 erc721 = IERC721(_originContract);
        address tokenOwner = erc721.ownerOf(_tokenId);

        require(
            msg.sender == tokenOwner,
            "removeSalePrice::Must be tokenOwner."
        );

        delete tokenSalePrices[_originContract][_tokenId][_target];

        emit SetSalePrice(
            _originContract,
            address(0),
            address(0),
            0,
            _tokenId,
            new address payable[](0),
            new uint8[](0)
        );
    }

    /// @notice Accept an offer placed on _originContract : _tokenId.
    /// @dev Zero address for _currency means that the offer being accepted is in ether.
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
    ) external override nonReentrant {
        _senderMustBeTokenOwner(_originContract, _tokenId);
        _ownerMustHaveMarketplaceApprovedForNFT(_originContract, _tokenId);
        _checkSplits(_splitAddresses, _splitRatios);

        Offer memory currOffer = tokenCurrentOffers[_originContract][_tokenId][
            _currencyAddress
        ];

        require(currOffer.amount != 0, "acceptOffer::No offer exists");

        require(
            currOffer.amount == _amount,
            "acceptOffer::Offer amount or currency not equal"
        );

        delete tokenSalePrices[_originContract][_tokenId][address(0)];

        delete tokenCurrentOffers[_originContract][_tokenId][_currencyAddress];

        IERC721 erc721 = IERC721(_originContract);
        erc721.safeTransferFrom(msg.sender, currOffer.buyer, _tokenId);

        _payout(
            _originContract,
            _tokenId,
            _currencyAddress,
            _amount,
            msg.sender,
            _splitAddresses,
            _splitRatios
        );

        marketplaceSettings.markERC721Token(_originContract, _tokenId, true);

        emit AcceptOffer(
            _originContract,
            currOffer.buyer,
            msg.sender,
            _currencyAddress,
            _amount,
            _tokenId,
            _splitAddresses,
            _splitRatios
        );
    }
}