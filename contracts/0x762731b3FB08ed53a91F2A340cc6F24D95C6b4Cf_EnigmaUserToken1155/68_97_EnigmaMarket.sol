// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721HolderUpgradeable.sol";
import "../interfaces/ITransferProxy.sol";
import "./NFTMarketReserveAuction.sol";
import "./TradeV4.sol";

/// @title EnigmaMarket
///
/// @dev This contract is a Transparent Upgradable based in openZeppelin v3.4.0.
///         Be careful when upgrade, you must respect the same storage.

contract EnigmaMarket is
    TradeV4,
    ERC721HolderUpgradeable, // Make sure the contract is able to use its
    NFTMarketReserveAuction
{
    // Though the TradeV4 contract is upgradeable, we still have to initialize the implementation through the
    // constructor. This is because we chose to import the non upgradeable EIP712 as it does not have storage
    // variable(which actually makes it upgradeable) as it only uses immmutable variables. This has several advantages:
    // - We can import it without worrying the storage layout
    // - Is more efficient as there is no need to read from the storage
    // Note: The cache mechanism will NOT be used here as the address will differ from the one calculated in the
    // constructor due to the fact that when the contract is operating we will be using delegatecall, meaningn
    // that the address will be the one from the proxy as opposed to the implementation's during the
    // constructor execution
    // solhint-disable-next-line no-empty-blocks
    constructor(string memory name, string memory version) TradeV4(name, version) {}

    /**
     * @notice Called once to configure the contract after the initial proxy deployment.
     * @dev This farms the initialize call out to inherited contracts as needed to initialize mutable variables.
     * @param _transferProxy the proxy from wich all NFT transfers are gonna be processed from.
     * @param _enigmaNFT721Address Enigma ERC721 NFT proxy.
     * @param _enigmaNFT1155Address Enigma ERC1155 NFT proxy.
     * @param _custodialAddress The address on wich NFTs are gonna be kept during Fiat Trades.
     * @param _minDuration The min duration for auctions, in seconds.
     * @param _maxDuration The max duration for auctions, in seconds.
     * @param _minIncrementPermille The minimum required when making an offer or placing a bid. Ej: 100 => 0.1 => 10%
     */
    function fullInitialize(
        ITransferProxy _transferProxy,
        address _enigmaNFT721Address,
        address _enigmaNFT1155Address,
        address _custodialAddress,
        uint256 _minDuration,
        uint256 _maxDuration,
        uint16 _minIncrementPermille
    ) external initializer {
        initializeTradeV4(_transferProxy, _enigmaNFT721Address, _enigmaNFT1155Address, _custodialAddress);
        __Ownable_init();
        __ReentrancyGuard_init();
        _initializeNFTMarketAuction();
        _initializeNFTMarketReserveAuction(_minDuration, _maxDuration);
        _initializeNFTMarketCore(_minIncrementPermille);
    }

    /**
     * @notice Called once to configure the contract after the initial proxy deployment.
     * @dev as we are updating an already deployed contracts, legacy vars don't need init.
     * @param _minDuration The min duration for auctions, in seconds.
     * @param _maxDuration The max duration for auctions, in seconds.
     */
    function upgradeInitialize(uint256 _minDuration, uint256 _maxDuration) external onlyOwner {
        _initializeNFTMarketAuction();
        _initializeNFTMarketReserveAuction(_minDuration, _maxDuration);
    }

    function getPlatformTreasury() public view returns (address payable) {
        // TODO: review if we don't need a new field for collecting fees
        return payable(owner());
    }

    /**
     * @inheritdoc NFTMarketCore
     */
    function _transferFromEscrow(
        address nftContract,
        uint256 tokenId,
        address recipient
    ) internal virtual override {
        // As we are transfering through our own market, there's no need to go by transferProxy
        IERC721(nftContract).transferFrom(address(this), recipient, tokenId);
    }

    /**
     * @inheritdoc NFTMarketCore
     */
    function _transferToEscrow(address nftContract, uint256 tokenId) internal virtual override {
        safeTransferFrom(AssetType.ERC721, msg.sender, address(this), nftContract, tokenId, 1);
    }

    /**
     * @dev Be careful when invoking this function as reentrancy guard should be put in place
     */
    // slither-disable-next-line reentrancy-eth
    function _distFunds(
        address nftContract,
        uint256 tokenId,
        uint256 amount,
        address payable seller,
        uint256 sellerFeesPerMille,
        uint256 buyerFeesPerMille
    )
        internal
        override
        returns (
            uint256 platformFee,
            uint256 royaltyFee,
            uint256 assetFee
        )
    {
        // Disable slither warning because it's only invoked from functions with nonReentrant checks
        FeeDistributionData memory feeDistributionData =
            getFees(amount, nftContract, tokenId, sellerFeesPerMille, buyerFeesPerMille, seller);
        _sendValueWithFallbackWithdraw(
            getPlatformTreasury(),
            feeDistributionData.fees.platformFee,
            SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT
        );

        if (feeDistributionData.toRightsHolder > 0) {
            _sendValueWithFallbackWithdraw(
                payable(feeDistributionData.rightsHolder),
                feeDistributionData.toRightsHolder,
                SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT
            );
        }

        if (feeDistributionData.toSeller > 0) {
            _sendValueWithFallbackWithdraw(seller, feeDistributionData.toSeller, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);
        }

        return (
            feeDistributionData.fees.platformFee,
            feeDistributionData.fees.royaltyFee,
            feeDistributionData.fees.assetFee
        );
    }

    /**
     * @notice Creates an auction for the given NFT.
     * The NFT is held in escrow until the auction is finalized or canceled.
     * buyer and seller fees are locked at creation time
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @param duration seconds for how long an auction lasts for once the first bid has been received.
     * @param reservePrice The initial reserve price for the auction.
     */
    function createReserveAuctionFor(
        address nftContract,
        uint256 tokenId,
        uint256 duration,
        uint256 reservePrice,
        uint256 amount,
        PlatformFees calldata platformFees
    ) internal override {
        verifyPlatformFeesSignature(platformFees, owner());
        NFTMarketReserveAuction.createReserveAuctionFor(
            nftContract,
            tokenId,
            duration,
            reservePrice,
            amount,
            platformFees
        );
    }

    /*********************
     ** PUBLIC FUNCTIONS *
     *********************/

    /**
     * @notice Creates an auction for the given NFT.
     * The NFT is held in escrow until the auction is finalized or canceled.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @param duration seconds for how long an auction lasts for once the first bid has been received.
     * @param reservePrice The initial reserve price for the auction.
     */
    function createReserveAuction(
        address nftContract,
        uint256 tokenId,
        uint256 duration,
        uint256 reservePrice,
        PlatformFees calldata platformFees
    ) external nonReentrant onlyValidAuctionConfig(reservePrice) {
        // get the amount, including buyer fees for this reserve price
        uint256 amount = applyBuyerFee(reservePrice, platformFees.buyerFeePermille);
        createReserveAuctionFor(nftContract, tokenId, duration, reservePrice, amount, platformFees);
    }
}