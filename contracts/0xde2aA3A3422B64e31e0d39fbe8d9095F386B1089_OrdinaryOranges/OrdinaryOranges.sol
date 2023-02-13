/**
 *Submitted for verification at Etherscan.io on 2023-02-12
*/

// File @openzeppelin/contracts/utils/introspection/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File @openzeppelin/contracts/interfaces/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);
}

// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File @openzeppelin/contracts/proxy/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) ||
                (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(
            !_initializing && _initialized < version,
            "Initializable: contract is already initialized"
        );
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// File @openzeppelin/contracts/token/ERC721/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
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
    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);
}

// File @openzeppelin/contracts/utils/[email protected]

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

// File contracts/interfaces/IGovernable.sol

pragma solidity 0.8.15;

/**
 * @notice Governable interface
 */
interface IGovernable {
    function governor() external view returns (address _governor);

    function transferGovernorship(address _proposedGovernor) external;
}

// File contracts/access/Governable.sol

pragma solidity 0.8.15;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (governor) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the governor account will be the one that deploys the contract. This
 * can later be changed with {transferGovernorship}.
 *
 */
abstract contract Governable is IGovernable, Context, Initializable {
    address public governor;
    address private proposedGovernor;

    event UpdatedGovernor(
        address indexed previousGovernor,
        address indexed proposedGovernor
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial governor.
     */
    constructor() {
        address msgSender = _msgSender();
        governor = msgSender;
        emit UpdatedGovernor(address(0), msgSender);
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial governor.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __Governable_init() internal onlyInitializing {
        address msgSender = _msgSender();
        governor = msgSender;
        emit UpdatedGovernor(address(0), msgSender);
    }

    /**
     * @dev Throws if called by any account other than the governor.
     */
    modifier onlyGovernor() {
        require(governor == _msgSender(), "not governor");
        _;
    }

    /**
     * @dev Transfers governorship of the contract to a new account (`proposedGovernor`).
     * Can only be called by the current governor.
     */
    function transferGovernorship(
        address _proposedGovernor
    ) external onlyGovernor {
        require(_proposedGovernor != address(0), "invalid proposed governor");
        proposedGovernor = _proposedGovernor;
    }

    /**
     * @dev Allows new governor to accept governorship of the contract.
     */
    function acceptGovernorship() external {
        require(proposedGovernor == _msgSender(), "not the proposed governor");
        emit UpdatedGovernor(governor, proposedGovernor);
        governor = proposedGovernor;
        proposedGovernor = address(0);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File contracts/interfaces/ICapsule.sol

pragma solidity 0.8.15;

interface ICapsule is IERC721, IERC2981 {
    function mint(address account, string memory _uri) external;

    function burn(address owner, uint256 tokenId) external;

    function setMetadataProvider(address _metadataAddress) external;

    // Read functions
    function baseURI() external view returns (string memory);

    function counter() external view returns (uint256);

    function exists(uint256 tokenId) external view returns (bool);

    function isCollectionMinter(address _account) external view returns (bool);

    function isCollectionPrivate() external view returns (bool);

    function maxId() external view returns (uint256);

    function royaltyRate() external view returns (uint256);

    function royaltyReceiver() external view returns (address);

    function tokenURIOwner() external view returns (address);

    ////////////////////////////////////////////////////////////////////////////
    //     Extra functions compare to original ICapsule interface    ///////////
    ////////////////////////////////////////////////////////////////////////////
    // Read functions
    function owner() external view returns (address);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    // Admin functions
    function lockCollectionCount(uint256 _nftCount) external;

    function setBaseURI(string calldata baseURI_) external;

    function setTokenURI(uint256 _tokenId, string memory _newTokenURI) external;

    function transferOwnership(address _newOwner) external;

    function updateTokenURIOwner(address _newTokenURIOwner) external;

    function updateRoyaltyConfig(
        address _royaltyReceiver,
        uint256 _royaltyRate
    ) external;
}

// File contracts/interfaces/ICapsuleFactory.sol

pragma solidity 0.8.15;

interface ICapsuleFactory is IGovernable {
    function capsuleCollectionTax() external view returns (uint256);

    function capsuleMinter() external view returns (address);

    function createCapsuleCollection(
        string memory _name,
        string memory _symbol,
        address _tokenURIOwner,
        bool _isCollectionPrivate
    ) external payable returns (address);

    function collectionBurner(address _capsule) external view returns (address);

    function getAllCapsuleCollections()
        external
        view
        returns (address[] memory);

    function getCapsuleCollectionsOf(
        address _owner
    ) external view returns (address[] memory);

    function getBlacklist() external view returns (address[] memory);

    function getWhitelist() external view returns (address[] memory);

    function isBlacklisted(address _user) external view returns (bool);

    function isCapsule(address _capsule) external view returns (bool);

    function isCollectionBurner(
        address _capsuleCollection,
        address _account
    ) external view returns (bool);

    function isWhitelisted(address _user) external view returns (bool);

    function taxCollector() external view returns (address);

    //solhint-disable-next-line func-name-mixedcase
    function VERSION() external view returns (string memory);

    // Special permission functions
    function addToWhitelist(address _user) external;

    function removeFromWhitelist(address _user) external;

    function addToBlacklist(address _user) external;

    function removeFromBlacklist(address _user) external;

    function flushTaxAmount() external;

    function setCapsuleMinter(address _newCapsuleMinter) external;

    function updateCapsuleCollectionBurner(
        address _capsuleCollection,
        address _newBurner
    ) external;

    function updateCapsuleCollectionOwner(
        address _previousOwner,
        address _newOwner
    ) external;

    function updateCapsuleCollectionTax(uint256 _newTax) external;

    function updateTaxCollector(address _newTaxCollector) external;
}

// File contracts/interfaces/ICapsuleMinter.sol

pragma solidity 0.8.15;

interface ICapsuleMinter is IGovernable {
    struct SingleERC20Capsule {
        address tokenAddress;
        uint256 tokenAmount;
    }

    struct MultiERC20Capsule {
        address[] tokenAddresses;
        uint256[] tokenAmounts;
    }

    struct SingleERC721Capsule {
        address tokenAddress;
        uint256 id;
    }

    struct MultiERC721Capsule {
        address[] tokenAddresses;
        uint256[] ids;
    }

    struct MultiERC1155Capsule {
        address[] tokenAddresses;
        uint256[] ids;
        uint256[] tokenAmounts;
    }

    function capsuleMintTax() external view returns (uint256);

    function factory() external view returns (ICapsuleFactory);

    function getMintWhitelist() external view returns (address[] memory);

    function getCapsuleOwner(
        address _capsule,
        uint256 _id
    ) external view returns (address);

    function getWhitelistedCallers() external view returns (address[] memory);

    function isMintWhitelisted(address _user) external view returns (bool);

    function isWhitelistedCaller(address _caller) external view returns (bool);

    function multiERC20Capsule(
        address _capsule,
        uint256 _id
    ) external view returns (MultiERC20Capsule memory _data);

    function multiERC721Capsule(
        address _capsule,
        uint256 _id
    ) external view returns (MultiERC721Capsule memory _data);

    function multiERC1155Capsule(
        address _capsule,
        uint256 _id
    ) external view returns (MultiERC1155Capsule memory _data);

    function singleERC20Capsule(
        address _capsule,
        uint256 _id
    ) external view returns (address _token, uint256 _amount);

    function mintSimpleCapsule(
        address _capsule,
        string memory _uri,
        address _receiver
    ) external payable;

    function burnSimpleCapsule(
        address _capsule,
        uint256 _id,
        address _burnFrom
    ) external;

    function mintSingleERC20Capsule(
        address _capsule,
        address _token,
        uint256 _amount,
        string memory _uri,
        address _receiver
    ) external payable;

    // @dev Legacy burn function
    function burnSingleERC20Capsule(address _capsule, uint256 _id) external;

    function burnSingleERC20Capsule(
        address _capsule,
        uint256 _id,
        address _burnFrom,
        address _receiver
    ) external;

    function mintSingleERC721Capsule(
        address _capsule,
        address _token,
        uint256 _id,
        string memory _uri,
        address _receiver
    ) external payable;

    function burnSingleERC721Capsule(
        address _capsule,
        uint256 _id,
        address _burnFrom,
        address _receiver
    ) external;

    function mintMultiERC20Capsule(
        address _capsule,
        address[] memory _tokens,
        uint256[] memory _amounts,
        string memory _uri,
        address _receiver
    ) external payable;

    function burnMultiERC20Capsule(
        address _capsule,
        uint256 _id,
        address _burnFrom,
        address _receiver
    ) external;

    function mintMultiERC721Capsule(
        address _capsule,
        address[] memory _tokens,
        uint256[] memory _ids,
        string memory _uri,
        address _receiver
    ) external payable;

    function burnMultiERC721Capsule(
        address _capsule,
        uint256 _id,
        address _burnFrom,
        address _receiver
    ) external;

    function mintMultiERC1155Capsule(
        address _capsule,
        address[] memory _tokens,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        string memory _uri,
        address _receiver
    ) external payable;

    function burnMultiERC1155Capsule(
        address _capsule,
        uint256 _id,
        address _burnFrom,
        address _receiver
    ) external;

    // Special permission functions
    function addToWhitelist(address _user) external;

    function removeFromWhitelist(address _user) external;

    function flushTaxAmount() external;

    function updateCapsuleMintTax(uint256 _newTax) external;

    function updateWhitelistedCallers(address _caller) external;
}

// File @openzeppelin/contracts/token/ERC721/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File contracts/OrdinaryOranges.sol

// SPDX-License-Identifier: GPLv3

pragma solidity 0.8.15;

/// @title OrdinaryOranges
contract OrdinaryOranges is Governable, IERC721Receiver {
    ICapsuleFactory public constant CAPSULE_FACTORY =
        ICapsuleFactory(0x4Ced59c19F1f3a9EeBD670f746B737ACf504d1eB);
    ICapsuleMinter public constant CAPSULE_MINTER =
        ICapsuleMinter(0xb8Cf4A28DA322598FDB78a1406a61B72d6F6b396);
    ICapsule public immutable capsuleCollection;

    /// @notice Team and giveaway mints
    uint8 public constant TEAM_MINT = 16;
    uint8 public constant GIVEAWAY_MINT = 16;

    /// @notice Mint Fee
    uint256 public OOMintFee = 1 ether;

    /// @notice Flag indicating whether the OO mint is enabled.
    bool public isMintEnabled;

    event OrdinaryOrangeMinted(address indexed user);
    event OrdinaryOrangeBurnt(
        address indexed user,
        uint256 indexed id,
        string indexed btcAddress
    );
    event MintToggled(bool mintStatus);

    constructor(address _capsuleCollection) payable {
        capsuleCollection = ICapsule(_capsuleCollection);
    }

    /// @notice Governor Mint
    function governorMint() external payable {
        address _caller = _msgSender();

        require(_caller == governor, "not-governor");
        require(
            capsuleCollection.counter() < TEAM_MINT + GIVEAWAY_MINT,
            "governor-mint-period-over"
        );

        // Ordinary Orange collection will be using baseURL and will not need URI for individual NFTs.
        // Hence passing empty token URI to mint function below.
        CAPSULE_MINTER.mintSimpleCapsule{value: msg.value}(
            address(capsuleCollection),
            "",
            _caller
        );

        emit OrdinaryOrangeMinted(_caller);
    }

    /// @notice Mint an Ordinary Orange to caller address
    function mint() external payable {
        require(isMintEnabled, "mint-is-not-enabled");
        require(msg.value == OOMintFee, "wrong-mint-fee-paid");

        address _caller = _msgSender();

        // Ordinary Orange collection will be using baseURL and will not need URI for individual NFTs.
        // Hence passing empty token URI to mint function below.
        CAPSULE_MINTER.mintSimpleCapsule{value: 0.001 ether}(
            address(capsuleCollection),
            "",
            _caller
        );
        emit OrdinaryOrangeMinted(_caller);
    }

    /**
     * @notice Burn an OO
     * @param id_ OO id to burn
     * @param btcAddress the address on Bitcoin which will recieve the corresponding OO
     */
    function burn(uint256 id_, string memory btcAddress) external {
        address _caller = _msgSender();
        // Transfer OO to contract
        capsuleCollection.safeTransferFrom(_caller, address(this), id_);
        // Burn OO
        CAPSULE_MINTER.burnSimpleCapsule(
            address(capsuleCollection),
            id_,
            address(this)
        );
        emit OrdinaryOrangeBurnt(_caller, id_, btcAddress);
    }

    /// @dev This function enables this contract to receive ERC721 tokens
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /******************************************************************************
     *                            Governor functions                              *
     *****************************************************************************/
    /// @notice onlyGovernor:: Toggle minting status of the Ordinary Oranges
    function toggleMint() external onlyGovernor {
        isMintEnabled = !isMintEnabled;
        emit MintToggled(isMintEnabled);
    }

    /**
     * @notice onlyGovernor:: Transfer ownership of the Ordinary Oranges collection
     * @param newOwner_ Address of new owner
     */
    function transferCollectionOwnership(
        address newOwner_
    ) external onlyGovernor {
        capsuleCollection.transferOwnership(newOwner_);
    }

    /**
     * @notice onlyGovernor:: Set the collection baseURI
     * @param baseURI_ New baseURI string
     */
    function updateBaseURI(string memory baseURI_) public onlyGovernor {
        capsuleCollection.setBaseURI(baseURI_);
    }

    /**
     * @notice Update collection burner. Add self address as collection burner for OO
     */
    function claimCollectionBurnerRole() external onlyGovernor {
        CAPSULE_MINTER.factory().updateCapsuleCollectionBurner(
            address(capsuleCollection),
            address(this)
        );
    }

    /**
     * @notice onlyGovernor:: Transfer metamaster of the Ordinary Oranges collection
     * @param metamaster_ Address of new metamaster
     */
    function updateMetamaster(address metamaster_) external onlyGovernor {
        capsuleCollection.updateTokenURIOwner(metamaster_);
    }

    /**
     * @notice onlyGovernor:: Update royalty receiver and rate in Ordinary Oranges collection
     * @param royaltyReceiver_ Address of royalty receiver
     * @param royaltyRate_ Royalty rate in Basis Points. ie. 100 = 1%, 10_000 = 100%
     */
    function updateRoyaltyConfig(
        address royaltyReceiver_,
        uint256 royaltyRate_
    ) external onlyGovernor {
        capsuleCollection.updateRoyaltyConfig(royaltyReceiver_, royaltyRate_);
    }
}