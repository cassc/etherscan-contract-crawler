// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "src/ManageableUpgradeable.sol";
import "./IBaselArtFixedPriceSale.sol";
import "../interfaces/IMintByUri.sol";
import "../libs/Errors.sol";
import "./BaselArtFixedPriceSaleStorage.sol";
import "../../QuantumBlackListable.sol";

error DropPriceNotMatching(uint256 dropId);
error ItemNotMinted(uint256 dropId, uint256 itemId);

contract BaselArtFixedPriceSale is
    IBaselArtFixedPriceSale,
    OwnableUpgradeable,
    ManageableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    /// >>>>>>>>>>>>>>>>>>>>>  EVENTS  <<<<<<<<<<<<<<<<<<<<<< ///
    event BaselArtFixedPriceDropPublished(
        uint256 indexed dropId,
        address indexed collection,
        uint256[] itemIds,
        uint256 price,
        uint256 start
    );
    event BaselArtFixedPriceDropRePublished(
        uint256 indexed dropId,
        uint256[] itemIds,
        uint256 price,
        uint256 start
    );
    event BaselArtFixedPriceDropCancelled(uint256 indexed dropId);

    /// >>>>>>>>>>>>>>>>>>>>>  INITIALIZER  <<<<<<<<<<<<<<<<<<<<<< ///
    function initialize(
        address admin,
        address minter,
        address blacklist,
        address payable artist,
        address payable treasury
    ) public virtual initializer {
        __BaselArtFixedPriceSale_init(
            admin,
            minter,
            blacklist,
            artist,
            treasury
        );
    }

    function __BaselArtFixedPriceSale_init(
        address admin,
        address minter,
        address blacklist,
        address payable artist,
        address payable treasury
    ) internal onlyInitializing {
        __Ownable_init();
        __Manageable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        __BaselArtFixedPriceSale_init_unchained(
            admin,
            minter,
            blacklist,
            artist,
            treasury
        );
    }

    function __BaselArtFixedPriceSale_init_unchained(
        address admin,
        address minter,
        address blacklist,
        address payable artist,
        address payable treasury
    ) internal onlyInitializing {
        BaselArtFixedPriceSaleStorage.Layout
            storage layout = BaselArtFixedPriceSaleStorage.layout();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(MANAGER_ROLE, admin);
        setBlacklist(blacklist);
        setPayout(artist, treasury);

        layout.minter = minter;
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

        BaselArtFixedPriceSaleStorage.layout().minter = minter;
    }

    /// @notice set payout address
    /// @param artist address of artist
    /// @param treasury address of quantum treasury
    function setPayout(address payable artist, address payable treasury)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        BaselArtFixedPriceSaleStorage.Layout
            storage m = BaselArtFixedPriceSaleStorage.layout();
        m.artistAddress = artist;
        m.treasuryAddress = treasury;
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

    modifier notPaused() {
        if (paused()) revert ContractPaused();
        _;
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
            uint256[] memory,
            uint128,
            uint256,
            bool,
            uint32
        )
    {
        BaselArtFixedPriceDrop memory fpDrop = BaselArtFixedPriceSaleStorage
            .layout()
            .drops[dropId];

        return (
            fpDrop.collection,
            fpDrop.itemIds,
            fpDrop.price,
            fpDrop.start,
            fpDrop.cancelled,
            fpDrop.numMinted
        );
    }

    /// @notice gets the item's tokenId
    /// @param dropId The id of the drop.
    /// @param itemId The id of the minted item.
    function itemOwner(uint256 dropId, uint256 itemId)
        public
        view
        returns (address)
    {
        BaselArtFixedPriceSaleStorage.Layout
        storage fp = BaselArtFixedPriceSaleStorage.layout();

        if (fp.itemOwners[dropId][itemId] == address(0x0)) revert ItemNotMinted(dropId, itemId);

        return (fp.itemOwners[dropId][itemId]);
    }

    /// @notice gets the number of items that can still be minted
    /// @param dropId The id of the drop.
    function remainingItems(uint256 dropId) public view returns (uint32) {
        BaselArtFixedPriceDrop memory fpDrop = BaselArtFixedPriceSaleStorage
            .layout()
            .drops[dropId];
        return uint32(fpDrop.itemIds.length) - fpDrop.numMinted;
    }

    /// >>>>>>>>>>>>>>>>>>>>>  GETTER FUNCTIONS - INTERNAL UTILS  <<<<<<<<<<<<<<<<<<<<<< ///

    /// @notice internal utility to check if a drop is sold out
    /// @param dropId The id of the drop
    function isSoldOut(uint256 dropId) internal view returns (bool) {
        BaselArtFixedPriceDrop memory fpDrop = BaselArtFixedPriceSaleStorage
            .layout()
            .drops[dropId];

        return
            fpDrop.numMinted > 0 && (fpDrop.numMinted == fpDrop.itemIds.length);
    }

    /// @notice internal utility to check if an item is part of a drop
    /// @param dropId The id of the drop.
    /// @param itemId The id of the item.
    function isItemInDrop(uint256 dropId, uint256 itemId)
        internal
        view
        returns (bool)
    {
        uint256[] memory itemIds = BaselArtFixedPriceSaleStorage
            .layout()
            .drops[dropId]
            .itemIds;

        for (uint8 i; i < itemIds.length; i++) {
            if (itemIds[i] == itemId) return true;
        }
        return false;
    }

    /// >>>>>>>>>>>>>>>>>>>>>  DROP MANAGEMENT  <<<<<<<<<<<<<<<<<<<<<< ///

    /// @notice creates a fixed price drop
    /// @param dropId The id of the drop.
    /// @param collection The address of the collection contract
    /// @param price The price of the drop.
    /// @param start The block timestamp at which the drop starts
    /// @param itemIds The list of item id's that will be part of the drop
    function publishDrop(
        uint256 dropId,
        address collection,
        uint256[] calldata itemIds,
        uint128 price,
        uint256 start
    ) public onlyRole(MANAGER_ROLE) notPaused {
        BaselArtFixedPriceSaleStorage.Layout
            storage fp = BaselArtFixedPriceSaleStorage.layout();

        if (fp.drops[dropId].itemIds.length > 0) revert DuplicateDrop(dropId);
        if (start < block.timestamp) revert InvalidDropStart();
        if (itemIds.length == 0) revert ItemsRequired();

        fp.drops[dropId] = BaselArtFixedPriceDrop(
            collection,
            itemIds,
            price,
            start,
            false,
            0
        );

        emit BaselArtFixedPriceDropPublished(
            dropId,
            collection,
            itemIds,
            price,
            start
        );
    }

    /// @notice over-writes an existing fixed price drop
    /// @param dropId The id of the drop.
    /// @param price The price of the drop.
    /// @param start The block timestamp at which the drop starts
    /// @param itemIds The list of item id's that will be part of the drop
    function rePublishDrop(
        uint256 dropId,
        uint256[] calldata itemIds,
        uint128 price,
        uint256 start
    ) public onlyRole(MANAGER_ROLE) notPaused {
        BaselArtFixedPriceSaleStorage.Layout
            storage layout = BaselArtFixedPriceSaleStorage.layout();

        BaselArtFixedPriceDrop memory fpDrop = layout.drops[dropId];

        if (fpDrop.cancelled) revert DropCancelled(dropId);
        if (fpDrop.itemIds.length == 0) revert DropNotFound(dropId);

        emit BaselArtFixedPriceDropRePublished(dropId, itemIds, price, start);

        // before start, anything can change (except for collection address)
        if (block.timestamp < fpDrop.start) {
            if (start < block.timestamp) revert InvalidDropStart();
            if (itemIds.length == 0) revert ItemsRequired();

            layout.drops[dropId].itemIds = itemIds;
            layout.drops[dropId].price = price;
            layout.drops[dropId].start = start;

            emit BaselArtFixedPriceDropRePublished(
                dropId,
                itemIds,
                price,
                start
            );
        } else {
            // If Drop has started, only price is allowed to change
            // possibly have dedicated `editPrice` function instead? Not refactoring yet due to frequent changes before MVP go-live
            layout.drops[dropId].price = price;

            emit BaselArtFixedPriceDropRePublished(
                dropId,
                fpDrop.itemIds,
                price,
                fpDrop.start
            );
        }
    }

    /// @notice prevents minting in a drop
    /// @param dropId The id of the drop.
    function cancelDrop(uint256 dropId)
        public
        onlyRole(MANAGER_ROLE)
        notPaused
    {
        BaselArtFixedPriceSaleStorage.Layout
            storage layout = BaselArtFixedPriceSaleStorage.layout();

        BaselArtFixedPriceDrop memory fpDrop = layout.drops[dropId];

        if (fpDrop.itemIds.length == 0) revert DropNotFound(dropId);
        if (fpDrop.cancelled) revert DropCancelled(dropId);

        layout.drops[dropId].cancelled = true;

        emit BaselArtFixedPriceDropCancelled(dropId);
    }

    /// >>>>>>>>>>>>>>>>>>>>>  BLACKLIST OPS  <<<<<<<<<<<<<<<<<<<<<< ///
    modifier isNotBlackListed(address user) {
        if (
            QuantumBlackListable.isBlackListed(
                user,
                BaselArtFixedPriceSaleStorage.layout().blackListAddress
            )
        ) {
            revert UserBlackListed();
        }
        _;
    }

    /// @notice update the blacklist contract
    /// @param blacklist The address of the blacklist contract
    function setBlacklist(address blacklist)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        BaselArtFixedPriceSaleStorage.Layout
            storage m = BaselArtFixedPriceSaleStorage.layout();
        m.blackListAddress = blacklist;
    }

    /// >>>>>>>>>>>>>>>>>>>>>  MINTING  <<<<<<<<<<<<<<<<<<<<<< ///

    /// @notice pays quantum artist and treasury from mint value
    function payout() internal {
        BaselArtFixedPriceSaleStorage.Layout
            storage fp = BaselArtFixedPriceSaleStorage.layout();

        uint256 payout_ = (msg.value * 9500) / 10000;
        fp.artistAddress.transfer(payout_);
        fp.treasuryAddress.transfer(msg.value - payout_);
    }

    /// @notice mints an item in the drop
    /// @param dropId The id of the drop.
    /// @param itemId The id of the item to be minted.
    function _mint(
        uint256 dropId,
        uint256 itemId,
        string memory uri,
        bytes memory data
    ) public payable notPaused isNotBlackListed(msg.sender) {
        BaselArtFixedPriceSaleStorage.Layout
            storage fp = BaselArtFixedPriceSaleStorage.layout();
        if (fp.minter == address(0)) revert InvalidAddress();

        BaselArtFixedPriceDrop memory fpDrop = fp.drops[dropId];

        if (fpDrop.itemIds.length == 0) revert DropNotFound(dropId);
        if (fpDrop.cancelled) revert DropCancelled(dropId);
        if (block.timestamp < fpDrop.start) revert DropNotStarted(dropId);
        if (isSoldOut(dropId)) revert DropSoldOut(dropId);
        if (msg.value != fpDrop.price) revert DropPriceNotMatching(dropId);
        if (!isItemInDrop(dropId, itemId)) revert ItemNotFound(dropId, itemId);

        IMintByUri collection = IMintByUri(fp.minter);

        fp.itemOwners[dropId][itemId] = msg.sender;
        fp.drops[dropId].numMinted++;

        collection.mint(msg.sender, uri, data);
        payout();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}