// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "@openzeppelin/contracts-upgradeable-0.7.2/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable-0.7.2/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-0.7.2/token/ERC721/IERC721.sol";
import "./storage/SuperRareBazaarStorage.sol";
import "./ISuperRareBazaar.sol";

/// @author koloz
/// @title SuperRareBazaar
/// @notice The unified contract for the bazaar logic (Marketplace and Auction House).
/// @dev All storage is inherrited and append only (no modifications) to make upgrade compliant.
contract SuperRareBazaar is
    ISuperRareBazaar,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    SuperRareBazaarStorage
{
    /////////////////////////////////////////////////////////////////////////
    // Initializer
    /////////////////////////////////////////////////////////////////////////
    function initialize(
        address _marketplaceSettings,
        address _royaltyRegistry,
        address _royaltyEngine,
        address _superRareMarketplace,
        address _superRareAuctionHouse,
        address _spaceOperatorRegistry,
        address _approvedTokenRegistry,
        address _payments,
        address _stakingRegistry,
        address _networkBeneficiary
    ) public initializer {
        require(_marketplaceSettings != address(0));
        require(_royaltyRegistry != address(0));
        require(_royaltyEngine != address(0));
        require(_superRareMarketplace != address(0));
        require(_superRareAuctionHouse != address(0));
        require(_spaceOperatorRegistry != address(0));
        require(_approvedTokenRegistry != address(0));
        require(_payments != address(0));
        require(_networkBeneficiary != address(0));

        marketplaceSettings = IMarketplaceSettings(_marketplaceSettings);
        royaltyRegistry = IERC721CreatorRoyalty(_royaltyRegistry);
        royaltyEngine = IRoyaltyEngineV1(_royaltyEngine);
        superRareMarketplace = _superRareMarketplace;
        superRareAuctionHouse = _superRareAuctionHouse;
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

    /////////////////////////////////////////////////////////////////////////
    // Admin Functions
    /////////////////////////////////////////////////////////////////////////
    function setMarketplaceSettings(address _marketplaceSettings)
        external
        onlyOwner
    {
        require(_marketplaceSettings != address(0));
        marketplaceSettings = IMarketplaceSettings(_marketplaceSettings);
    }

    function setRoyaltyRegistry(address _royaltyRegistry) external onlyOwner {
        require(_royaltyRegistry != address(0));
        royaltyRegistry = IERC721CreatorRoyalty(_royaltyRegistry);
    }

    function setRoyaltyEngine(address _royaltyEngine) external onlyOwner {
        require(_royaltyEngine != address(0));
        royaltyEngine = IRoyaltyEngineV1(_royaltyEngine);
    }

    function setSuperRareMarketplace(address _superRareMarketplace)
        external
        onlyOwner
    {
        require(_superRareMarketplace != address(0));
        superRareMarketplace = _superRareMarketplace;
    }

    function setSuperRareAuctionHouse(address _superRareAuctionHouse)
        external
        onlyOwner
    {
        require(_superRareAuctionHouse != address(0));
        superRareAuctionHouse = _superRareAuctionHouse;
    }

    function setSpaceOperatorRegistry(address _spaceOperatorRegistry)
        external
        onlyOwner
    {
        require(_spaceOperatorRegistry != address(0));
        spaceOperatorRegistry = ISpaceOperatorRegistry(_spaceOperatorRegistry);
    }

    function setApprovedTokenRegistry(address _approvedTokenRegistry)
        external
        onlyOwner
    {
        require(_approvedTokenRegistry != address(0));
        approvedTokenRegistry = IApprovedTokenRegistry(_approvedTokenRegistry);
    }

    function setPayments(address _payments) external onlyOwner {
        require(_payments != address(0));
        payments = IPayments(_payments);
    }

    function setStakingRegistry(address _stakingRegistry) external onlyOwner {
        require(_stakingRegistry != address(0));
        stakingRegistry = _stakingRegistry;
    }

    function setNetworkBeneficiary(address _networkBeneficiary)
        external
        onlyOwner
    {
        require(_networkBeneficiary != address(0));
        networkBeneficiary = _networkBeneficiary;
    }

    function setMinimumBidIncreasePercentage(
        uint8 _minimumBidIncreasePercentage
    ) external onlyOwner {
        minimumBidIncreasePercentage = _minimumBidIncreasePercentage;
    }

    function setMaxAuctionLength(uint8 _maxAuctionLength) external onlyOwner {
        maxAuctionLength = _maxAuctionLength;
    }

    function setAuctionLengthExtension(uint256 _auctionLengthExtension)
        external
        onlyOwner
    {
        auctionLengthExtension = _auctionLengthExtension;
    }

    function setOfferCancelationDelay(uint256 _offerCancelationDelay)
        external
        onlyOwner
    {
        offerCancelationDelay = _offerCancelationDelay;
    }

    /////////////////////////////////////////////////////////////////////////
    // Marketplace Functions
    /////////////////////////////////////////////////////////////////////////

    /// @notice Place an offer for a given asset
    /// @dev Notice we need to verify that the msg sender has approved us to move funds on their behalf.
    /// @dev Covers use of any currency (0 address is eth).
    /// @dev _amount is the amount of the offer excluding the marketplace fee.
    /// @dev There can be multiple offers of different currencies, but only 1 per currency.
    /// @param _originContract Contract address of the asset being listed.
    /// @param _tokenId Token Id of the asset.
    /// @param _currencyAddress Address of the token being offered.
    /// @param _amount Amount being offered.
    /// @param _convertible If the offer can be converted into an auction
    function offer(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount,
        bool _convertible
    ) external payable override {
        (bool success, bytes memory data) = superRareMarketplace.delegatecall(
            abi.encodeWithSelector(
                this.offer.selector,
                _originContract,
                _tokenId,
                _currencyAddress,
                _amount,
                _convertible
            )
        );

        require(success, string(data));
    }

    /// @notice Purchases the token for the current sale price.
    /// @dev Covers use of any currency (0 address is eth).
    /// @dev Need to verify that the buyer (if not using eth) has the marketplace approved for _currencyContract.
    /// @dev Need to verify that the seller has the marketplace approved for _originContract.
    /// @param _originContract Contract address for asset being bought.
    /// @param _tokenId TokenId of asset being bought.
    /// @param _currencyAddress Currency address of asset being used to buy.
    /// @param _amount Amount the piece if being bought for (including marketplace fee).
    function buy(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount
    ) external payable override {
        (bool success, bytes memory data) = superRareMarketplace.delegatecall(
            abi.encodeWithSelector(
                this.buy.selector,
                _originContract,
                _tokenId,
                _currencyAddress,
                _amount
            )
        );

        require(success, string(data));
    }

    /// @notice Cancels an existing offer the sender has placed on a piece.
    /// @param _originContract Contract address of token.
    /// @param _tokenId TokenId that has an offer.
    /// @param _currencyAddress Currency address of the offer.
    function cancelOffer(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress
    ) external override {
        (bool success, bytes memory data) = superRareMarketplace.delegatecall(
            abi.encodeWithSelector(
                this.cancelOffer.selector,
                _originContract,
                _tokenId,
                _currencyAddress
            )
        );

        require(success, string(data));
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
        (bool success, bytes memory data) = superRareMarketplace.delegatecall(
            abi.encodeWithSelector(
                this.setSalePrice.selector,
                _originContract,
                _tokenId,
                _currencyAddress,
                _listPrice,
                _target,
                _splitAddresses,
                _splitRatios
            )
        );

        require(success, string(data));
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
    ) external override {
        (bool success, bytes memory data) = superRareMarketplace.delegatecall(
            abi.encodeWithSelector(
                this.acceptOffer.selector,
                _originContract,
                _tokenId,
                _currencyAddress,
                _amount,
                _splitAddresses,
                _splitRatios
            )
        );

        require(success, string(data));
    }

    /////////////////////////////////////////////////////////////////////////
    // Auction House Functions
    /////////////////////////////////////////////////////////////////////////

    /// @notice Configures an Auction for a given asset.
    /// @dev If auction type is coldie (reserve) then _startingAmount cant be 0.
    /// @dev _currencyAddress equal to the zero address denotes eth.
    /// @dev All time related params are unix epoch timestamps.
    /// @param _auctionType The type of auction being configured.
    /// @param _originContract Contract address of the asset being put up for auction.
    /// @param _tokenId Token Id of the asset.
    /// @param _startingAmount The reserve price or min bid of an auction.
    /// @param _currencyAddress The currency the auction is being conducted in.
    /// @param _lengthOfAuction The amount of time in seconds that the auction is configured for.
    /// @param _splitAddresses Addresses to split the sellers commission with.
    /// @param _splitRatios The ratio for the split corresponding to each of the addresses being split with.
    function configureAuction(
        bytes32 _auctionType,
        address _originContract,
        uint256 _tokenId,
        uint256 _startingAmount,
        address _currencyAddress,
        uint256 _lengthOfAuction,
        uint256 _startTime,
        address payable[] calldata _splitAddresses,
        uint8[] calldata _splitRatios
    ) external override {
        (bool success, bytes memory data) = superRareAuctionHouse.delegatecall(
            abi.encodeWithSelector(
                this.configureAuction.selector,
                _auctionType,
                _originContract,
                _tokenId,
                _startingAmount,
                _currencyAddress,
                _lengthOfAuction,
                _startTime,
                _splitAddresses,
                _splitRatios
            )
        );

        require(success, string(data));
    }

    /// @notice Converts an offer into a coldie auction.
    /// @dev Covers use of any currency (0 address is eth).
    /// @dev Only covers converting an offer to a coldie auction.
    /// @dev Cant convert offer if an auction currently exists.
    /// @param _originContract Contract address of the asset.
    /// @param _tokenId Token Id of the asset.
    /// @param _currencyAddress Address of the currency being converted.
    /// @param _amount Amount being converted into an auction.
    /// @param _lengthOfAuction Number of seconds the auction will last.
    /// @param _splitAddresses Addresses that the sellers take in will be split amongst.
    /// @param _splitRatios Ratios that the take in will be split by.
    function convertOfferToAuction(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount,
        uint256 _lengthOfAuction,
        address payable[] calldata _splitAddresses,
        uint8[] calldata _splitRatios
    ) external override {
        (bool success, bytes memory data) = superRareAuctionHouse.delegatecall(
            abi.encodeWithSelector(
                this.convertOfferToAuction.selector,
                _originContract,
                _tokenId,
                _currencyAddress,
                _amount,
                _lengthOfAuction,
                _splitAddresses,
                _splitRatios
            )
        );

        require(success, string(data));
    }

    /// @notice Cancels a configured Auction that has not started.
    /// @dev Requires the person sending the message to be the auction creator or token owner.
    /// @param _originContract Contract address of the asset pending auction.
    /// @param _tokenId Token Id of the asset.
    function cancelAuction(address _originContract, uint256 _tokenId)
        external
        override
    {
        (bool success, bytes memory data) = superRareAuctionHouse.delegatecall(
            abi.encodeWithSelector(
                this.cancelAuction.selector,
                _originContract,
                _tokenId
            )
        );

        require(success, string(data));
    }

    /// @notice Places a bid on a valid auction.
    /// @dev Only the configured currency can be used (Zero address for eth)
    /// @param _originContract Contract address of asset being bid on.
    /// @param _tokenId Token Id of the asset.
    /// @param _currencyAddress Address of currency being used to bid.
    /// @param _amount Amount of the currency being used for the bid.
    function bid(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount
    ) external payable override {
        (bool success, bytes memory data) = superRareAuctionHouse.delegatecall(
            abi.encodeWithSelector(
                this.bid.selector,
                _originContract,
                _tokenId,
                _currencyAddress,
                _amount
            )
        );

        require(success, string(data));
    }

    /// @notice Settles an auction that has ended.
    /// @dev Anyone is able to settle an auction since non-input params are used.
    /// @param _originContract Contract address of asset.
    /// @param _tokenId Token Id of the asset.
    function settleAuction(address _originContract, uint256 _tokenId)
        external
        override
    {
        (bool success, bytes memory data) = superRareAuctionHouse.delegatecall(
            abi.encodeWithSelector(
                this.settleAuction.selector,
                _originContract,
                _tokenId
            )
        );

        require(success, string(data));
    }

    /// @notice Grabs the current auction details for a token.
    /// @param _originContract Contract address of asset.
    /// @param _tokenId Token Id of the asset.
    /** @return Auction Struct: creatorAddress, creationTime, startingTime, lengthOfAuction,
                currencyAddress, minimumBid, auctionType, splitRecipients array, and splitRatios array.
    */
    function getAuctionDetails(address _originContract, uint256 _tokenId)
        external
        view
        override
        returns (
            address,
            uint256,
            uint256,
            uint256,
            address,
            uint256,
            bytes32,
            address payable[] memory,
            uint8[] memory
        )
    {
        Auction memory auction = tokenAuctions[_originContract][_tokenId];

        return (
            auction.auctionCreator,
            auction.creationBlock,
            auction.startingTime,
            auction.lengthOfAuction,
            auction.currencyAddress,
            auction.minimumBid,
            auction.auctionType,
            auction.splitRecipients,
            auction.splitRatios
        );
    }

    function getSalePrice(
        address _originContract,
        uint256 _tokenId,
        address _target
    )
        external
        view
        override
        returns (
            address,
            address,
            uint256,
            address payable[] memory,
            uint8[] memory
        )
    {
        SalePrice memory sp = tokenSalePrices[_originContract][_tokenId][
            _target
        ];

        return (
            sp.seller,
            sp.currencyAddress,
            sp.amount,
            sp.splitRecipients,
            sp.splitRatios
        );
    }
}