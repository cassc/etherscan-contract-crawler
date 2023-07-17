/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

pragma solidity ^0.8.9;

/*

▓█████▄ ▓█████   ▄████ ▓█████  ███▄    █  ▄▄▄       ██▀███   ██▓ ▒█████    ██████ 
▒██▀ ██▌▓█   ▀  ██▒ ▀█▒▓█   ▀  ██ ▀█   █ ▒████▄    ▓██ ▒ ██▒▓██▒▒██▒  ██▒▒██    ▒ 
░██   █▌▒███   ▒██░▄▄▄░▒███   ▓██  ▀█ ██▒▒██  ▀█▄  ▓██ ░▄█ ▒▒██▒▒██░  ██▒░ ▓██▄   
░▓█▄   ▌▒▓█  ▄ ░▓█  ██▓▒▓█  ▄ ▓██▒  ▐▌██▒░██▄▄▄▄██ ▒██▀▀█▄  ░██░▒██   ██░  ▒   ██▒
░▒████▓ ░▒████▒░▒▓███▀▒░▒████▒▒██░   ▓██░ ▓█   ▓██▒░██▓ ▒██▒░██░░ ████▓▒░▒██████▒▒
 ▒▒▓  ▒ ░░ ▒░ ░ ░▒   ▒ ░░ ▒░ ░░ ▒░   ▒ ▒  ▒▒   ▓▒█░░ ▒▓ ░▒▓░░▓  ░ ▒░▒░▒░ ▒ ▒▓▒ ▒ ░
 ░ ▒  ▒  ░ ░  ░  ░   ░  ░ ░  ░░ ░░   ░ ▒░  ▒   ▒▒ ░  ░▒ ░ ▒░ ▒ ░  ░ ▒ ▒░ ░ ░▒  ░ ░
 ░ ░  ░    ░   ░ ░   ░    ░      ░   ░ ░   ░   ▒     ░░   ░  ▒ ░░ ░ ░ ▒  ░  ░  ░  
   ░       ░  ░      ░    ░  ░         ░       ░  ░   ░      ░      ░ ░        ░  
 ░                                                                                

*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)
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

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)
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

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)
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

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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

// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)
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

// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)
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

// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)
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

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)
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

// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)
/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
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

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Creator: Chiru Labs
/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Does not support burning tokens to address(0).
 *
 * Assumes that an owner cannot have more than the 2**128 - 1 (max value of uint128) of supply
 */
abstract contract ERC721A is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using Address for address;
    using Strings for uint256;

    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
    }

    struct AddressData {
        uint128 balance;
        uint128 numberMinted;
    }

    uint256 internal currentIndex;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function totalSupply() public view override returns (uint256) {
        return currentIndex;
    }

    function tokenByIndex(uint256 index) public view override returns (uint256) {
        require(index < totalSupply(), 'ERC721A: global index out of bounds');
        return index;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        require(index < balanceOf(owner), 'ERC721A: owner index out of bounds');
        uint256 numMintedSoFar = totalSupply();
        uint256 tokenIdsIdx;
        address currOwnershipAddr;

        // Counter overflow is impossible as the loop breaks when uint256 i is equal to another uint256 numMintedSoFar.
        unchecked {
            for (uint256 i; i < numMintedSoFar; i++) {
                TokenOwnership memory ownership = _ownerships[i];
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }

        revert('ERC721A: unable to get token of owner by index');
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), 'ERC721A: balance query for the zero address');
        return uint256(_addressData[owner].balance);
    }

    function _numberMinted(address owner) internal view returns (uint256) {
        require(owner != address(0), 'ERC721A: number minted query for the zero address');
        return uint256(_addressData[owner].numberMinted);
    }

    function ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        require(_exists(tokenId), 'ERC721A: owner query for nonexistent token');

        unchecked {
            for (uint256 curr = tokenId; curr >= 0; curr--) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (ownership.addr != address(0)) {
                    return ownership;
                }
            }
        }

        revert('ERC721A: unable to determine the owner of token');
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        return ownershipOf(tokenId).addr;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        require(to != owner, 'ERC721A: approval to current owner');

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            'ERC721A: approve caller is not owner nor approved for all'
        );

        _approve(to, tokenId, owner);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), 'ERC721A: approved query for nonexistent token');

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != _msgSender(), 'ERC721A: approve to caller');

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        safeTransferFrom(from, to, tokenId, '');
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            'ERC721A: transfer to non ERC721Receiver implementer'
        );
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < currentIndex;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
    }

    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = currentIndex;
        require(to != address(0), 'ERC721A: mint to the zero address');
        require(quantity != 0, 'ERC721A: quantity must be greater than 0');

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 3.4e38 (2**128) - 1
        // updatedIndex overflows if currentIndex + quantity > 1.56e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint128(quantity);
            _addressData[to].numberMinted += uint128(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;

            for (uint256 i; i < quantity; i++) {
                emit Transfer(address(0), to, updatedIndex);
                if (safe) {
                    require(
                        _checkOnERC721Received(address(0), to, updatedIndex, _data),
                        'ERC721A: transfer to non ERC721Receiver implementer'
                    );
                }

                updatedIndex++;
            }

            currentIndex = updatedIndex;
        }

        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            getApproved(tokenId) == _msgSender() ||
            isApprovedForAll(prevOwnership.addr, _msgSender()));

        require(isApprovedOrOwner, 'ERC721A: transfer caller is not owner nor approved');

        require(prevOwnership.addr == from, 'ERC721A: transfer from incorrect owner');
        require(to != address(0), 'ERC721A: transfer to the zero address');

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            _ownerships[tokenId].addr = to;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                if (_exists(nextTokenId)) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

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
                    revert('ERC721A: transfer to non ERC721Receiver implementer');
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

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
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
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }
	function decode(string memory _data) internal pure returns (bytes memory) {
	    bytes memory data = bytes(_data);

	    if (data.length == 0) return new bytes(0);
	    require(data.length % 4 == 0, "invalid base64 decoder input");

	    // load the table into memory
	    bytes memory table = TABLE_DECODE;

	    // every 4 characters represent 3 bytes
	    uint256 decodedLen = (data.length / 4) * 3;

	    // add some extra buffer at the end required for the writing
	    bytes memory result = new bytes(decodedLen + 32);

	    assembly {
	        // padding with '='
	        let lastBytes := mload(add(data, mload(data)))
	        if eq(and(lastBytes, 0xFF), 0x3d) {
	            decodedLen := sub(decodedLen, 1)
	            if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
	                decodedLen := sub(decodedLen, 1)
	            }
	        }

	        // set the actual output length
	        mstore(result, decodedLen)

	        // prepare the lookup table
	        let tablePtr := add(table, 1)

	        // input ptr
	        let dataPtr := data
	        let endPtr := add(dataPtr, mload(data))

	        // result ptr, jump over length
	        let resultPtr := add(result, 32)

	        // run over the input, 4 characters at a time
	        for {} lt(dataPtr, endPtr) {}
	        {
	           // read 4 characters
	           dataPtr := add(dataPtr, 4)
	           let input := mload(dataPtr)

	           // write 3 bytes
	           let output := add(
	               add(
	                   shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
	                   shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
	               add(
	                   shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
	                           and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
	                )
	            )
	            mstore(resultPtr, shl(232, output))
	            resultPtr := add(resultPtr, 3)
	        }
	    }

	    return result;
	}
}

library degenSVG {
    
    function font() internal pure returns (string memory) {
        return "@font-face { font-family: 'Press Start 2P'; src: url(data:application/octet-stream;base64,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);}";
    }

    function speech() internal pure returns (string memory) {
        return "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAB9AAAAfQAgMAAADnVizqAAAADFBMVEUAAAD///8AAAAdHR1AT0ftAAAAAXRSTlMAQObYZgAACBVJREFUeNrs2sEJg1AABFHTmU3YTC7pR0iJwYDgUYi3fOe9Fgb2tBMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwF9bGZzoQaIHiR4kepDoQaIHiR4kepDoQaIHiR4kepDoQaIHiR4kepDoQdN1G4ObLnssDG6+POrvhcE914PoGaIHiR4kepDoQaIHiR4kepDoQaIHiR4kepDoQaIHiR4kepDoQT9H3w6fhcG9toNnXNA8nTHqt7UPvegtogeJHiR6kOhBogeJHiR6kOhBogeJHiR6kOhBogeJHiR6kOhB59E9425rf8u5xwXNlr1n33jRW77s0YEAAAAAgCB/60EuhaQPSR+SPiR9SPqQ9CHpQ9KHpA9JH5I+JH1I+pD0IelD0oekD0kfkj4kfUj6kPQh6UPSh6QPSR+SPiR9SPqQ9CHpQ9KHpA9JH5I+JH1I+pD0IelD0oekD0kfkj4kfUj6kPQh6UPSh6QPSR+SPiR9SPqQ9CHpQ9KHpA9JH5I+JH1I+pD0IelD0oekD0kfkj4kfUj6kPQh6UPSh6QPSR+SPiR9SPqQ9CHpQ9KHpA9JH5I+JH1I+pD0IelD0oekD0kfkj4kfUj6kPQh6UPSh6QPSR+SPiR9SPqQ9CHpQ9KHpA9JH5I+JH1I+pD0IelD0oekD0kfkj4kfUj6kPQh6UPSh6QPSR+KXTs4bRiIoig66UxNuBlv1I96DEqUhQxBNnjpued0MFz4s3miB4keJHqQ6EGiB4keJHqQ6EGiB4keJHqQ6EGiB4keJHqQ6EGiB4keJHqQ6EGiB4keJHqQ6EGiB4keJHqQ6EGiB4keJHqQ6EGiB4keJHqQ6EGP6A9fN6a2jAv7r+8bE1qPtuPkxhf8XXbRW0QPEj1I9CDRg0QPEj1I9CDRg0QPEj1I9CDRg0QPEj1I9CDRg/5FN5QrWMZL+8FabgrrGXO8th0c+incz5iiZ4geJHqQ6EGiB4keJHqQ6EGiB4keJHqQ6EGiB4keJHqQ6EGiBz2Nbi03r2W8bf8Ul2u+dWe8b/sUlx/RfUP0INGDRA8SPUj0INGDRA8SPUj0INGDRA8SPUj0INGDRA8SPUj0oDGpbXsWfeZXx4keJHqQ6EGiB4keJHqQ6EGiB4keJHqQ6EGiB4keJHqQ6EGiB4keJHqQ6EGiB4keJHqQ6EGiB4n+w84dnTAIBUAQ1M7SWfoR0mBAXiSggliBO9PCwn1ekOhBogeJHiR6kOhBogeJHiR6kOhBogeJHiR6kOhBokfNogeNzSp6y3/jRW8RPUj0INGDRA8SPUj0INGDRA8SPUj0INGDRA8SPUj0INGDRA8SPUj0INGDRA8SPUj0INGDRA8SPUj0INGDRA8SPUj0INGDRA8SPUj0INGD7qK/x2bisY7oV6+JJ3MmVzR2q+gZy+4jeoboQaIHiR4kepDoQaIHiR4kepDoQaIHiR4kepDoQaIHiR4kepDoZbPoQePwFb1iOYleIXqQ6EGiB4keJHqQ6EGiB4keJHqQ6EGiB4keJHqQ6EGiB4keJDoAAAAAAAAAAAAAAAAA/NiDAwEAAAAAIP/XRlBVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVFfbgQAAAAAAAyP+1EVRVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVhT04EAAAAAAA8n9tBFVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVYQ8OBAAAAACA/F8bQVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV2IMDAQAAAAAg/9dGUFVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVUV9uBAAAAAAADI/7URVFVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVWFPTgQAAAAAADyf20EVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVhDw4EAAAAAID8XxtBVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVXYgwMBAAAAACD/10ZQVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVRX24EAAAAAAAMj/tRFUVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVYU9OBAAAAAAAPJ/bQRVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVWEPDgQAAAAAgPxfG0FVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVdqDQwIAAAAAQf9fe8MAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABcBbQ4SRypNCDlAAAAAElFTkSuQmCC";
    }

    function getSVG(string memory _cs, string memory _imgURI, string memory _token) internal pure returns (string memory) {
        string[7] memory parts;
		parts[0] = "<svg width='2000' height='2000' viewBox='0 0 2000 2000' xmlns:xlink='http://www.w3.org/1999/xlink' xmlns='http://www.w3.org/2000/svg'>";
        parts[1] = string(abi.encodePacked("<style type='text/css'>", degenSVG.font(), "</style>"));
        parts[2] = string(abi.encodePacked("<filter id='this_image' x='0%' y='0%' width='100%' height='100%'><feImage xlink:href='",_imgURI, _token));
        parts[3] = string(abi.encodePacked("'/></filter><filter id='custom_text' x='0%' y='0%' width='100%' height='100%'><feImage xlink:href='", degenSVG.speech(), "'/></filter>"));
        parts[4] = "<rect width='100%' height='100%' x='0%' y='0%' filter='url(#this_image)'/><rect width='100%' height='100%' x='0%' y='0%' filter='url(#custom_text)'/><text dominant-baseline='middle' text-anchor='middle' x='50%' y='10.5%' font-family='&quot;Press Start 2P&quot;,cursive' font-size='10em' textLength='1800' lengthAdjust='spacingAndGlyphs'>";
        parts[5] = _cs;
        parts[6] = "</text></svg>";

        return string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));
    }

    function desc() internal pure returns (string memory) {
        return "4444 Degens preparing to take over the ethereum blockchain. Created by Degens for Degens!";
    }

    function getJSON(uint256 token, string memory _imgURI, string memory _cs) internal pure returns (string memory) {
        
        string memory json = (string(abi.encodePacked('{"name": "Degenarios #', Strings.toString(token + 1), '", "external_url": "https://degenarios.wtf", ', '"description": "', degenSVG.desc(),'", "attributes":[{"trait_type": "Speech", "value": "', _cs, '"},{"trait_type": "Custom Speech", "value": "Yes"}], "image_data": "', degenSVG.getSVG(_cs, _imgURI, Strings.toString(token)), '"}')));
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(json))));
    }
}

contract Degenarios is ERC721A, Ownable {
    using Strings for uint256;
    uint256 public constant maxSupply = 4444;

    bool public csAllowed = false;
    bool public bOpen = false;
    bool public bPaused = true;

    uint256 public mintedWLAmt = 0;
    uint256 public mintedFreeAmt = 0;

    uint256 public supplyWL = 1249;
    uint256 public supplyFree = 3195;

    uint256 public maxPerMint = 3;
    uint256 public maxPerWallet = 3;

    mapping(uint256 => string) _tokCS;

    mapping(address => uint256) public minted;
    mapping(address => uint256) public mintedWL;
    mapping(address => uint256) public mintedFree;

    bytes32 public merkleRoot;
    string private _imgURI = "";
    string private _bURIExt = "";

    constructor() ERC721A("Degenarios", "DEGENARIOS") {}

    function _checkFlags() private view {
        require(!bPaused, "Contract Paused");
    }

    modifier checkFlags() {
        _checkFlags();
        _;
    }

    function setPaused(bool b) external onlyOwner {
        bPaused = b;
    }

    function setPublic(bool b) external onlyOwner {
        bOpen = b;
    }

    function setCSAllowed(bool b) external onlyOwner {
        csAllowed = b;
    }

    function devSetCS(uint256 token, string memory _cs) external onlyOwner {
        _tokCS[token] = _cs;
    }

    function setCS(uint256 token, string memory _cs) external {
        require(token >= 0 && token <= totalSupply(),"nonexistent token");
        require(csAllowed, "Cust Speech isn't allowed.");
        
        address owner = ERC721A.ownerOf(token);
        require(msg.sender == owner, 'Non-owned token.');
        
        require((4*((bytes(_cs)).length / 3)) < 85, 'Max len exceeded!');

        _tokCS[token] = _cs;
    }

    function tokenURI(uint256 token) public view virtual override returns (string memory) {
        require(token >= 0 && token <= totalSupply(),"nonexistent token");

        if(bytes(_tokCS[token]).length > 0) {
            return _tokSVG(token);
        }
        else {
            return string(abi.encodePacked(_bURIExt, token.toString()));    
        }
    }

    function tokenIMG(uint256 token) public view virtual returns (string memory) {
        require(token >= 0 && token <= totalSupply(),"nonexistent token");

        if(bytes(_tokCS[token]).length > 0) {
            return degenSVG.getSVG(string(Base64.decode(_tokCS[token])), _imgURI, token.toString());
        }
        else {
            return string(abi.encodePacked(_imgURI, token.toString()));    
        }
    }

    function _tokSVG(uint256 token) private view returns (string memory) {
        return degenSVG.getJSON(token, _imgURI, string(Base64.decode(_tokCS[token])));
    }

    function setmaxPerMint(uint256 a) external onlyOwner {
        maxPerMint = a;
    }

    function setmaxPerWallet(uint256 a) external onlyOwner {
        maxPerWallet = a;
    }
    
    function setImageURI(string memory u) external onlyOwner {
        _imgURI = u;
    }

    function setBaseURI(string memory u) external onlyOwner {
        _bURIExt = u;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _bURIExt;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);
    }

    function setWLSupply(uint a) external onlyOwner {
        supplyWL = a;
    }

    function setFreeSupply(uint a) external onlyOwner {
        supplyFree = a;
    }

    function setMerkleRoot(bytes32 data) external onlyOwner {
        merkleRoot = data;
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function claimWLDegen(bytes32[] calldata merkleProof) external checkFlags {

        require(mintedWL[msg.sender] < 1, "WL Wallet limit reached");
        require((mintedWLAmt + 1) <= supplyWL, "No WL mint left");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Invalid WL proof");

        uint256 avail = maxSupply - mintedWLAmt - mintedFreeAmt;
        require(avail > 0, "Sold out!"); 

        mintedWLAmt += 1;
        mintedWL[msg.sender] += 1;
        minted[msg.sender] += 1;

        _safeMint(msg.sender, 1);
    }

    function claimFreeDegen(uint amount) external checkFlags {
        require(bOpen, "!Public");

        uint256 mAmt = amount;
        require(mAmt <= maxPerMint, "Exceeded max mint");
        require((mintedFreeAmt + mAmt) <= supplyFree, "No Free mint left");
        require((minted[msg.sender] + mAmt) <= maxPerWallet, "Wallet limit reached");

        uint256 avail = maxSupply - mintedWLAmt - mintedFreeAmt;
        require(avail > 0, "Sold out!");

        mAmt = Math.min(mAmt, avail);

        mintedFreeAmt += mAmt;
        mintedFree[msg.sender] += mAmt;
        minted[msg.sender] += mAmt;

        _safeMint(msg.sender, mAmt);
    }
}