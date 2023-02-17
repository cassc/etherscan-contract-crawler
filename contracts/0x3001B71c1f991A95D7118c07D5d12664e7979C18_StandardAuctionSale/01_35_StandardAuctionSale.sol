// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "src/ManageableUpgradeable.sol";
import {QuantumBlackListable} from "../QuantumBlackListable.sol";
import "./interfaces/IMinterceptor.sol";
import "./interfaces/IStandardAuctionSale.sol";
import "./libs/Errors.sol";
import "./libs/AuthStructs.sol";
import "./StandardAuctionSaleStorage.sol";

// Custom errors
error AlreadyBid();
error AlreadyRefunded();
error BidTooLow(uint256 bidAmount, uint256 startingPrice);
error BidderZeroAddress();
error DropNotEnded(uint256 dropId);
error ItemAlreadyMinted(uint256 itemId);
error ItemNotSold(uint256 dropId, uint256 itemId);
error ItemSold(uint256 dropId, uint256 itemId);
error NoBid();
error NotHighestBidder();
error NoValueNeeded();
error VoucherBidderNotMatching(address expected, address actual);

contract StandardAuctionSale is
    IStandardAuctionSale,
    OwnableUpgradeable,
    ManageableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    /// >>>>>>>>>>>>>>>>>>>>>  EVENTS  <<<<<<<<<<<<<<<<<<<<<< ///
    event StandardAuctionDropPublished(
        uint256 voucherId,
        uint256 indexed dropId,
        address indexed collection,
        bytes32 merkleRoot,
        uint256 startingPrice,
        uint256 start,
        uint256 auctionPeriod,
        uint256 numItems
    );
    event StandardAuctionDropRePublished(
        uint256 voucherId,
        uint256 indexed dropId,
        bytes32 merkleRoot,
        uint256 startingPrice,
        uint256 start,
        uint256 auctionPeriod,
        uint256 numItems
    );
    event StandardAuctionDropAdminRePublished(
        uint256 indexed dropId,
        uint256 startingPrice,
        uint256 listingStart,
        uint256 auctionPeriod
    );
    event StandardAuctionDropCancelled(
        uint256 voucherId,
        uint256 indexed dropId
    );
    event StandardAuctionDropAdminCancelled(uint256 indexed dropId);

    event ItemFirstBid(
        uint256 dropId,
        uint256 itemId,
        address bidder,
        uint256 bidAmount
    );

    event ItemBid(
        uint256 dropId,
        uint256 itemId,
        address bidder,
        uint256 bidAmount
    );
    event BidRefunded(
        uint256 dropId,
        uint256 itemId,
        address bidder,
        uint256 bidAmount
    );

    /// >>>>>>>>>>>>>>>>>>>>>  INITIALIZER  <<<<<<<<<<<<<<<<<<<<<< ///
    function initialize(
        address admin,
        address minter,
        address blackList
    ) public virtual initializer {
        __StandardAuctionSale_init(admin, minter, blackList);
    }

    function __StandardAuctionSale_init(
        address admin,
        address minter,
        address blackList
    ) internal onlyInitializing {
        __Ownable_init();
        __Manageable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        __StandardAuctionSale_init_unchained(admin, minter);
        setBlacklist(blackList);
    }

    function __StandardAuctionSale_init_unchained(address admin, address minter)
        internal
        onlyInitializing
    {
        StandardAuctionSaleStorage.Layout
            storage qs = StandardAuctionSaleStorage.layout();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(MANAGER_ROLE, admin);

        qs.minter = minter;
    }

    /// >>>>>>>>>>>>>>>>>>>>>  ROLES & PERMISSIONS  <<<<<<<<<<<<<<<<<<<<<< ///
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    /// @notice set address of the minter contract
    /// @param minter The address of the new minter contract
    function setMinter(address minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (minter == address(0)) revert InvalidAddress();

        StandardAuctionSaleStorage.layout().minter = minter;
    }

    /// >>>>>>>>>>>>>>>>>>>>>  CONTRACT MANAGEMENT  <<<<<<<<<<<<<<<<<<<<<< ///

    /// @notice Pause contract
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpause contract
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /// >>>>>>>>>>>>>>>>>>>>>  BLACKLIST OPS  <<<<<<<<<<<<<<<<<<<<<< ///
    modifier isNotBlackListed(address user) {
        if (
            QuantumBlackListable.isBlackListed(
                user,
                StandardAuctionSaleStorage.layout().blackListAddress
            )
        ) {
            revert QuantumBlackListable.BlackListedAddress(user);
        }
        _;
    }

    /// @notice update the BlackList contract address
    /// @param blackList The address of the blacklist contract
    function setBlacklist(address blackList)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused
    {
        StandardAuctionSaleStorage.Layout storage s = StandardAuctionSaleStorage
            .layout();
        s.blackListAddress = blackList;
    }

    /// >>>>>>>>>>>>>>>>>>>>>  PLATFORM-LEVEL SETTINGS  <<<<<<<<<<<<<<<<<<<<<< ///

    function setMinBidIncrement(uint256 newIncrement)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused
    {
        StandardAuctionSaleStorage.layout().minBidIncrement = newIncrement;
    }

    /// >>>>>>>>>>>>>>>>>>>>>  GETTER FUNCTIONS  <<<<<<<<<<<<<<<<<<<<<< ///

    /// >>>>>>>>>>>>>>>>>>>>>  GETTER FUNCTIONS - PUBLIC  <<<<<<<<<<<<<<<<<<<<<< ///

    /// @notice gets the drop details
    /// @param dropId The id of the drop.
    function drop(uint256 dropId)
        public
        view
        returns (
            address,
            uint96,
            uint128,
            uint32,
            bool,
            uint32,
            uint32
        )
    {
        StandardAuctionDrop storage stdAuction = StandardAuctionSaleStorage
            .layout()
            .drops[dropId];

        return (
            stdAuction.collection,
            stdAuction.startingPrice,
            stdAuction.listingStart,
            stdAuction.auctionPeriod,
            stdAuction.cancelled,
            stdAuction.numMinted,
            stdAuction.numItems
        );
    }

    function minBidIncrement() public view returns (uint256) {
        return StandardAuctionSaleStorage.layout().minBidIncrement;
    }

    /// @notice gets the number of items in the drop
    /// @param dropId The id of the drop.
    function collection(uint256 dropId) public view returns (address) {
        return StandardAuctionSaleStorage.layout().drops[dropId].collection;
    }

    /// @notice gets the number of items in the drop
    /// @param dropId The id of the drop.
    function totalItems(uint256 dropId) public view returns (uint32) {
        return StandardAuctionSaleStorage.layout().drops[dropId].numItems;
    }

    /// @notice gets the number of mintable items remaining
    /// @param dropId The id of the drop.
    function remainingItems(uint256 dropId) public view returns (uint32) {
        StandardAuctionDrop storage stdAuction = StandardAuctionSaleStorage
            .layout()
            .drops[dropId];

        return stdAuction.numItems - stdAuction.numMinted;
    }

    /// @notice returns the address of the auction's highest bidder
    /// @param dropId The id of the drop.
    function highestBidder(uint256 dropId, uint256 itemId)
        public
        view
        returns (address)
    {
        return
            StandardAuctionSaleStorage
            .layout()
            .bids[dropId][itemId].highestBidder;
    }

    /// @notice returns the auction's highest bid in wei
    /// @param dropId The id of the drop.
    function highestBid(uint256 dropId, uint256 itemId)
        public
        view
        returns (uint96)
    {
        return
            StandardAuctionSaleStorage.layout().bids[dropId][itemId].highestBid;
    }

    /// @notice returns the auction's highest bid in wei
    /// @param dropId The id of the drop.
    function minimumBid(uint256 dropId, uint256 itemId)
        public
        view
        returns (uint96)
    {
        StandardAuctionSaleStorage.Layout
            storage layout = StandardAuctionSaleStorage.layout();

        uint96 currentBid = layout.bids[dropId][itemId].highestBid;

        return
            currentBid > 0 // override minimum price if there is any bid. any change to minimum price will not affect existing bids
                ? currentBid + uint96(layout.minBidIncrement)
                : layout.drops[dropId].startingPrice;
    }

    function getBid(uint256 dropId, uint256 itemId)
        public
        view
        returns (
            address,
            uint96,
            bool,
            bool
        )
    {
        StandardAuctionItemBid storage currentBid = StandardAuctionSaleStorage
            .layout()
            .bids[dropId][itemId];

        return (
            currentBid.highestBidder,
            currentBid.highestBid,
            currentBid.minted,
            currentBid.refunded
        );
    }

    /// @notice internal utility to check if an item is part of a drop
    /// @param dropId The id of the drop.
    /// @param itemId The id of the item.
    function isItemInDrop(
        uint256 dropId,
        uint256 itemId,
        bytes32[] calldata proof
    ) public view returns (bool) {
        StandardAuctionDrop storage stdAuction = StandardAuctionSaleStorage
            .layout()
            .drops[dropId];
        return
            MerkleProof.verify(
                proof,
                stdAuction.merkleRoot,
                keccak256(abi.encodePacked(itemId))
            );
    }

    function itemSold(uint256 dropId, uint256 itemId)
        public
        view
        returns (bool)
    {
        StandardAuctionDrop storage stdAuction = StandardAuctionSaleStorage
            .layout()
            .drops[dropId];

        return
            stdAuction.firstBidTime[itemId] > 0 &&
            (block.timestamp >
                (stdAuction.firstBidTime[itemId] + stdAuction.auctionPeriod));
    }

    /// >>>>>>>>>>>>>>>>>>>>>  GETTER FUNCTIONS - INTERNAL UTILS  <<<<<<<<<<<<<<<<<<<<<< ///

    function dropStarted(uint256 dropId) internal view returns (bool) {
        StandardAuctionDrop storage stdAuction = StandardAuctionSaleStorage
            .layout()
            .drops[dropId];

        return block.timestamp >= stdAuction.listingStart;
    }

    function dropExists(uint256 dropId) internal view returns (bool) {
        return
            StandardAuctionSaleStorage.layout().drops[dropId].collection !=
            address(0);
    }

    /// >>>>>>>>>>>>>>>>>>>>>  DROP MANAGEMENT  <<<<<<<<<<<<<<<<<<<<<< ///

    /// @notice publishes a standard auction drop
    /// @param dropId The id of the drop.
    /// @param collectionAddress The address of the collection contract
    /// @param merkleRoot The new root for the drop items
    /// @param startingPrice The starting price of the drop.
    /// @param listingStart The auction listingStart timestamp
    /// @param auctionPeriod The auction duration, in seconds
    /// @param numItems Number of items in the drop
    function publishDrop(
        uint256 voucherId,
        uint256 dropId,
        address collectionAddress,
        bytes32 merkleRoot,
        uint96 startingPrice,
        uint128 listingStart,
        uint32 auctionPeriod,
        uint32 numItems
    ) public onlyRole(MANAGER_ROLE) whenNotPaused {
        StandardAuctionSaleStorage.Layout
            storage layout = StandardAuctionSaleStorage.layout();

        if (dropExists(dropId)) revert DuplicateDrop(dropId);
        if (listingStart < block.timestamp) revert InvalidDropStart();
        if (numItems == 0) revert ItemsRequired();

        StandardAuctionDrop storage newDrop = layout.drops[dropId];
        newDrop.collection = collectionAddress;
        newDrop.startingPrice = startingPrice;
        newDrop.listingStart = listingStart;
        newDrop.auctionPeriod = auctionPeriod;
        newDrop.numItems = numItems;
        newDrop.merkleRoot = merkleRoot;

        emit StandardAuctionDropPublished(
            voucherId,
            dropId,
            collectionAddress,
            merkleRoot,
            startingPrice,
            listingStart,
            auctionPeriod,
            numItems
        );
    }

    /// @notice over-writes an existing standard auction drop
    /// @param dropId The id of the drop.
    /// @param merkleRoot The new root for the drop items
    /// @param startingPrice The starting price of the drop.
    /// @param listingStart The auction listingStart timestamp
    /// @param auctionPeriod The auction duration, in seconds
    function rePublishDrop(
        uint256 voucherId,
        uint256 dropId,
        bytes32 merkleRoot,
        uint96 startingPrice,
        uint128 listingStart,
        uint32 auctionPeriod,
        uint32 numItems
    ) public onlyRole(MANAGER_ROLE) whenNotPaused {
        StandardAuctionSaleStorage.Layout
            storage layout = StandardAuctionSaleStorage.layout();

        StandardAuctionDrop storage stdAuction = layout.drops[dropId];

        if (stdAuction.cancelled) revert DropCancelled(dropId);
        if (!dropExists(dropId)) revert DropNotFound(dropId);

        if (block.timestamp < stdAuction.listingStart) {
            if (listingStart < block.timestamp) revert InvalidDropStart();
            if (numItems == 0) revert ItemsRequired();

            layout.drops[dropId].startingPrice = startingPrice;
            layout.drops[dropId].listingStart = listingStart;
            layout.drops[dropId].auctionPeriod = auctionPeriod;
            layout.drops[dropId].numItems = numItems;
            layout.drops[dropId].merkleRoot = merkleRoot;

            emit StandardAuctionDropRePublished(
                voucherId,
                dropId,
                merkleRoot,
                startingPrice,
                listingStart,
                auctionPeriod,
                numItems
            );
        } else {
            // If Drop has started, only price is allowed to change
            // possibly have dedicated `editPrice` function instead? Not refactoring yet due to frequent changes before MVP go-live
            layout.drops[dropId].startingPrice = startingPrice;

            emit StandardAuctionDropRePublished(
                voucherId,
                dropId,
                stdAuction.merkleRoot,
                startingPrice,
                stdAuction.listingStart,
                stdAuction.auctionPeriod,
                stdAuction.numItems
            );
        }
    }

    /// @notice over-writes an existing standard auction drop
    /// @param dropId The id of the drop.
    /// @param startingPrice The starting price of the drop.
    /// @param listingStart The auction listingStart timestamp
    /// @param auctionPeriod The auction duration, in seconds
    function adminRePublishDrop(
        uint256 dropId,
        uint96 startingPrice,
        uint128 listingStart,
        uint32 auctionPeriod
    ) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        StandardAuctionSaleStorage.Layout
            storage layout = StandardAuctionSaleStorage.layout();

        StandardAuctionDrop storage stdAuction = layout.drops[dropId];

        if (stdAuction.cancelled) revert DropCancelled(dropId);
        if (!dropExists(dropId)) revert DropNotFound(dropId);

        if (block.timestamp < stdAuction.listingStart) {
            if (listingStart < block.timestamp) revert InvalidDropStart();

            layout.drops[dropId].startingPrice = startingPrice;
            layout.drops[dropId].listingStart = listingStart;
            layout.drops[dropId].auctionPeriod = auctionPeriod;

            emit StandardAuctionDropAdminRePublished(
                dropId,
                startingPrice,
                listingStart,
                auctionPeriod
            );
        } else {
            // do not edit the listingStart after the listing started!
            layout.drops[dropId].startingPrice = startingPrice;
            layout.drops[dropId].auctionPeriod = auctionPeriod;

            emit StandardAuctionDropAdminRePublished(
                dropId,
                startingPrice,
                stdAuction.listingStart,
                auctionPeriod
            );
        }
    }

    /// @notice prevents minting in a drop
    /// @param dropId The id of the drop.
    function cancelDrop(uint256 voucherId, uint256 dropId)
        public
        onlyRole(MANAGER_ROLE)
        whenNotPaused
    {
        StandardAuctionSaleStorage.Layout
            storage layout = StandardAuctionSaleStorage.layout();

        StandardAuctionDrop storage stdAuction = layout.drops[dropId];

        if (!dropExists(dropId)) revert DropNotFound(dropId);
        if (stdAuction.cancelled) revert DropCancelled(dropId);

        if (dropStarted(dropId)) revert DropStarted(dropId);

        // cancel first to avoid re-entrancy
        layout.drops[dropId].cancelled = true;
        emit StandardAuctionDropCancelled(voucherId, dropId);
    }

    /// @notice prevents minting in a drop
    /// @param dropId The id of the drop.
    function adminCancelDrop(uint256 dropId)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused
    {
        StandardAuctionSaleStorage.Layout
            storage layout = StandardAuctionSaleStorage.layout();

        StandardAuctionDrop storage stdAuction = layout.drops[dropId];

        if (!dropExists(dropId)) revert DropNotFound(dropId);
        if (stdAuction.cancelled) revert DropCancelled(dropId);

        // cancel first to avoid re-entrancy
        layout.drops[dropId].cancelled = true;
        emit StandardAuctionDropAdminCancelled(dropId);
    }

    /// >>>>>>>>>>>>>>>>>>>>>  BIDDING  <<<<<<<<<<<<<<<<<<<<<< ///

    function _bid(
        uint256 dropId,
        uint256 itemId,
        address newBidder,
        bytes32[] calldata proof
    ) internal whenNotPaused isNotBlackListed(newBidder) {
        StandardAuctionSaleStorage.Layout
            storage layout = StandardAuctionSaleStorage.layout();

        StandardAuctionDrop storage stdAuction = layout.drops[dropId];

        if (!dropExists(dropId)) revert DropNotFound(dropId);
        if (stdAuction.cancelled) revert DropCancelled(dropId);
        if (block.timestamp < stdAuction.listingStart)
            revert DropNotStarted(dropId);
        if (itemSold(dropId, itemId)) revert ItemSold(dropId, itemId);
        if (!isItemInDrop(dropId, itemId, proof))
            revert ItemNotFound(dropId, itemId);

        StandardAuctionItemBid storage currentBid = layout.bids[dropId][itemId];

        if (newBidder == address(0)) revert BidderZeroAddress();
        if (newBidder == currentBid.highestBidder) revert AlreadyBid();

        uint256 minBid = minimumBid(dropId, itemId);

        if (msg.value < minBid) revert BidTooLow(msg.value, minBid);
        if (msg.value <= currentBid.highestBid) revert BidTooLow(msg.value, currentBid.highestBid);

        uint256 previousBid = currentBid.highestBid;
        address previousBidder = currentBid.highestBidder;

        // replace values immediately to avoid re-entrancy
        layout.bids[dropId][itemId].highestBidder = newBidder;
        layout.bids[dropId][itemId].highestBid = uint96(msg.value);

        if (previousBidder != address(0)) {
            payable(previousBidder).transfer(previousBid);

            emit BidRefunded(dropId, itemId, previousBidder, previousBid);
            emit ItemBid(dropId, itemId, newBidder, msg.value);
        } else {
            stdAuction.firstBidTime[itemId] = block.timestamp;
            emit ItemFirstBid(dropId, itemId, newBidder, msg.value);
        }
    }

    function authorizedBid(BidAuth calldata bidAuth)
        public
        payable
        validateBidAuth(bidAuth)
    {
        // expire the nonce immediately to avoid re-entrancy
        StandardAuctionSaleStorage.layout().vouchersUsed[bidAuth.id] = true;

        _bid(bidAuth.dropId, bidAuth.itemId, bidAuth.bidder, bidAuth.proof);
    }

    /// >>>>>>>>>>>>>>>>>>>>>  VOUCHER VALIDATION  <<<<<<<<<<<<<<<<<<<<<< ///

    /// @notice internal util to validate authorization vouchers
    /// @param signer signer's address
    /// @param voucherId the voucher id (voucher id)
    /// @param voucherId the voucher id (voucher id)
    /// @param validFrom signature validity period start
    /// @param validPeriod signature validity period duration
    function validateVoucher(
        address signer,
        uint256 voucherId,
        uint256 validFrom,
        uint256 validPeriod
    ) internal view {
        if (signer == address(0) || !hasRole(MANAGER_ROLE, signer))
            revert InvalidAuthorizationSignature();

        if (StandardAuctionSaleStorage.layout().vouchersUsed[voucherId])
            revert VoucherUsed();

        if (block.timestamp <= validFrom)
            revert VoucherNotValidYet(validFrom, block.timestamp);

        if (validPeriod > 0 && block.timestamp > (validFrom + validPeriod))
            revert AuthorizationExpired(
                validFrom + validPeriod,
                block.timestamp
            );
    }

    /// @notice modifier to validate a drop management authorization voucher
    /// @param mintAuth drop management authorization voucher struct, containing the parameters to mint an item:
    /// @param mintAuth.id - voucher id
    /// @param mintAuth.r - signature
    /// @param mintAuth.s - signature
    /// @param mintAuth.v - signature
    /// @param mintAuth.validFrom - signature validity period start
    /// @param mintAuth.validPeriod - signature validity period duration
    /// @param mintAuth.dropType - the type of drop: FixedPrice or StandardAuction
    /// @param mintAuth.dropId - The id of the drop
    /// @param mintAuth.itemId - The item id that will be minted
    /// @param mintAuth.to - the address where the minted item will be transferred
    /// @param mintAuth.proof - merkle proof for item id
    modifier validateMintAuth(
        MintAuth calldata mintAuth,
        string calldata uri,
        bytes calldata data
    ) {
        if (mintAuth.dropType != DropType.StandardAuction)
            revert InvalidDropType();

        bytes32 digest = ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    mintAuth.id,
                    mintAuth.validFrom,
                    mintAuth.validPeriod,
                    mintAuth.dropId,
                    mintAuth.itemId,
                    mintAuth.proof,
                    mintAuth.dropType,
                    mintAuth.to,
                    mintAuth.quantity,
                    keccak256(abi.encodePacked(uri)),
                    data
                )
            )
        );

        address signer = ECDSA.recover(
            digest,
            mintAuth.v,
            mintAuth.r,
            mintAuth.s
        );

        validateVoucher(
            signer,
            mintAuth.id,
            mintAuth.validFrom,
            mintAuth.validPeriod
        );

        _;
    }

    /// @notice modifier to validate a standard auction bid authorization voucher
    /// @param bidAuth drop management authorization voucher struct, containing the parameters to mint an item:
    /// @param bidAuth.id - voucher id
    /// @param bidAuth.r - signature
    /// @param bidAuth.s - signature
    /// @param bidAuth.v - signature
    /// @param bidAuth.validFrom - signature validity period start
    /// @param bidAuth.validPeriod - signature validity period duration
    /// @param bidAuth.dropId - The id of the drop
    /// @param bidAuth.itemId - The item id that will be minted
    /// @param bidAuth.bidder - the bidder's address
    modifier validateBidAuth(BidAuth calldata bidAuth) {
        if (bidAuth.dropType != DropType.StandardAuction)
            revert InvalidDropType();

        if (bidAuth.bidder != msg.sender)
            revert VoucherBidderNotMatching(bidAuth.bidder, msg.sender);

        bytes32 digest = ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    bidAuth.id,
                    bidAuth.validFrom,
                    bidAuth.validPeriod,
                    bidAuth.dropType,
                    bidAuth.dropId,
                    bidAuth.itemId,
                    bidAuth.bidder,
                    bidAuth.proof
                )
            )
        );

        address signer = ECDSA.recover(digest, bidAuth.v, bidAuth.r, bidAuth.s);

        validateVoucher(
            signer,
            bidAuth.id,
            bidAuth.validFrom,
            bidAuth.validPeriod
        );

        _;
    }

    /// >>>>>>>>>>>>>>>>>>>>>  MINTING  <<<<<<<<<<<<<<<<<<<<<< ///

    /// @notice mints an item in the drop
    /// @param mintAuth an auth voucher struct containing the parameters to mint an item
    function authorizedMint(
        MintAuth calldata mintAuth,
        string calldata uri,
        bytes calldata data
    ) public payable validateMintAuth(mintAuth, uri, data) {
        // expire the nonce immediately to avoid re-entrancy
        StandardAuctionSaleStorage.layout().vouchersUsed[mintAuth.id] = true;

        _mint(mintAuth, uri, data);
    }

    /// @notice mints an item in the drop
    /// @param mintAuth an auth voucher struct containing the parameters to mint an item
    /// @param uri The item's uri
    /// @param data additional params for the mint function
    function _mint(
        MintAuth calldata mintAuth, // Reuse struct otherwise stack too deep
        string calldata uri,
        bytes calldata data
    ) internal whenNotPaused {
        StandardAuctionSaleStorage.Layout
            storage layout = StandardAuctionSaleStorage.layout();

        if (layout.minter == address(0)) revert InvalidAddress();
        if (msg.value > 0) revert NoValueNeeded();

        StandardAuctionDrop storage stdAuction = layout.drops[mintAuth.dropId];

        if (!dropExists(mintAuth.dropId)) revert DropNotFound(mintAuth.dropId);
        if (stdAuction.cancelled) revert DropCancelled(mintAuth.dropId);

        if (!isItemInDrop(mintAuth.dropId, mintAuth.itemId, mintAuth.proof))
            revert ItemNotFound(mintAuth.dropId, mintAuth.itemId);

        if (!itemSold(mintAuth.dropId, mintAuth.itemId))
            revert ItemNotSold(mintAuth.dropId, mintAuth.itemId);

        StandardAuctionItemBid storage currentBid = layout.bids[
            mintAuth.dropId
        ][mintAuth.itemId];

        if (currentBid.minted) revert ItemAlreadyMinted(mintAuth.itemId);

        if (
            (currentBid.highestBid <= 0) ||
            (currentBid.highestBidder == address(0))
        ) revert NoBid();
        if (mintAuth.to != currentBid.highestBidder) revert NotHighestBidder();

        if (currentBid.refunded) revert AlreadyRefunded();

        layout.drops[mintAuth.dropId].numMinted++;
        layout.bids[mintAuth.dropId][mintAuth.itemId].minted = true;

        IMinterceptor minterceptor = IMinterceptor(layout.minter);
        // transfer bid funds to Minterceptor contract & mint item
        minterceptor.mintByUri{value: currentBid.highestBid}(
            mintAuth.id,
            stdAuction.collection,
            mintAuth.itemId,
            mintAuth.to,
            uri,
            data
        );
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}