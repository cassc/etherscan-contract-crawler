/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: erc721a/contracts/IERC721A.sol


// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// File: erc721a/contracts/ERC721A.sol


// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;


/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Bypass for a `--via-ir` bug (https://github.com/chiru-labs/ERC721A/pull/364).
    struct TokenApprovalRef {
        address value;
    }

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // The next token ID to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See {_packedOwnershipOf} implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    // - [232..255] `extraData`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => TokenApprovalRef) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view virtual returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return _burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    // If not burned.
                    if (packed & _BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an initialized ownership slot
                        // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                        // before an unintialized ownership slot
                        // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                        // Hence, `curr` will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed will be zero.
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) public payable virtual override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId].value;
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, _BITMASK_ADDRESS)
            // `msgSender == owner || msgSender == approvedAddress`.
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedSlotAndAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId].value`.
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `tokenId` - Token ID to be transferred.
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            uint256 toMasked;
            uint256 end = startTokenId + quantity;

            // Use assembly to loop and emit the `Transfer` event for gas savings.
            // The duplicated `log4` removes an extra check and reduces stack juggling.
            // The assembly, together with the surrounding Solidity code, have been
            // delicately arranged to nudge the compiler into producing optimized opcodes.
            assembly {
                // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
                toMasked := and(to, _BITMASK_ADDRESS)
                // Emit the `Transfer` event.
                log4(
                    0, // Start of data (0, since no data).
                    0, // End of data (0, since no data).
                    _TRANSFER_EVENT_SIGNATURE, // Signature.
                    0, // `address(0)`.
                    toMasked, // `to`.
                    startTokenId // `tokenId`.
                )

                // The `iszero(eq(,))` check ensures that large values of `quantity`
                // that overflows uint256 will make the loop run out of gas.
                // The compiler will optimize the `iszero` away for performance.
                for {
                    let tokenId := add(startTokenId, 1)
                } iszero(eq(tokenId, end)) {
                    tokenId := add(tokenId, 1)
                } {
                    // Emit the `Transfer` event. Similar to above.
                    log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
                }
            }
            if (toMasked == 0) revert MintToZeroAddress();

            _currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            _currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = _currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) revert();
            }
        }
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, '');
    }

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}

// File: suki-pets.sol

//SPDX-License-Identifier: MIT  
pragma solidity ^0.8.11;  



  
contract Sukipets is ERC721A, Ownable{  
    using Strings for uint;

    mapping(address=>uint256) public maxCanMint;
    mapping(address=>uint256) public numberMinted;
    string private _baseURIextended = "ipfs://QmU4G6otJ7FYasnykeqsDGeLhWSvvuUPHmdfJ4DsygcaX6/";
    string private beforeRevealUri = "ipfs://Qmbmt585oeuuzVRfUAq52KZs2RQQsBrzQqFkmCDBisYFCV";
    bool revealed = false;
    bool paused = true;

    constructor() ERC721A("Sukipets", "Suki") {
        maxCanMint[0xCDB3C2C1C0f4f8AB403bDF4C396F5A9e4B4F2DBa] = 125;
        maxCanMint[0x858F7b8Afe8bAC89b527C35C31259013AEce9e89] = 100;
        maxCanMint[0xE72EB31b59F85b19499A0F3b3260011894FA0d65] = 90;
        maxCanMint[0x5511cE8264Dff56eDBC0DC1714f0e5Be0DAE635F] = 79;
        maxCanMint[0x9059B7c20390161aF7A8fD2aAc21f1b9ac7b22BE] = 77;
        maxCanMint[0x48F51Ef910aa37E5e1Ba417d285fd09C60cE477E] = 74;
        maxCanMint[0xf5B9Deb10215a6F6D268EFCA2509E5Be7a25De2B] = 74;
        maxCanMint[0x74aC45c146bcAA47A227C87a32860eb8aC3e57C4] = 66;
        maxCanMint[0x57524EfC73e194e4F19DC1606FB7a3E1Dbf719B3] = 66;
        maxCanMint[0xB5696E4057B9BA76616cEcB5A537eAcA7B3CDf54] = 54;
        maxCanMint[0x3685f876710d70c47AEBFe558e92f71745a0A868] = 51;
        maxCanMint[0xbd2F02451E6B79556E4E3ef43a7F386BBDBba920] = 50;
        maxCanMint[0xdc2D12cDEFe1b3B9060692a5d47015d219286077] = 50;
        maxCanMint[0xbAaBA861464F25f52c2eE10CC3AC024F4f77812a] = 48;
        maxCanMint[0xbC05cC5C18a71EB09d46ba76f58B368223eFfB87] = 46;
        maxCanMint[0x4a9C0C0C98Aa321a5A2f225aaB93D56b064fF65f] = 44;
        maxCanMint[0xF2c06f90FB58844C09220e01E3116A2293Df6960] = 43;
        maxCanMint[0x89f42ccb1B90103A4b886Cc8ee01979492808079] = 43;
        maxCanMint[0x6AD244466777fB941917deAb621e922B1fEAdD85] = 42;
        maxCanMint[0x46e449a3f88D0E35b4520bC36e8DFDA195c896B0] = 40;
        maxCanMint[0x803ba0999D81111cfbCe278Dc6473F3B5EBB0b33] = 40;
        maxCanMint[0x50F27CdB650879A41fb07038bF2B818845c20e17] = 40;
        maxCanMint[0xA05aFa2FEc1CbF8d81b087Ab869C3E18d31B91F5] = 37;
        maxCanMint[0x644c38c61499E5856d42c975c048E4DC298957f9] = 36;
        maxCanMint[0xA5f09C6f40Aa9b8f7AD70d64c42e20df1aD1F0F4] = 35;
        maxCanMint[0xf03b5F229A14B53094D9566642Fb5e2e7273586d] = 35;
        maxCanMint[0xd5B6513eF79398924A444E0e60679Ae7B24A8850] = 35;
        maxCanMint[0xF8F3c1dbc6575874B2C0BcaeA553b05d2600cFe6] = 34;
        maxCanMint[0x80e52d1211c635F25dD9A43d2F04eB9e5d722209] = 32;
        maxCanMint[0x56879cc88fa3895C082C22035dB1386DcAc53bba] = 31;
        maxCanMint[0x683C3ac15e4E024E1509505B9a8F3f7B1A1cFf1e] = 30;
        maxCanMint[0xF24A733aA13f3a49069ccF86d52E7798aB4cc069] = 30;
        maxCanMint[0x9f68273597Bf21F3106972547af2F0b6B57542a7] = 29;
        maxCanMint[0x9fdAF0bD765561FBD609ea28Ea67A39054CB28bB] = 27;
        maxCanMint[0xA3C277b8f35881CBdb017E52bcC376B3ce8F21dA] = 27;
        maxCanMint[0x401CC1B6620e30ade449BB8f593a0d0799FbAC93] = 27;
        maxCanMint[0xd64e10DC8b85F21EA73E09a491d0D6782a476ebf] = 26;
        maxCanMint[0x64493b8a91B74dAC11254bee50E482F3090708E1] = 26;
        maxCanMint[0x126438c3A64DA4eF5a8dde07366270367310f855] = 26;
        maxCanMint[0x6299aED920679C4a680Fb53A0E63B8f878208878] = 25;
        maxCanMint[0xc7b438Bf83ad6f69BD8409bE5faF5C2dbde624e3] = 25;
        maxCanMint[0xDC9cF37de275199d863f7253eAa1063406282302] = 25;
        maxCanMint[0x6a167aBE38959433aaaA984B3d50761aC60ee875] = 25;
        maxCanMint[0xB6218ED3763b5f0e65AaC362259aDB0c73F33570] = 25;
        maxCanMint[0xEab7CD40143bDF4B1bF360E6717914Ca022b8ea6] = 24;
        maxCanMint[0xf2E9db3c5D06015833Df31eD3C37172a2B34EE7F] = 24;
        maxCanMint[0xC665A60F22dDa926B920DEB8FFAC0EF9D8a17460] = 23;
        maxCanMint[0x38bf30d3F1528BBD2BB8A242E9a0F4405affb8d0] = 22;
        maxCanMint[0x5Cb51D06d8da391Cc359ba996Bd10Ced0f7cf249] = 22;
        maxCanMint[0x772326885AB95f131031Ffb8560E4D97778A2488] = 22;
        maxCanMint[0xa750818e28ff0f8cd50182eEC34E316dF8fF792c] = 22;
        maxCanMint[0x17fBa501Df40e83605D01fBEF7f68174537E361A] = 22;
        maxCanMint[0xDF12161AfaF4367F130bBd7aEb50abFfCE612619] = 22;
        maxCanMint[0xDf71cb01E0eFaa639459Cf191f98463BE4B4a438] = 21;
        maxCanMint[0xdBfd836c989E1FE9586cB0D1BFB35E7849Be23a5] = 21;
        maxCanMint[0xf00bae4D8266000aA5C012baa693D8C12E4edF08] = 21;
        maxCanMint[0x2604fb7B2c561D6a277a0EC8c2308A26CEe18272] = 20;
        maxCanMint[0x0338CE5020c447f7e668DC2ef778025CE398266B] = 20;
        maxCanMint[0xEB3648865b1471996e5F65Ae845F9Eb9226B9a02] = 20;
        maxCanMint[0xa6134EB7381978804646088Df4BB42c5232D82Da] = 20;
        maxCanMint[0x7419aCdbC0F58E8bC449bc180736cD41153e2A4A] = 20;
        maxCanMint[0xe8B102C80969012f49cDdfeB834211517b33F0e2] = 19;
        maxCanMint[0xe0dC2949fdbe146acb64f32F814a9d6f49DD7e72] = 19;
        maxCanMint[0x9A58B8934Cb846431D6f7E8EdF91Eb0a1A31126a] = 19;
        maxCanMint[0x42F3f76Ba5202D7A4C48fD428B5613c657689BCC] = 18;
        maxCanMint[0x0846931641992A70d393771b5D9A1AB8ad5b2F28] = 18;
        maxCanMint[0x3546BD99767246C358ff1497f1580C8365b25AC8] = 18;
        maxCanMint[0x754C807eb8F31B277814976f08245D5052cBEADd] = 18;
        maxCanMint[0x1D88ED266B159e02504f5ACA17755B0394E375DD] = 17;
        maxCanMint[0xE19153EC0Dd84f092a1E81Ff7DA27F7d014E7EcF] = 17;
        maxCanMint[0x1565e23aBE9C15C714B662B77C87ED9a61ee19D2] = 17;
        maxCanMint[0x202AC9a140c49fffc51AcD4c65272A339fb9Ef02] = 17;
        maxCanMint[0x00D29fBc981d05edBA69BC0909E391a132271357] = 17;
        maxCanMint[0x6b4331048c411795a89D54484E3653107D58a64E] = 17;
        maxCanMint[0xAe73A7a38C6c04E2cC9EC3c416F48185ecD26F7B] = 17;
        maxCanMint[0x8b338b8380755D416d892a0d7793BEf75f6105ea] = 16;
        maxCanMint[0x97DD415191b68B589d47271D2ab1bc389Db33Aa0] = 16;
        maxCanMint[0x5AB5844Dd55Ab73212D1527e4CF72FEA884e39DD] = 16;
        maxCanMint[0x2218cd12c0402e3fd3693148DE476B299f658675] = 16;
        maxCanMint[0x49b9cA9214559E8819fa7889BB2AdC28330d5133] = 16;
        maxCanMint[0x6cef15E37392F13d0873dc18497CA8087C681e01] = 15;
        maxCanMint[0x7Ed716a3c0a634fa033CAD0e53BC5fDBc838e23B] = 15;
        maxCanMint[0x87ffC50E4E55dF07dD4437bE29931CBd9e2AA345] = 15;
        maxCanMint[0x92b7a519317acA2895455A179E5742Ec2BE06a48] = 15;
        maxCanMint[0x59e2337D163A7E7694f868b6e503400119E11e54] = 15;
        maxCanMint[0xD13397383D0B65531F4B1F545e20CBA18f063Ee3] = 15;
        maxCanMint[0x8dF99c988C718DC83D1AeF1bF60f21B00046b7dB] = 15;
        maxCanMint[0x9c07606F19575780a208402731Bc7C8169D7ad50] = 14;
        maxCanMint[0xE37fcAA787701C471c7841b0651060a7441a5d04] = 14;
        maxCanMint[0xc2B330e15b59ADC48097d6345cfd1b7444741664] = 14;
        maxCanMint[0xC383ed33ae4DEc3181806db17eFC22C5CF853f02] = 14;
        maxCanMint[0xc4DaD120712A92117Cc65D46514BE8B49ED846a1] = 14;
        maxCanMint[0xe68d37fC77aC92C709643783426D45E96e4e437a] = 14;
        maxCanMint[0x728B3DE78C3bD3e9c970524cA6aae1f8D6A61996] = 14;
        maxCanMint[0x12C012D2bF99dE146c6C7465b81647Abc56C9110] = 14;
        maxCanMint[0x121EE2b015888a6d0D4a925ea41C0CAf78C8D54a] = 13;
        maxCanMint[0x0e8CF84cb1eB4D7aE149014437b12c54f782c148] = 13;
        maxCanMint[0x4A4a10Bf794619c0b8361Be60EF60C8E50397796] = 12;
        maxCanMint[0xe4bBCbFf51e61D0D95FcC5016609aC8354B177C4] = 12;
        maxCanMint[0xb8454b3E34EabFaB14B1119cc657aE2CaAa12f06] = 12;
        maxCanMint[0xA99062EB6933A449C1C7F2adE4cc356E50a38C93] = 12;
        maxCanMint[0xf983557eC70fbf1A4B1e247AF7Bf10247E9B69c4] = 12;
        maxCanMint[0x1bAb11011E459C452edaFc962CB0113301535A3D] = 12;
        maxCanMint[0x777bef8D44c5EfE02F3C0a705EC3bff613C82a9C] = 12;
        maxCanMint[0xF0B1235f8BeEEe6b6DA7Fd065cc0E8Abc8b5c170] = 12;
        maxCanMint[0xf8B3b8432aB49Fe071F386f0917981994d7a164D] = 12;
        maxCanMint[0x2aA139151910B409896994A97Ce4aE9e9641b1E2] = 12;
        maxCanMint[0x77D0F704fC514d82c3a712D348Cf3889ab02307B] = 11;
        maxCanMint[0xD7272f37e384B594e885237aa29013cB49295e14] = 11;
        maxCanMint[0x4f7d8d1310ea5C238A98c525F080A6eDf6Ff8c6a] = 11;
        maxCanMint[0x1e8eBAA6D9BF90ca2800F97C95aFEDd6A64C91e2] = 11;
        maxCanMint[0x1c64a937Eb94C8dAAAa1F721B2208661e52657Cc] = 11;
        maxCanMint[0x22892d4D59b28C530d58932504B666388c125566] = 11;
        maxCanMint[0x3E4D97C22571C5Ff22f0DAaBDa2d3835E67738EB] = 11;
        maxCanMint[0x3abA81c64364dE5ed0bc8dCB78Ed1538C33B0FDF] = 11;
        maxCanMint[0x04028198E451f64212c33CA22cB3b1FbA6272459] = 11;
        maxCanMint[0x5FF840DB03FCb71e9AFe70CD5966610E21c2d634] = 11;
        maxCanMint[0x75331eBbE0B00b97cAb532384F13c9B479F074eC] = 11;
        maxCanMint[0x8AA7f50D61338d9c26601b0c8936b771c365D0E5] = 11;
        maxCanMint[0x50F808e2876c025A2322883EB084C58528cF930D] = 11;
        maxCanMint[0x2927a6Ba73aD0A156D5260F0f85bBbDe0625daaF] = 11;
        maxCanMint[0x0A9931aB317d8398e7316F7889f6CA39de328699] = 11;
        maxCanMint[0x5B97106fa5D8686a447B3bC6A98Fd0fbA35Dd314] = 11;
        maxCanMint[0x6AE73a69536bf213D70625312624b880A3f1efAF] = 11;
        maxCanMint[0x535fbDca6B64121e393cA0F90037C209269380bd] = 10;
        maxCanMint[0xf54611A627aFA7c00a58569932554372dD3F4b3B] = 10;
        maxCanMint[0xd555b5555855F08504F57AbFBC6410D26C995bEe] = 10;
        maxCanMint[0x16F5617073952DaAbC5Aad5A75000dd29B48Ca60] = 10;
        maxCanMint[0x19607BfF45627bE7979d154aF503122c6C3fd6e1] = 10;
        maxCanMint[0xD01235368C40a11D80dee1D7F809F2e00247a0Bc] = 10;
        maxCanMint[0x7ac2C842a100963C34E6D05e9ace9f3e367eD140] = 10;
        maxCanMint[0x71331f76038117f177446DFF68139Cd068b3d5cE] = 10;
        maxCanMint[0xc5F59709974262c4AFacc5386287820bDBC7eB3A] = 10;
        maxCanMint[0x273d140F7A2199d59603a6b03A08369a473C5E88] = 10;
        maxCanMint[0x43c7C3943A181774FD1791742EF6b42d671E30c3] = 10;
        maxCanMint[0xb71B13b85D2c094B0FDeC64ab891b5BF5f110a8e] = 10;
        maxCanMint[0xe916Ad4CE7A5558e84d2924D13Cee50299c02446] = 10;
        maxCanMint[0xaF62994A7a1E5C4A4B88Ca3550F0637afeC0877f] = 10;
        maxCanMint[0x0Ff1302cD9B14f71ACF639C484600a60Dd27Dd0F] = 10;
        maxCanMint[0x5FD2C02689d138547B7b1b9E7d9A309d5A03edCd] = 10;
        maxCanMint[0x0bc7815F29EdE74742d7377821506f705Cf0D809] = 10;
        maxCanMint[0x8bea67D814FFB834Dcd2Fe4b1b1f35C70bcda420] = 10;
        maxCanMint[0x5Eb67a3b141f3036899EE77822A41277166c540e] = 10;
        maxCanMint[0xdbCc6698d4686EE3fba49c2245072460594efE6E] = 10;
        maxCanMint[0x26D7B4fe67f4601643304b5023b3CAF3A72E8504] = 10;
        maxCanMint[0x2F1390eC03A03e57a1406BDef57c9cF487f62B78] = 9;
        maxCanMint[0x102A618b36C32b338C03526255DCF2A39eB1897f] = 9;
        maxCanMint[0x7056443b73BD19E5F20E1ABE733FaDd602A13BDD] = 9;
        maxCanMint[0xF7ABE060EA1E437383665ea6702e0C48722931F5] = 9;
        maxCanMint[0xd4Eaa41Ce286518E3fbC0f09fd613347fC4C6C20] = 9;
        maxCanMint[0x96f844BeED7d89d22c760f000066CE8f76b23301] = 9;
        maxCanMint[0x711281C1b26AaEd86E40e4cAaf76c1962B45E161] = 9;
        maxCanMint[0xC373a84E54efb5c64dd8ba4f3Aed914926137bfC] = 9;
        maxCanMint[0x58c32253E3633608bdd19BC6A062A90FB063AE77] = 9;
        maxCanMint[0x0D174e0AEde78eeACa12420493C27d8f68151D15] = 9;
        maxCanMint[0x12093977A68A38e0452f7ab6e6871479F01a975a] = 9;
        maxCanMint[0x758e83c114E36a28CA1f31C4d2ADB5Ec7c04C578] = 9;
        maxCanMint[0x766a6923A62d062fa6Da59f91d9b669A85bc7B15] = 9;
        maxCanMint[0xAF1CC56A81AE3Db157b73Db4dBCd20907DB5793f] = 9;
        maxCanMint[0xFd4848aCDC68b55C9352c59722EaC9292668f7cf] = 9;
        maxCanMint[0xD9b42f222263C31e57d90A77217759EE6701B204] = 9;
        maxCanMint[0xbF119e78c70BDc031C87993CCC3C8423f00D4B5d] = 8;
        maxCanMint[0xB5E14DCf2520d154606254094f32C8D32D509115] = 8;
        maxCanMint[0x5BE8f739C8Ea94D99b44ab0B1421889c8b99b2E1] = 8;
        maxCanMint[0x2Ec7b0b01d7c72a31F3834FE4f208C4D04d1CDAC] = 8;
        maxCanMint[0xD00d3f8Fe21226E74dB52419ff67Cd3FfC009078] = 8;
        maxCanMint[0xaC66ACa609591d6a4a97432EB2E838E533D3BB33] = 8;
        maxCanMint[0x7dD2C9f1CcE194AEc1dC6fA3548a8E6dAFc5F4B2] = 8;
        maxCanMint[0x2BDF1a698d39A4358e2C162dEacc038FAdb8A9d5] = 8;
        maxCanMint[0x71DF5D0FDB96883F9B47f0A433445bDf64609440] = 8;
        maxCanMint[0x4Ede472ac52fA969c502c6f4344A16a99196d9bC] = 8;
        maxCanMint[0xd6D7Ea4833f22edBED3DbD3d71Adf3cdD8E36a01] = 8;
        maxCanMint[0x091e2f9422A22a09E478455Fd59bE8CB6ee56463] = 8;
        maxCanMint[0xB99aF14667098ee10d4379c933e14d3d034a79Bc] = 8;
        maxCanMint[0xB3343E623d7a6860881ed9b178Ecb22796812396] = 8;
        maxCanMint[0xe10772c3c2e8879b13d5d2886eF8e9f9B95b83Aa] = 7;
        maxCanMint[0x34cC62A979B2F4A3D757a6527aD6835C6284B6B9] = 7;
        maxCanMint[0xd4Db6d8Ef756141DE0D838808Ddb8fFCd847D7ff] = 7;
        maxCanMint[0xFaA39BB9Ec02DA01292C957F486A38Df9bA7093f] = 7;
        maxCanMint[0xB4C6cA259B15E7Bcc3d3c5c7D364A2c4EfD42Cf0] = 7;
        maxCanMint[0x3BFA05f792851A693a7B95bAf6c1DC59C8fE42aC] = 7;
        maxCanMint[0x2b5bF359827D89A1aF72444241357cEE6EBAD2cf] = 7;
        maxCanMint[0x92e0049C4Cdd67512bdA9ba4dce55b554ACF44fF] = 7;
        maxCanMint[0x9C512f927E1eCDd8851Dc846da79e0668B5B58b3] = 7;
        maxCanMint[0xe5217a66F5D92F444593f53892f7dc9527f1731D] = 7;
        maxCanMint[0xf576DAE6F10ea36a4dFaDE275Aa576560E3b4b4A] = 7;
        maxCanMint[0xd547226AaC3878aB4b4C6f7063af810d439B0C3D] = 7;
        maxCanMint[0xB41738fDf7efEaA0b70Cf322916C6491746B785b] = 7;
        maxCanMint[0x3595A1508CB1180E8e7F50008Db1109F5293eFC5] = 7;
        maxCanMint[0x049043E57A8a9FC11d95f620aD2ef6c359F52BB6] = 7;
        maxCanMint[0x7B8c81492592357D57221299d4794751d619CA2A] = 7;
        maxCanMint[0xB58007c1990a0ae29f0D34543714BAf168149F82] = 7;
        maxCanMint[0x1D9cdcBC9C414FABD0d0b50f69d4385877Ac7279] = 7;
        maxCanMint[0xC8Ed3c2d1509FCf3A3C97c68De3DBa66381d337C] = 7;
        maxCanMint[0xd6F6E99c4905c6e8A751Bb0aFeEFA8Dcc56a30dC] = 7;
        maxCanMint[0xeA884574a7B1ce52D0Fdc2f4Ac4862183D3Feaf4] = 6;
        maxCanMint[0x77AF9774Afccc8feE8105f4ECD1f96ba9a878A40] = 6;
        maxCanMint[0xD335E1B1EDb5b92DF2D1C1112D1bE08f34d912bD] = 6;
        maxCanMint[0xD874f397202b032e2611cf999ff737Da419233E9] = 6;
        maxCanMint[0x9A0944626Acae8708265DbB2177CE89004d3A593] = 6;
        maxCanMint[0xc59292b1caf144F2877a88b120B4E71e48385569] = 6;
        maxCanMint[0xeCf14386BF1F271AEcb5407e777D41e8a16933b7] = 6;
        maxCanMint[0x0e447fb04462372D905fF8ffAe3A075eE7B2bDC6] = 6;
        maxCanMint[0x716BAE0a89A5635d9233B6E99e4a20c48959f5F9] = 6;
        maxCanMint[0xA522048F3084d25cDDb5b7BbA83374272322Eb61] = 6;
        maxCanMint[0xA98D2867de6b1dFf44Fe4b355DEa098E81d06aEb] = 6;
        maxCanMint[0x13d73e760833f68647Db4a94602F61895c0B5e92] = 6;
        maxCanMint[0xf29155745c8Ee222d4F7d6A2a7a50c1901F27de2] = 6;
        maxCanMint[0x650D62F4F149c0F8578bfDc5fDC04C4d0BE8B5cE] = 6;
        maxCanMint[0x920d838e76A6B5cB6355e8d8f2A9aC2655FdAAFf] = 6;
        maxCanMint[0xeb6Bc3940C9fe8D7A90BAeB168F64F2FeCD9A5cE] = 6;
        maxCanMint[0x847c1B4F34E93D2ae81B9D099c3E52F53d9aBEa2] = 6;
        maxCanMint[0x679AC673368119aC02daca310E8fC6A08E8ddf81] = 6;
        maxCanMint[0x518944Eb64B16A66A78ae5E6298cA8e321417fdC] = 6;
        maxCanMint[0xECC74B40a057eFf408bC9eb3fA90226EF69Df200] = 6;
        maxCanMint[0x8e2Ed01aF1a58cDe920204aBc5E27fC42c628646] = 6;
        maxCanMint[0x42Dca0244DCA7872B3096c91b98CaAB45e1aCFB6] = 6;
        maxCanMint[0x879253B5Cc2B13bb976e075F0571F85454A315f6] = 6;
        maxCanMint[0xc0B498FFed0B32Cb1458688c40f22342f82b8089] = 6;
        maxCanMint[0xE02A25580b96BE0B9986181Fd0b4CF2b9FD75Ec2] = 5;
        maxCanMint[0x7Cf3d9Ca9136F95C60c7428D5b23D18549c57DC4] = 5;
        maxCanMint[0x67e5cF1fD5e5e1944731800C789CA1B17af81873] = 5;
        maxCanMint[0x5804f53931f3E690459f3A4AA654B794EecF15CD] = 5;
        maxCanMint[0x6E83f03becEfaC2623564EE8F9983Ff76D67A556] = 5;
        maxCanMint[0x7155B42aE4Fe9D3db9fb0d8448759e5F87FfE6D9] = 5;
        maxCanMint[0x3EDEB829dDC8763B3C1e77223E71b7370FD1B8C2] = 5;
        maxCanMint[0x012E168ACb9fdc90a4ED9fd6cA2834D9bF5b579e] = 5;
        maxCanMint[0x2ED5ab4D78053B9cAe07fFD772c445265a280225] = 5;
        maxCanMint[0xC4ca31a2c3974EB1FDe8694529c65aDF654ce665] = 5;
        maxCanMint[0xAC32Ea503C5e3E03d7E079d7fba99A168Fd69B6B] = 5;
        maxCanMint[0xB219b6c4b4C4ccEfD7066871aB20486a283aC27e] = 5;
        maxCanMint[0xB61D414164Ed30F49Bd612Fd827D399aB39739D8] = 5;
        maxCanMint[0xb719C471a5A9228Ad9459D2caEc9eABC71c2B42B] = 5;
        maxCanMint[0x7C2f06ab61a94fe9760cC8d9ad35A33c0472CB8E] = 5;
        maxCanMint[0x247BCDaaeE715428a0a8b02B79a641C051F3A111] = 5;
        maxCanMint[0x255Be6D417D25d553414fb9608EF6303af9EB771] = 5;
        maxCanMint[0xb5FCF39eB16F0F4886753d2bfa6A74145a938c6C] = 5;
        maxCanMint[0xaa584127b91100DdE6b52228C28848A7B1D059c9] = 5;
        maxCanMint[0x34756D8400f2426851dc46D6ab38F0Df004CE1E7] = 5;
        maxCanMint[0x27DB134012676a0542c667c610920e269AFE89B9] = 5;
        maxCanMint[0x317AABc1A970390b88EA43147D1B104391e5Afb5] = 5;
        maxCanMint[0x1C7B647AddBf316a882cb84a2a099d99eFf8cf9e] = 5;
        maxCanMint[0x00110599200B90b8A7ea20e1d50d2d0c6bEB00e3] = 5;
        maxCanMint[0xc0Ff4140D577077554c5B2fFFA334896a47BD0B8] = 5;
        maxCanMint[0xE527CE94580057c75468E22f470ad6A31d93607E] = 5;
        maxCanMint[0x1CE9d62Ac3DD1b897d582cDa4075793ee8D0bfD3] = 5;
        maxCanMint[0x35F0899275E52406A6f5F0c8854347Ff334D02EA] = 5;
        maxCanMint[0xEc6FbB231D6d80DC18C9ae3BB64CfE0548eE7Ec6] = 5;
        maxCanMint[0xB349607b1eB483D7BAE309B3ddC1fAc2897dc37b] = 5;
        maxCanMint[0xCF4cA3Cf56923A1D70BB90a6EAeC3eeFe6E39ECC] = 5;
        maxCanMint[0x963Cad32ea383670F81a1e78806A8Cf727c31670] = 5;
        maxCanMint[0x9b173f8c1f1942de6fa0055A4e91d72c0d770826] = 5;
        maxCanMint[0xb3792F424f8A8c65B8fF8430ec6859fB1187c0c1] = 5;
        maxCanMint[0x5b17d1AEe4A5a9b0b86e6DD727955Bd56ff0AaB4] = 5;
        maxCanMint[0x73E4a2B60Cf48E8BaF2B777E175a5B1E4D0C2d8f] = 5;
        maxCanMint[0x989019429a17fe4d7b6593566f459e4C1AF90dbb] = 5;
        maxCanMint[0x7e345A2A7C6AB50eeBa694b4a5f98898ecA59bCC] = 5;
        maxCanMint[0x541dE0606257132E4cA0E34439FCB6675ce2857b] = 5;
        maxCanMint[0xFc1953FFBdc5F89b9231E8aF9D304eb011F09E1C] = 5;
        maxCanMint[0xC851c83E912e704D6C7d8b3863b506fFe56B0711] = 5;
        maxCanMint[0xdD15553673126d386f9E735d0cc56a96E59Cc095] = 4;
        maxCanMint[0xe1e2E153e785118Fa7b50e93e6b8cf887F025Bc7] = 4;
        maxCanMint[0x4dAdAFcad7131ED274bc99FC8EB916520a19dA3f] = 4;
        maxCanMint[0x002947f3aDD48ED81d3575Bc4e1E9F50744eF856] = 4;
        maxCanMint[0x0Dd70E248a98C9ceBF1431048f593Eb1CcA3EF43] = 4;
        maxCanMint[0x7F2466ae8bADee7Dc0109Edd0b6Dde08C432236c] = 4;
        maxCanMint[0x7d043B98F65d1F0eF30BDD15DA9149B869162e78] = 4;
        maxCanMint[0x66C4051052a318099a6aAdc65C32B9e0b6026B51] = 4;
        maxCanMint[0x6041f881358C71D64bc9253c9ba0391DF69F7d98] = 4;
        maxCanMint[0x61194c3494A607d30f1c272Fa5E95C14934D0c50] = 4;
        maxCanMint[0x34383A9f83C86Eceb3748fb89fd9be2805c8B02c] = 4;
        maxCanMint[0x013598ea3fd28608C23ebac199c5B4218e2adE3A] = 4;
        maxCanMint[0x23af11044229183E0181c0D47CD2151529C85998] = 4;
        maxCanMint[0x10662025145B7EAc2E41C4033828Ee044d0Ccf91] = 4;
        maxCanMint[0x209E86C762487978B7221DB46cBb7BcAC7088fC9] = 4;
        maxCanMint[0x35eC46646c5ae18d0A8ED57b67FD5bbBA4C5a9d4] = 4;
        maxCanMint[0x3c7Eab613cc0d396D464E9A8a36C39807d878F03] = 4;
        maxCanMint[0xD218d90B76a0bDc9A599f4C4F65FBA7a2140Baf8] = 4;
        maxCanMint[0xd210A01936a901c79254De8fC693f743E5757F8F] = 4;
        maxCanMint[0xDC6bCD40Bb59b65ee136437E52cf808F5614e03A] = 4;
        maxCanMint[0xc229d7D3dD662A1b107E29AA84bb0C8Ff609CF3A] = 4;
        maxCanMint[0xf87aB2a5e1a187169E9f2ce379196Ef0bdEfa726] = 4;
        maxCanMint[0x7BBC6F3CdCCFcf03CB062856E751b8950DAd812b] = 4;
        maxCanMint[0x6252F1aEeD803422cf152f1720c437389047Cf86] = 4;
        maxCanMint[0x369615Bc57975B06C418f42d3FDA3754A385B97b] = 4;
        maxCanMint[0x47Eeb072A8DAE3aB80b1E6123a44eCc80d2c49fF] = 4;
        maxCanMint[0xbf23B32f95694920c663c40416899e284aEa1284] = 4;
        maxCanMint[0x03f0e94Eb076174130D571FB46f5209eE7300Bc5] = 4;
        maxCanMint[0x4f764a08c66251e13bdd85B4Bb0652B739736328] = 4;
        maxCanMint[0x585020d9C6b56874B78979F29d84E082D34f0B2a] = 4;
        maxCanMint[0x6beEF2B2fE00FDDCa12A8CDA2D4B00435b0ba3b6] = 4;
        maxCanMint[0xBDe27a773b61863Ecae638647dA3489f1d6EA17E] = 4;
        maxCanMint[0xafD1e0562c91A933f4B40154045cEe71939E95eA] = 4;
        maxCanMint[0xB1Ec54030e383b9cE0cDAA988ba52364bFCe9c3C] = 4;
        maxCanMint[0xFcaE89f3319C760d4F481A522aa717AF81e93E77] = 4;
        maxCanMint[0xfF7efba11A8888d6974997d4a8940Bf83cd7a580] = 4;
        maxCanMint[0x247806e6de35d25E92803b67e8406EfFfAfE0804] = 4;
        maxCanMint[0x1Dbf0011d6094c7AFD594CF1699bb988302Cb77a] = 4;
        maxCanMint[0x04367Ecb39bB77ba7A61E31D91D7820324c3760E] = 4;
        maxCanMint[0x3204D904f61C3502050cAB4fDd241f0B6295cD8B] = 4;
        maxCanMint[0x25a940bC0cDF97B7A5ba9C76b6b048153f8EE247] = 4;
        maxCanMint[0x645C93A65946FF26331037a021c22851C8dA19Ac] = 4;
        maxCanMint[0x5C5bc3619FE3458E21887e1017Ba9EF6Ec5DeCE8] = 4;
        maxCanMint[0x689717c0B1Ab0f188235CfA487CeD32fEEbF9698] = 4;
        maxCanMint[0xaE416E324029AcB10367349234c13EDf44b0ddFD] = 4;
        maxCanMint[0x2cae0Ac9a7A7048516868AAd672C49AB632B38c8] = 4;
        maxCanMint[0x63F0a3660170A5c9cd4CA7b28B82f0011FFB37C4] = 4;
        maxCanMint[0xb6721C54Fc4BfC7bFA197CFFAbA58D6a70EA2F4B] = 4;
        maxCanMint[0xa719Fd2A38984d40902933Eb0290251787c37110] = 4;
        maxCanMint[0x2421eC23Ac1eE9141E431b2D6Cf3f7de6208D51a] = 4;
        maxCanMint[0x06fD7f49CA5bC7929A92B1C7B4639f049b413820] = 4;
        maxCanMint[0x131CFa6b38a8022A0d569bCe6247EEbc7DD6a65E] = 4;
        maxCanMint[0x89681c69de56e5867EB1cB0b444DF5690297a242] = 4;
        maxCanMint[0x568D19F28D550127577f3C371fC22A5514054968] = 4;
        maxCanMint[0x316808F098BF728570edB18e894A2e27c92F945F] = 4;
        maxCanMint[0x377e3fe216220c77FaE3fe2ec016b19c89253260] = 4;
        maxCanMint[0x3912d7eA8140e16dAc355892653F3512C3cf3749] = 4;
        maxCanMint[0x39317B24ca5bf020a6df2C332aD683A8A434c81A] = 4;
        maxCanMint[0xBCef707cc941c5F8D253fFc9899E7dc7cABE913C] = 4;
        maxCanMint[0xB8639881C532Cb9457F5b068E9CCfA3771399EFF] = 4;
        maxCanMint[0x996dE8e846D8BAe8751bB90e86a143C7a086e6D5] = 4;
        maxCanMint[0xE8A849B299aDED97C21bE9f93c20fa39783172b7] = 4;
        maxCanMint[0xee06Bd8B2A7630363BBB8AC4B90Bb3E7d2652a34] = 4;
        maxCanMint[0x93a692FE5477902C3cf5F6997c1cf59a3712cED4] = 3;
        maxCanMint[0xA5b17eF8bFbB9A1E9C55A5C21C52F50a9d9fEe6a] = 3;
        maxCanMint[0xA7D7Ac8Fe7e8693B5599C69cC7d4F6226677845B] = 3;
        maxCanMint[0xa8153eA1DcE111099C19C123DDC0E698D003FC47] = 3;
        maxCanMint[0xB98DffE8F3c069dC265Bd18A0ae9f6A7F6F678Ab] = 3;
        maxCanMint[0xC1E549320f048D8149d5B0cB9Cb268dA59f1F2aD] = 3;
        maxCanMint[0xCba19876EE8225CC54A1b5B3DcC660b40d2dcd66] = 3;
        maxCanMint[0xCCD97de4446ac858F1E772C4b98D9fC920A5Cc2c] = 3;
        maxCanMint[0xd10F2fCF380Cd0fE6628Ed0842e4Cc8a1F168117] = 3;
        maxCanMint[0x30B507aAA56EdEa94d9Bf08dc3A1885DB5E093aF] = 3;
        maxCanMint[0x28Dca5fF7Ac78BAB442C04Bc8fBbF9c768B125c9] = 3;
        maxCanMint[0x358EfDff791021c8a343FDf373872041229c27C1] = 3;
        maxCanMint[0x6EEf09B526d883F98762a7005FABD2c800DfCA44] = 3;
        maxCanMint[0x71D319eF3eE40b24E22f87898b9D261b77A423Bc] = 3;
        maxCanMint[0x87FCFE1B0EAE956b4c0A23E627D6FC9443C3B111] = 3;
        maxCanMint[0x8B40b81f83FEc3dd68A0dE41bE39BE2d5A52C04d] = 3;
        maxCanMint[0x8E05bD9fA3059eC69C15bc1a6F4D94f0Ac26ce00] = 3;
        maxCanMint[0x5Bca4075dFC8065235cF75C6b15B410e62845Fec] = 3;
        maxCanMint[0x58BDAacE5EA0Fa11f0Fb1c3cAEA5E3ceB1218dE5] = 3;
        maxCanMint[0x6d8431dFB4742157c660cE1070AF507aAFCF5A9B] = 3;
        maxCanMint[0x137d9174D3bd00F2153DcC0Fe7AF712d3876a71E] = 3;
        maxCanMint[0x1de2980970f80A2A957E6FBD7362F9EE7Dad2f9F] = 3;
        maxCanMint[0x3d223432095B6634d1779d43be9e6e0716124449] = 3;
        maxCanMint[0x477e0d5C6323fE7106E9fa39a5089baEcf5b0a93] = 3;
        maxCanMint[0xEEDA4E9a5Ca757e3a2dd9aB5d91E99C4a1FF0423] = 3;
        maxCanMint[0xB4E70352F1571a2CEED9cec00283b55cF52bD909] = 3;
        maxCanMint[0xaFbc3F98EEDB5f9A25a4AB2232d1346612efE77C] = 3;
        maxCanMint[0x9308c261Dc19178a8b81C07b80CaaDe0fF057f6e] = 3;
        maxCanMint[0x658da7a6d1e87E40846A3028E91dd615d1f39ef7] = 3;
        maxCanMint[0x56543717d994D09D5862AB9c6f99bCe964AE664a] = 3;
        maxCanMint[0x5bee4dF518Fe0F7606A2bA6336da33f7fD1E9273] = 3;
        maxCanMint[0x4ae8f6a32b956D3C1d18252c976aD4FB140f7A69] = 3;
        maxCanMint[0x8909DF3271e675cF648764Cd268c6C247334C884] = 3;
        maxCanMint[0x3B3Fc1f418Bef741a954403e5c6cCe50df4349E9] = 3;
        maxCanMint[0x8DBB0c0886D8a1c0C058094c7f9B83214584f93b] = 3;
        maxCanMint[0xA57876de5E9a0C58751b51f704cF2dB517788a6d] = 3;
        maxCanMint[0x96A38D33aB85ee3ea487de6d378D68C17CCe8989] = 3;
        maxCanMint[0x96F0239435B909D012D88fc8Cb4471786384bf67] = 3;
        maxCanMint[0x97A7F66Cc4f800dfB282d2eb0CD073b1E7B4aaa0] = 3;
        maxCanMint[0xA433d9C5915F197B3E24d42028b8C61345315C4e] = 3;
        maxCanMint[0xdA6787e118D0EeA60279eE36c4eec1ae3eeaCBe6] = 3;
        maxCanMint[0xbAABe3388e299336294a447bA56Ab880948A86F5] = 3;
        maxCanMint[0xee8a9d3A7D2aeF744262A895f8e2A6F74a91CEcc] = 3;
        maxCanMint[0x5E69D2Ed4Ea69d60E44Ff6AD676CF86841862c03] = 3;
        maxCanMint[0x6628B486a3E25772A8748e8fc8DebD0cc7564Ae3] = 3;
        maxCanMint[0x324A2EF0781bd84e4a367f142C324C16aC8914da] = 3;
        maxCanMint[0x2A03BE1ce58d21A2eCB3B3bc143b98057622ABE0] = 3;
        maxCanMint[0x46F655abF896301b72eb27B76F5e063899b9067C] = 3;
        maxCanMint[0x01A27d462cD43D86e8123f47CdFE6228DaD6D845] = 3;
        maxCanMint[0xb597B202294Dd5a4A616FCc2F178588BFc6D2c16] = 3;
        maxCanMint[0xA80974441DB857456F3205b9f1ca17436Fb7128F] = 3;
        maxCanMint[0xd52EBce9adc24A47ECbfBeABC8eF042590411C73] = 3;
        maxCanMint[0xDAE6cA75bB2aFD213E5887513D8b1789122EaAea] = 3;
        maxCanMint[0x7695Ea5De20f829Eb3161B6D5299D94Cb68F0E11] = 3;
        maxCanMint[0x8988609E3cd4bf52a0469a68DeBD21A53C1e027e] = 3;
        maxCanMint[0x8CC544C72Eec90Aa78f1ccD97258b435E4cd4c9D] = 3;
        maxCanMint[0x61aCd9FB7faE3C8026B868cbD4E00c2bD22908b4] = 3;
        maxCanMint[0x10E28f6c91184d75FD2773dCD00959cB6C08AB31] = 3;
        maxCanMint[0x3635B3d38B971ED37b17E6E1Ac685Af87bc8d930] = 3;
        maxCanMint[0x382Cc2a8c06364b0b14f8ce8904e7A358F830B9F] = 3;
        maxCanMint[0xc6eeA54B97f5754501Ca4f07fd5AB5482Ca3247A] = 3;
        maxCanMint[0xA06e3ecA46df7e71238ebD04fA627BFFC7d3EbDe] = 3;
        maxCanMint[0xA16E2A2A5Fd19F6C6347F3a5A7ac0187d6da2348] = 3;
        maxCanMint[0xd78fbdC173966E19031e8ce8358979cC0eE402Da] = 3;
        maxCanMint[0xE72eEEe16e51ccbEc900C7e1064120c75eFB88fE] = 3;
        maxCanMint[0x4D30A57E2B1Ed93baC382a3D89d28C95E8937B77] = 3;
        maxCanMint[0x39A2634D55C6dad47d8431E9DB0fcF70058dFEa2] = 3;
        maxCanMint[0x42Db77c4eE2260DDF31ecc9670Ed38bc8D61A811] = 3;
        maxCanMint[0x43cF525d63987D17052d9891587BCfB9592c3eE2] = 3;
        maxCanMint[0x456c8f06e6Dd3FCe8C8896F30535033a3F1Df35c] = 3;
        maxCanMint[0x133FC918b3A27fA314c45a08eC7EB794EF0283FC] = 3;
        maxCanMint[0x578b076f33C021ca8EC8873BE00c734559A99057] = 3;
        maxCanMint[0x70b1bCB7244fEDCaEa2C36dc939dA3a6f86aF793] = 3;
        maxCanMint[0x85A144Ceb815Aa88C7d770599AEF329B0d217148] = 3;
        maxCanMint[0xac18BAD4072a8dd2F5F6ac3dcA06d0f4BEC43e6B] = 3;
        maxCanMint[0xaEDa87F3F3d68337Ed3cf32D98DBbc94c380eBBC] = 3;
        maxCanMint[0xc1692cD69493436b01cddcbE5FeDbC911746A7C1] = 3;
        maxCanMint[0xbD3E3caEE39ED59A119cFe7360747Ca02C77D22D] = 3;
        maxCanMint[0xC708C777D0Eb401F50dC2Cbf8c2ACc4B0B2817a7] = 3;
        maxCanMint[0xe6354edB3D71A675210eAf9e007f37b82A04DDf6] = 3;
        maxCanMint[0xD89B835e9064D5f623F720bA368232D3C0a42886] = 3;
        maxCanMint[0xc27FD9D5113dE19EA89D0265Be9FD93F35f052c8] = 3;
        maxCanMint[0xa86Fd35dbB69502075CA2E265E534147999D265d] = 3;
        maxCanMint[0xb0002A56ce9Ca0881887DDA33c5EB3e18Ed4bb84] = 3;
        maxCanMint[0x96eCa8bCCdA5092898B7E664a45cDfC099F3BD3a] = 3;
        maxCanMint[0x93b3FAF1cfFF1C75c5456010287e30e6B00b57fE] = 3;
        maxCanMint[0x9078F31071946b1fBf8004bd86faeECbdA018fe6] = 3;
        maxCanMint[0x007c2249F1E2905106B555E28e3F6198cCE75EC6] = 3;
        maxCanMint[0x134F240827Dd4B047942589998a163A2A1002F1a] = 3;
        maxCanMint[0x433e23480F440Ef14f37c2b134133F3556C09e87] = 3;
        maxCanMint[0x57d4B4BA387f815467029851D9f1F751cedEec1A] = 3;
        maxCanMint[0x6acD98b7f9D818699ACEb70f5E87fe148CCbb988] = 3;
        maxCanMint[0x73e5f3c6Eb53C1Af075A4856449D5dcA59ABA999] = 3;
        maxCanMint[0x5e1127BE6dab460330E97E0DbB4912aCcf6Ea178] = 3;
        maxCanMint[0x5E3CDeF0c80dc57196243B693e971242513Ff6Cc] = 3;
        maxCanMint[0x6e3f8E093Fe749398aac60515686fC4FC4baC514] = 3;
        maxCanMint[0x79296381BD8690482376fe355E0F68dCa8BB6B4e] = 3;
        maxCanMint[0xA3B75D9023Bf8f78E674C7151091BD2eBe4c747C] = 3;
        maxCanMint[0x1057B6adB95680C811c256A393F5C523d94fd6a6] = 3;
        maxCanMint[0x14C9709c1a7615DaE2011e3F9a768b6B5f121fA7] = 3;
        maxCanMint[0x0D297417E7Db958CFBdc9c2c852Abe2F1f54E5eb] = 3;
        maxCanMint[0x419CD705b540eC01dAF54f10C98c3a643583D700] = 3;
        maxCanMint[0x448E9EdC342A54Ce9dbb6361c2A7cCa4dE7Cb9F7] = 3;
        maxCanMint[0xE0e76a34C17635ebFF5D80B1e387Fcdd4EEab863] = 3;
        maxCanMint[0xb699Dd31905Aad5d38718389367F28830CFFB330] = 3;
        maxCanMint[0xC1923cAe3b5ff75c87A1CEfA8E80e2985E1232A8] = 2;
        maxCanMint[0xCbaeEb4aD27791953368d3B2f6e24c4301dD366d] = 2;
        maxCanMint[0xdbEFee517025559E7898d3a48f18221C32D3Fcf5] = 2;
        maxCanMint[0xfB843f8c4992EfDb6b42349C35f025ca55742D33] = 2;
        maxCanMint[0x44d29dCDe217aD801a9a49C95976520a7547BE1B] = 2;
        maxCanMint[0x226F3Cad6Ca7998CcdC65CcF95B23Df250E4Cc86] = 2;
        maxCanMint[0x39F8f85134E2743fe7357E14Bd3f5307c250923D] = 2;
        maxCanMint[0x3a9e5E90B35C13F271b4FC1DBdf3BecF7b37Ec69] = 2;
        maxCanMint[0x568b680E3F28F449E2Ac159ecFeb6EC5DBa2f02A] = 2;
        maxCanMint[0x0800833a3706db6fBbD846d5d1b9370a79Af8097] = 2;
        maxCanMint[0x1CE77A2A2AE92BcC60AD460B37B0D0a6dc9e706B] = 2;
        maxCanMint[0xA530B243a20Cb49317288EA530Dc8A03b0C0Ed63] = 2;
        maxCanMint[0xAc99D7FaACeCC0062d8CD37140E1f399c06e6674] = 2;
        maxCanMint[0xA2Eae178F372220FF6C6D8CACD63EfE4e4b44525] = 2;
        maxCanMint[0xa18e03994fb5527fF3926b7F788ab8Ae4c79D326] = 2;
        maxCanMint[0x93e029D33955c190B775e08E6bc302096e035f2E] = 2;
        maxCanMint[0x7739ac07DE3720aA04fDfAaba7d4843aa63d1D86] = 2;
        maxCanMint[0x6a7ea8945D0Cdb9b53030F63b4b26263e4478C8f] = 2;
        maxCanMint[0x60a4f65DA916F1D23970F460B5ee05Ef84e76f55] = 2;
        maxCanMint[0x646eF0b780dbDbaEA2d8a44B39AbCD0DC44B8363] = 2;
        maxCanMint[0x59365f3C86b49245cb0F7Ed4E525439e8E09f089] = 2;
        maxCanMint[0x51ec49e33394A49D74aC61EbDc8fd9E531335BaC] = 2;
        maxCanMint[0x419e1753D481AD83A79831B3CD1e4206971cCa48] = 2;
        maxCanMint[0x41F3cbBaA1EDA77EccE61E3f6814a843f77CD1eD] = 2;
        maxCanMint[0x46fa1F938df87F459AC67F52b0fC55b44126Be66] = 2;
        maxCanMint[0x1592221ff5c0397a563d58D7F3E6c95dd444b2CD] = 2;
        maxCanMint[0x25fF1A45954F35A257a1198e7cdeA128A3Ed692E] = 2;
        maxCanMint[0x2036DE0a1E6a12ee5eB00F91A66A4AfCb5b2f287] = 2;
        maxCanMint[0x3d2CE2E1bDcDd6FD1115867047F7fdd3DA06357D] = 2;
        maxCanMint[0x33E6EEE1a7E91904e3C131f433846Ecc6D2505b6] = 2;
        maxCanMint[0x26268e120b2D916e74605654EEe7D3b0788f255A] = 2;
        maxCanMint[0x2733CAEc18289DF88827287A72CE6CAF0F785522] = 2;
        maxCanMint[0x9363113e33E67cB2B50ac57Ed52166BEF07d853B] = 2;
        maxCanMint[0x9920e37E71d75ADAB923678A453cdb7C994F1490] = 2;
        maxCanMint[0xb1dcF33B6c81e79f76e2473fAbd35cD944bF192a] = 2;
        maxCanMint[0xB34F47362C951CDFa3CBEb124BEc9b57fEADa5A0] = 2;
        maxCanMint[0xB6C567A0a1B88293e803f2db1BC9bCd77487C2bF] = 2;
        maxCanMint[0xBC0a8358507Fd406Fa97ec82aeB6fA057e9603e9] = 2;
        maxCanMint[0xc668023964daA7dED2cbdC4Cf0FD8D2588fBe2d7] = 2;
        maxCanMint[0xc48d912C6596a0138e058323fD9929209A66Cfd8] = 2;
        maxCanMint[0xe59F680b3Da35C0aeaF5eeE6fbd89CaB0E0E8377] = 2;
        maxCanMint[0xfE505FDC65030dD93F44c5bAE1B0F36a55b50291] = 2;
        maxCanMint[0xc57ac1820F7C7370455dDdefa8E1B23D971d4091] = 2;
        maxCanMint[0xFA0359AB83269Aeb4D5c071d1211EAC0E86f591A] = 2;
        maxCanMint[0xFe2576De850Fb3E48EE63ccac691a6DcFB8C6Bca] = 2;
        maxCanMint[0xF7955Beaf279AC339a10C13e23F7bfd015aDe0be] = 2;
        maxCanMint[0xed278A7a1A191EF365C1FA55373A8aF6638F5A02] = 2;
        maxCanMint[0xAf749CA22395604E4D064c35e2cAA27bA96B1B55] = 2;
        maxCanMint[0x84874AA02dB3BFFf23E9C6BFAd0B6cFc198231Be] = 2;
        maxCanMint[0x9C781fD91dd7F14053a39963F6a7dAB0FB22d133] = 2;
        maxCanMint[0x7eF61cAcD0C785eAcDFe17649d1c5BcBA676a858] = 2;
        maxCanMint[0x7F3D1132983122F90bB82207C0F877C992E443Af] = 2;
        maxCanMint[0x808a9125290A16F8d736160109e0a5D7575fBdEa] = 2;
        maxCanMint[0x8fedfc5B02c134aE5fB7D607f43f1C33e3D28566] = 2;
        maxCanMint[0x90F44e29bB9C3d378c1E1cC0e72a0Cf0CAa518E1] = 2;
        maxCanMint[0x01Fe13639b3C0B9127412b6f8210e4753ac1Da37] = 2;
        maxCanMint[0x1Cf8B7c59560C7142085a8Da527A79871872544A] = 2;
        maxCanMint[0x231CBfF45BE54f0f5bb931a378e58b89452b12f0] = 2;
        maxCanMint[0x2af5Ec633726D4f14C88030e5C39590162C947Ed] = 2;
        maxCanMint[0x36190836708D3326C4b55a4aB24D694305c8571d] = 2;
        maxCanMint[0x465D06aA6b0dcd4f2d9a38d14B20A042B92EFbc0] = 2;
        maxCanMint[0x4e1ce0B96fC37f81F5508c6608687AF4F78f23b2] = 2;
        maxCanMint[0x6882185EF840a543643d9CDb8f41d1C6B0bdeAB7] = 2;
        maxCanMint[0xe6519b4726aA433ED7a748125e3445876bc34100] = 2;
        maxCanMint[0xab68e2CA50CB56e82fdb9ad31414eF35Ec07dF72] = 2;
        maxCanMint[0x98cE912ea90388950BaB6779DD104Db6F2d540eD] = 2;
        maxCanMint[0x9e5Be83C1fEf4584Ff0fEA476623305eBfAb5986] = 2;
        maxCanMint[0xA3d95B59dc61fe47412f408a219a22A61dfbB21b] = 2;
        maxCanMint[0xC74b209fe38EcED29105C802FfB4BA280895546A] = 2;
        maxCanMint[0xDf4AcE29970D2F2Aa44De82f708755d27F5234c0] = 2;
        maxCanMint[0xE09165D4CB9B92c24De770A3d1aF363570A402fe] = 2;
        maxCanMint[0x223716C5aa5fd892c0dAff1f24D4531272E8B12d] = 2;
        maxCanMint[0x3C7406F59035671DdB9B1bfA81D735D065beA88c] = 2;
        maxCanMint[0x43E47385f6b3f8BDBe02C210bf5C74B6c34Ff441] = 2;
        maxCanMint[0x1D40FC9456A1E6F13f69615FEe1cbcBe604B9167] = 2;
        maxCanMint[0x13e2d56Ca035257Fb75a27b7e49a78ED03D213e9] = 2;
        maxCanMint[0x0D70FCB6DdB62fB08C6FC13D7B83DA1DD232926C] = 2;
        maxCanMint[0x6bC5bCA2C80F481AF8E0029b53382a096f21DC41] = 2;
        maxCanMint[0x5e7Ddc75ddBA78301F35e4C98B6c1F1684a6FB8E] = 2;
        maxCanMint[0x69a94bd1252A3845D79ED7a56d674BbF2A79443e] = 2;
        maxCanMint[0x50668e0f859FD1C97efcE964fcafb70eF6206DbB] = 2;
        maxCanMint[0x48248E89c1AbAE32bCBcff54564FD4Cb6a979723] = 2;
        maxCanMint[0x580fFb0D49fbF9B7D9c5b8e9B982899D0268457E] = 2;
        maxCanMint[0x8Da94F299c7626e59F28e020b5747f9eD67627DF] = 2;
        maxCanMint[0x7caA9f43822e288782e3e8797C8A16774C689b3D] = 2;
        maxCanMint[0xC4B64403e00D1CfDB76E67378aFc6698f59F3D63] = 2;
        maxCanMint[0xF1b211973F515061234acFa6D978426498647463] = 2;
        maxCanMint[0xd5e0978654caDe8fC01983899df720Cca7a1cBB0] = 2;
        maxCanMint[0xd93CaC570ebF525B4F1f725606dC8BC4d81ABA63] = 2;
        maxCanMint[0xacdB2444BB641cf42BA4bf09243Cbb61D876c084] = 2;
        maxCanMint[0xfE598c8DBEA6d78Dd06AE537B8171695d075106E] = 2;
        maxCanMint[0x03bDDc8CB7c81828A8BB762473b49ef207B3Cd7e] = 2;
        maxCanMint[0x1e31De516b8db1836b500F190587B14Fe8C5c8C6] = 2;
        maxCanMint[0x3aF7f85584184F63b533e547E255AE7265EE6A90] = 2;
        maxCanMint[0x5e624A7Ad13b5c01d547B1A95A386D1f6147Bf56] = 2;
        maxCanMint[0x6aC029Ae2e792a56354C544347F38d68db618492] = 2;
        maxCanMint[0x732848ae73FCCf9ED2709242BF54008fD00b0088] = 2;
        maxCanMint[0x6d762732a886705B2813f6763D4ffc0d810183E2] = 2;
        maxCanMint[0x6D7C9F86d84F9535D68968B4464197BB1Af2B9e4] = 2;
        maxCanMint[0x76d81893313b4B4701637606da284e4Fb724D3e0] = 2;
        maxCanMint[0x979842ADf40Cea8Ee62B23A1964DcFc6443276C8] = 2;
        maxCanMint[0x95722D15041F50fE9135962cC87042B4d6DaB382] = 2;
        maxCanMint[0x9663992a9eC4f9bd98F409D69bAe3909B5430C75] = 2;
        maxCanMint[0x86377eA2423f6Af0eB35CF9453fD0E5581AB0A56] = 2;
        maxCanMint[0x997197d6EdfD538086a6475f5466c4096276D3ae] = 2;
        maxCanMint[0xCEe5a0A7fff203E7dbaEF110221359aFc3A0CFd6] = 2;
        maxCanMint[0xeCa48e391E4eA76CD52328C73A549BE86Ce99f8D] = 2;
        maxCanMint[0xF0B68255D0b548426c038ECE7c1e236ecdCD04E7] = 2;
        maxCanMint[0xF60ff2c493248CDc1DD5F61FB7A4F0F210D46E26] = 2;
        maxCanMint[0xfaEF7f132595C54C026F718a0A343AEE73cff71D] = 2;
        maxCanMint[0xd692a8b22ADEE210234a7fb00510E300411a8B93] = 2;
        maxCanMint[0xdFA413375306E2169AdCBbE8551f69739328E6dd] = 2;
        maxCanMint[0xE216E8Ab691Bda159d0f2A559a36CD102d8fd9D4] = 2;
        maxCanMint[0xe5e096Ff9413971C6B2377E7811AF53E82CA4d70] = 2;
        maxCanMint[0xA3551E31972557912D69197Cf224fE9b167A4db6] = 2;
        maxCanMint[0x9cD096C8aBe256DeDC71d7f50f90F2f7daD77dd6] = 2;
        maxCanMint[0x3Ccf39F671729ed82eC47c66FB35aAaB9133C0Ba] = 2;
        maxCanMint[0x3d9cb1c56C0CC3Ea3107ec7fF6055Bd348D1FcFa] = 2;
        maxCanMint[0x40EbF8a762801D1706D9D16A8abFEc4c452d15e5] = 2;
        maxCanMint[0x2d2340b5a45d33dC052F158cAa8D6C764DB29D52] = 2;
        maxCanMint[0x0E9161626Cbc5Ea98f2A06C69e2bF100FE41a907] = 2;
        maxCanMint[0x2C5d877d7Fa03538C4d1B8BF337B6237b290dc7c] = 2;
        maxCanMint[0x007DbeD1B4a125c45DF88F3FFa350ff70c94DD9f] = 2;
        maxCanMint[0x021d5ABEA6EFbcD5dBa2C8Ae9237471448Ea0856] = 2;
        maxCanMint[0x83Bff380D2c59F88F3132542fb23B40AfCf361d7] = 2;
        maxCanMint[0x88eC581a0F36CD37f22c618EaF2DfbBBc1B5a365] = 2;
        maxCanMint[0x71e22168B702bcFF528b8974Cd4B723250B67609] = 2;
        maxCanMint[0x749def3Fb9dAE4825e7C8B360D5466480BC3BA2b] = 2;
        maxCanMint[0x767A58ba5b0E404f5bEFBde4d7f00926df568FE4] = 2;
        maxCanMint[0x554e0B456a38885501D519299ef0D0ba9715d0b1] = 2;
        maxCanMint[0xa6CB7cfd3d4fC39deC50745d7b5D37B121C701e2] = 2;
        maxCanMint[0xa1f80A85cad8ef802e5341b3D7792CBFCFb501D4] = 2;
        maxCanMint[0xb199c4c3F96F71f86190A385aae89696bc0107cD] = 2;
        maxCanMint[0xcDDCbD9C2665A71CD4cf5d1FaC0740Bf7643F260] = 2;
        maxCanMint[0xc348f4B6dBf1B156D802810DB2f6d59F36c837BF] = 2;
        maxCanMint[0xFC739BCE80D13F7a374b7aFDdBAd1c8991453051] = 2;
        maxCanMint[0xF9e0A4bb28f2CC7775Bb91dFAcAD0DEaef6605D4] = 2;
        maxCanMint[0xea79b1f6EA30a2DccB7C066Da6204fBf4131BD2C] = 2;
        maxCanMint[0xF0bF1C59ee9b78A2Ce5763165e1B6B24Cb35fD8A] = 2;
        maxCanMint[0xf229617126be90b7Ab4AE9fE5967C54ED7111144] = 2;
        maxCanMint[0xf4c40bF7070Fdcf64Ecf020bCb583738A6cC3bcD] = 2;
        maxCanMint[0xF50131d7d2B5239Fe1e934658fE3f6131532A437] = 2;
        maxCanMint[0x4444da3cFa07C77A8977DA1275723A8b5dEB14c8] = 2;
        maxCanMint[0x4167B32BB11907f400D510Bf590aAc413C9195a0] = 2;
        maxCanMint[0x331f9e988d9Eb82e7962c8c8f4b965B65863C618] = 2;
        maxCanMint[0x2A8F38956eb0C63A5F2E51333aBcFEF8d8ed1b4B] = 2;
        maxCanMint[0x129C957B1453E4Eca1Af2BF34492C0fe67298BE9] = 2;
        maxCanMint[0x6dA5dddbdE91D9a3e917B09943813177d768240c] = 2;
        maxCanMint[0x7822F20Ce0afe078118c7aE284c577b5a155FF9a] = 2;
        maxCanMint[0x9044aB3AACBB8609eF3Af11924b2c7378aDD772e] = 2;
        maxCanMint[0x862CFA785AfC31CB182EB6f01B0fe6e649ba0657] = 2;
        maxCanMint[0x8da324F75C882F561a5d44BBD0B1BaE26ED17a79] = 2;
        maxCanMint[0x7d38Cfba886BC11828d5c6A5ECdd49550E8a57a0] = 2;
        maxCanMint[0x7d5026aEA0E7478fA869af375a4ede8a5a35CBeE] = 2;
        maxCanMint[0x8f1450C06e273BB11fC76227fB3Bd79943b29E95] = 2;
        maxCanMint[0x90ac9C725aA7479015Cb1d2aD128BCAfe457E42b] = 2;
        maxCanMint[0x90C8E3A8482D9ac808ec0E9870bDd3772A13F2aC] = 2;
        maxCanMint[0x4e258cC6180E73A69Bb0Ce18621c8901AEd3B792] = 2;
    }

    

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

     function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }
  
    function mint(uint256 quantity) external payable {  
        require(quantity <= maxCanMint[msg.sender], "Not allowed mint that quantity");
        require(numberMinted[msg.sender] <= quantity, "Exceeds current mint allowance");
        require(paused == false, "Minting is currently paused");
        numberMinted[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);  
       
       }  
       
    function reveal() external onlyOwner() {
           revealed = true;
    }
           
    function pause() external onlyOwner() {
      paused = true;
      
    }
    
    function unpause() external onlyOwner() {
      paused = false;
     }
  
  
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        if(revealed == true){
             return bytes(baseURI).length > 0 ? string( abi.encodePacked(baseURI, Strings.toString(tokenId), ".json")) : "";
        }else{
            return bytes(baseURI).length > 0 ? beforeRevealUri : "";
        }
    }



}