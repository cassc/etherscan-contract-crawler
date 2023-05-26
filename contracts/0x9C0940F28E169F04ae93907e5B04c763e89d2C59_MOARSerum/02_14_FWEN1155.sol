// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "../erc/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

error NonAdmin();
error NonMinter();
error NonExistentToken();
error MetadataFrozen();
error BurningInactive();
error NonOwnerOrApproved();
error RoyaltyPercentageExceed();

contract FWEN1155 is ERC1155, IERC2981, Ownable {
    using Strings for uint256;

    // =========== AccessControl ===========
    address public admin;
    mapping(address => bool) public minters;

    // ================== Supply ==================
    mapping(uint256 => uint256) public totalSupply;

    // ======= Metadata =======
    bool public metadataFrozen;
    string internal _baseURI;

    // ======= Burning =======
    bool public burningActive;

    // ========= Royalties ==========
    address internal _royaltyAddress;
    uint256 internal _royaltyPercent;

    /**
     * @dev Constructor function.
     * @param admin_ admin role
     * @param royaltyAddress royalty fee receiver address
     */
    constructor(address admin_, address royaltyAddress) ERC1155() {
        admin = admin_;
        _royaltyAddress = royaltyAddress;
        _royaltyPercent = 4;
    }

    /**
     * @dev Throws if called by any account other than `admin`.
     */
    modifier onlyAdmin() {
        if (admin != msg.sender) { revert NonAdmin(); }
        _;
    }

    /**
     * @dev Throws if called by any account other than `minters`.
     */
    modifier onlyMinter() {
        if (!minters[msg.sender]) { revert NonMinter(); }
        _;
    }

    /**
     * @dev Sets `admin`
     * @param newAdmin the new `admin` address
     *
     * Requirements:
     *
     * - the caller must be `owner`.
     */
    function setAdmin(address newAdmin) external virtual onlyOwner {
        admin = newAdmin;
    }

    /**
     * @dev Updates `minters`
     * @param minter the minter address to be updated
     * @param valid if the address a valid minter
     *
     * Requirements:
     *
     * - the caller must be `owner`.
     */
    function updateMinter(address minter, bool valid) external virtual onlyAdmin {
        minters[minter] = valid;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Toggles `burningActive`, and `metadataFrozen`
     * @param flag the flag to toggle
     *
     * Requirements:
     *
     * - the caller must be `admin`.
     */
    function toggleFlag(uint256 flag) external virtual onlyAdmin {
        if (flag == uint256(keccak256("BURN")))
            burningActive = !burningActive;
        else if (flag == uint256(keccak256("METADATA")))
            metadataFrozen = true;
    }

    /**
     * @dev Sets base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     * @param baseURI base URI to set
     *
     * Requirements:
     *
     * - the caller must be `admin`.
     */
    function setBaseURI(string memory baseURI) external virtual onlyAdmin {
        if (metadataFrozen) { revert MetadataFrozen(); }
        _baseURI = baseURI;
    }

    /**
     * @dev Returns the URI for a given token ID
     * Throws if the token ID does not exist.
     * @param tokenId uint256 ID of the token to query
     */
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        if (!exists(tokenId)) { revert NonExistentToken(); }
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     * @param id uint256 ID of the token to query
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return totalSupply[id] > 0;
    }

    /**
     * @dev Creates new tokens with same tokenId for `to`
     * @param to owner of new tokens
     * @param id tokenId of new tokens
     * @param amount amount of new tokens
     * @param data additional data, it has no specified format and it is sent in call to `to`.
     *
     * Requirements:
     *
     * - the caller must be `minter`.
     */
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external virtual onlyMinter {
        _mint(to, id, amount, data);
    }

    /**
     * @dev Creates new tokens with multiple tokenIds for `to`
     * @param to owner of new tokens
     * @param ids tokenIds of new tokens
     * @param amounts amounts of each tokenId
     * @param data additional data, it has no specified format and it is sent in call to `to`.
     *
     * Requirements:
     *
     * - the caller must be `minter`.
     */
    function mintBatch(address to,uint256[] memory ids, uint256[] memory amounts, bytes memory data) external virtual onlyMinter {
        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` of `tokenId` which belongs to `from`
     * Throws if the caller is not token owner or approved
     * @param from token owner
     * @param id tokenId of the token to be destroyed
     * @param amount amount of the tokenId to be destroyed
     */
    function burn(address from, uint256 id, uint256 amount) external virtual {
        if (!burningActive) { revert BurningInactive(); }
        if (from != msg.sender && !isApprovedForAll(from, msg.sender)) { revert NonOwnerOrApproved(); }

        _burn(from, id, amount);
    }

    /**
     * @dev Destroys multi `tokenIds` which belong to `from`
     * Throws if the caller is not token owner or approved
     * @param from token owner
     * @param ids tokenIds of the tokens to be destroyed
     * @param amounts amounts of the tokenIds to be destroyed
     */
    function burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) external virtual {
        if (!burningActive) { revert BurningInactive(); }
        if (from != msg.sender && !isApprovedForAll(from, msg.sender)) { revert NonOwnerOrApproved(); }

        _burnBatch(from, ids, amounts);
    }

    /**
     * @dev Sets royalty info for all tokens
     * @param royaltyReceiver address to receive royalty fee
     * @param royaltyPercentage percentage of royalty fee
     *
     * Requirements:
     *
     * - the caller must be the contract owner.
     */
    function setRoyaltyInfo(address royaltyReceiver, uint256 royaltyPercentage) external virtual onlyOwner {
        if (royaltyPercentage > 100) { revert RoyaltyPercentageExceed(); }
        _royaltyAddress = royaltyReceiver;
        _royaltyPercent = royaltyPercentage;
    }

    /**
     * @dev See {IERC2981-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view virtual override returns (address receiver, uint256 royaltyAmount){
        if (!exists(tokenId)) { revert NonExistentToken(); }
        return (_royaltyAddress, (salePrice * _royaltyPercent) / 100);
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        ERC1155._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    totalSupply[id] = supply - amount;
                }
            }
        }
    }
}