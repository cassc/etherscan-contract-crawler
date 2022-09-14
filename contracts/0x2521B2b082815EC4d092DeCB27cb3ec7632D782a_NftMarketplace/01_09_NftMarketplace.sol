// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @notice Thrown when state of contract is equal to the one specified
error NftMarketplace__StateIsNot(uint256 state);
/// @notice Thrown when state of contract is not equal to the one specified
error NftMarketplace__StateIs(uint256 state);
/// @notice Thrown when the token (erc20) is not listed as payment token
error NftMarketplace__TokenNotListed(address tokenAddress);
/// @notice Thrown when price is below or equal to zero
error NftMarketplace__PriceMustBeAboveZero();
/// @notice Thrown when market is not approved to transfer `tokenId` of `nftAddress`
error NftMarketplace__NotApprovedForNft(address nftAddress, uint256 tokenId);
/// @notice Thrown when `tokenId` of `nftAddress` is already listed on market
error NftMarketplace__AlreadyListed(address nftAddress, uint256 tokenId);
/// @notice Thrown when `tokenId` of `nftAddress` is not listed on market
error NftMarketplace__NftNotListed(address nftAddress, uint256 tokenId);
/// @notice Thrown when caller is not owner of `tokenId` at `nftAddress`
error NftMarketplace__NotOwnerOfNft(address nftAddress, uint256 tokenId);
/// @notice Thrown when caller does not send enough eth to market
error NftMarketplace__NotEnoughFunds();
/// @notice Thrown when allowance of market is less than required
error NftMarketplace__NotEnoughAllowance();
/// @notice Thrown when erc20 token transfer failed
error NftMarketplace__TokenTransferFailed(address tokenAddress);
/// @notice Thrown when eth transfer failed
error NftMarketplace__EthTransferFailed();
/// @notice Thrown when caller has no eligible funds for withdrawal
error NftMarketplace__NoEligibleFunds();
/// @notice Thrown when index does not exist in an array
error NftMarketplace__IndexOutOfBounds();

/**
 * @title NftMarketplace
 * @author Philipp Keinberger
 * @notice This contract is an nft marketplace, where users can list (sell) and buy
 * nfts using eth and erc20 tokens. Payment tokens (e.g. erc20-tokens, accepted by
 * the marketplace as payment for nfts) can be added and removed through access-
 * restricted functions, favourably controlled by a governor contract (e.g. dao) to
 * allow for decentralized governance of the marketplace. The contract is designed
 * to be upgradeable.
 * @dev This contract implements the IERC721 and IERC20 Openzeppelin interfaces for the
 * ERC721 and ERC20 token standards.
 *
 * The Marketplace implements Chainlink price feeds to retrieve prices of listed erc20
 * payment tokens.
 *
 * This contract inherits from Openzeppelins OwnableUpgradeable contract in order to
 * allow owner features, while still keeping upgradeablity functionality. The
 * Marketplace is designed to be deployed through a proxy contract to allow for future
 * upgrades of the contract.
 */
contract NftMarketplace is OwnableUpgradeable {
    /**
     * @dev Defines the state of the contract, allows for state restricted functionality
     * of the contract
     */
    enum MarketState {
        CLOSED,
        UPDATING,
        OPEN
    }

    /// @dev Defines the data structure for a listing (listed nft) on the market
    struct Listing {
        address seller;
        uint256 nftPrice;
        /**
         * @dev Specifies payment tokens accepted by the seller as payments (have to be
         * listed as paymentTokens in `s_paymentTokens`)
         */
        address[] paymentTokenAddresses;
    }

    /**
     * @dev Defines the data structure for a payment token (erc20) to be used as payment
     * for listed nfts
     */
    struct PaymentToken {
        address priceFeedAddress;
        uint8 decimals;
    }

    MarketState private s_marketState;
    /// @dev nftContractAddress => nftTokenId => Listing
    mapping(address => mapping(uint256 => Listing)) private s_listings;
    /// @dev userAddress to eligible eth (in wei) for withdrawal
    mapping(address => uint256) private s_eligibleFunds;
    /// @dev erc20ContractAddress => PaymentToken
    mapping(address => PaymentToken) private s_paymentTokens;

    /// @notice Event emitted when a new nft is listed on the market
    event NftListed(
        address indexed seller,
        address indexed nftAddr,
        uint256 indexed tokenId,
        uint256 price,
        address[] tokensForPayment
    );
    /// @notice Event emitted when an nft is delisted by the seller
    event NftDelisted(address indexed nftAddr, uint256 indexed tokenId);
    /// @notice Event emitted when seller updates the price of an nft
    event NftPriceUpdated(address indexed nftAddr, uint256 indexed tokenId, uint256 indexed price);
    /// @notice Event emitted when seller adds an erc20 token accepted as payment for the nft
    event NftPaymentTokenAdded(
        address indexed nftAddr,
        uint256 indexed tokenId,
        address indexed paymentTokenAddress
    );
    /// @notice Event emitted when seller removes an erc20 token previously accepted as payment for the nft
    event NftPaymentTokenRemoved(
        address indexed nftAddr,
        uint256 indexed tokenId,
        address indexed paymentTokenAddress
    );
    /// @notice Event emitted when an nft is bought
    event NftBought(address nftAddr, uint256 tokenId, address indexed buyer, uint256 indexed price);

    /// @notice Event emitted when a new payment token gets added to the market
    event PaymentTokenAdded(address tokenAddress);
    /// @notice Event emitted when a payment token is removed from the market
    event PaymentTokenRemoved(address tokenAddress);

    /// @notice Checks if market state is equal to `state`
    modifier stateIs(MarketState state) {
        if (state != s_marketState) revert NftMarketplace__StateIsNot(uint256(state));
        _;
    }

    /// @notice Checks if market state is not equal to `state`
    modifier stateIsNot(MarketState state) {
        if (state == s_marketState) revert NftMarketplace__StateIs(uint256(state));
        _;
    }

    /// @notice Checks if nft `tokenId` of `nftAddr` is listed on market
    modifier isListed(address nftAddr, uint256 tokenId) {
        Listing memory l_listing = s_listings[nftAddr][tokenId];
        if (l_listing.nftPrice <= 0) revert NftMarketplace__NftNotListed(nftAddr, tokenId);
        _;
    }

    /// @notice Checks if `shouldBeOwner` is owner of `tokenId` at `nftAddr`
    modifier isNftOwner(
        address shouldBeOwner,
        address nftAddr,
        uint256 tokenId
    ) {
        IERC721 nft = IERC721(nftAddr);
        if (nft.ownerOf(tokenId) != shouldBeOwner)
            revert NftMarketplace__NotOwnerOfNft(nftAddr, tokenId);
        _;
    }

    /// @notice ensures that initialize can only be called through proxy
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializer function which replaces constructor for upgradeability functionality.
     * Sets the msg.sender as owner
     */
    function initialize() public initializer {
        __Ownable_init();
    }

    /**
     * @notice Function for setting the state of the marketplace
     * @param newState Is the new value for the state
     * @dev This function can only be called by the owner
     */
    function setState(MarketState newState) external onlyOwner {
        s_marketState = newState;
    }

    /**
     * @notice Function for adding a payment token (erc20) as payment method for nft
     * purchases using erc20 tokens
     * @param tokenAddress Is the address of the erc20 contract
     * @param priceFeedAddress Is the address of the chainlink price feed for the
     * erc20
     * @param decimals Is the amount of decimals returned by the chainlink price
     * feed
     * @dev This function reverts if the market is CLOSED or the caller is not
     * the owner of the marketplace.
     *
     * Checking if the tokenAddress indeed implements the IERC20 interface is not
     * provided since the function can only be called by the owner, while the owner
     * should be trustworthy enough to check for that beforehand. Main reason for
     * that is gas savings.
     *
     * This function emits the {PaymentTokenAdded} event.
     */
    function addPaymentToken(
        address tokenAddress,
        address priceFeedAddress,
        uint8 decimals
    ) external onlyOwner stateIsNot(MarketState.CLOSED) {
        s_paymentTokens[tokenAddress] = PaymentToken(priceFeedAddress, decimals);

        emit PaymentTokenAdded(tokenAddress);
    }

    /**
     * @notice Function for removing a payment token from the contract
     * @param tokenAddress Is the address of the payment token (erc20) to be removed
     * @dev This function reverts if the market is CLOSED or the caller is not
     * the owner of the marketplace.
     *
     * This function emits the {PaymentTokenRemoved} event.
     */
    function removePaymentToken(address tokenAddress)
        external
        onlyOwner
        stateIsNot(MarketState.CLOSED)
    {
        delete s_paymentTokens[tokenAddress];

        emit PaymentTokenRemoved(tokenAddress);
    }

    /**
     * @notice Function for listing an nft on the marketplace
     * @param nftAddr Is the address of the nft contract
     * @param tokenId Is the token id of the nft
     * @param nftPrice Is the price set by msg.sender for the listing
     * @param allowedPaymentTokens Are payment tokens allowed as
     * payment methods for the nft (optional)
     * @dev This function reverts if the market is not OPEN, the caller is
     * not the owner of `tokenId` at `nftAddr`, or the marketplace is not
     * approved to transfer the nft. The function also reverts if
     * `allowedPaymentTokens` contains an erc20-token, which is not added as
     * a paymentToken on the marketplace. If `allowedPaymentTokens` are not
     * specified, the nft will only be able to be sold using the buyNftEth
     * function.
     *
     * This implementation still lets sellers hold their nft until
     * the item actually gets sold. The buyNft functions will check for
     * allowance to spend the nft still being present when called.
     * This function emits the {NftListed} event.
     */
    function listNft(
        address nftAddr,
        uint256 tokenId,
        uint256 nftPrice,
        address[] calldata allowedPaymentTokens
    ) external stateIs(MarketState.OPEN) isNftOwner(msg.sender, nftAddr, tokenId) {
        IERC721 nft = IERC721(nftAddr);
        if (nft.getApproved(tokenId) != address(this))
            revert NftMarketplace__NotApprovedForNft(nftAddr, tokenId);

        uint256 alreadylistedPrice = s_listings[nftAddr][tokenId].nftPrice;
        if (alreadylistedPrice > 0) revert NftMarketplace__AlreadyListed(nftAddr, tokenId);
        if (nftPrice <= 0) revert NftMarketplace__PriceMustBeAboveZero();

        for (uint256 index = 0; index < allowedPaymentTokens.length; index++) {
            address l_address = allowedPaymentTokens[index];
            PaymentToken memory l_paymentToken = s_paymentTokens[l_address];
            if (l_paymentToken.decimals == 0) revert NftMarketplace__TokenNotListed(l_address);
        }

        s_listings[nftAddr][tokenId] = Listing(msg.sender, nftPrice, allowedPaymentTokens);
        emit NftListed(msg.sender, nftAddr, tokenId, nftPrice, allowedPaymentTokens);
    }

    /**
     * @notice Function for cancelling a listing on the marketplace
     * @param nftAddr Is the address of the nft contract
     * @param tokenId Is the id of the nft
     * @dev This function reverts if the market is not OPEN, the caller
     * is not the owner of `tokenId` at `nftAddr`, or the nft is not
     * listed on the marketplace.
     *
     * This implementation only deletes the listing from the
     * mapping. Sellers have to revoke approval rights for their nft
     * on their own or through a frontend application.
     * This function emits the {NftDelisted} event.
     */
    function cancelListing(address nftAddr, uint256 tokenId)
        external
        stateIs(MarketState.OPEN)
        isNftOwner(msg.sender, nftAddr, tokenId)
        isListed(nftAddr, tokenId)
    {
        delete s_listings[nftAddr][tokenId];

        emit NftDelisted(nftAddr, tokenId);
    }

    /**
     * @notice Function for updating the price of the listing on the marketplace
     * @param nftAddr Is the address of the nft contract
     * @param tokenId Is the id of the nft
     * @param newPrice Is the new price for the nft
     * @dev This function reverts if the market is not OPEN, the caller
     * is not the owner of `tokenId` at `nftAddr`, or the nft is not
     * listed on the marketplace.
     *
     * This function emits the {NftPriceUpdated} event.
     */
    function updateListingPrice(
        address nftAddr,
        uint256 tokenId,
        uint256 newPrice
    )
        external
        stateIs(MarketState.OPEN)
        isNftOwner(msg.sender, nftAddr, tokenId)
        isListed(nftAddr, tokenId)
    {
        if (newPrice <= 0) revert NftMarketplace__PriceMustBeAboveZero();

        s_listings[nftAddr][tokenId].nftPrice = newPrice;
        emit NftPriceUpdated(nftAddr, tokenId, newPrice);
    }

    /**
     * @notice Function for adding a payment token to a listing
     * @param nftAddr Is the address of the nft contract
     * @param tokenId Is the id of the nft
     * @param paymentTokenAddress is the address of the payment token to be
     * added
     * @dev This function reverts if the market is not OPEN, the caller
     * is not the owner of `tokenId` at `nftAddr`, or the nft is not
     * listed on the marketplace.
     *
     * This function emits the {NftPaymentTokenAdded} event.
     */
    function addPaymentTokenAtListing(
        address nftAddr,
        uint256 tokenId,
        address paymentTokenAddress
    )
        external
        stateIs(MarketState.OPEN)
        isNftOwner(msg.sender, nftAddr, tokenId)
        isListed(nftAddr, tokenId)
    {
        if (s_paymentTokens[paymentTokenAddress].decimals == 0)
            revert NftMarketplace__TokenNotListed(paymentTokenAddress);

        s_listings[nftAddr][tokenId].paymentTokenAddresses.push(paymentTokenAddress);

        emit NftPaymentTokenAdded(nftAddr, tokenId, paymentTokenAddress);
    }

    /**
     * @notice Function for removing a payment token to a listing
     * @param nftAddr Is the address of the nft contract
     * @param tokenId Is the id of the nft
     * @param index is the index of the payment token to be removed
     * @dev This function reverts if the market is not OPEN, the caller
     * is not the owner of `tokenId` at `nftAddr`, or the nft is not
     * listed on the marketplace.
     *
     * This function emits the {NftPaymentTokenRemoved} event.
     */
    function removePaymentTokenAtListing(
        address nftAddr,
        uint256 tokenId,
        uint256 index
    )
        external
        stateIs(MarketState.OPEN)
        isNftOwner(msg.sender, nftAddr, tokenId)
        isListed(nftAddr, tokenId)
    {
        uint256 paymentTokenAddressesLen = s_listings[nftAddr][tokenId]
            .paymentTokenAddresses
            .length;
        if (index >= paymentTokenAddressesLen) revert NftMarketplace__IndexOutOfBounds();

        address paymentTokenAddress = s_listings[nftAddr][tokenId].paymentTokenAddresses[index];

        s_listings[nftAddr][tokenId].paymentTokenAddresses[index] = s_listings[nftAddr][tokenId]
            .paymentTokenAddresses[paymentTokenAddressesLen - 1];
        s_listings[nftAddr][tokenId].paymentTokenAddresses.pop();

        emit NftPaymentTokenRemoved(nftAddr, tokenId, paymentTokenAddress);
    }

    /**
     * @notice Function for buying an nft on the marketplace with eth
     * @param nftAddr Is the address of the nft contract
     * @param tokenId Is the id of the nft
     * @dev This function reverts if the market is not OPEN, the nft
     * is not listed on the marketplace, the marketplace is not approved
     * to transfer the nft or the amount of eth sent to the marketplace is
     * smaller than the price of the nft.
     *
     * This implementation will transfer the nft to the buyer directly,
     * while granting the seller address the right to withdraw the eth
     * amount sent by the buyer to the marketplace by calling the
     * withdrawFunds function. Checking the amount of eligible funds
     * for withdrawal can be done by calling getEligibleFunds.
     *
     * This function emits the {NftBought} event.
     */
    function buyNftEth(address nftAddr, uint256 tokenId)
        external
        payable
        stateIs(MarketState.OPEN)
        isListed(nftAddr, tokenId)
    {
        IERC721 nft = IERC721(nftAddr);
        if (nft.getApproved(tokenId) != address(this))
            revert NftMarketplace__NotApprovedForNft(nftAddr, tokenId);

        Listing memory l_listing = s_listings[nftAddr][tokenId];

        if (msg.value < l_listing.nftPrice) revert NftMarketplace__NotEnoughFunds();

        delete s_listings[nftAddr][tokenId];

        s_eligibleFunds[l_listing.seller] += msg.value;

        nft.safeTransferFrom(l_listing.seller, msg.sender, tokenId);

        emit NftBought(nftAddr, tokenId, msg.sender, l_listing.nftPrice);
    }

    /**
     * @notice Function for buying an nft on the marketplace with an erc20
     * (payment) token.
     * @param nftAddr Is the address of the nft contract
     * @param tokenId Is the id of the nft
     * @param paymentTokenIndex Is the index of the paymentToken in the
     * Listing.paymentTokenAddresses array
     * @dev This function reverts if the market is not OPEN, the nft
     * is not listed on the marketplace or the marketplace, the marketplace
     * is not approved to spend the nft or the approved token amount by
     * buyer is smaller than the amount of tokens required to pay for the
     * nft.
     *
     * The amount of tokens needed of paymentToken at index `paymentTokenIndex`
     * is retrieved from the getTokenAmountFromEthAmount function, which converts
     * the price (eth in wei) to the token amount (in wei) using Chainlink
     * price feeds.
     *
     * This implementation will transfer the nft to the buyer directly,
     * while also transferring the amount of tokens paid directly to the
     * seller. If the transfer of the erc20 tokens fails, the function
     * is reverted (nft will not be transferred to buyer).
     *
     * This function emits the {NftBought} event.
     */
    function buyNftErc20(
        address nftAddr,
        uint256 tokenId,
        uint256 paymentTokenIndex
    ) external stateIs(MarketState.OPEN) isListed(nftAddr, tokenId) {
        IERC721 nft = IERC721(nftAddr);
        if (nft.getApproved(tokenId) != address(this))
            revert NftMarketplace__NotApprovedForNft(nftAddr, tokenId);

        Listing memory l_listing = s_listings[nftAddr][tokenId];

        address erc20TokenAddress = l_listing.paymentTokenAddresses[paymentTokenIndex];

        uint256 requiredTokenAllowance = getTokenAmountFromEthAmount(
            l_listing.nftPrice,
            erc20TokenAddress
        );

        IERC20 erc20Token = IERC20(erc20TokenAddress);
        uint256 allowance = erc20Token.allowance(msg.sender, address(this));

        if (allowance < requiredTokenAllowance) revert NftMarketplace__NotEnoughAllowance();

        delete s_listings[nftAddr][tokenId];

        if (!erc20Token.transferFrom(msg.sender, l_listing.seller, requiredTokenAllowance))
            revert NftMarketplace__TokenTransferFailed(erc20TokenAddress);

        nft.safeTransferFrom(l_listing.seller, msg.sender, tokenId);

        emit NftBought(nftAddr, tokenId, msg.sender, l_listing.nftPrice);
    }

    /**
     * @notice Function for withdrawing eth from the marketplace, if eligible
     * funds is greater than zero (only after purchases with eth)
     * @dev This function reverts if the market is CLOSED or if there are no
     * eligible funds of the caller to withdraw.
     */
    function withdrawFunds() external stateIsNot(MarketState.CLOSED) {
        uint256 amount = s_eligibleFunds[msg.sender];
        if (amount <= 0) revert NftMarketplace__NoEligibleFunds();

        s_eligibleFunds[msg.sender] = 0;
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        if (!sent) revert NftMarketplace__EthTransferFailed();
    }

    /**
     * @notice Function for converting `ethAmount` to amount of tokens using
     * Chainlink price feeds
     * @param ethAmount Amount of eth (in wei) to be converted
     * @param tokenAddress Is the address of the erc20 token
     * @return Token amount (in wei)
     * @dev This function reverts if the `tokenAddress` is not listed as a
     * paymentToken.
     *
     * This implementation returns the token amount in wei (18 decimals).
     */
    function getTokenAmountFromEthAmount(uint256 ethAmount, address tokenAddress)
        public
        view
        returns (uint256)
    {
        PaymentToken memory l_paymentToken = s_paymentTokens[tokenAddress];

        if (l_paymentToken.priceFeedAddress == address(0))
            revert NftMarketplace__TokenNotListed(tokenAddress);

        AggregatorV3Interface priceFeed = AggregatorV3Interface(l_paymentToken.priceFeedAddress);
        (, int256 ercPrice, , , ) = priceFeed.latestRoundData();

        uint256 power = 18 - l_paymentToken.decimals;
        uint256 decimalAdjustedErcPrice = uint256(ercPrice) * (10**power);
        return (decimalAdjustedErcPrice * ethAmount) / 1e18;
    }

    /**
     * @notice This function returns the current MarketState of the
     * marketplace
     * @return State of the marketplace
     */
    function getState() public view returns (MarketState) {
        return s_marketState;
    }

    /**
     * @notice This function returns the current Listing of `tokenId`
     * at `nftAddr` (if existing)
     * @param nftAddr Is the address of the nft contract
     * @param tokenId Is the id of the nft
     * @return Listing of `tokenId` at `nftAddr`
     */
    function getListing(address nftAddr, uint256 tokenId) public view returns (Listing memory) {
        return s_listings[nftAddr][tokenId];
    }

    /**
     * @notice Function for looking up the amount of eligible funds
     * that can be withdrawn
     * @param addr Is the address to be looked up
     * @return Eligible funds of `addr` for withdrawal from
     * marketplace
     */
    function getEligibleFunds(address addr) public view returns (uint256) {
        return s_eligibleFunds[addr];
    }

    /**
     * @notice Function for looking up payment token of marketplace
     * @param addr Is the contract address of the payment token
     * @return PaymentToken of `addr`
     */
    function getPaymentToken(address addr) public view returns (PaymentToken memory) {
        return s_paymentTokens[addr];
    }

    /**
     * @notice Function for retrieving version of marketplace
     * @return Version
     */
    function getVersion() public pure returns (uint8) {
        return 1;
    }
}