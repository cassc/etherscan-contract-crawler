// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "../erc/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

error NonAdmin();
error MetadataFrozen();
error BurnningInactive();
error TransferDeactive();
error TransferLocked();
error TransferLockedByAdmin();
error RoyaltyPercentageExceed();
error ArrayLengthMismatch();

contract MoarBase is ERC721, IERC2981, Ownable {
    using Strings for uint256;

    // ==== Admin Role ====
    address private _admin;

    // ======= Metadata =======
    bool public metadataFrozen;
    string private _baseURI;

    // ======= Burning =======
    bool public burningActive;

    // ================================= Transfer ==================================
    enum LockStatus {
        Unlock,
        LockByAdmin,
        LockByTokenOwner
    }

    bool public transferDeactive;
    mapping ( uint256 => LockStatus ) public transferLocks;

    event LockTransfer(address indexed owner, uint256 indexed tokenId, bool locked);

    // ======== Royalties ==========
    address private _royaltyAddress;
    uint256 private _royaltyPercent;

    /**
     * @dev Initializes the contract by setting a `default_admin` of the token access control.
     */
    constructor(address admin, address royaltyAddress ) {
        _admin = admin;
        _royaltyAddress = royaltyAddress;
        _royaltyPercent = 6;
    }

    /**
     * @dev Throws if called by any account other than the `_admin`.
     */
    modifier onlyAdmin() {
        if (_admin != _msgSender())  { revert NonAdmin(); }
        _;
    }

    /**
     * @dev Sets `_admin` address
     * @param admin new admin address to set
     *
     * Requirements:
     *
     * - `saleOn` must be false,
     * - the caller must be `owner`.
     */
    function setAdmin( address admin) external onlyOwner {
        _admin = admin;
    }

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return "MOAR by Joan Cornella";
    }

    /**
     * @dev Returns the token collection symbol
     */
    function symbol() public view virtual override returns (string memory) {
        return "MOAR";
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

/**
     * @dev Sets base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     * @param baseURI base URI to set
     *
     * Requirements:
     *
     * - the caller must be owner.
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        if (metadataFrozen) { revert MetadataFrozen(); }
        _baseURI = baseURI;
    }

    /**
     * @dev Returns the URI for a given token ID
     * Throws if the token ID does not exist.
     * @param tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) { revert NonExistentToken(); }
        if (bytes(_baseURI).length > 0)
            return string(abi.encodePacked(_baseURI, tokenId.toString()));
        return string(abi.encodePacked("https://metadata.thefwenclub.com/moar/", tokenId.toString()));
    }

    /**
     * @dev Toggles `burningActive`, `transferActive` and `metadataFrozen`
     *
     * Requirements:
     *
     * - the caller must be `owner`.
     */
    function toggleFlag(uint256 flag) public virtual onlyOwner {
        if (flag == uint256(keccak256("BURN")))
            burningActive = !burningActive;
        else if (flag == uint256(keccak256("TRANSFER")))
            transferDeactive = !transferDeactive;
        else if (flag == uint256(keccak256("METADATA")))
            metadataFrozen = true;
    }

    /**
     * @dev Destroys `tokenId`.
     * Throws if the caller is not token owner or approved
     * @param tokenId uint256 ID of the token to be destroyed
     */
    function burn(uint256 tokenId) external {
        if (!burningActive) { revert BurnningInactive(); }
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) {revert NonOwnerOrApproved(); }
        _burn(tokenId);
    }

    /**
     * @dev Set royalty info for all tokens
     * @param royaltyReceiver address to receive royalty fee
     * @param royaltyPercentage percentage of royalty fee
     *
     * Requirements:
     *
     * - the caller must be the contract owner.
     */
    function setRoyaltyInfo(address royaltyReceiver, uint256 royaltyPercentage) public onlyOwner {
        if (royaltyPercentage > 100) { revert RoyaltyPercentageExceed(); }
        _royaltyAddress = royaltyReceiver;
        _royaltyPercent = royaltyPercentage;
    }

    /**
     * @dev See {IERC2981-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount){
        if (!_exists(tokenId)) { revert NonExistentToken(); }
        return (_royaltyAddress, (salePrice * _royaltyPercent) / 100);
    }

    /**
     * @dev See {ERC721-_transfer}.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        if (transferDeactive) { revert TransferDeactive(); }
        if (transferLocks[tokenId] != LockStatus.Unlock) { revert TransferLocked(); }
        super._transfer(from, to, tokenId);
    }

    /**
     * Locks the transfer of a particular tokenId. This is designed for a non-escrowstaking contract
     * that comes later to lock a user's NFT while still letting them keep it in their wallet.
     *
     * @param tokenId The ID of the token to lock.
     * @param locked The status of the lock; true to lock, false to unlock.
     *
     * Requirements:
     *
     * - the caller must be the token owner or approved.
     */
    function lockTransfer (uint256 tokenId, bool locked) external {
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) { revert NonOwnerOrApproved(); }
        if (transferLocks[tokenId] == LockStatus.LockByAdmin) { revert TransferLockedByAdmin(); }

        transferLocks[tokenId] = locked ? LockStatus.LockByTokenOwner : LockStatus.Unlock;
        emit LockTransfer(ERC721.ownerOf(tokenId), tokenId, locked);
    }

    /**
     * Locks the transfer of tokenIds. This is designed for a non-escrowstaking contract
     * that comes later to lock a user's NFT while still letting them keep it in their wallet.
     *
     * @param tokenIds The IDs of the token to lock.
     * @param locks The status of the lock; true to lock, false to unlock.
     *
     * Requirements:
     *
     * - the caller must be `_admin`.
     */
    function lockTransfers (uint256[] memory tokenIds, bool[] memory locks) external onlyAdmin {
        if (tokenIds.length != locks.length) { revert ArrayLengthMismatch(); }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            transferLocks[tokenIds[i]] = locks[i] ? LockStatus.LockByAdmin : LockStatus.Unlock;
            emit LockTransfer(ERC721.ownerOf(tokenIds[i]), tokenIds[i], locks[i]);
        }
    }
}