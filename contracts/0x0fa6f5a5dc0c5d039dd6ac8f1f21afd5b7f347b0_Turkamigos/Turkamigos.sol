/**
 *Submitted for verification at Etherscan.io on 2023-07-07
*/

// File: contracts/operator-filter-registry/lib/Constants.sol
    
    
    pragma solidity ^0.8.13;
    
    address constant CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS = 0x000000000000AAeB6D7670E522A718067333cd4E;
    address constant CANONICAL_CORI_SUBSCRIPTION = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;
    // File: contracts/operator-filter-registry/IOperatorFilterRegistry.sol
    
    
    pragma solidity ^0.8.13;
    
    interface IOperatorFilterRegistry {
        /**
         * @notice Returns true if operator is not filtered for a given token, either by address or codeHash. Also returns
         *         true if supplied registrant address is not registered.
         */
        function isOperatorAllowed(address registrant, address operator) external view returns (bool);
    
        /**
         * @notice Registers an address with the registry. May be called by address itself or by EIP-173 owner.
         */
        function register(address registrant) external;
    
        /**
         * @notice Registers an address with the registry and "subscribes" to another address's filtered operators and codeHashes.
         */
        function registerAndSubscribe(address registrant, address subscription) external;
    
        /**
         * @notice Registers an address with the registry and copies the filtered operators and codeHashes from another
         *         address without subscribing.
         */
        function registerAndCopyEntries(address registrant, address registrantToCopy) external;
    
        /**
         * @notice Unregisters an address with the registry and removes its subscription. May be called by address itself or by EIP-173 owner.
         *         Note that this does not remove any filtered addresses or codeHashes.
         *         Also note that any subscriptions to this registrant will still be active and follow the existing filtered addresses and codehashes.
         */
        function unregister(address addr) external;
    
        /**
         * @notice Update an operator address for a registered address - when filtered is true, the operator is filtered.
         */
        function updateOperator(address registrant, address operator, bool filtered) external;
    
        /**
         * @notice Update multiple operators for a registered address - when filtered is true, the operators will be filtered. Reverts on duplicates.
         */
        function updateOperators(address registrant, address[] calldata operators, bool filtered) external;
    
        /**
         * @notice Update a codeHash for a registered address - when filtered is true, the codeHash is filtered.
         */
        function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;
    
        /**
         * @notice Update multiple codeHashes for a registered address - when filtered is true, the codeHashes will be filtered. Reverts on duplicates.
         */
        function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;
    
        /**
         * @notice Subscribe an address to another registrant's filtered operators and codeHashes. Will remove previous
         *         subscription if present.
         *         Note that accounts with subscriptions may go on to subscribe to other accounts - in this case,
         *         subscriptions will not be forwarded. Instead the former subscription's existing entries will still be
         *         used.
         */
        function subscribe(address registrant, address registrantToSubscribe) external;
    
        /**
         * @notice Unsubscribe an address from its current subscribed registrant, and optionally copy its filtered operators and codeHashes.
         */
        function unsubscribe(address registrant, bool copyExistingEntries) external;
    
        /**
         * @notice Get the subscription address of a given registrant, if any.
         */
        function subscriptionOf(address addr) external returns (address registrant);
    
        /**
         * @notice Get the set of addresses subscribed to a given registrant.
         *         Note that order is not guaranteed as updates are made.
         */
        function subscribers(address registrant) external returns (address[] memory);
    
        /**
         * @notice Get the subscriber at a given index in the set of addresses subscribed to a given registrant.
         *         Note that order is not guaranteed as updates are made.
         */
        function subscriberAt(address registrant, uint256 index) external returns (address);
    
        /**
         * @notice Copy filtered operators and codeHashes from a different registrantToCopy to addr.
         */
        function copyEntriesOf(address registrant, address registrantToCopy) external;
    
        /**
         * @notice Returns true if operator is filtered by a given address or its subscription.
         */
        function isOperatorFiltered(address registrant, address operator) external returns (bool);
    
        /**
         * @notice Returns true if the hash of an address's code is filtered by a given address or its subscription.
         */
        function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);
    
        /**
         * @notice Returns true if a codeHash is filtered by a given address or its subscription.
         */
        function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);
    
        /**
         * @notice Returns a list of filtered operators for a given address or its subscription.
         */
        function filteredOperators(address addr) external returns (address[] memory);
    
        /**
         * @notice Returns the set of filtered codeHashes for a given address or its subscription.
         *         Note that order is not guaranteed as updates are made.
         */
        function filteredCodeHashes(address addr) external returns (bytes32[] memory);
    
        /**
         * @notice Returns the filtered operator at the given index of the set of filtered operators for a given address or
         *         its subscription.
         *         Note that order is not guaranteed as updates are made.
         */
        function filteredOperatorAt(address registrant, uint256 index) external returns (address);
    
        /**
         * @notice Returns the filtered codeHash at the given index of the list of filtered codeHashes for a given address or
         *         its subscription.
         *         Note that order is not guaranteed as updates are made.
         */
        function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);
    
        /**
         * @notice Returns true if an address has registered
         */
        function isRegistered(address addr) external returns (bool);
    
        /**
         * @dev Convenience method to compute the code hash of an arbitrary contract
         */
        function codeHashOf(address addr) external returns (bytes32);
    }
    // File: contracts/operator-filter-registry/OperatorFilterer.sol
    
    
    pragma solidity ^0.8.13;
    
    
    /**
     * @title  OperatorFilterer
     * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
     *         registrant's entries in the OperatorFilterRegistry.
     * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
     *         - 'onlyAllowedOperator' modifier for 'transferFrom' and 'safeTransferFrom' methods.
     *         - 'onlyAllowedOperatorApproval' modifier for 'approve' and 'setApprovalForAll' methods.
     *         Please note that if your token contract does not provide an owner with EIP-173, it must provide
     *         administration methods on the contract itself to interact with the registry otherwise the subscription
     *         will be locked to the options set during construction.
     */
    
    abstract contract OperatorFilterer {
        /// @dev Emitted when an operator is not allowed.
        error OperatorNotAllowed(address operator);
    
        IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
            IOperatorFilterRegistry(CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS);
    
        /// @dev The constructor that is called when the contract is being deployed.
        constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
            // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
            // will not revert, but the contract will need to be registered with the registry once it is deployed in
            // order for the modifier to filter addresses.
            if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
                if (subscribe) {
                    OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    if (subscriptionOrRegistrantToCopy != address(0)) {
                        OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                    } else {
                        OPERATOR_FILTER_REGISTRY.register(address(this));
                    }
                }
            }
        }
    
        /**
         * @dev A helper function to check if an operator is allowed.
         */
        modifier onlyAllowedOperator(address from) virtual {
            // Allow spending tokens from addresses with balance
            // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
            // from an EOA.
            if (from != msg.sender) {
                _checkFilterOperator(msg.sender);
            }
            _;
        }
    
        /**
         * @dev A helper function to check if an operator approval is allowed.
         */
        modifier onlyAllowedOperatorApproval(address operator) virtual {
            _checkFilterOperator(operator);
            _;
        }
    
        /**
         * @dev A helper function to check if an operator is allowed.
         */
        function _checkFilterOperator(address operator) internal view virtual {
            // Check registry code length to facilitate testing in environments without a deployed registry.
            if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
                // under normal circumstances, this function will revert rather than return false, but inheriting contracts
                // may specify their own OperatorFilterRegistry implementations, which may behave differently
                if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                    revert OperatorNotAllowed(operator);
                }
            }
        }
    }
    // File: contracts/operator-filter-registry/DefaultOperatorFilterer.sol
    
    
    pragma solidity ^0.8.13;
    
    
    /**
     * @title  DefaultOperatorFilterer
     * @notice Inherits from OperatorFilterer and automatically subscribes to the default OpenSea subscription.
     * @dev    Please note that if your token contract does not provide an owner with EIP-173, it must provide
     *         administration methods on the contract itself to interact with the registry otherwise the subscription
     *         will be locked to the options set during construction.
     */
    
    abstract contract DefaultOperatorFilterer is OperatorFilterer {
        /// @dev The constructor that is called when the contract is being deployed.
        constructor() OperatorFilterer(CANONICAL_CORI_SUBSCRIPTION, true) {}
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
         * The token must be owned by 'from'.
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
         * The 'quantity' minted with ERC2309 exceeds the safety limit.
         */
        error MintERC2309QuantityExceedsLimit();
    
        /**
         * The 'extraData' cannot be set on an unintialized ownership slot.
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
            // Arbitrary data similar to 'startTimestamp' that can be set via {_extraData}.
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
         * 'interfaceId'. See the corresponding
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
         * @dev Emitted when 'tokenId' token is transferred from 'from' to 'to'.
         */
        event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    
        /**
         * @dev Emitted when 'owner' enables 'approved' to manage the 'tokenId' token.
         */
        event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    
        /**
         * @dev Emitted when 'owner' enables or disables
         * ('approved') 'operator' to manage all of its assets.
         */
        event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
        /**
         * @dev Returns the number of tokens in 'owner''s account.
         */
        function balanceOf(address owner) external view returns (uint256 balance);
    
        /**
         * @dev Returns the owner of the 'tokenId' token.
         *
         * Requirements:
         *
         * - 'tokenId' must exist.
         */
        function ownerOf(uint256 tokenId) external view returns (address owner);
    
        /**
         * @dev Safely transfers 'tokenId' token from 'from' to 'to',
         * checking first that contract recipients are aware of the ERC721 protocol
         * to prevent tokens from being forever locked.
         *
         * Requirements:
         *
         * - 'from' cannot be the zero address.
         * - 'to' cannot be the zero address.
         * - 'tokenId' token must exist and be owned by 'from'.
         * - If the caller is not 'from', it must be have been allowed to move
         * this token by either {approve} or {setApprovalForAll}.
         * - If 'to' refers to a smart contract, it must implement
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
         * @dev Equivalent to 'safeTransferFrom(from, to, tokenId, '')'.
         */
        function safeTransferFrom(
            address from,
            address to,
            uint256 tokenId
        ) external payable;
    
        /**
         * @dev Transfers 'tokenId' from 'from' to 'to'.
         *
         * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
         * whenever possible.
         *
         * Requirements:
         *
         * - 'from' cannot be the zero address.
         * - 'to' cannot be the zero address.
         * - 'tokenId' token must be owned by 'from'.
         * - If the caller is not 'from', it must be approved to move this token
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
         * @dev Gives permission to 'to' to transfer 'tokenId' token to another account.
         * The approval is cleared when the token is transferred.
         *
         * Only a single account can be approved at a time, so approving the
         * zero address clears previous approvals.
         *
         * Requirements:
         *
         * - The caller must own the token or be an approved operator.
         * - 'tokenId' must exist.
         *
         * Emits an {Approval} event.
         */
        function approve(address to, uint256 tokenId) external payable;
    
        /**
         * @dev Approve or remove 'operator' as an operator for the caller.
         * Operators can call {transferFrom} or {safeTransferFrom}
         * for any token owned by the caller.
         *
         * Requirements:
         *
         * - The 'operator' cannot be the caller.
         *
         * Emits an {ApprovalForAll} event.
         */
        function setApprovalForAll(address operator, bool _approved) external;
    
        /**
         * @dev Returns the account approved for 'tokenId' token.
         *
         * Requirements:
         *
         * - 'tokenId' must exist.
         */
        function getApproved(uint256 tokenId) external view returns (address operator);
    
        /**
         * @dev Returns if the 'operator' is allowed to manage all of the assets of 'owner'.
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
         * @dev Returns the Uniform Resource Identifier (URI) for 'tokenId' token.
         */
        function tokenURI(uint256 tokenId) external view returns (string memory);
    
        // =============================================================
        //                           IERC2309
        // =============================================================
    
        /**
         * @dev Emitted when tokens in 'fromTokenId' to 'toTokenId'
         * (inclusive) is transferred from 'from' to 'to', as defined in the
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
     * starting from '_startTokenId()'.
     *
     * Assumptions:
     *
     * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
     * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
     */
    contract ERC721A is IERC721A {
        // Bypass for a '--via-ir' bug (https://github.com/chiru-labs/ERC721A/pull/364).
        struct TokenApprovalRef {
            address value;
        }
    
        // =============================================================
        //                           CONSTANTS
        // =============================================================
    
        // Mask of an entry in packed address data.
        uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;
    
        // The bit position of 'numberMinted' in packed address data.
        uint256 private constant _BITPOS_NUMBER_MINTED = 64;
    
        // The bit position of 'numberBurned' in packed address data.
        uint256 private constant _BITPOS_NUMBER_BURNED = 128;
    
        // The bit position of 'aux' in packed address data.
        uint256 private constant _BITPOS_AUX = 192;
    
        // Mask of all 256 bits in packed address data except the 64 bits for 'aux'.
        uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;
    
        // The bit position of 'startTimestamp' in packed ownership.
        uint256 private constant _BITPOS_START_TIMESTAMP = 160;
    
        // The bit mask of the 'burned' bit in packed ownership.
        uint256 private constant _BITMASK_BURNED = 1 << 224;
    
        // The bit position of the 'nextInitialized' bit in packed ownership.
        uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;
    
        // The bit mask of the 'nextInitialized' bit in packed ownership.
        uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;
    
        // The bit position of 'extraData' in packed ownership.
        uint256 private constant _BITPOS_EXTRA_DATA = 232;
    
        // Mask of all 256 bits in a packed ownership except the 24 bits for 'extraData'.
        uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;
    
        // The mask of the lower 160 bits for addresses.
        uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;
    
        // The maximum 'quantity' that can be minted with {_mintERC2309}.
        // This limit is to prevent overflows on the address data entries.
        // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
        // is required to cause an overflow, which is unrealistic.
        uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;
    
        // The 'Transfer' event signature is given by:
        // 'keccak256(bytes("Transfer(address,address,uint256)"))'.
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
        // - [0..159]   'addr'
        // - [160..223] 'startTimestamp'
        // - [224]      'burned'
        // - [225]      'nextInitialized'
        // - [232..255] 'extraData'
        mapping(uint256 => uint256) private _packedOwnerships;
    
        // Mapping owner address to address data.
        //
        // Bits Layout:
        // - [0..63]    'balance'
        // - [64..127]  'numberMinted'
        // - [128..191] 'numberBurned'
        // - [192..255] 'aux'
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
            // more than '_currentIndex - _startTokenId()' times.
            unchecked {
                return _currentIndex - _burnCounter - _startTokenId();
            }
        }
    
        /**
         * @dev Returns the total amount of tokens minted in the contract.
         */
        function _totalMinted() internal view virtual returns (uint256) {
            // Counter underflow is impossible as '_currentIndex' does not decrement,
            // and it is initialized to '_startTokenId()'.
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
         * @dev Returns the number of tokens in 'owner''s account.
         */
        function balanceOf(address owner) public view virtual override returns (uint256) {
            if (owner == address(0)) revert BalanceQueryForZeroAddress();
            return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
        }
    
        /**
         * Returns the number of tokens minted by 'owner'.
         */
        function _numberMinted(address owner) internal view returns (uint256) {
            return (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
        }
    
        /**
         * Returns the number of tokens burned by or on behalf of 'owner'.
         */
        function _numberBurned(address owner) internal view returns (uint256) {
            return (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
        }
    
        /**
         * Returns the auxiliary data for 'owner'. (e.g. number of whitelist mint slots used).
         */
        function _getAux(address owner) internal view returns (uint64) {
            return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
        }
    
        /**
         * Sets the auxiliary data for 'owner'. (e.g. number of whitelist mint slots used).
         * If there are multiple variables, please pack them into a uint64.
         */
        function _setAux(address owner, uint64 aux) internal virtual {
            uint256 packed = _packedAddressData[owner];
            uint256 auxCasted;
            // Cast 'aux' with assembly to avoid redundant masking.
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
         * 'interfaceId'. See the corresponding
         * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
         * to learn more about how these ids are created.
         *
         * This function call must use less than 30000 gas.
         */
        function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
            // The interface IDs are constants representing the first 4 bytes
            // of the XOR of all function selectors in the interface.
            // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
            // (e.g. 'bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)')
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
         * @dev Returns the Uniform Resource Identifier (URI) for 'tokenId' token.
         */
        function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
            if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
    
            string memory baseURI = _baseURI();
            return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
        }
    
        /**
         * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
         * token will be the concatenation of the 'baseURI' and the 'tokenId'. Empty
         * by default, it can be overridden in child contracts.
         */
        function _baseURI() internal view virtual returns (string memory) {
            return '';
        }
    
        // =============================================================
        //                     OWNERSHIPS OPERATIONS
        // =============================================================
    
        /**
         * @dev Returns the owner of the 'tokenId' token.
         *
         * Requirements:
         *
         * - 'tokenId' must exist.
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
         * @dev Returns the unpacked 'TokenOwnership' struct at 'index'.
         */
        function _ownershipAt(uint256 index) internal view virtual returns (TokenOwnership memory) {
            return _unpackedOwnership(_packedOwnerships[index]);
        }
    
        /**
         * @dev Initializes the ownership slot minted at 'index' for efficiency purposes.
         */
        function _initializeOwnershipAt(uint256 index) internal virtual {
            if (_packedOwnerships[index] == 0) {
                _packedOwnerships[index] = _packedOwnershipOf(index);
            }
        }
    
        /**
         * Returns the packed ownership data of 'tokenId'.
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
                            // (i.e. 'ownership.addr != address(0) && ownership.burned == false')
                            // before an unintialized ownership slot
                            // (i.e. 'ownership.addr == address(0) && ownership.burned == false')
                            // Hence, 'curr' will not underflow.
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
         * @dev Returns the unpacked 'TokenOwnership' struct from 'packed'.
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
                // Mask 'owner' to the lower 160 bits, in case the upper bits somehow aren't clean.
                owner := and(owner, _BITMASK_ADDRESS)
                // 'owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags'.
                result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
            }
        }
    
        /**
         * @dev Returns the 'nextInitialized' flag set if 'quantity' equals 1.
         */
        function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
            // For branchless setting of the 'nextInitialized' flag.
            assembly {
                // '(quantity == 1) << _BITPOS_NEXT_INITIALIZED'.
                result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
            }
        }
    
        // =============================================================
        //                      APPROVAL OPERATIONS
        // =============================================================
    
        /**
         * @dev Gives permission to 'to' to transfer 'tokenId' token to another account.
         * The approval is cleared when the token is transferred.
         *
         * Only a single account can be approved at a time, so approving the
         * zero address clears previous approvals.
         *
         * Requirements:
         *
         * - The caller must own the token or be an approved operator.
         * - 'tokenId' must exist.
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
         * @dev Returns the account approved for 'tokenId' token.
         *
         * Requirements:
         *
         * - 'tokenId' must exist.
         */
        function getApproved(uint256 tokenId) public view virtual override returns (address) {
            if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();
    
            return _tokenApprovals[tokenId].value;
        }
    
        /**
         * @dev Approve or remove 'operator' as an operator for the caller.
         * Operators can call {transferFrom} or {safeTransferFrom}
         * for any token owned by the caller.
         *
         * Requirements:
         *
         * - The 'operator' cannot be the caller.
         *
         * Emits an {ApprovalForAll} event.
         */
        function setApprovalForAll(address operator, bool approved) public virtual override {
            _operatorApprovals[_msgSenderERC721A()][operator] = approved;
            emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
        }
    
        /**
         * @dev Returns if the 'operator' is allowed to manage all of the assets of 'owner'.
         *
         * See {setApprovalForAll}.
         */
        function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
            return _operatorApprovals[owner][operator];
        }
    
        /**
         * @dev Returns whether 'tokenId' exists.
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
         * @dev Returns whether 'msgSender' is equal to 'approvedAddress' or 'owner'.
         */
        function _isSenderApprovedOrOwner(
            address approvedAddress,
            address owner,
            address msgSender
        ) private pure returns (bool result) {
            assembly {
                // Mask 'owner' to the lower 160 bits, in case the upper bits somehow aren't clean.
                owner := and(owner, _BITMASK_ADDRESS)
                // Mask 'msgSender' to the lower 160 bits, in case the upper bits somehow aren't clean.
                msgSender := and(msgSender, _BITMASK_ADDRESS)
                // 'msgSender == owner || msgSender == approvedAddress'.
                result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
            }
        }
    
        /**
         * @dev Returns the storage slot and value for the approved address of 'tokenId'.
         */
        function _getApprovedSlotAndAddress(uint256 tokenId)
            private
            view
            returns (uint256 approvedAddressSlot, address approvedAddress)
        {
            TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
            // The following is equivalent to 'approvedAddress = _tokenApprovals[tokenId].value'.
            assembly {
                approvedAddressSlot := tokenApproval.slot
                approvedAddress := sload(approvedAddressSlot)
            }
        }
    
        // =============================================================
        //                      TRANSFER OPERATIONS
        // =============================================================
    
        /**
         * @dev Transfers 'tokenId' from 'from' to 'to'.
         *
         * Requirements:
         *
         * - 'from' cannot be the zero address.
         * - 'to' cannot be the zero address.
         * - 'tokenId' token must be owned by 'from'.
         * - If the caller is not 'from', it must be approved to move this token
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
                    // This is equivalent to 'delete _tokenApprovals[tokenId]'.
                    sstore(approvedAddressSlot, 0)
                }
            }
    
            // Underflow of the sender's balance is impossible because we check for
            // ownership above and the recipient's balance can't realistically overflow.
            // Counter overflow is incredibly unrealistic as 'tokenId' would have to be 2**256.
            unchecked {
                // We can directly increment and decrement the balances.
                --_packedAddressData[from]; // Updates: 'balance -= 1'.
                ++_packedAddressData[to]; // Updates: 'balance += 1'.
    
                // Updates:
                // - 'address' to the next owner.
                // - 'startTimestamp' to the timestamp of transfering.
                // - 'burned' to 'false'.
                // - 'nextInitialized' to 'true'.
                _packedOwnerships[tokenId] = _packOwnershipData(
                    to,
                    _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
                );
    
                // If the next slot may not have been initialized (i.e. 'nextInitialized == false') .
                if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                    uint256 nextTokenId = tokenId + 1;
                    // If the next slot's address is zero and not burned (i.e. packed value is zero).
                    if (_packedOwnerships[nextTokenId] == 0) {
                        // If the next slot is within bounds.
                        if (nextTokenId != _currentIndex) {
                            // Initialize the next slot to maintain correctness for 'ownerOf(tokenId + 1)'.
                            _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                        }
                    }
                }
            }
    
            emit Transfer(from, to, tokenId);
            _afterTokenTransfers(from, to, tokenId, 1);
        }
    
        /**
         * @dev Equivalent to 'safeTransferFrom(from, to, tokenId, '')'.
         */
        function safeTransferFrom(
            address from,
            address to,
            uint256 tokenId
        ) public payable virtual override {
            safeTransferFrom(from, to, tokenId, '');
        }
    
        /**
         * @dev Safely transfers 'tokenId' token from 'from' to 'to'.
         *
         * Requirements:
         *
         * - 'from' cannot be the zero address.
         * - 'to' cannot be the zero address.
         * - 'tokenId' token must exist and be owned by 'from'.
         * - If the caller is not 'from', it must be approved to move this token
         * by either {approve} or {setApprovalForAll}.
         * - If 'to' refers to a smart contract, it must implement
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
         * 'startTokenId' - the first token ID to be transferred.
         * 'quantity' - the amount to be transferred.
         *
         * Calling conditions:
         *
         * - When 'from' and 'to' are both non-zero, 'from''s 'tokenId' will be
         * transferred to 'to'.
         * - When 'from' is zero, 'tokenId' will be minted for 'to'.
         * - When 'to' is zero, 'tokenId' will be burned by 'from'.
         * - 'from' and 'to' are never both zero.
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
         * 'startTokenId' - the first token ID to be transferred.
         * 'quantity' - the amount to be transferred.
         *
         * Calling conditions:
         *
         * - When 'from' and 'to' are both non-zero, 'from''s 'tokenId' has been
         * transferred to 'to'.
         * - When 'from' is zero, 'tokenId' has been minted for 'to'.
         * - When 'to' is zero, 'tokenId' has been burned by 'from'.
         * - 'from' and 'to' are never both zero.
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
         * 'from' - Previous owner of the given token ID.
         * 'to' - Target address that will receive the token.
         * 'tokenId' - Token ID to be transferred.
         * '_data' - Optional data to send along with the call.
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
         * @dev Mints 'quantity' tokens and transfers them to 'to'.
         *
         * Requirements:
         *
         * - 'to' cannot be the zero address.
         * - 'quantity' must be greater than 0.
         *
         * Emits a {Transfer} event for each mint.
         */
        function _mint(address to, uint256 quantity) internal virtual {
            uint256 startTokenId = _currentIndex;
            if (quantity == 0) revert MintZeroQuantity();
    
            _beforeTokenTransfers(address(0), to, startTokenId, quantity);
    
            // Overflows are incredibly unrealistic.
            // 'balance' and 'numberMinted' have a maximum limit of 2**64.
            // 'tokenId' has a maximum limit of 2**256.
            unchecked {
                // Updates:
                // - 'balance += quantity'.
                // - 'numberMinted += quantity'.
                //
                // We can directly add to the 'balance' and 'numberMinted'.
                _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);
    
                // Updates:
                // - 'address' to the owner.
                // - 'startTimestamp' to the timestamp of minting.
                // - 'burned' to 'false'.
                // - 'nextInitialized' to 'quantity == 1'.
                _packedOwnerships[startTokenId] = _packOwnershipData(
                    to,
                    _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
                );
    
                uint256 toMasked;
                uint256 end = startTokenId + quantity;
    
                // Use assembly to loop and emit the 'Transfer' event for gas savings.
                // The duplicated 'log4' removes an extra check and reduces stack juggling.
                // The assembly, together with the surrounding Solidity code, have been
                // delicately arranged to nudge the compiler into producing optimized opcodes.
                assembly {
                    // Mask 'to' to the lower 160 bits, in case the upper bits somehow aren't clean.
                    toMasked := and(to, _BITMASK_ADDRESS)
                    // Emit the 'Transfer' event.
                    log4(
                        0, // Start of data (0, since no data).
                        0, // End of data (0, since no data).
                        _TRANSFER_EVENT_SIGNATURE, // Signature.
                        0, // 'address(0)'.
                        toMasked, // 'to'.
                        startTokenId // 'tokenId'.
                    )
    
                    // The 'iszero(eq(,))' check ensures that large values of 'quantity'
                    // that overflows uint256 will make the loop run out of gas.
                    // The compiler will optimize the 'iszero' away for performance.
                    for {
                        let tokenId := add(startTokenId, 1)
                    } iszero(eq(tokenId, end)) {
                        tokenId := add(tokenId, 1)
                    } {
                        // Emit the 'Transfer' event. Similar to above.
                        log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
                    }
                }
                if (toMasked == 0) revert MintToZeroAddress();
    
                _currentIndex = end;
            }
            _afterTokenTransfers(address(0), to, startTokenId, quantity);
        }
    
        /**
         * @dev Mints 'quantity' tokens and transfers them to 'to'.
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
         * - 'to' cannot be the zero address.
         * - 'quantity' must be greater than 0.
         *
         * Emits a {ConsecutiveTransfer} event.
         */
        function _mintERC2309(address to, uint256 quantity) internal virtual {
            uint256 startTokenId = _currentIndex;
            if (to == address(0)) revert MintToZeroAddress();
            if (quantity == 0) revert MintZeroQuantity();
            if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();
    
            _beforeTokenTransfers(address(0), to, startTokenId, quantity);
    
            // Overflows are unrealistic due to the above check for 'quantity' to be below the limit.
            unchecked {
                // Updates:
                // - 'balance += quantity'.
                // - 'numberMinted += quantity'.
                //
                // We can directly add to the 'balance' and 'numberMinted'.
                _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);
    
                // Updates:
                // - 'address' to the owner.
                // - 'startTimestamp' to the timestamp of minting.
                // - 'burned' to 'false'.
                // - 'nextInitialized' to 'quantity == 1'.
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
         * @dev Safely mints 'quantity' tokens and transfers them to 'to'.
         *
         * Requirements:
         *
         * - If 'to' refers to a smart contract, it must implement
         * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
         * - 'quantity' must be greater than 0.
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
         * @dev Equivalent to '_safeMint(to, quantity, '')'.
         */
        function _safeMint(address to, uint256 quantity) internal virtual {
            _safeMint(to, quantity, '');
        }
    
        // =============================================================
        //                        BURN OPERATIONS
        // =============================================================
    
        /**
         * @dev Equivalent to '_burn(tokenId, false)'.
         */
        function _burn(uint256 tokenId) internal virtual {
            _burn(tokenId, false);
        }
    
        /**
         * @dev Destroys 'tokenId'.
         * The approval is cleared when the token is burned.
         *
         * Requirements:
         *
         * - 'tokenId' must exist.
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
                    // This is equivalent to 'delete _tokenApprovals[tokenId]'.
                    sstore(approvedAddressSlot, 0)
                }
            }
    
            // Underflow of the sender's balance is impossible because we check for
            // ownership above and the recipient's balance can't realistically overflow.
            // Counter overflow is incredibly unrealistic as 'tokenId' would have to be 2**256.
            unchecked {
                // Updates:
                // - 'balance -= 1'.
                // - 'numberBurned += 1'.
                //
                // We can directly decrement the balance, and increment the number burned.
                // This is equivalent to 'packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;'.
                _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;
    
                // Updates:
                // - 'address' to the last owner.
                // - 'startTimestamp' to the timestamp of burning.
                // - 'burned' to 'true'.
                // - 'nextInitialized' to 'true'.
                _packedOwnerships[tokenId] = _packOwnershipData(
                    from,
                    (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
                );
    
                // If the next slot may not have been initialized (i.e. 'nextInitialized == false') .
                if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                    uint256 nextTokenId = tokenId + 1;
                    // If the next slot's address is zero and not burned (i.e. packed value is zero).
                    if (_packedOwnerships[nextTokenId] == 0) {
                        // If the next slot is within bounds.
                        if (nextTokenId != _currentIndex) {
                            // Initialize the next slot to maintain correctness for 'ownerOf(tokenId + 1)'.
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
         * @dev Directly sets the extra data for the ownership data 'index'.
         */
        function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
            uint256 packed = _packedOwnerships[index];
            if (packed == 0) revert OwnershipNotInitializedForExtraData();
            uint256 extraDataCasted;
            // Cast 'extraData' with assembly to avoid redundant masking.
            assembly {
                extraDataCasted := extraData
            }
            packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
            _packedOwnerships[index] = packed;
        }
    
        /**
         * @dev Called during each token transfer to set the 24bit 'extraData' field.
         * Intended to be overridden by the cosumer contract.
         *
         * 'previousExtraData' - the value of 'extraData' before transfer.
         *
         * Calling conditions:
         *
         * - When 'from' and 'to' are both non-zero, 'from''s 'tokenId' will be
         * transferred to 'to'.
         * - When 'from' is zero, 'tokenId' will be minted for 'to'.
         * - When 'to' is zero, 'tokenId' will be burned by 'from'.
         * - 'from' and 'to' are never both zero.
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
         * @dev Returns the message sender (defaults to 'msg.sender').
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
                // Assign the 'str' to the end.
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
                    // Keep dividing 'temp' until zero.
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
    
    // File: erc721a/contracts/extensions/IERC721AQueryable.sol
    
    
    // ERC721A Contracts v4.2.3
    // Creator: Chiru Labs
    
    pragma solidity ^0.8.4;
    
    
    /**
     * @dev Interface of ERC721AQueryable.
     */
    interface IERC721AQueryable is IERC721A {
        /**
         * Invalid query range ('start' >= 'stop').
         */
        error InvalidQueryRange();
    
        /**
         * @dev Returns the 'TokenOwnership' struct at 'tokenId' without reverting.
         *
         * If the 'tokenId' is out of bounds:
         *
         * - 'addr = address(0)'
         * - 'startTimestamp = 0'
         * - 'burned = false'
         * - 'extraData = 0'
         *
         * If the 'tokenId' is burned:
         *
         * - 'addr = <Address of owner before token was burned>'
         * - 'startTimestamp = <Timestamp when token was burned>'
         * - 'burned = true'
         * - 'extraData = <Extra data when token was burned>'
         *
         * Otherwise:
         *
         * - 'addr = <Address of owner>'
         * - 'startTimestamp = <Timestamp of start of ownership>'
         * - 'burned = false'
         * - 'extraData = <Extra data at start of ownership>'
         */
        function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);
    
        /**
         * @dev Returns an array of 'TokenOwnership' structs at 'tokenIds' in order.
         * See {ERC721AQueryable-explicitOwnershipOf}
         */
        function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory);
    
        /**
         * @dev Returns an array of token IDs owned by 'owner',
         * in the range ['start', 'stop')
         * (i.e. 'start <= tokenId < stop').
         *
         * This function allows for tokens to be queried if the collection
         * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
         *
         * Requirements:
         *
         * - 'start < stop'
         */
        function tokensOfOwnerIn(
            address owner,
            uint256 start,
            uint256 stop
        ) external view returns (uint256[] memory);
    
        /**
         * @dev Returns an array of token IDs owned by 'owner'.
         *
         * This function scans the ownership mapping and is O('totalSupply') in complexity.
         * It is meant to be called off-chain.
         *
         * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
         * multiple smaller scans if the collection is large enough to cause
         * an out-of-gas error (10K collections should be fine).
         */
        function tokensOfOwner(address owner) external view returns (uint256[] memory);
    }
    
    // File: contracts/IERC721L.sol
    
    pragma solidity ^0.8.4;
    
    
    interface IERC721L is IERC721AQueryable {
        error CannotIncreaseMaxMintableSupply();
        error CannotUpdatePermanentBaseURI();
        error GlobalWalletLimitOverflow();
        error InsufficientStageTimeGap();
        error InvalidProof();
        error InvalidStage();
        error InvalidStageArgsLength();
        error InvalidStartAndEndTimestamp();
        error NoSupplyLeft();
        error NotEnoughValue();
        error StageSupplyExceeded();
        error TimestampExpired();
        error WalletGlobalLimitExceeded();
        error WalletStageLimitExceeded();
        error WithdrawFailed();
    
        struct MintStageInfo {
            uint80 cost;
            uint32 walletLimit; // 0 for unlimited
            bytes32 merkleRoot; // 0x0 for no presale enforced
            uint24 maxStageSupply; // 0 for unlimited
            uint64 startTimeUnixSeconds;
            uint64 endTimeUnixSeconds;
        }
    
        event UpdateStage(
            uint256 stage,
            uint80 cost,
            uint32 walletLimit,
            bytes32 merkleRoot,
            uint24 maxStageSupply,
            uint64 startTimeUnixSeconds,
            uint64 endTimeUnixSeconds
        );
    
    
        event SetMaxMintableSupply(uint256 maxMintableSupply);
        event SetGlobalWalletLimit(uint256 globalWalletLimit);
        event SetActiveStage(uint256 activeStage);
        event SetBaseURI(string baseURI);
        event PermanentBaseURI(string baseURI);
        event Withdraw(uint256 value);
    
    
        function getNumberStages() external view returns (uint256);
    
        function getGlobalWalletLimit() external view returns (uint256);
    
        function getMaxMintableSupply() external view returns (uint256);
    
        function totalMintedByAddress(address a) external view returns (uint256);
    
        
    
        function getStageInfo(uint256 index)
            external
            view
            returns (
                MintStageInfo memory,
                uint32,
                uint256
            );
    
        function getActiveStageFromTimestamp(uint64 timestamp)
            external
            view
            returns (uint256);
    
    }
    // File: erc721a/contracts/extensions/ERC721AQueryable.sol
    
    
    // ERC721A Contracts v4.2.3
    // Creator: Chiru Labs
    
    pragma solidity ^0.8.4;
    
    
    
    /**
     * @title ERC721AQueryable.
     *
     * @dev ERC721A subclass with convenience query functions.
     */
    abstract contract ERC721AQueryable is ERC721A, IERC721AQueryable {
        /**
         * @dev Returns the 'TokenOwnership' struct at 'tokenId' without reverting.
         *
         * If the 'tokenId' is out of bounds:
         *
         * - 'addr = address(0)'
         * - 'startTimestamp = 0'
         * - 'burned = false'
         * - 'extraData = 0'
         *
         * If the 'tokenId' is burned:
         *
         * - 'addr = <Address of owner before token was burned>'
         * - 'startTimestamp = <Timestamp when token was burned>'
         * - 'burned = true'
         * - 'extraData = <Extra data when token was burned>'
         *
         * Otherwise:
         *
         * - 'addr = <Address of owner>'
         * - 'startTimestamp = <Timestamp of start of ownership>'
         * - 'burned = false'
         * - 'extraData = <Extra data at start of ownership>'
         */
        function explicitOwnershipOf(uint256 tokenId) public view virtual override returns (TokenOwnership memory) {
            TokenOwnership memory ownership;
            if (tokenId < _startTokenId() || tokenId >= _nextTokenId()) {
                return ownership;
            }
            ownership = _ownershipAt(tokenId);
            if (ownership.burned) {
                return ownership;
            }
            return _ownershipOf(tokenId);
        }
    
        /**
         * @dev Returns an array of 'TokenOwnership' structs at 'tokenIds' in order.
         * See {ERC721AQueryable-explicitOwnershipOf}
         */
        function explicitOwnershipsOf(uint256[] calldata tokenIds)
            external
            view
            virtual
            override
            returns (TokenOwnership[] memory)
        {
            unchecked {
                uint256 tokenIdsLength = tokenIds.length;
                TokenOwnership[] memory ownerships = new TokenOwnership[](tokenIdsLength);
                for (uint256 i; i != tokenIdsLength; ++i) {
                    ownerships[i] = explicitOwnershipOf(tokenIds[i]);
                }
                return ownerships;
            }
        }
    
        /**
         * @dev Returns an array of token IDs owned by 'owner',
         * in the range ['start', 'stop')
         * (i.e. 'start <= tokenId < stop').
         *
         * This function allows for tokens to be queried if the collection
         * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
         *
         * Requirements:
         *
         * - 'start < stop'
         */
        function tokensOfOwnerIn(
            address owner,
            uint256 start,
            uint256 stop
        ) external view virtual override returns (uint256[] memory) {
            unchecked {
                if (start >= stop) revert InvalidQueryRange();
                uint256 tokenIdsIdx;
                uint256 stopLimit = _nextTokenId();
                // Set 'start = max(start, _startTokenId())'.
                if (start < _startTokenId()) {
                    start = _startTokenId();
                }
                // Set 'stop = min(stop, stopLimit)'.
                if (stop > stopLimit) {
                    stop = stopLimit;
                }
                uint256 tokenIdsMaxLength = balanceOf(owner);
                // Set 'tokenIdsMaxLength = min(balanceOf(owner), stop - start)',
                // to cater for cases where 'balanceOf(owner)' is too big.
                if (start < stop) {
                    uint256 rangeLength = stop - start;
                    if (rangeLength < tokenIdsMaxLength) {
                        tokenIdsMaxLength = rangeLength;
                    }
                } else {
                    tokenIdsMaxLength = 0;
                }
                uint256[] memory tokenIds = new uint256[](tokenIdsMaxLength);
                if (tokenIdsMaxLength == 0) {
                    return tokenIds;
                }
                // We need to call 'explicitOwnershipOf(start)',
                // because the slot at 'start' may not be initialized.
                TokenOwnership memory ownership = explicitOwnershipOf(start);
                address currOwnershipAddr;
                // If the starting slot exists (i.e. not burned), initialize 'currOwnershipAddr'.
                // 'ownership.address' will not be zero, as 'start' is clamped to the valid token ID range.
                if (!ownership.burned) {
                    currOwnershipAddr = ownership.addr;
                }
                for (uint256 i = start; i != stop && tokenIdsIdx != tokenIdsMaxLength; ++i) {
                    ownership = _ownershipAt(i);
                    if (ownership.burned) {
                        continue;
                    }
                    if (ownership.addr != address(0)) {
                        currOwnershipAddr = ownership.addr;
                    }
                    if (currOwnershipAddr == owner) {
                        tokenIds[tokenIdsIdx++] = i;
                    }
                }
                // Downsize the array to fit.
                assembly {
                    mstore(tokenIds, tokenIdsIdx)
                }
                return tokenIds;
            }
        }
    
        /**
         * @dev Returns an array of token IDs owned by 'owner'.
         *
         * This function scans the ownership mapping and is O('totalSupply') in complexity.
         * It is meant to be called off-chain.
         *
         * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
         * multiple smaller scans if the collection is large enough to cause
         * an out-of-gas error (10K collections should be fine).
         */
        function tokensOfOwner(address owner) external view virtual override returns (uint256[] memory) {
            unchecked {
                uint256 tokenIdsIdx;
                address currOwnershipAddr;
                uint256 tokenIdsLength = balanceOf(owner);
                uint256[] memory tokenIds = new uint256[](tokenIdsLength);
                TokenOwnership memory ownership;
                for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                    ownership = _ownershipAt(i);
                    if (ownership.burned) {
                        continue;
                    }
                    if (ownership.addr != address(0)) {
                        currOwnershipAddr = ownership.addr;
                    }
                    if (currOwnershipAddr == owner) {
                        tokenIds[tokenIdsIdx++] = i;
                    }
                }
                return tokenIds;
            }
        }
    }
    
    
    // File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol
    
    
    // OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)
    
    pragma solidity ^0.8.0;
    
    /**
     * @dev These functions deal with verification of Merkle Tree proofs.
     *
     * The tree and the proofs can be generated using our
     * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
     * You will find a quickstart guide in the readme.
     *
     * WARNING: You should avoid using leaf values that are 64 bytes long prior to
     * hashing, or use a hash function other than keccak256 for hashing leaves.
     * This is because the concatenation of a sorted pair of internal nodes in
     * the merkle tree could be reinterpreted as a leaf value.
     * OpenZeppelin's JavaScript library generates merkle trees that are safe
     * against this attack out of the box.
     */
    library MerkleProof {
        /**
         * @dev Returns true if a 'leaf' can be proved to be a part of a Merkle tree
         * defined by 'root'. For this, a 'proof' must be provided, containing
         * sibling hashes on the branch from the leaf to the root of the tree. Each
         * pair of leaves and each pair of pre-images are assumed to be sorted.
         */
        function verify(
            bytes32[] memory proof,
            bytes32 root,
            bytes32 leaf
        ) internal pure returns (bool) {
            return processProof(proof, leaf) == root;
        }
    
        /**
         * @dev Calldata version of {verify}
         *
         * _Available since v4.7._
         */
        function verifyCalldata(
            bytes32[] calldata proof,
            bytes32 root,
            bytes32 leaf
        ) internal pure returns (bool) {
            return processProofCalldata(proof, leaf) == root;
        }
    
        /**
         * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
         * from 'leaf' using 'proof'. A 'proof' is valid if and only if the rebuilt
         * hash matches the root of the tree. When processing the proof, the pairs
         * of leafs & pre-images are assumed to be sorted.
         *
         * _Available since v4.4._
         */
        function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
            bytes32 computedHash = leaf;
            for (uint256 i = 0; i < proof.length; i++) {
                computedHash = _hashPair(computedHash, proof[i]);
            }
            return computedHash;
        }
    
        /**
         * @dev Calldata version of {processProof}
         *
         * _Available since v4.7._
         */
        function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
            bytes32 computedHash = leaf;
            for (uint256 i = 0; i < proof.length; i++) {
                computedHash = _hashPair(computedHash, proof[i]);
            }
            return computedHash;
        }
    
        /**
         * @dev Returns true if the 'leaves' can be simultaneously proven to be a part of a merkle tree defined by
         * 'root', according to 'proof' and 'proofFlags' as described in {processMultiProof}.
         *
         * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
         *
         * _Available since v4.7._
         */
        function multiProofVerify(
            bytes32[] memory proof,
            bool[] memory proofFlags,
            bytes32 root,
            bytes32[] memory leaves
        ) internal pure returns (bool) {
            return processMultiProof(proof, proofFlags, leaves) == root;
        }
    
        /**
         * @dev Calldata version of {multiProofVerify}
         *
         * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
         *
         * _Available since v4.7._
         */
        function multiProofVerifyCalldata(
            bytes32[] calldata proof,
            bool[] calldata proofFlags,
            bytes32 root,
            bytes32[] memory leaves
        ) internal pure returns (bool) {
            return processMultiProofCalldata(proof, proofFlags, leaves) == root;
        }
    
        /**
         * @dev Returns the root of a tree reconstructed from 'leaves' and sibling nodes in 'proof'. The reconstruction
         * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
         * leaf/inner node or a proof sibling node, depending on whether each 'proofFlags' item is true or false
         * respectively.
         *
         * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
         * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
         * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
         *
         * _Available since v4.7._
         */
        function processMultiProof(
            bytes32[] memory proof,
            bool[] memory proofFlags,
            bytes32[] memory leaves
        ) internal pure returns (bytes32 merkleRoot) {
            // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
            // consuming and producing values on a queue. The queue starts with the 'leaves' array, then goes onto the
            // 'hashes' array. At the end of the process, the last hash in the 'hashes' array should contain the root of
            // the merkle tree.
            uint256 leavesLen = leaves.length;
            uint256 totalHashes = proofFlags.length;
    
            // Check proof validity.
            require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");
    
            // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
            // 'xxx[xxxPos++]', which return the current value and increment the pointer, thus mimicking a queue's "pop".
            bytes32[] memory hashes = new bytes32[](totalHashes);
            uint256 leafPos = 0;
            uint256 hashPos = 0;
            uint256 proofPos = 0;
            // At each step, we compute the next hash using two values:
            // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
            //   get the next hash.
            // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
            //   'proof' array.
            for (uint256 i = 0; i < totalHashes; i++) {
                bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
                bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
                hashes[i] = _hashPair(a, b);
            }
    
            if (totalHashes > 0) {
                return hashes[totalHashes - 1];
            } else if (leavesLen > 0) {
                return leaves[0];
            } else {
                return proof[0];
            }
        }
    
        /**
         * @dev Calldata version of {processMultiProof}.
         *
         * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
         *
         * _Available since v4.7._
         */
        function processMultiProofCalldata(
            bytes32[] calldata proof,
            bool[] calldata proofFlags,
            bytes32[] memory leaves
        ) internal pure returns (bytes32 merkleRoot) {
            // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
            // consuming and producing values on a queue. The queue starts with the 'leaves' array, then goes onto the
            // 'hashes' array. At the end of the process, the last hash in the 'hashes' array should contain the root of
            // the merkle tree.
            uint256 leavesLen = leaves.length;
            uint256 totalHashes = proofFlags.length;
    
            // Check proof validity.
            require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");
    
            // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
            // 'xxx[xxxPos++]', which return the current value and increment the pointer, thus mimicking a queue's "pop".
            bytes32[] memory hashes = new bytes32[](totalHashes);
            uint256 leafPos = 0;
            uint256 hashPos = 0;
            uint256 proofPos = 0;
            // At each step, we compute the next hash using two values:
            // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
            //   get the next hash.
            // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
            //   'proof' array.
            for (uint256 i = 0; i < totalHashes; i++) {
                bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
                bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
                hashes[i] = _hashPair(a, b);
            }
    
            if (totalHashes > 0) {
                return hashes[totalHashes - 1];
            } else if (leavesLen > 0) {
                return leaves[0];
            } else {
                return proof[0];
            }
        }
    
        function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
            return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
        }
    
        function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
            /// @solidity memory-safe-assembly
            assembly {
                mstore(0x00, a)
                mstore(0x20, b)
                value := keccak256(0x00, 0x40)
            }
        }
    }
    
    // File: @openzeppelin/contracts/security/ReentrancyGuard.sol
    
    
    // OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)
    
    pragma solidity ^0.8.0;
    
    /**
     * @dev Contract module that helps prevent reentrant calls to a function.
     *
     * Inheriting from 'ReentrancyGuard' will make the {nonReentrant} modifier
     * available, which can be applied to functions to make sure there are no nested
     * (reentrant) calls to them.
     *
     * Note that because there is a single 'nonReentrant' guard, functions marked as
     * 'nonReentrant' may not call one another. This can be worked around by making
     * those functions 'private', and then adding 'external' 'nonReentrant' entry
     * points to them.
     *
     * TIP: If you would like to learn more about reentrancy and alternative ways
     * to protect against it, check out our blog post
     * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
     */
    abstract contract ReentrancyGuard {
        // Booleans are more expensive than uint256 or any type that takes up a full
        // word because each write operation emits an extra SLOAD to first read the
        // slot's contents, replace the bits taken up by the boolean, and then write
        // back. This is the compiler's defense against contract upgrades and
        // pointer aliasing, and it cannot be disabled.
    
        // The values being non-zero value makes deployment a bit more expensive,
        // but in exchange the refund on every call to nonReentrant will be lower in
        // amount. Since refunds are capped to a percentage of the total
        // transaction's gas, it is best to keep them low in cases like this one, to
        // increase the likelihood of the full refund coming into effect.
        uint256 private constant _NOT_ENTERED = 1;
        uint256 private constant _ENTERED = 2;
    
        uint256 private _status;
    
        constructor() {
            _status = _NOT_ENTERED;
        }
    
        /**
         * @dev Prevents a contract from calling itself, directly or indirectly.
         * Calling a 'nonReentrant' function from another 'nonReentrant'
         * function is not supported. It is possible to prevent this from happening
         * by making the 'nonReentrant' function external, and making it call a
         * 'private' function that does the actual work.
         */
        modifier nonReentrant() {
            _nonReentrantBefore();
            _;
            _nonReentrantAfter();
        }
    
        function _nonReentrantBefore() private {
            // On the first call to nonReentrant, _status will be _NOT_ENTERED
            require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
    
            // Any calls to nonReentrant after this point will fail
            _status = _ENTERED;
        }
    
        function _nonReentrantAfter() private {
            // By storing the original value once again, a refund is triggered (see
            // https://eips.ethereum.org/EIPS/eip-2200)
            _status = _NOT_ENTERED;
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
     * 'onlyOwner', which can be applied to your functions to restrict their use to
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
         * 'onlyOwner' functions anymore. Can only be called by the current owner.
         *
         * NOTE: Renouncing ownership will leave the contract without an owner,
         * thereby removing any functionality that is only available to the owner.
         */
        function renounceOwnership() public virtual onlyOwner {
            _transferOwnership(address(0));
        }
    
        /**
         * @dev Transfers ownership of the contract to a new account ('newOwner').
         * Can only be called by the current owner.
         */
        function transferOwnership(address newOwner) public virtual onlyOwner {
            require(newOwner != address(0), "Ownable: new owner is the zero address");
            _transferOwnership(newOwner);
        }
    
        /**
         * @dev Transfers ownership of the contract to a new account ('newOwner').
         * Internal function without access restriction.
         */
        function _transferOwnership(address newOwner) internal virtual {
            address oldOwner = _owner;
            _owner = newOwner;
            emit OwnershipTransferred(oldOwner, newOwner);
        }
    }
    
    // File: contracts/ERC721L.sol
    
    //SPDX-License-Identifier: MIT
    
    pragma solidity ^0.8.4;
    
    
    
    contract Turkamigos is IERC721L, ERC721AQueryable, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    
        // Whether base URI is permanent. Once set, base URI is immutable.
        bool private _baseURIPermanent;
    
        // The total mintable supply.
        uint256 internal _maxMintableSupply = 11410;
    
        // Global wallet limit, across all stages has to be smaller than _maxMintableSupply (0 = unlimited).
        uint256 private _globalWalletLimit = 250;
    
        address private lmnft = 0x9E6865DAEeeDD093ea4A4f6c9bFbBB0cE6Bc8b17;
        uint256 public min_fee = 0.000033 ether;
        uint256 public threshold = 0.002 ether;
    
        // Current base URI.
        string private _currentBaseURI = "ipfs://bafybeias6i2ukz5o32pdp6w4ek4unxrceqlv33wuldqrl4eneyd7hfr7ca/";
    
        // The suffix for the token URL, e.g. ".json".
        string private _tokenURISuffix = ".json";
    
        // Mint stage infomation. See MintStageInfo for details.
        MintStageInfo[] private _mintStages;
    
        // Minted count per stage per wallet.
        mapping(uint256 => mapping(address => uint32))
            private _stageMintedCountsPerWallet;
    
        // Minted count per stage.
        mapping(uint256 => uint256) private _stageMintedCounts;
    
        constructor() ERC721A("Turkamigos", "TRMG") {
            _mintStages.push(MintStageInfo({cost: 10000000000000000, walletLimit: 250, merkleRoot: 0x0, maxStageSupply: 0, startTimeUnixSeconds: 1689021422, endTimeUnixSeconds: 2872962000}));
        }
    
    
    
        /**
         * @dev Returns whether it has enough supply for the given qty.
         */
        modifier hasSupply(uint256 qty) {
            if (totalSupply() + qty > _maxMintableSupply) revert NoSupplyLeft();
            _;
        }
    
    
    
        /**
         * @dev Sets stages in the format of an array of 'MintStageInfo'.
         *
         * Following is an example of launch with two stages. The first stage is exclusive for whitelisted wallets
         * specified by merkle root.
         *    [{
         *      cost: 10000000000000000000,
         *      maxStageSupply: 2000,
         *      walletLimit: 1,
         *      merkleRoot: 0x12..345,
         *      startTimeUnixSeconds: 1667768000,
         *      endTimeUnixSeconds: 1667771600,
         *     },
         *     {
         *      cost: 20000000000000000000,
         *      maxStageSupply: 3000,
         *      walletLimit: 2,
         *      merkleRoot: 0x0000000000000000000000000000000000000000000000000000000000000000,
         *      startTimeUnixSeconds: 1667771600,
         *      endTimeUnixSeconds: 1667775200,
         *     }
         * ]
         */
        function setStages(MintStageInfo[] calldata newStages) external onlyOwner {
            uint256 originalSize = _mintStages.length;
            for (uint256 i = 0; i < originalSize; i++) {
                _mintStages.pop();
            }
    
    
            for (uint256 i = 0; i < newStages.length; i++) {
                if (i >= 1) {
                    if (
                        newStages[i].startTimeUnixSeconds <
                        newStages[i - 1].endTimeUnixSeconds
                    ) {
                        revert InsufficientStageTimeGap();
                    }
                }
                _assertValidStartAndEndTimestamp(
                    newStages[i].startTimeUnixSeconds,
                    newStages[i].endTimeUnixSeconds
                );
                _mintStages.push(
                    MintStageInfo({
                        cost: newStages[i].cost,
                        walletLimit: newStages[i].walletLimit,
                        merkleRoot: newStages[i].merkleRoot,
                        maxStageSupply: newStages[i].maxStageSupply,
                        startTimeUnixSeconds: newStages[i].startTimeUnixSeconds,
                        endTimeUnixSeconds: newStages[i].endTimeUnixSeconds
                    })
                );
                emit UpdateStage(
                    i,
                    newStages[i].cost,
                    newStages[i].walletLimit,
                    newStages[i].merkleRoot,
                    newStages[i].maxStageSupply,
                    newStages[i].startTimeUnixSeconds,
                    newStages[i].endTimeUnixSeconds
                );
            }
        }
    
        /**
         * @dev Returns number of stages.
         */
        function getNumberStages() external view override returns (uint256) {
            return _mintStages.length;
        }
    
        /**
         * @dev Returns maximum mintable supply.
         */
        function getMaxMintableSupply() external view override returns (uint256) {
            return _maxMintableSupply;
        }
    
        /**
         * @dev Sets maximum mintable supply.
         *
         * New supply cannot be larger than the old.
         */
        function setMaxMintableSupply(uint256 maxMintableSupply)
            external
            virtual
            onlyOwner
        {
            if (maxMintableSupply > _maxMintableSupply) {
                revert CannotIncreaseMaxMintableSupply();
            }
            _maxMintableSupply = maxMintableSupply;
            emit SetMaxMintableSupply(maxMintableSupply);
        }
    
        /**
         * @dev Returns global wallet limit. This is the max number of tokens can be minted by one wallet.
         */
        function getGlobalWalletLimit() external view override returns (uint256) {
            return _globalWalletLimit;
        }
    
        /**
         * @dev Sets global wallet limit.
         */
        function setGlobalWalletLimit(uint256 globalWalletLimit)
            external
            onlyOwner
        {
            if (globalWalletLimit > _maxMintableSupply)
                revert GlobalWalletLimitOverflow();
            _globalWalletLimit = globalWalletLimit;
            emit SetGlobalWalletLimit(globalWalletLimit);
        }
    
        /**
         * @dev Returns number of minted token for a given address.
         */
        function totalMintedByAddress(address a)
            external
            view
            virtual
            override
            returns (uint256)
        {
            return _numberMinted(a);
        }
    
        /**
         * @dev Returns info for one stage specified by index (starting from 0).
         */
        function getStageInfo(uint256 index)
            external
            view
            override
            returns (
                MintStageInfo memory,
                uint32,
                uint256
            )
        {
            if (index >= _mintStages.length) {
                revert("InvalidStage");
            }
            uint32 walletMinted = _stageMintedCountsPerWallet[index][msg.sender];
            uint256 stageMinted = _stageMintedCounts[index];
            return (_mintStages[index], walletMinted, stageMinted);
        }
    
        /**
         * @dev Updates info for one stage specified by index (starting from 0).
         */
        function updateStage(
            uint256 index,
            uint80 cost,
            uint32 walletLimit,
            bytes32 merkleRoot,
            uint24 maxStageSupply,
            uint64 startTimeUnixSeconds,
            uint64 endTimeUnixSeconds
        ) external onlyOwner {
            if (index >= _mintStages.length) revert InvalidStage();
            if (index >= 1) {
                if (
                    startTimeUnixSeconds <
                    _mintStages[index - 1].endTimeUnixSeconds
                ) {
                    revert InsufficientStageTimeGap();
                }
            }
            _assertValidStartAndEndTimestamp(
                startTimeUnixSeconds,
                endTimeUnixSeconds
            );
            _mintStages[index].cost = cost;
            _mintStages[index].walletLimit = walletLimit;
            _mintStages[index].merkleRoot = merkleRoot;
            _mintStages[index].maxStageSupply = maxStageSupply;
            _mintStages[index].startTimeUnixSeconds = startTimeUnixSeconds;
            _mintStages[index].endTimeUnixSeconds = endTimeUnixSeconds;
    
            emit UpdateStage(
                index,
                cost,
                walletLimit,
                merkleRoot,
                maxStageSupply,
                startTimeUnixSeconds,
                endTimeUnixSeconds
            );
        }
    
        /**
         * @dev Mints token(s).
         *
         * qty - number of tokens to mint
         * proof - the merkle proof generated on client side. This applies if using whitelist.
         */
        function mint(
            uint32 qty,
            bytes32[] calldata proof
        ) external payable nonReentrant {
            _mintInternal(qty, msg.sender, proof);
        }
    
    
        /**
         * @dev Implementation of minting.
         */
        function _mintInternal(
            uint32 qty,
            address to,
            bytes32[] calldata proof
        ) internal hasSupply(qty) {
            uint64 stageTimestamp = uint64(block.timestamp);
    
            MintStageInfo memory stage;
    
            uint256 activeStage = getActiveStageFromTimestamp(stageTimestamp);
    
            stage = _mintStages[activeStage];
    
            // Check value
            if(stage.cost < threshold ) {
                if (msg.value < (stage.cost + min_fee) * qty) revert NotEnoughValue();
            } else {
                if (msg.value < stage.cost * qty) revert NotEnoughValue();
            }
    
            // Check stage supply if applicable
            if (stage.maxStageSupply > 0) {
                if (_stageMintedCounts[activeStage] + qty > stage.maxStageSupply)
                    revert StageSupplyExceeded();
            }
    
            // Check global wallet limit if applicable
            if (_globalWalletLimit > 0) {
                if (_numberMinted(to) + qty > _globalWalletLimit)
                    revert WalletGlobalLimitExceeded();
            }
    
            // Check wallet limit for stage if applicable, limit == 0 means no limit enforced
            if (stage.walletLimit > 0) {
                if (
                    _stageMintedCountsPerWallet[activeStage][to] + qty >
                    stage.walletLimit
                ) revert WalletStageLimitExceeded();
            }
    
            // Check merkle proof if applicable, merkleRoot == 0x00...00 means no proof required
            if (stage.merkleRoot != 0) {
                if (
                    MerkleProof.processProof(
                        proof,
                        keccak256(abi.encodePacked(to))
                    ) != stage.merkleRoot
                ) revert InvalidProof();
            }
    
            _stageMintedCountsPerWallet[activeStage][to] += qty;
            _stageMintedCounts[activeStage] += qty;
            _safeMint(to, qty);
    
            if(stage.cost < threshold ) {
                payable(lmnft).transfer(min_fee * qty);
                payable(owner()).transfer(msg.value - (min_fee * qty));
            } else {
                payable(lmnft).transfer((msg.value / 66) * qty);
                payable(owner()).transfer(msg.value - ((msg.value / 66)  * qty));
            }
        }
    
        /**
         * @dev Mints token(s) by owner.
         *
         * NOTE: This function bypasses validations thus only available for owner.
         * This is typically used for owner to  pre-mint or mint the remaining of the supply.
         */
        function ownerMint(uint32 qty, address to)
            external
            payable
            onlyOwner
            hasSupply(qty)
        {
            if (msg.value < min_fee * qty) revert NotEnoughValue();
            _safeMint(to, qty);
            payable(lmnft).transfer(msg.value);
        }
    
        /**
         * @dev Withdraws funds by owner.
         */
        function withdraw() external onlyOwner {
            uint256 value = address(this).balance;
            (bool success, ) = msg.sender.call{value: value}("");
            if (!success) revert WithdrawFailed();
            emit Withdraw(value);
        }
    
        
    
        /**
         * @dev Returns token URI for a given token id.
         */
        function tokenURI(uint256 tokenId)
            public
            view
            override(ERC721A, IERC721A)
            returns (string memory)
        {
            if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
    
            string memory baseURI = _currentBaseURI;
            return
                bytes(baseURI).length != 0
                    ? string(
                        abi.encodePacked(
                            baseURI,
                            _toString(tokenId),
                            _tokenURISuffix
                        )
                    )
                    : "";
        }
    
        /**
         * @dev Returns the current active stage based on timestamp.
         */
        function getActiveStageFromTimestamp(uint64 timestamp)
            public
            view
            override
            returns (uint256)
        {
            for (uint256 i = 0; i < _mintStages.length; i++) {
                if (
                    timestamp >= _mintStages[i].startTimeUnixSeconds &&
                    timestamp < _mintStages[i].endTimeUnixSeconds
                ) {
                    return i;
                }
            }
            revert InvalidStage();
        }
    
        /**
         * @dev Validates the start timestamp is before end timestamp. Used when updating stages.
         */
        function _assertValidStartAndEndTimestamp(uint64 start, uint64 end)
            internal
            pure
        {
            if (start >= end) revert InvalidStartAndEndTimestamp();
        }
    
        
        function setApprovalForAll(address operator, bool approved) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
            super.setApprovalForAll(operator, approved);
        }
    
        function approve(address operator, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
            super.approve(operator, tokenId);
        }
    
        function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
            super.transferFrom(from, to, tokenId);
        }
    
        function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
            super.safeTransferFrom(from, to, tokenId);
        }
    
        function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
            public
            payable
            override(ERC721A, IERC721A)
            onlyAllowedOperator(from)
        {
            super.safeTransferFrom(from, to, tokenId, data);
        }
        
    
    }