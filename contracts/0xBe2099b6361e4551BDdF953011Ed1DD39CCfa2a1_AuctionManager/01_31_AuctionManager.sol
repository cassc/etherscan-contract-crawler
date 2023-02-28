// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.10;

import { IMinimalForwarder } from "./interfaces/IMinimalForwarder.sol";
import { IAuctionManager } from "./interfaces/IAuctionManager.sol";
import { IOwnable } from "./interfaces/IOwnable.sol";
import { IERC721GeneralMint } from "../erc721/interfaces/IERC721GeneralMint.sol";
import { IERC721EditionMint } from "../erc721/interfaces/IERC721EditionMint.sol";
import "../utils/EIP712Upgradeable.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { IERC721, IERC165 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title Manages auctions
 * @notice Facilitates lion's share of auctions on HL
 * @dev Does not support meta-transactions at the moment.
 *      Will support, if a need arises. Otherwise, save some gas without.
 * @author [email protected]
 */
contract AuctionManager is
    IAuctionManager,
    ReentrancyGuardUpgradeable,
    EIP712Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    ERC721Holder,
    ERC1155Holder
{
    using ECDSA for bytes32;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @notice Tracks number of bids made per user per auction
     */
    mapping(bytes32 => mapping(address => uint256)) public auctionBids;

    /**
     * @notice Tracks auction ids to auctions
     */
    mapping(bytes32 => IAuctionManager.EnglishAuction) private _auctions;

    /**
     * @notice Tracks auction ids to data about current highest bidder on respective auction
     */
    mapping(bytes32 => IAuctionManager.HighestBidderData) private _highestBidders;

    /**
     * @notice Trusted minimal forwarder on collections
     */
    address private _collectionMinimalForwarder;

    /**
     * @notice Cut of winning bids taken by platform, in basis points
     */
    uint256 private _platformCutBPS;

    /**
     * @notice Platform receiving portion of payment
     */
    address payable private _platform;

    /**
     * @notice Platform transaction executors
     */
    EnumerableSet.AddressSet internal _platformExecutors;

    /**
     * @notice Tracks auction ids to the edition auction data for the auction
     */
    mapping(bytes32 => IAuctionManager.EditionAuction) private _auctionEditions;

    /**
     * @notice Emitted when platform executor is added or removed
     * @param executor Changed executor
     * @param added True if executor was added and false otherwise
     */
    event PlatformExecutorChanged(address indexed executor, bool indexed added);

    /**
     * @notice Require that the specified auction does not exist (auction id is not being used)
     * @param auctionId ID of auction being checked
     */
    modifier auctionNonExistent(bytes32 auctionId) {
        require(_auctions[auctionId].state == AuctionState.NON_EXISTENT, "Auction id used");
        _;
    }

    /**
     * @notice Require that the specified auction exists and it is in the LIVE_ON_CHAIN state
     * @param auctionId ID of auction being checked
     */
    modifier auctionIsLiveOnChain(bytes32 auctionId) {
        require(_auctions[auctionId].state == AuctionState.LIVE_ON_CHAIN, "Not live");
        _;
    }

    /**
     * @notice Require that caller is auction owner
     * @param auctionId ID of auction who's owner is checked
     */
    modifier onlyAuctionOwner(bytes32 auctionId) {
        require(_auctions[auctionId].owner == msg.sender, "Not auction owner");
        _;
    }

    /**
     * @notice Require that caller is a collection's owner or the collection itself
     * @param auction Auction for collection
     */
    modifier onlyCollectionOrCollectionOwner(IAuctionManager.EnglishAuction memory auction) {
        require(
            auction.collection == msg.sender || IOwnable(auction.collection).owner() == msg.sender,
            "Not collection owner or collection"
        );
        _;
    }

    /**
     * @notice Require that caller is the auction's current highest bidder
     * @param auctionId Auction ID
     */
    modifier onlyHighestBidder(bytes32 auctionId) {
        require(_highestBidders[auctionId].bidder == msg.sender, "Not current highest bidder");
        _;
    }

    /* solhint-disable no-empty-blocks */
    receive() external payable {}

    fallback() external payable {}

    /**
     * @notice Initialize the contract
     * @param platform Platform
     * @param collectionMinimalForwarder Trusted minimal forwarder on collections
     * @param initialUpgrader Initial account able to upgrade contract
     * @param initialExecutor Initial account to seed executors with
     */
    function initialize(
        address payable platform,
        address collectionMinimalForwarder,
        address initialUpgrader,
        address initialExecutor
    ) external initializer {
        _platform = platform;
        _collectionMinimalForwarder = collectionMinimalForwarder;
        _platformCutBPS = 500;
        _platformExecutors.add(initialExecutor);

        __EIP721Upgradeable_initialize("AuctionManager", "1.0.0");
        __ReentrancyGuard_init();
        __Ownable_init();

        _transferOwnership(initialUpgrader);
    }

    /**
     * @notice Add platform executor. Expected to be protected by a smart contract wallet.
     * @param _executor Platform executor to add
     */
    function addPlatformExecutor(address _executor) external onlyOwner {
        require(_executor != address(0), "Cannot set to null address");
        require(_platformExecutors.add(_executor), "Already added");
        emit PlatformExecutorChanged(_executor, true);
    }

    /**
     * @notice Deprecate platform executor. Expected to be protected by a smart contract wallet.
     * @param _executor Platform executor to deprecate
     */
    function deprecatePlatformExecutor(address _executor) external onlyOwner {
        require(_platformExecutors.remove(_executor), "Not deprecated");
        emit PlatformExecutorChanged(_executor, false);
    }

    /**
     * @notice See {IAuctionManager-createAuctionForNewToken}
     */
    function createAuctionForNewToken(bytes32 auctionId, IAuctionManager.EnglishAuction memory auction)
        external
        override
        nonReentrant
        onlyCollectionOrCollectionOwner(auction)
    {
        _createAuction(auctionId, auction, true);
    }

    /**
     * @notice See {IAuctionManager-createAuctionForNewEdition}
     */
    function createAuctionForNewEdition(
        bytes32 auctionId,
        IAuctionManager.EnglishAuction memory auction,
        uint256 editionId
    ) external override nonReentrant onlyCollectionOrCollectionOwner(auction) auctionNonExistent(auctionId) {
        auction.mintWhenReserveMet = true;
        auction.state = AuctionState.LIVE_ON_CHAIN;

        _auctions[auctionId] = auction;
        _auctionEditions[auctionId] = IAuctionManager.EditionAuction(true, editionId);

        emit EnglishAuctionCreated(
            auctionId,
            auction.owner,
            auction.collection,
            auction.tokenId,
            auction.currency,
            auction.paymentRecipient,
            auction.endTime
        );
    }

    /**
     * @notice See {IAuctionManager-createAuctionForExistingToken}
     */
    function createAuctionForExistingToken(bytes32 auctionId, IAuctionManager.EnglishAuction memory auction)
        external
        override
        nonReentrant
        onlyCollectionOrCollectionOwner(auction)
    {
        IERC721(auction.collection).safeTransferFrom(auction.owner, address(this), auction.tokenId);
        _createAuction(auctionId, auction, false);
    }

    /**
     * @notice See {IAuctionManager-createAuctionForExistingTokenWithMetaTxPacket}
     */
    function createAuctionForExistingTokenWithMetaTxPacket(
        bytes32 auctionId,
        IAuctionManager.EnglishAuction memory auction,
        IMinimalForwarder.ForwardRequest calldata req,
        bytes calldata requestSignature
    ) external override nonReentrant onlyCollectionOrCollectionOwner(auction) {
        IMinimalForwarder(_collectionMinimalForwarder).execute(req, requestSignature);
        _createAuction(auctionId, auction, false);
    }

    /**
     * @notice See {IAuctionManager-bid}
     */
    function bid(
        IAuctionManager.Claim calldata claim,
        bytes calldata claimSignature,
        address preferredNftRecipient
    ) external payable override auctionIsLiveOnChain(claim.auctionId) nonReentrant {
        IAuctionManager.EnglishAuction memory auction = _auctions[claim.auctionId];
        IAuctionManager.HighestBidderData memory currentHighestBidderData = _highestBidders[claim.auctionId];

        // validate validity of time, update value
        require(block.timestamp <= auction.endTime, "Auction expired");

        bool timeExtended = false;
        if (block.timestamp.add(claim.buffer) > auction.endTime) {
            auction.endTime = block.timestamp.add(claim.buffer);
            _auctions[claim.auctionId].endTime = auction.endTime;
            timeExtended = true;
        }

        // handle last highest bid
        bool firstBid = true;
        if (currentHighestBidderData.bidder != address(0)) {
            firstBid = false;
            _processLastHighestBid(currentHighestBidderData, auction.currency);
        }

        _processGatedMintClaim(
            claim,
            auction.currency,
            claimSignature,
            currentHighestBidderData,
            preferredNftRecipient
        );

        // if mintOnReserve and this is first valid bid, mint via general interface
        if (firstBid && auction.mintWhenReserveMet) {
            // mint new nft and put it into escrow if this auction doesn't have an nft in escrow yet

            IAuctionManager.EditionAuction memory editionAuction = _auctionEditions[claim.auctionId];
            if (editionAuction.used == true) {
                auction.tokenId = IERC721EditionMint(auction.collection).mintOneToRecipient(
                    editionAuction.editionId,
                    address(this)
                );
            } else {
                auction.tokenId = IERC721GeneralMint(auction.collection).mintOneToOneRecipient(address(this));
            }
            _auctions[claim.auctionId].tokenId = auction.tokenId;
        }

        // emit correct events
        emit Bid(
            claim.auctionId,
            claim.claimer,
            firstBid,
            auction.collection,
            auction.tokenId,
            claim.bidPrice,
            timeExtended,
            preferredNftRecipient,
            auction.endTime
        );

        if (timeExtended) {
            emit TimeLengthened(claim.auctionId, auction.tokenId, auction.collection, claim.buffer, auction.endTime);
        }
    }

    /**
     * @notice See {IAuctionManager-fulfillAuction}
     */
    function fulfillAuction(bytes32 auctionId) external override auctionIsLiveOnChain(auctionId) nonReentrant {
        IAuctionManager.EnglishAuction memory auction = _auctions[auctionId];
        IAuctionManager.HighestBidderData memory highestBidderData = _highestBidders[auctionId];
        require(block.timestamp > auction.endTime && auction.endTime != 0, "Auction hasn't ended");

        // send nft to recipient as preferred by winning bidder
        try
            IERC721(auction.collection).safeTransferFrom(
                address(this),
                highestBidderData.preferredNFTRecipient,
                auction.tokenId
            )
        {} catch {
            // encourage fulfiller to urge highest bidder to update their preferred nft recipient
            revert("Preferred nft recipient is an invalid receiver");
        }

        // send winning bid to payment recipient on auction and platform
        uint256 platformCut = highestBidderData.amount.mul(_platformCutBPS).div(10000);
        uint256 recipientCut = highestBidderData.amount.sub(platformCut);

        if (auction.currency == address(0)) {
            (bool sentToRecipient, bytes memory dataRecipient) = auction.paymentRecipient.call{ value: recipientCut }(
                ""
            );
            require(sentToRecipient, "Failed to send native gas token to payment recipient");

            if (platformCut > 0) {
                (bool sentToPlatform, bytes memory dataPlatform) = _platform.call{ value: platformCut }("");
                require(sentToPlatform, "Failed to send native gas token to platform");
            }
        } else {
            IERC20(auction.currency).transfer(auction.paymentRecipient, recipientCut);

            if (platformCut > 0) {
                IERC20(auction.currency).transfer(_platform, platformCut);
            }
        }

        emit AuctionWon(
            auctionId,
            auction.tokenId,
            auction.collection,
            auction.owner,
            highestBidderData.bidder,
            auction.paymentRecipient,
            highestBidderData.preferredNFTRecipient,
            auction.currency,
            highestBidderData.amount,
            uint256(10000).sub(_platformCutBPS)
        );

        _auctions[auctionId].state = AuctionState.FULFILLED;
    }

    /**
     * @notice See {IAuctionManager-cancelAuctionOnChain}
     */
    function cancelAuctionOnChain(bytes32 auctionId)
        external
        override
        nonReentrant
        auctionIsLiveOnChain(auctionId)
        onlyAuctionOwner(auctionId)
    {
        IAuctionManager.EnglishAuction memory auction = _auctions[auctionId];
        IAuctionManager.HighestBidderData memory highestBidderData = _highestBidders[auctionId];
        require(highestBidderData.bidder == address(0), "Reserve price met already");

        // if the auction manager has the nft in escrow, return it
        if (!auction.mintWhenReserveMet) {
            IERC721(auction.collection).safeTransferFrom(address(this), auction.owner, auction.tokenId);
        }

        _auctions[auctionId].state = AuctionState.CANCELLED_ON_CHAIN;
        emit AuctionCanceledOnChain(auctionId, auction.owner, auction.collection, auction.tokenId);
    }

    /**
     * @notice See {IAuctionManager-updatePaymentRecipient}
     */
    function updatePaymentRecipient(bytes32 auctionId, address payable newPaymentRecipient)
        external
        onlyAuctionOwner(auctionId)
        auctionIsLiveOnChain(auctionId)
    {
        _auctions[auctionId].paymentRecipient = newPaymentRecipient;

        emit PaymentRecipientUpdated(auctionId, _auctions[auctionId].owner, newPaymentRecipient);
    }

    /**
     * @notice See {IAuctionManager-updatePreferredNFTRecipient}
     */
    function updatePreferredNFTRecipient(bytes32 auctionId, address newPreferredNFTRecipient)
        external
        onlyHighestBidder(auctionId)
        auctionIsLiveOnChain(auctionId)
    {
        _highestBidders[auctionId].preferredNFTRecipient = newPreferredNFTRecipient;

        emit PreferredNFTRecipientUpdated(auctionId, _auctions[auctionId].owner, newPreferredNFTRecipient);
    }

    /**
     * @notice See {IAuctionManager-updatePlatform}
     */
    function updatePlatform(address payable newPlatform) external onlyOwner {
        _platform = newPlatform;

        emit PlatformUpdated(newPlatform);
    }

    /**
     * @notice See {IAuctionManager-updatePlatformCut}
     */
    function updatePlatformCut(uint256 newCutBPS) external onlyOwner {
        _platformCutBPS = newCutBPS;
    }

    /**
     * @notice See {IAuctionManager-updateEndTime}
     */
    function updateEndTime(bytes32 auctionId, uint256 newEndTime)
        external
        onlyAuctionOwner(auctionId)
        auctionIsLiveOnChain(auctionId)
    {
        require(_highestBidders[auctionId].bidder == address(0), "Can't update after first valid bid");
        _auctions[auctionId].endTime = newEndTime;

        emit EndTimeUpdated(auctionId, _auctions[auctionId].owner, newEndTime);
    }

    /**
     * @notice See {IAuctionManager-verifyClaim}
     */
    function verifyClaim(
        Claim calldata claim,
        bytes calldata claimSignature,
        address expectedMsgSender
    ) external view auctionIsLiveOnChain(claim.auctionId) returns (bool) {
        address signer = _claimSigner(claim, claimSignature);
        IAuctionManager.HighestBidderData memory currentHighestBidderData = _highestBidders[claim.auctionId];

        uint256 currentNumClaimsByUser = auctionBids[claim.auctionId][claim.claimer];

        _validateUnwrappedClaim(currentNumClaimsByUser, claim, currentHighestBidderData, signer, expectedMsgSender);

        return true;
    }

    /**
     * @notice See {IAuctionManager-getFullAuctionData}
     */
    function getFullAuctionData(bytes32 auctionId)
        external
        view
        returns (
            IAuctionManager.EnglishAuction memory,
            IAuctionManager.HighestBidderData memory,
            IAuctionManager.EditionAuction memory
        )
    {
        return (_auctions[auctionId], _highestBidders[auctionId], _auctionEditions[auctionId]);
    }

    /**
     * @notice See {IAuctionManager-getFullAuctionsData}
     */
    function getFullAuctionsData(bytes32[] calldata auctionIds)
        external
        view
        returns (
            IAuctionManager.EnglishAuction[] memory,
            IAuctionManager.HighestBidderData[] memory,
            IAuctionManager.EditionAuction[] memory
        )
    {
        uint256 auctionIdsLength = auctionIds.length;
        IAuctionManager.EnglishAuction[] memory auctions = new IAuctionManager.EnglishAuction[](auctionIdsLength);
        IAuctionManager.HighestBidderData[] memory highestBiddersData = new IAuctionManager.HighestBidderData[](
            auctionIdsLength
        );
        IAuctionManager.EditionAuction[] memory auctionEditions = new IAuctionManager.EditionAuction[](
            auctionIdsLength
        );

        for (uint256 i = 0; i < auctionIdsLength; i++) {
            bytes32 auctionId = auctionIds[i];
            auctions[i] = _auctions[auctionId];
            highestBiddersData[i] = _highestBidders[auctionId];
            auctionEditions[i] = _auctionEditions[auctionId];
        }

        return (auctions, highestBiddersData, auctionEditions);
    }

    /**
     * @notice Returns platform executors
     */
    function platformExecutors() external view returns (address[] memory) {
        return _platformExecutors.values();
    }

    /**
     * @notice See {UUPSUpgradeable-_authorizeUpgrade}
     * @param // New implementation to upgrade to
     */
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @notice Process, verify, and update the state of a gated auction bid claim
     * @param claim Claim
     * @param currency Auction currency
     * @param claimSignature Signed + encoded claim
     * @param currentHighestBidderData Data of current highest bidder / bid
     * @param preferredNftRecipient Current highest bidder's preferred NFT recipient if their bid wins
     */
    function _processGatedMintClaim(
        IAuctionManager.Claim calldata claim,
        address currency,
        bytes calldata claimSignature,
        IAuctionManager.HighestBidderData memory currentHighestBidderData,
        address preferredNftRecipient
    ) private {
        _verifyClaimAndUpdateData(claim, claimSignature, currentHighestBidderData, preferredNftRecipient);

        // make payments
        if (currency == address(0)) {
            // keep native gas token value on contract
            require(msg.value >= claim.bidPrice, "Invalid native gas token payment");
        } else {
            IERC20(currency).transferFrom(claim.claimer, address(this), claim.bidPrice);
        }
    }

    /**
     * @notice Send the last highest bid back to the bidder
     * @param currentHighestBidderData Data of the last highest bid
     * @param currency Auction currency
     */
    function _processLastHighestBid(IAuctionManager.HighestBidderData memory currentHighestBidderData, address currency)
        private
    {
        if (currency == address(0)) {
            (bool sentToRecipient, bytes memory dataRecipient) = currentHighestBidderData.bidder.call{
                value: currentHighestBidderData.amount
            }("");
            require(sentToRecipient, "Failed to send Ether to last highest bidder");
        } else {
            IERC20(currency).transfer(currentHighestBidderData.bidder, currentHighestBidderData.amount);
        }
    }

    /**
     * @notice Verify, and update the state of a gated bid claim
     * @param claim Claim
     * @param signature Signed + encoded claim
     * @param currentHighestBidderData Data of current highest bidder / bid
     * @param preferredNftRecipient Current highest bidder's preferred NFT recipient if their bid wins
     */
    function _verifyClaimAndUpdateData(
        Claim calldata claim,
        bytes calldata signature,
        IAuctionManager.HighestBidderData memory currentHighestBidderData,
        address preferredNftRecipient
    ) private {
        address signer = _claimSigner(claim, signature);

        uint256 currentNumClaimsByUser = auctionBids[claim.auctionId][claim.claimer];

        _validateUnwrappedClaim(currentNumClaimsByUser, claim, currentHighestBidderData, signer, msg.sender);

        // update claim state
        auctionBids[claim.auctionId][claim.claimer] = currentNumClaimsByUser + 1;

        // update highest bidder data
        _highestBidders[claim.auctionId] = IAuctionManager.HighestBidderData(
            claim.claimer,
            preferredNftRecipient,
            claim.bidPrice
        );
    }

    /**
     * @notice Create an auction
     * @param auctionId Auction ID
     * @param auction Details of auction to create
     * @param newToken True if this auction will mint a new token when reserve price is met
     */
    function _createAuction(
        bytes32 auctionId,
        IAuctionManager.EnglishAuction memory auction,
        bool newToken
    ) private auctionNonExistent(auctionId) {
        auction.mintWhenReserveMet = newToken;
        auction.state = AuctionState.LIVE_ON_CHAIN;

        _auctions[auctionId] = auction;

        emit EnglishAuctionCreated(
            auctionId,
            auction.owner,
            auction.collection,
            auction.tokenId,
            auction.currency,
            auction.paymentRecipient,
            auction.endTime
        );
    }

    /**
     * @notice Returns true if account passed in is a platform executor
     * @param _executor Account being checked
     */
    function _isPlatformExecutor(address _executor) private view returns (bool) {
        return _platformExecutors.contains(_executor);
    }

    /**
     * @notice Recover claim signature signer
     * @param claim Claim
     * @param signature Claim signature
     */
    function _claimSigner(IAuctionManager.Claim calldata claim, bytes calldata signature)
        private
        view
        returns (address)
    {
        return _hashTypedDataV4(keccak256(_claimABIEncoded(claim))).recover(signature);
    }

    /**
     * @notice Validate an unwrapped claim
     * @param currentNumClaimsByUser Current number of claims by claimer
     * @param claim Claim
     * @param currentHighestBidderData Data of current highest bidder / bid
     * @param signer Claim signature signer
     * @param msgSender Message sender
     */
    function _validateUnwrappedClaim(
        uint256 currentNumClaimsByUser,
        Claim calldata claim,
        IAuctionManager.HighestBidderData memory currentHighestBidderData,
        address signer,
        address msgSender
    ) private view {
        require(msgSender == claim.claimer, "Sender not claimer");
        require(_isPlatformExecutor(signer), "Claim signer not executor");
        require(
            currentHighestBidderData.bidder != address(0) || claim.bidPrice >= claim.reservePrice,
            "Reserve price not met"
        );
        require(claim.claimExpiryTimestamp >= block.timestamp, "Claim expired");
        require(
            claim.maxClaimsPerAccount == 0 || currentNumClaimsByUser < claim.maxClaimsPerAccount,
            "Exceeded max claims for account"
        );
        if (claim.minimumIncrementPerBidPctBPS == 0) {
            require(claim.bidPrice > currentHighestBidderData.amount, "Bid not higher");
        } else {
            require(
                claim.bidPrice >=
                    currentHighestBidderData.amount.add(
                        currentHighestBidderData.amount.mul(claim.minimumIncrementPerBidPctBPS).div(10000)
                    ),
                "Bid not big enough of a jump"
            );
        }
    }

    /**
     * @notice Return abi-encoded claim
     * @param claim Claim
     */
    function _claimABIEncoded(Claim calldata claim) private pure returns (bytes memory) {
        return
            abi.encode(
                _getClaimTypeHash(),
                claim.auctionId,
                claim.bidPrice,
                claim.reservePrice,
                claim.maxClaimsPerAccount,
                claim.claimExpiryTimestamp,
                claim.buffer,
                claim.minimumIncrementPerBidPctBPS,
                claim.claimer
            );
    }

    /* solhint-disable max-line-length */
    /**
     * @notice Get claim typehash
     */
    function _getClaimTypeHash() private pure returns (bytes32) {
        return
            keccak256(
                "Claim(bytes32 auctionId,uint256 bidPrice,uint256 reservePrice,uint256 maxClaimsPerAccount,uint256 claimExpiryTimestamp,uint256 buffer,uint256 minimumIncrementPerBidPctBPS,address claimer)"
            );
    }
}