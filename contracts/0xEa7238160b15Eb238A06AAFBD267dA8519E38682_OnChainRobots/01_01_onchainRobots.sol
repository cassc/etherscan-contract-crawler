/**
 *Submitted for verification at Etherscan.io on 2021-09-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//
//
// On chain PFP collection of 10k unique profile images with the following properties:
//   - a single Ethereum transaction created everything
//   - all metadata on chain
//   - all images on chain in svg format
//   - all created in the constraints of a single txn without need of any other txns to load additional data
//   - no use of other deployed contracts
//   - all 10,000 OnChain Robots are unique
//   - the traits have distribution and rarities interesting for collecting
//   - everything on chain can be used in other apps and collections in the future
// And did I say, Robots?

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// 
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {
            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
            mstore(result, encodedLen)
        }
        return string(result);
    }
}

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

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

/*
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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
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
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
}

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
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
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// Bring on the OnChain Robots!
contract OnChainRobots is ERC721Enumerable, ReentrancyGuard, Ownable {

  using Strings for uint256;
  bool public mintStatus;
  uint public price=4;





  uint256 public constant maxSupply = 5000;
  uint256 public numClaimed = 0;
  string[] private background = ["166","5cb","fe7","9cf","f8e","e72","8e7","fdd"]; // only trait that is uniform, no need for rarity weights
  string[] private fur1 = ["777","fff","aae","fa8","f14","fc2","396","777","049","901","fc5","ffe","574","bcc","d04","222","889","7f9","fd1"];
  string[] private fur2 = ["532","653","653","653","653","653","653","653","653","653","110","653","711","344","799","555","8a8","32f","653"];
  uint8[] private fur_w =[249, 246, 223, 141, 116, 114, 93, 90, 89, 86, 74, 72, 55, 48, 39, 32, 28, 14, 8];
  string[] private eyes = ["abe","0a0","653","888","be7","abe","0a0","653","888","be7","cef","abe","0a0","653","888","be7","cef","abe","0a0","653","888","be7","cef"];
  uint8[] private eyes_w = [245, 121, 107, 101, 79, 78, 70, 68, 62, 58, 56, 51, 50, 48, 44, 38, 35, 33, 31, 22, 15, 10, 7];
  string[] private mouth = ["653","ffc","f89","777","049","901","bcc","d04","fd1","ffc","653","f89","777","049","bcc","901","901","bcc","653","d04","ffc","f89","777","049","fd1","f89","777","bcc","d04","049","ffc","901","fd1"];
  uint8[] private mouth_w = [252, 172, 80, 79, 56, 49, 37, 33, 31, 30, 28, 27, 26, 23, 22, 18, 15, 14, 13, 12, 11, 10, 10, 10, 9, 8, 7, 7, 6, 5, 5, 4, 3];
  string[] private earring = ["999","fe7","999","999","fe7","bdd"];
  uint8[] private earring_w = [251, 32, 29, 17, 16, 8, 5];
  string[] private clothes1 = ["057","099","9db","eda","e90","c60","b30","5b9","18a","e75","8b9","e52","fac","ece","f8a","9b6","98f","0c9","ffb","896","fb4","d25","288","7dd","fa9","ffd","fff","567","701","d72","c22","124","437","fc5","19a","167","f9c","ecf","eeb","adf","dfe","e65","2cb"];
  string[] private clothes2 = ["e34","29b","fb0","f70","8fd","58b","f76","fb6","46e","94d","5a3","8c2","ac5","e52","fac","bfe","fc5","bdf","3b0","fdc","9a5","fac","f70","bbf","8cc","89f","faf","7cb","6dd","f55","7fa","cfa","fe9","fde","9fe","9eb","e23","f26","afd","1cb","77e","629","af4"];
  uint8[] private clothes_w = [251, 55, 45, 43, 38, 37, 34, 33, 32, 31, 31, 31, 31, 31, 30, 30, 29, 29, 28, 27, 27, 27, 26, 25, 24, 22, 21, 20, 19, 19, 19, 19, 19, 19, 18, 17, 16, 15, 14, 13, 11, 9, 8, 6];
  string[] private hat1 = ["fa0","daa","a66","524","b8b","672","d43","edf","aaf","78c","778","666","fcd","113","f47","fb9","cdd","432","546","a86","ddb","8b7","466","225","244","934","858","459","59a","cba","9c3","f72","538","fdc","113","fce",""];
  string[] private hat2 = ["0f0","00f","f80","ff0","90f","f0f","f48","f00","0f0","00f","f80","ff0","90f","f0f","000","f00","0f0","00f","f80","ff0","90f","f0f","f00","0f0","00f","f80","ff0","90f","f00","f0f","f00","000","000","0f0","00f","f48",""];  
  uint8[] private hat_w = [251, 64, 47, 42, 39, 38, 36, 35, 34, 34, 33, 29, 28, 26, 26, 25, 25, 25, 22, 21, 20, 20, 18, 17, 17, 15, 14, 14, 13, 13, 12, 12, 12, 10, 9, 8, 7];
    string[] private z = ['<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 480 480"><rect x="0" y="0" width="480" height="480" style="fill:#',
    '"/><path d="M194.6,359.97h93.64c28.38,0,51.41,23.04,51.41,51.41v69.22H143.18v-69.22c0-28.38,23.04-51.41,51.41-51.41Z" style=" stroke: #000; stroke-miterlimit: 10; stroke-width: 13px;fill: #', '"/><rect id="left-nipple" x="78.5" y="379.78" width="45.38" height="121.79" rx="22.69" ry="22.69" style="stroke: #000; stroke-miterlimit: 10; stroke-width: 13px;fill: #', '"/><rect id="Right-nipple" x="359.5" y="379.78" width="45.38" height="121.79" rx="22.69" ry="22.69" style=" stroke: #000; stroke-miterlimit: 10; stroke-width: 13px;fill: #',
    '"/><rect x="70.1" y="190.69" width="47.49" height="73.6" rx="15.4" ry="15.4" style=" stroke: #000; stroke-miterlimit: 10; stroke-width: 8px;fill: #', '"/><circle id="Left-innerEar" cx="101.19" cy="228.53" r="19.92" style=" stroke: #000; stroke-miterlimit: 10; stroke-width: 9px;fill: #', '"/><rect x="366.62" y="185.69" width="47.49" height="73.6" rx="16.58" ry="16.58" transform="translate(780.73 444.98) rotate(-180)" style=" stroke: #000; stroke-miterlimit: 10; stroke-width: 8px;fill: #',
    '"/><circle id="Left-innerEar" cx="383.02" cy="223.53" r="19.92" style=" stroke: #000; stroke-miterlimit: 10; stroke-width: 9px;fill: #', '"/><rect x="102.97" y="112.65" width="277.47" height="230.36" rx="105.7" ry="105.7" style=" stroke: #000; stroke-miterlimit: 10; stroke-width: 13px;fill: #', '"/><rect x="102.97" y="112.65" width="277.47" height="230.36" rx="105.7" ry="105.7" style="fill: #',
    '"/><circle id="Left-OuterEye" cx="191.15" cy="225.98" r="27.93" style=" stroke: #000; stroke-miterlimit: 10; stroke-width: 10px;fill: #fff"/><circle id="Right-OuterEye" cx="292.15" cy="225.98" r="27.93" style=" stroke: #000; stroke-miterlimit: 10; stroke-width: 10px;fill: #fff"/><circle id="Left-OuterEye" cx="191.15" cy="225.98" r="14.65" style="fill: #',
    '"/><circle id="Right-OuterEye" cx="292.15" cy="225.98" r="14.65" style="fill: #', '"/> <circle id="Left-InnerEye" cx="191.15" cy="225.98" r="7.5" style="fill: #000"/><circle id="Right-InnerEye" cx="292.15" cy="225.98" r="7.5" style="fill: #000"/>',
    '<path d="M208.67,343.01h66.06c45.59,0,84.44-28.87,99.27-69.32H109.4c14.83,40.45,53.68,69.32,99.27,69.32Z" style=" stroke: #000; stroke-miterlimit: 10; stroke-width: 5px;fill: #',
     '"/><path id="Mouth" d="M214.15,304.04l3.49,1.38c15.45,6.12,32.66,6.08,48.08-.1l3.19-1.28" style="fill: none;  stroke-miterlimit: 10; stroke-width: 10px;stroke: #000"/><circle cx="101" cy="400.31" r="10.29" style="fill: #fcff3"/><circle cx="382" cy="400.31" r="10.29" style="fill: #fcff3"/>',
    '</svg>'];
  string private cross='<path id="path961" d="M456.18,59.69c0-5.1-3.14-9.53-7.81-11.92,1.64-4.96,.71-10.35-2.89-13.95s-8.99-4.53-13.95-2.89c-2.35-4.67-6.81-7.81-11.92-7.81s-9.53,3.14-11.88,7.81c-4.99-1.64-10.38-.71-13.98,2.89-3.6,3.6-4.5,8.99-2.85,13.95-4.67,2.39-7.85,6.81-7.85,11.92s3.18,9.53,7.85,11.92c-1.64,4.96-.75,10.35,2.85,13.95,3.6,3.6,8.99,4.5,13.95,2.89,2.39,4.67,6.81,7.81,11.92,7.81s9.56-3.14,11.92-7.81c4.96,1.61,10.35,.71,13.95-2.89s4.53-8.99,2.89-13.95c4.67-2.39,7.81-6.81,7.81-11.92Zm-41.78,14.98l-13.34-13.34,5.03-5.07,8.06,8.06,17.12-18.66,5.24,4.85s-22.12,24.15-22.12,24.15Z" style="fill: #4496d2; stroke: #fff; stroke-miterlimit: 10; stroke-width: 4px;"/>';
  string private clo1='<path d="M198.82,362.56h85.18c28.38,0,51.41,23.04,51.41,51.41v64.03H147.41v-64.03c0-28.38,23.04-51.41,51.41-51.41Z" style="fill: #';
  string private clo2='"/><circle cx="243.28" cy="426.62" r="37.48" style="fill: #231f20; stroke: #fff; stroke-miterlimit: 10; stroke-width: 4px;"/><path d="M240.89,416.58v30.72h-12.49v-42.08h16.02c4.92,0,8.8,1.29,11.64,3.88s4.26,5.96,4.26,10.12-1.87,7.87-5.62,10.72l7.25,17.35h-13.18l-6.06-13.56v-10.79h1.01c2.65,0,3.97-1.14,3.97-3.41,0-1.98-1.54-2.96-4.61-2.96h-2.21Z" style="fill: #';
  string private hh1='<line x1="241.47" y1="89.18" x2="241.7" y2="112.65" style="fill: none; stroke: #000; stroke-miterlimit: 10; stroke-width: 13px;"/><circle cx="242.44" cy="65.13" r="25.85" style=" stroke: #000; stroke-miterlimit: 10; stroke-width: 13px;fill: #';
  string private hh2='"/><polygon points="202.29 114.55 284.65 114.82 242.44 149.97 202.29 114.55" style=" stroke: #000; stroke-miterlimit: 10; stroke-width: 7px;fill: #';
  string private sl1='<rect x="167.5" y="191.41" width="46.65" height="19.87" style="fill: #00a651; stroke: #000; stroke-miterlimit: 10; stroke-width: 10px;"/><rect x="269.01" y="191.61" width="46.65" height="19" style="fill: #00a651; stroke: #000; stroke-miterlimit: 10; stroke-width: 10px;"/><rect x="160.03" y="185.69" width="163.36" height="22.6" style="fill: #';
  string private sl2='"/><rect x="160" y="170" width="0" height="0" style="fill:#';
  string private mou='<rect x="191.15" y="294.03" width="101" height="18.96" style="fill: #fff; stroke: #000; stroke-miterlimit: 10; stroke-width: 6px;"/><line x1="203.27" y1="294.03" x2="203.27" y2="312.99" style="fill: none; stroke: #000; stroke-miterlimit: 10; stroke-width: 6px;"/><line x1="216.07" y1="294.03" x2="216.07" y2="312.99" style="fill: none; stroke: #000; stroke-miterlimit: 10; stroke-width: 6px;"/><line x1="228.07" y1="294.03" x2="228.07" y2="312.99" style="fill: none; stroke: #000; stroke-miterlimit: 10; stroke-width: 6px;"/><line x1="241.07" y1="294.03" x2="241.07" y2="312.99" style="fill: none; stroke: #000; stroke-miterlimit: 10; stroke-width: 6px;"/><line x1="254.07" y1="294.03" x2="254.07" y2="312.99" style="fill: none; stroke: #000; stroke-miterlimit: 10; stroke-width: 6px;"/><line x1="267.07" y1="294.03" x2="267.07" y2="312.99" style="fill: none; stroke: #000; stroke-miterlimit: 10; stroke-width: 6px;"/><line x1="280.07" y1="294.03" x2="280.07" y2="312.99" style="fill: none; stroke: #000; stroke-miterlimit: 10; stroke-width: 6px;"/>';
  string private ey1='<path id="path3307" d="M164.1,163.44c0,3.53-2.86,6.4-6.4,6.4s-6.4-2.86-6.4-6.4,2.86-6.4,6.4-6.4,6.4,2.86,6.4,6.4Z" style="fill: none; stroke: #010101; stroke-linecap: square; stroke-miterlimit: 3.8; stroke-width: 2px;"/><path id="shapes-f16-en.svgpath1554" d="M159.93,159.13c-1.35-.79-.74,1.23-2.28,1.26-1.54,.04-1.01-2.01-2.33-1.16s.63,1.3-.12,2.74c-.74,1.44-2.14-.07-2.11,1.57s1.37,.07,2.17,1.48-1.13,1.94,.23,2.73,.74-1.23,2.28-1.26c1.54-.04,1.01,2.01,2.33,1.16s-.63-1.3,.12-2.74,2.14,.07,2.11-1.57-1.37-.07-2.17-1.48c-.8-1.41,1.13-1.94-.23-2.73h0Z" style=" fill-rule: evenodd; stroke: #010101; stroke-width: .38px;fill: #';
  string private ey2='"/><path id="path3307" d="M334.1,163.44c0,3.53-2.86,6.4-6.4,6.4s-6.4-2.86-6.4-6.4,2.86-6.4,6.4-6.4,6.4,2.86,6.4,6.4Z" style="fill: none; stroke: #010101; stroke-linecap: square; stroke-miterlimit: 3.8; stroke-width: 2px;"/><path id="shapes-f16-en.svgpath1554" d="M329.93,159.13c-1.35-.79-.74,1.23-2.28,1.26-1.54,.04-1.01-2.01-2.33-1.16s.63,1.3-.12,2.74c-.74,1.44-2.14-.07-2.11,1.57s1.37,.07,2.17,1.48-1.13,1.94,.23,2.73,.74-1.23,2.28-1.26c1.54-.04,1.01,2.01,2.33,1.16s-.63-1.3,.12-2.74,2.14,.07,2.11-1.57-1.37-.07-2.17-1.48c-.8-1.41,1.13-1.94-.23-2.73h0Z" style=" fill-rule: evenodd; stroke: #010101; stroke-width: .38px;fill: #';
  string private ey3='<rect x="167.5" y="234.41" width="46.65" height="19.87" style="fill: #00a651; stroke: #000; stroke-miterlimit: 10; stroke-width: 10px;"/><rect x="269.01" y="234.61" width="46.65" height="19" style="fill: #00a651; stroke: #000; stroke-miterlimit: 10; stroke-width: 10px;"/><rect x="160.03" y="237.41" width="163.36" height="23.32" style="fill: #';
  string private zz='"/>';
  string private ea1='<rect x="17.24" y="304.56" width="92.01" height="50.4" rx="13.52" ry="13.52" style="fill: #006838; stroke: #231f20; stroke-miterlimit: 10; stroke-width: 4px; ';
  string private ea2='"/><rect x="17.24" y="304.56" width="92.01" height="50.4" rx="13.52" ry="13.52" style="fill: #006838; stroke: #231f20; stroke-miterlimit: 10; stroke-width: 4px;"/><rect x="17.24" y="304.56" width="92.01" height="50.4" rx="13.52" ry="13.52" style="fill: #006838;"/><path d="m50.38,338.36c-2.48,0-4.35-.71-5.59-2.14s-1.86-3.57-1.86-6.43c0-2.71.64-4.81,1.93-6.3s3.1-2.23,5.43-2.23c1.16,0,2.18.18,3.06.54s1.52.88,1.93,1.54l-1.75,1.73c-.36-.53-.81-.94-1.35-1.23s-1.13-.43-1.75-.43c-1.58,0-2.8.54-3.68,1.63s-1.31,2.63-1.31,4.62c0,2.18.44,3.81,1.31,4.9s2.18,1.63,3.91,1.63c.74,0,1.4-.07,1.96-.22s1.03-.27,1.39-.37l.91,2.04c-.33.1-.9.24-1.73.43s-1.76.28-2.82.28Zm-1.08-6.33v-2.23h5.55v2.23h-5.55Zm3.3,5.62v-7.85h2.32v7.85h-2.32Z" style="fill: #fff;"/><path d="m57.72,338.13v-16.64h2.34v16.64h-2.34Zm4.45-6.8l-1.8-6.89h-.68v-2.95h1.66l1.8,7.15h.09l.23,2.7h-1.31Zm.68,0l.35-2.7h.14l1.8-7.15h1.66v2.95h-.68l-1.8,6.89h-1.48Zm3.59,6.8v-16.64h2.34v16.64h-2.34Z" style="fill: #fff;"/><path d="m77.31,338.36c-.48,0-.88-.17-1.22-.51s-.51-.75-.51-1.22.17-.89.51-1.23.75-.5,1.22-.5.89.17,1.23.5.5.75.5,1.23-.17.88-.5,1.22-.75.51-1.23.51Zm-1.03-5.58l-.19-11.41h2.44l-.23,11.41h-2.02Z" style="fill: #fff; ';
  string private ea3='"/><rect x="17.24" y="304.56" width="92.01" height="50.4" rx="13.52" ry="13.52" style="fill: #006838; stroke: #231f20; stroke-miterlimit: 10; stroke-width: 4px;"/><rect x="17.24" y="304.56" width="92.01" height="50.4" rx="13.52" ry="13.52" style="fill: #006838;"/><path d="m36.92,338.65v-16.64h2.44v16.64h-2.44Zm7.45,0l-4.78-12.66h-1.08v-3.98h1.55l4.78,12.66h.59v3.98h-1.05Zm.7,0v-16.64h2.44v16.64h-2.44Z" style="fill: #fff;"/><path d="m57.47,338.88c-2.48,0-4.35-.71-5.59-2.14s-1.86-3.57-1.86-6.43c0-2.71.64-4.81,1.93-6.3s3.1-2.23,5.43-2.23c1.16,0,2.18.18,3.06.54s1.52.88,1.93,1.54l-1.75,1.73c-.36-.53-.81-.94-1.35-1.23s-1.13-.43-1.75-.43c-1.58,0-2.8.54-3.68,1.63s-1.31,2.63-1.31,4.62c0,2.18.44,3.81,1.31,4.9s2.18,1.63,3.91,1.63c.74,0,1.4-.07,1.96-.22s1.03-.27,1.39-.37l.91,2.04c-.33.1-.9.24-1.73.43s-1.76.28-2.82.28Zm-1.08-6.33v-2.23h5.55v2.23h-5.55Zm3.3,5.62v-7.85h2.32v7.85h-2.32Z" style="fill: #fff;"/><path d="m64.81,338.65v-16.64h2.34v16.64h-2.34Zm4.45-6.8l-1.8-6.89h-.68v-2.95h1.66l1.8,7.15h.09l.23,2.7h-1.31Zm.68,0l.35-2.7h.14l1.8-7.15h1.66v2.95h-.68l-1.8,6.89h-1.48Zm3.59,6.8v-16.64h2.34v16.64h-2.34Z" style="fill: #fff;"/><path d="m79.34,324.23v-2.23h10.12v2.23h-10.12Zm0,14.41v-2.23h10.12v2.23h-10.12Zm3.83,0v-16.64h2.44v16.64h-2.44Z" style="fill: #fff;"/>';
  string private ea4='"/><rect x="17.24" y="304.56" width="92.01" height="50.4" rx="13.52" ry="13.52" style="fill: #006838; stroke: #231f20; stroke-miterlimit: 10; stroke-width: 4px;"/><rect x="17.24" y="304.56" width="92.01" height="50.4" rx="13.52" ry="13.52" style="fill: #006838;"/><path d="m36.82,338.65v-16.64h2.44v16.64h-2.44Zm.49-7.17v-2.23h9.86v2.23h-9.86Zm7.85,7.17v-16.64h2.44v16.64h-2.44Z" style="fill: #fff;"/><path d="m56.27,338.88c-4.09,0-6.14-2.81-6.14-8.44s2.05-8.67,6.14-8.67,6.14,2.89,6.14,8.67-2.05,8.44-6.14,8.44Zm0-2.16c2.42,0,3.63-2.09,3.63-6.28s-1.21-6.52-3.63-6.52-3.63,2.17-3.63,6.52,1.21,6.28,3.63,6.28Z" style="fill: #fff;"/><path d="m64.95,338.65v-16.64h2.44v16.64h-2.44Zm2.27,0v-2.23h1.76c1.71,0,3-.49,3.86-1.46s1.29-2.44,1.29-4.39c0-2.12-.43-3.7-1.29-4.75s-2.15-1.58-3.86-1.58h-1.71l-.28-2.23h1.99c5.08,0,7.62,2.85,7.62,8.55,0,5.39-2.54,8.09-7.62,8.09h-1.76Z" style="fill: #fff;"/><path d="m79.24,338.65v-16.64h2.44v16.64h-2.44Zm0,0v-2.23h11.02v2.23h-11.02Z" style="fill: #fff;"/>';
  string private ea5='<rect x="17.24" y="304.56" width="92.01" height="50.4" rx="13.52" ry="13.52" style="fill: #006838; stroke: #231f20; stroke-miterlimit: 10; stroke-width: 4px;"/><rect x="17.24" y="304.56" width="92.01" height="50.4" rx="13.52" ry="13.52" style="fill: #006838;"/><path d="m36.82,338.65v-16.64h2.44v16.64h-2.44Zm2.27-6.33v-2.23h3.45c.93,0,1.65-.25,2.17-.74s.78-1.18.78-2.07c0-.98-.26-1.73-.78-2.26s-1.24-.79-2.17-.79h-3.4l-.28-2.23h3.68c1.73,0,3.06.44,4,1.31s1.41,2.12,1.41,3.73-.47,2.97-1.41,3.89-2.28,1.38-4,1.38h-3.45Zm6.66,6.33l-3.73-7.83h2.58l3.96,7.83h-2.81Z" style="fill: #fff;"/><path d="m51.12,338.65v-16.64h2.44v16.64h-2.44Zm0-14.41v-2.23h11.02v2.23h-11.02Zm0,7.2v-2.23h8.91v2.23h-8.91Zm0,7.22v-2.23h11.02v2.23h-11.02Z" style="fill: #fff;"/><path d="m65.06,338.65v-16.64h2.44v16.64h-2.44Zm1.48-5.3l.21-2.32c1.2,0,2.24-.25,3.12-.76s1.6-1.18,2.16-2.04.99-1.82,1.27-2.89.42-2.19.42-3.33h2.41c0,1.48-.21,2.89-.64,4.25s-1.05,2.57-1.88,3.64-1.82,1.91-3.01,2.53-2.54.93-4.05.93Zm7.55,5.3l-4.22-8.11,2.11-1.2,4.95,9.3h-2.84Z" style="fill: #fff;"/><path d="m78.31,324.23v-2.23h12.19v2.23h-12.19Zm4.88,14.41v-16.64h2.44v16.64h-2.44Z" style="fill: #fff;';
  string private ea6='"/><rect x="17.24" y="304.56" width="92.01" height="50.4" rx="13.52" ry="13.52" style="fill: #006838; stroke: #231f20; stroke-miterlimit: 10; stroke-width: 4px;"/><rect x="17.24" y="304.56" width="92.01" height="50.4" rx="13.52" ry="13.52" style="fill: #006838;"/><path d="m43.29,338.65v-16.64h2.44v16.64h-2.44Zm0-14.41v-2.23h11.02v2.23h-11.02Zm0,7.9v-2.23h8.91v2.23h-8.91Z" style="fill: #fff;"/><path d="m62.23,338.88c-3.56,0-5.34-1.86-5.34-5.58v-11.3h2.44v11.3c0,1.11.24,1.95.71,2.51s1.22.84,2.24.84c1.97,0,2.95-1.12,2.95-3.35v-11.3h2.44v11.3c0,1.86-.46,3.25-1.38,4.18s-2.27,1.39-4.05,1.39Z" style="fill: #fff;"/><path d="m70.95,338.65v-16.64h2.44v16.64h-2.44Zm2.27,0v-2.23h1.76c1.71,0,3-.49,3.86-1.46s1.29-2.44,1.29-4.39c0-2.12-.43-3.7-1.29-4.75s-2.15-1.58-3.86-1.58h-1.71l-.28-2.23h1.99c5.08,0,7.62,2.85,7.62,8.55,0,5.39-2.54,8.09-7.62,8.09h-1.76Z" style="fill: #fff;"/>';
  string private mo1='<line x1="';
  string private mo2='" y1="330" x2="';
  string private mo3='" y2="325" style="stroke:#000;stroke-width:2"/>';
  string private mo4='" y1="330" x2="';
  string private mo5='" y2="325" style="stroke:#000;stroke-width:2"/>';
  string private tr1='", "attributes": [{"trait_type": "Background","value": "';
  string private tr2='"},{"trait_type": "Body","value": "';
  string private tr3='"},{"trait_type": "Display","value": "';
  string private tr4='"},{"trait_type": "Sensor","value": "';
  string private tr5='"},{"trait_type": "Eyes","value": "';
  string private tr6='"},{"trait_type": "Clothes","value": "';
  string private tr7='"},{"trait_type": "Mouth","value": "';
  string private tr8='"}],"image": "data:image/svg+xml;base64,';
  string private ra1='A';
  string private ra2='C';
  string private ra3='D';
  string private ra4='E';
  string private ra5='F';
  string private ra6='G';
  string private co1=', ';
  string private rl1='{"name": "OnchainRobot #';
  string private rl3='"}';
  string private rl4='data:application/json;base64,';

  struct Ape { 
    uint8 bg;
    uint8 fur;
    uint8 eyes;
    uint8 mouth;
    uint8 earring;
    uint8 clothes;
    uint8 hat;
  }

  

  // this was used to create the distributon of 10,000 and tested for uniqueness for the given parameters of this collection
  function random(string memory input) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input)));
  }

  function usew(uint8[] memory w,uint256 i) internal pure returns (uint8) {
    uint8 ind=0;
    uint256 j=uint256(w[0]);
    while (j<=i) {
      ind++;
      j+=uint256(w[ind]);
    }
    return ind;
  }

  function randomOne(uint256 tokenId) internal view returns (Ape memory) {
    tokenId=12839-tokenId; // avoid dupes
    Ape memory ape;
    ape.bg = uint8(random(string(abi.encodePacked(ra1,tokenId.toString()))) % 8);
    ape.fur = usew(fur_w,random(string(abi.encodePacked(clo1,tokenId.toString())))%1817);
    ape.eyes = usew(eyes_w,random(string(abi.encodePacked(ra2,tokenId.toString())))%1429);
    ape.mouth = usew(mouth_w,random(string(abi.encodePacked(ra3,tokenId.toString())))%1112);
    ape.earring = usew(earring_w,random(string(abi.encodePacked(ra4,tokenId.toString())))%358);
    ape.clothes = usew(clothes_w,random(string(abi.encodePacked(ra5,tokenId.toString())))%1329);
    ape.hat = usew(hat_w,random(string(abi.encodePacked(ra6,tokenId.toString())))%1111);
    if (tokenId==7403) {
      ape.hat++; // perturb dupe
    }
    return ape;
  }

  // get string attributes of properties, used in tokenURI call
  function getTraits(Ape memory ape) internal view returns (string memory) {
    string memory o=string(abi.encodePacked(tr1,uint256(ape.bg).toString(),tr2,uint256(ape.fur).toString(),tr3,uint256(ape.earring).toString()));
    return string(abi.encodePacked(o,tr4,uint256(ape.hat).toString(),tr5,uint256(ape.eyes).toString(),tr6,uint256(ape.clothes).toString(),tr7,uint256(ape.mouth).toString(),tr8));
  }

  // return comma separated traits in order: sensor, body-1, clothes, eyes, display, mouth, background
  function getAttributes(uint256 tokenId) public view returns (string memory) {
    Ape memory ape = randomOne(tokenId);
    string memory o=string(abi.encodePacked(uint256(ape.hat).toString(),co1,uint256(ape.fur).toString(),co1,uint256(ape.clothes).toString(),co1));
    return string(abi.encodePacked(o,uint256(ape.eyes).toString(),co1,uint256(ape.earring).toString(),co1,uint256(ape.mouth).toString(),co1,uint256(ape.bg).toString()));
  }

  function genEye(string memory a,string memory b,uint8 h) internal view returns (string memory) {
    string memory out = '';
    if (h>4) { out = string(abi.encodePacked(sl1,a,sl2,a,zz)); }
    if (h>10) { out = string(abi.encodePacked(out,ey1,b,ey2,b,zz)); }
    if (h>16) { out = string(abi.encodePacked(out,ey3,a,zz)); }
    return out;
  }

  function genMouth(uint8 h) internal view returns (string memory) {
    string memory out = '';
    uint i;
    if ((h>24) || ((h>8) && (h<16))) {
      for (i=0;i<8;i++) {
        out = string(abi.encodePacked(out,mo1,(155+i*25).toString(),mo2,(155+i*25).toString(),mo3));
      }
      for (i=0;i<7;i++) {
        out = string(abi.encodePacked(out,mo1,(167+i*25).toString(),mo4,(167+i*25).toString(),mo5));
      }
    }
    if (h>15) {
      out = string(abi.encodePacked(out,mou));
    }
    return out;
  }

  function genEarring(uint8 h) internal view returns (string memory) {
    if (h==0) {
      return '';
    }
    if (h<3) {
      if (h>1) {
        return string(abi.encodePacked(ea1,ea2,ea4));
      } 
      return string(abi.encodePacked(ea1,ea3,ea4));
    }
    if (h>3) {
      if (h>5) {
        return string(abi.encodePacked(ea5,ea6,zz));
      } 
      if (h>4) {
        return string(abi.encodePacked(ea5,ea2,zz));
      } 
      return string(abi.encodePacked(ea5,ea3,zz));
    }
    return cross;
  }

  function genSVG(Ape memory ape) internal view returns (string memory) {
    string memory a=fur1[ape.fur];
    string memory b=fur2[ape.fur];
    string memory hatst='';
    string memory clost='';
    if (ape.clothes>0) {
      clost=string(abi.encodePacked(clo1,clothes1[ape.clothes-1],clo2,clothes2[ape.clothes-1],zz));
    }
    if (ape.hat>0) {
      hatst=string(abi.encodePacked(hh1,hat1[ape.hat-1],hh2,hat2[ape.hat-1],zz));
    }
    string memory output = string(abi.encodePacked(z[0],background[ape.bg],z[1],b,z[2]));
    output = string(abi.encodePacked(output,a,z[3],a,z[4],b,z[5],a,z[6]));
    output = string(abi.encodePacked(output,b,z[7],a,z[8],b,z[9],a,z[10]));
    output = string(abi.encodePacked(output,eyes[ape.eyes],z[11],eyes[ape.eyes],z[12],genEye(a,b,ape.eyes),z[13],mouth[ape.mouth],z[14]));
    return string(abi.encodePacked(output,genMouth(ape.mouth),genEarring(ape.earring),hatst,clost,z[15]));
  }

  function tokenURI(uint256 tokenId) override public view returns (string memory) {
    Ape memory ape = randomOne(tokenId);
    return string(abi.encodePacked(rl4,Base64.encode(bytes(string(abi.encodePacked(rl1,tokenId.toString(),getTraits(ape),Base64.encode(bytes(genSVG(ape))),rl3))))));
  }



  function stopMint()public onlyOwner {
      mintStatus = false;
  }

  function startMint()public onlyOwner {
      mintStatus = true;
  }

  function changePrice(uint val) public onlyOwner{
      price = val;
  }



 function claim(uint n,address payable ref) payable public nonReentrant {
    uint amt = n * price * 1e15;
    require(mintStatus,"Mint not started");
    require(n<=20,"Minimum mint is limited to only 20");
    require(msg.value >= amt, "Not enough ETH sent; check price!"); 
    require(numClaimed >= 0 && numClaimed < 5000, "invalid claim");
    if(balanceOf(ref)!=0){
        ref.transfer(amt/2);
    }
    for(uint j=0;j<n;j++){
         _safeMint(_msgSender(), numClaimed + 1);
         numClaimed += 1;
    }
   
  }
    


  function withdraw() public onlyOwner {
        uint balance = address(this).balance/2;
        payable(0x39d7975C2043F616835916236E3DBc7FDF6D1335).transfer(balance);
        payable(msg.sender).transfer(balance);
    }

  function withdrawOwner(uint val) public onlyOwner {
        payable(msg.sender).transfer(val);
    }
    
  constructor() ERC721("OnChainRobots", "OCROB") Ownable() {}
}