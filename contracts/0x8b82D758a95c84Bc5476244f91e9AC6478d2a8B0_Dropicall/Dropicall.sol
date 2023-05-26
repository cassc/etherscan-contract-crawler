/**
 *Submitted for verification at Etherscan.io on 2022-04-23
*/

// SPDX-License-Identifier: MIT
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




//Copyleft (ɔ) All Rights Reversed




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

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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



// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)




// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)




// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)





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
        _setApprovalForAll(_msgSender(), operator, approved);
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

        _afterTokenTransfer(address(0), to, tokenId);
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

        _afterTokenTransfer(owner, address(0), tokenId);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
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
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
                return retval == IERC721Receiver.onERC721Received.selector;
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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



struct Shareholder {
	address addr;
	uint256 percent;
}
contract Dropicall is ERC721Enumerable, Ownable {

	mapping(address => uint256) private share_pool;
	address[] private share_addr; // [i]

	// [addr][id] (usually i,j)
	// Contains "unrolled" share amounts to distribute.
	uint256[][] private share_price_matrix;
	// [j]
	// Pairs of [price,count]
	uint256[2][] private prices_n;

	uint256 public immutable item_count;

	bool private sale_data_ok = false;

	uint256 private immutable max_supply;
	function get_mint_price(uint j) public view returns(uint256) {
		require(j < prices_n.length);
		return prices_n[j][0] * prices_n[j][1];
	}
	function get_mint_count(uint j) public view returns(uint256) {
		require(j < prices_n.length);
		return prices_n[j][1];
	}
	function pay_and_mint(uint j) private {
		require( j < prices_n.length, "Invalid mint option." );
		require(msg.value == get_mint_price(j), "Incorrect value paid.");
		require(totalSupply() + prices_n[j][1] <= max_supply, "Not enough left.");
		distribute_share(j);
		uint ts = totalSupply() + 1;
		for (uint i = 0; i < prices_n[j][1]; i++) {
			_safeMint(msg.sender, ts + i);
		}
	}
	function distribute_share(uint256 j) private {
		for ( uint i = 0; i < share_addr.length; i++ ) {
			share_pool[share_addr[i]] += share_price_matrix[i][j];
		}
	}
	function init_sale_data(Shareholder[] memory shareholders, uint256[2][] memory amounts_prices ) private {
		require(!sale_data_ok, "Already initialized");
		require(shareholders.length > 0, "Must provide at least one shareholder.");
		require(amounts_prices.length > 0, "Must provide prices.");
		prices_n = amounts_prices;
		uint256 p = 0;
		for ( uint256 i = 0; i < shareholders.length; i++ ) {
			require( shareholders[i].percent > 0 && shareholders[i].percent <= 100, "Percentage out of range." );
			p += shareholders[i].percent;
			share_addr.push(shareholders[i].addr);
			share_price_matrix.push();
			for ( uint256 j = 0; j < amounts_prices.length; j++ ) {
				require( amounts_prices[j][0] % 100 == 0, "Prices must each be a multiple of 100 Wei." );
				uint256 v = (amounts_prices[j][0] / 100) * shareholders[i].percent;
				share_price_matrix[i].push(v * amounts_prices[j][1]);
			}
		}
		require( p == 100, "Combined shares do not add up to 100 percent." );
		sale_data_ok = true;
		/* Deactivate for less constructor gas * /
		for ( uint256 j = 0; j < amounts_prices.length; j++ ) {
			uint256 c = 0;
			for ( uint256 i = 0; i < shareholders.length; i++ ) {
				c += share_price_matrix[i][j];
			}
			assert( c == amounts_prices[j][0] * amounts_prices[j][1] ); // Unrolled prices do not add up to the original.
		}
		/ * */
	}
	function withdraw_share() public {
		require(share_pool[msg.sender] > 0, "No shares for this address to withdraw." );
		address payable dest = payable(msg.sender);
		uint256 bounty = share_pool[msg.sender];
		share_pool[msg.sender] = 0;
		dest.transfer(bounty);
	}

	///////////////

	string private __baseURI;
	function _baseURI() internal view virtual override returns (string memory) {
		return __baseURI;
	}
	function _setBaseURI(string memory baseURI_) internal virtual {
		__baseURI = baseURI_;
	}
	function setBaseURI(string memory baseURI) public onlyOwner {
		_setBaseURI(baseURI);
	}

	string private __contractURI;
	function _contractURI() internal view virtual returns (string memory) {
		return __contractURI;
	}
	function _setContractURI(string memory contractURI_) internal virtual {
		__contractURI = contractURI_;
	}
	function setContractURI(string memory contractURI) public onlyOwner {
		_setContractURI(contractURI);
	}
	///////////////

	bool premint_started;
	bool mint_started;

	mapping(address => bool) public whitelist;

	function mint_main(uint256 option_id) public payable {
		require( mint_started || ( premint_started && whitelist[msg.sender] ), "You may not mint at this time." );
		pay_and_mint( option_id );
	}

	function start_premint() public onlyOwner {
		premint_started = true;
	}
	function start_mint() public onlyOwner {
		require( premint_started, "Starting mint without premint first, did you press the wrong button?" );
		mint_started = true;
	}

	constructor() ERC721(
		"Dropicall",
		"DRCA"
	) {
		Shareholder[] memory sh = new Shareholder[](2);
		sh[0] = Shareholder( { addr: 0xB520F068a908A1782a543aAcC3847ADB77A04778, percent: 10 } ); // remco
		sh[1] = Shareholder( { addr: 0x4dDAc376f28BE60e1F7642A4D302C6Cf6CAe1D92, percent: 90 } ); // mezza

		// Why? So that you can query this (it's public)
		item_count = 3;
		uint256[2][] memory price_table = new uint256[2][](item_count);		
		price_table[0] = [ uint256(8e7 gwei), 1 ];
		price_table[1] = [ uint256(7e7 gwei), 5 ];
		price_table[2] = [ uint256(6e7 gwei), 10 ];

		max_supply = 3333;

		init_sale_data( sh, price_table );

		// _setContractURI( "this is a very long string about mice. squeak are mice making a home in your code??" );
		// _setBaseURI( "this is a very long string about mice. actually this is for more conservative gas estimates.." );

		whitelist[0x2cc2149D905fe27841055CC31700641e0E6C944D] = true;
		whitelist[0x9508d995ca98DAc918D0a4F18Acd67BC545C8b92] = true;
		whitelist[0x1077011F38c120973238eF266Dd45edad4a78E99] = true;
		whitelist[0x32E094eeD5995331a45F2eb8727Da81156845Ff0] = true;
		whitelist[0x88923378021BeA85f9b09Ce571a309E12C7D2262] = true;
		whitelist[0x87CBd58ba04C8a0D26A0242d5Ac06f30269a96c5] = true;
		whitelist[0xf5D4E11f6392a138cDaD459367C45Fe8B90dB704] = true;
		whitelist[0xF9f5a72142bd0bdb9A6053191104c010d912c1BD] = true;
		whitelist[0x2ec970270130EdbA7D9B1f0f7cE7DFb3d1f6Cf6a] = true;
		whitelist[0x32918DBB0Dad6C0E92eBc72F024A61FB8507277E] = true;
		whitelist[0x8694EC6954a576D42e5a95488ae2C175A959f04c] = true;
		whitelist[0x98c1d8A5cd2e6FA559ba6ae0680B388b799AC231] = true;
		whitelist[0xFB52e265F03e1783e222f30106418a4a1487D0e7] = true;
		whitelist[0x1F38EbCFfb0Be993b981225a917aAA8a6d6A4E52] = true;
		whitelist[0xA7b2A23fF93f04D9D04a645Fc90450845106f19c] = true;
		whitelist[0x104B2edadfe9F12E99C422E6823D1eEa40343564] = true;
		whitelist[0xF7C53Fd0599632cAa643C8bC7b195ffE041F9134] = true;
		whitelist[0x32Cc2EC897F21a77A704e9a7313af6a640c47BB5] = true;
		whitelist[0xdDe74f034163192dd2170BB56B9CAc2d45Ce0a36] = true;
		whitelist[0xDC89B615F0e36261c02b0B7d92bBcBD31C3C6269] = true;
		whitelist[0x984b18B1823Fef04A4Ca7cF1e8A0eF5359fA522F] = true;
		whitelist[0xd42d08ca1A876ac9BD2bFe631eE7D997cAE39229] = true;
		whitelist[0x56C82d09b490F63531656E25838536C97e10610f] = true;
		whitelist[0x0503bF05c49F96faaC2B0f5fD394672eD4603C52] = true;
		whitelist[0x768058a4b0054dc1cb025889B2eFD9C2051d2Bf6] = true;
		whitelist[0x76fC54b4eC08917fc4a7FC6a72d0BaAff9861ad7] = true;
		whitelist[0xF43E468e6E39F490E7198cDe92c6995e843ef4c5] = true;
		whitelist[0xD31D14f6B5AeFDaB5fE16DeA29fA46F6B8c15bF2] = true;
		whitelist[0xB1Bb9A663765255542221B8C2106660c84E0B7ce] = true;
		whitelist[0xF7C53Fd0599632cAa643C8bC7b195ffE041F9134] = true;
		whitelist[0x8694EC6954a576D42e5a95488ae2C175A959f04c] = true;
		whitelist[0x8d586f380846dCA988cB3B345231AF02F989C411] = true;
		whitelist[0xe4A24b53C97A25A21fe0Ee6a1a1F652A5dAFe88f] = true;
		whitelist[0x0EDb2533655876b1656243fd6ee9B16401281df8] = true;
		whitelist[0xe958a38D6819bBa0501020e37e1F7C0e54584FAA] = true;
		whitelist[0x008BA4907924f86C62fBb31Fe4A0dFE91c0e6acc] = true;
		whitelist[0xe81FC42336c9314A9Be1EDB3F50eA9e275C93df3] = true;
		whitelist[0xB7E64cb5B81cc275024B056DBDb8eB4afd84b4EA] = true;
		whitelist[0x2A1Ca52f11A7F0aA923A6739d49c69004C7246e1] = true;
		whitelist[0x1AC76Ec4c02c5488E8DcB892272e9E284d5Fe295] = true;
		whitelist[0xE0E7745713Cca16eE73e231428921B424f419b10] = true;
		whitelist[0x001Bf5f51453E74aa44dE9eE47F9deB6E896Ca29] = true;
		whitelist[0x2227de445Dbfd90712C48bCD74D492CccA1Cb242] = true;
		whitelist[0x767A60F295AEDd958932088F9Cd6a4951D8739b6] = true;
		whitelist[0x10455d2469b5235F95C2512026307bD77b1511d2] = true;
		whitelist[0x00000000000Cd56832cE5dfBcBFf02e7eC639BC9] = true;
		whitelist[0xcb9F176f3C90837a727E4678e29515cB2D557F18] = true;
		whitelist[0x5ea7e5e100aE141d1f0Fa98852e335CBa9A9f374] = true;
		whitelist[0xb6E34A8A93031a24C264Be59D0BaC00bcaeF9051] = true;
		whitelist[0x8149DC18D39FDBa137E43C871e7801E7CF566D41] = true;
		whitelist[0xda1D4Bd894709DbD9a140c05bdaedd19afE7fb00] = true;
		whitelist[0x4EfeceA2A42E1E73737e4dda7234e999A84Ca60B] = true;
		whitelist[0x49AAD19d4f36EB41dDF3d54151D5ba0c0531A888] = true;
		whitelist[0xdAE4012B41657B7118324Fe13aF91eEc0EC95acD] = true;
		whitelist[0xAf981AFA2f5fd50ffEDBB5728FA0fFd2a99b93CE] = true;
		whitelist[0x25a61B9CB2D749b062fA87b792ca60faEdDdF851] = true;
		whitelist[0x10172b1A8fD270C2F4F45561617747ad2a35B31E] = true;
		whitelist[0x885dA0E56F2B1aEd633f9A3847D3b057832a5463] = true;
		whitelist[0x9294bb652f4B1392Ff8c266Cc75BA45ba312c124] = true;
		whitelist[0xCbE7396ea129242438C565Ec5dCB8A37f187E639] = true;
		whitelist[0x5C45b39E13c4129dF392072045747DDbcedA1eB9] = true;
		whitelist[0x84a6C06CCEfE63C5C8df52dFff3101a480aD3760] = true;
		whitelist[0x2bFaC2D8D79D13D45862EA64ce0f25C5D34e9cA8] = true;
		whitelist[0xC41CfcEc2b5f65A2c6bF70869cbC116Aa0ec0Ada] = true;
		whitelist[0x2378598aEf5768d12df9ab72dee9AF37a2741F5A] = true;
		whitelist[0x8205F2AB276C78d06a8F9bE9b1C97A776C7dD805] = true;
		whitelist[0xe5A7a206E9a8769f90ca792EbB68E9268231F717] = true;
		whitelist[0x1258436bc2Ce96f60e0032b07DA166Ac588f1a00] = true;
		whitelist[0x4218bA2E10E56aAC410205A7576d8FBc3DD54420] = true;
		whitelist[0xc2086C494819b15EF371585e45682C50CbC20aF5] = true;
		whitelist[0xce0E1766269e63a87FB1C1e5C745B1db32b5713d] = true;
		whitelist[0xDc610C4766450E3184AfC312ef2224702299219b] = true;
		whitelist[0x3bfd26bCF88E595F65e1583AfbdFcd6CF87EA169] = true;
		whitelist[0xdc52C2E7FC45B30bd5636f8D45BBEBAE4CE87f46] = true;
		whitelist[0x264B6B1D31F95c01876C17a8b30D3Ce68dF1371C] = true;
		whitelist[0x2705045Ef16d185a84AEF570cdddE535A0A95d1f] = true;
		whitelist[0x9Be8cbE548110b4F09D932cdfbaC082c9dD98899] = true;
		whitelist[0xbb5D3Fc1E82dCAD48d07ADac292a08d765FD1eFf] = true;
		whitelist[0x419fD53f8c5c957Ae2c52A7df6904e986E59db62] = true;
		whitelist[0x284643Cea4d1Aa85596C69195557967408Fc18F7] = true;
		whitelist[0x91cE2EaAa0ae31B8b109E4a2038Fa7aC3e83034f] = true;
		whitelist[0x38b3bb561700fc263240c4bCfA6F9a5A10167556] = true;
		whitelist[0x4FB54f1F8c545cf31619978E97A3F8396894C88f] = true;
		whitelist[0xc6F236891c3099ce4b210793BB1b3030fFfBaA67] = true;
		whitelist[0x6232d7a6085D0Ab8F885292078eEb723064a376B] = true;
		whitelist[0x0f0924A3a5111e7987A23a49Af826D2Ba431342e] = true;
		whitelist[0xC273ee810842f9fFc9Ce781e4AeD4533A4bdd6De] = true;
		whitelist[0xa58112df57A29a5DFd7a22164a38216b56f39960] = true;
		whitelist[0x33d704D1347bBf81C05104bC41beE19e83C02205] = true;
		whitelist[0x389fb1a81410D20cB6119c134A727E21ebBFEA59] = true;
		whitelist[0xA381D21bc2bc9e349dc4332854788d1036BBD107] = true;
		whitelist[0x89032c0cFF4abb9bc490dF104Ec89eff27314909] = true;
		whitelist[0xdb29C08D0A11D376A54EAABbaa89EB7853e32da5] = true;
		whitelist[0x32E094eeD5995331a45F2eb8727Da81156845Ff0] = true;
		whitelist[0xF896E426615E44a2610F4C3D5343B63b557E11e2] = true;
		whitelist[0xa4939a893C7AEfE9629d7525BE3Db799a9E1045B] = true;
		whitelist[0x36ABc45216Ee411581DA092B9caa98Ac460afc45] = true;
		whitelist[0x657A38e6994CB578351376dCDb077330D00665d6] = true;
		whitelist[0x459B3154699F7e49F7FBcf9591dEfa0a1f1177fc] = true;
		whitelist[0x9b7657D46ea863bfDD0c48b4C41794D47e95E6De] = true;
		whitelist[0xcE20b5aF05868d1d39a65FA47ec285067145686a] = true;
		whitelist[0x40b1ED5efC7aE8a8B50F34963bA89984DcB0529d] = true;
		whitelist[0xB35248FeEB246b850Fac690a1BEaF5130dC71894] = true;
		whitelist[0xad9df182acaDfAd985E854FB93F52F62C0Af6db4] = true;
		whitelist[0x84572C31ACdd30c03982e27b809D30b1eFbCD8f2] = true;
		whitelist[0x018881270dD7738aE1D74dCBc48Ed70A0B47E5A5] = true;
		whitelist[0x8Bfd22d7fa34839447af3B4ED35B847DE5882dC5] = true;
		whitelist[0x9f3BcE237ea107ffad3aa7852F8Dd847e6b82A5D] = true;
		whitelist[0x354d4D759c49094f60D537bfD7177c05b70c20cC] = true;
		whitelist[0xf89C94f43B36719046b55E2AE60BacBfc0dB1C6a] = true;
		whitelist[0xA1830E8d9F019FEB448478a171Bb37Cc6C4c0482] = true;
		whitelist[0x40f465F1ba4c2Aba91c0C896cb92bbe4c7e545DF] = true;
		whitelist[0x57a879266C02bD29d11C956156E9a524de4483D7] = true;
		whitelist[0xFaED43c98a40711e9521859f9ad80a90B6a84968] = true;
		whitelist[0xAB723364C7Acb9b26029f002f942d2C8ed789a3B] = true;
		whitelist[0x3E09005C7B9FC14B4f035260aA4a38B44566dd62] = true;
		whitelist[0x1F4FD7F98275D44A48E1DDFB184aa125dC8Aa9AE] = true;
		whitelist[0x5ad3b640c760CA369321682A0FfBf866C07b2b5a] = true;
		whitelist[0x0B0b8696f89Ba073FC8515FF649618A4fb361885] = true;
		whitelist[0x8CFBD1994cF924d80ec7891CafcEc51CcE4f999b] = true;
		whitelist[0xab88C3E77D9CEB047Face254612653Ee35C9ff0e] = true;
		whitelist[0xF8eF2dD0Bd0D7cD6f60DDa52ab01da6cD2AbE7B1] = true;
		whitelist[0x7417E3bCdE8726908895152A8F3925a756b1894D] = true;
		whitelist[0x0FdbfDc79ad0e2e3F76cC8b7Be6e8bE901E57552] = true;
		whitelist[0xA23FcB4645cc618549Da1b61b8564429C2C32Ff9] = true;
		whitelist[0xCAc5EE14B2155bDf3c7CACAF091c9b481fB47bD2] = true;
		whitelist[0xF405f10feDE59e1D7350c3A3fF8488C33a1f07fa] = true;
		whitelist[0x6ae615835aa020fF1239DEC4DD7A3A5e8b975649] = true;
		whitelist[0x730Ca048cab18D4F09F2A295936325adDfeE7BcF] = true;
		whitelist[0xC9582D09acDec05aa8Fee7fdebb5F10B7E9d039f] = true;
		whitelist[0xE16491e0c975E0394D30e356dE7495Ad8550eAfa] = true;
		whitelist[0x5bd3bf853B9970D93Da64d7628919997C1a06a6c] = true;
		whitelist[0x98CaC89Bba31cE2B18f8CfdF34dAEdF29F383B2E] = true;
		whitelist[0x04ceFD6166D0Ee8f8112Cae7237Bb9207a0ef253] = true;
		whitelist[0x3F38FD15b1Ac453410d8D55e0Ec6696E70BE93a1] = true;
		whitelist[0xE9fAD6906bF563732012Ebf6c30BD47E5E96EbC8] = true;
		whitelist[0x4F64C6b8333F74890b0ba0AF4d480d8ecce01e17] = true;
		whitelist[0xa8A2Aa7200B360e9B76fAFe60950a587449a0ed4] = true;
		whitelist[0x08295076180ee8A6De5a4221Ab5bcD3f7A61200B] = true;
		whitelist[0xEf6c1456A2467c9016a443812D0c182706FDF722] = true;
		whitelist[0x11A6cdf624b0e32B377c6097606edFAB3f0f326E] = true;
		whitelist[0x003dfd836b5AecC95F0E42F1E1F21879C31E8F46] = true;
		whitelist[0xCcb147f3ef9Cb2e8E616D5bF55C1147d0Be6b371] = true;
		whitelist[0x7Ed716a3c0a634fa033CAD0e53BC5fDBc838e23B] = true;
		whitelist[0xeAc5f9b3cd48123a69FE69CE93A7F58100A56552] = true;
		whitelist[0xF9567F184dE6B1fcF617850dE093F78f6c78b0f6] = true;
		whitelist[0x788F93C6165B1Ae7A1297527d0037160A32C1252] = true;
		whitelist[0xd35fC346e15BA5b446917C9fD23A9471d6144701] = true;
		whitelist[0xF3D9281fa183B74F32B96E1c5244596045f4edE8] = true;
		whitelist[0x7302bC5b47F5588174A148C90747a88CB528A8c1] = true;
		whitelist[0xAca3b4110403F3c4dacb35A7B3Aa0a84eFb6A3e9] = true;
		whitelist[0x8F8B4759dC93CA55bD6997DF719F20F581F10F5C] = true;
		whitelist[0x69469f819AbdF47f0164b7fe905993EBDF09bbE8] = true;
		whitelist[0xb9ab9578a34a05c86124c399735fdE44dEc80E7F] = true;
		whitelist[0x327F66c77330AD01CBe89DE9523811CBA0c33fE6] = true;
		whitelist[0x0EC666C5901ba8829138716176Fb44CF214939ed] = true;
		whitelist[0xD68faC38f2AA31c499DF26e3C432Efe3bB019164] = true;
		whitelist[0x3BA3D09f70CED571FE3F629Adc234e200ef5EA46] = true;
		whitelist[0x08cF1208e638a5A3623be58d600e35c6199baa9C] = true;
		whitelist[0x59e147Ec5BB417745356A1e2d9433F3A07D74419] = true;
		whitelist[0x87933405d041141e3564cDD7a2D4b62411E76e89] = true;
		whitelist[0x40CbFEd4ce554C018306207A597586603428152d] = true;
		whitelist[0xb761b98E4A80A3b2d899Bd5cD7E04288952F614a] = true;
		whitelist[0x06687d0C06053124BF67B83a71dB1Dfb50A88527] = true;
		whitelist[0xe425FbdDA869433Db7a123F55d1Aa476947e8040] = true;
		whitelist[0x439EEc211024b3389D38972003cB9D845cF420ce] = true;
		whitelist[0xb540b333FD631F8c4bb389c6E81A99dd50C811C4] = true;
		whitelist[0xfE505FDC65030dD93F44c5bAE1B0F36a55b50291] = true;
		whitelist[0x1ad0b2a3760E4148479bC882c4f148558F17Fcd1] = true;
		whitelist[0xdB39DD32A6203840dB4D7406D780aB3125b66588] = true;
		whitelist[0xcC833833C2B9B0fd7e3122d92AaCb72B53633768] = true;
		whitelist[0xEa506b68aA88120a939372aB746A1b35551AF6F9] = true;
		whitelist[0x9d528bfDef21538303A59D5284801299DdF64e37] = true;
		whitelist[0x80b1960Ce559fDF3f7543B0d87fbB5381f8C3903] = true;
		whitelist[0x82674C58211C0134348B016810Db718b832d4233] = true;
		whitelist[0x8029D8D22610E457360e7Bdfb388e138A7730DA5] = true;
		whitelist[0x97e167a835C54FdeB1F55433ff8bFb94E3359514] = true;
		whitelist[0xD26593E8A99999d418bC58d7C77Ca10611731162] = true;
		whitelist[0x159Ae2b05b03460954fe7b6C0984157DA1A64ea6] = true;
		whitelist[0x1dFbCA42cC60Fbbf3b5FADc3BDF55353B1EA807f] = true;
		whitelist[0x23B2b77c050c4f4fB2EFEb8A6755719A179e7430] = true;
		whitelist[0x681Cbae1C41e5eeC8411dD8e009fA71F81D03F7F] = true;
		whitelist[0xc8664B56Df7ea10C57a8499B10AfC70C78b0650e] = true;
		whitelist[0xbE863eADD096Fe478D3589d6879d15794d729764] = true;
		whitelist[0x5b44a8aBf5b5280cD93fc7E481FbF1Fd46bEdB1A] = true;
		whitelist[0xe6B31e9FC87A81a9bdBFfadBD0c9809f53723efA] = true;
		whitelist[0xa6D3465aE5Da55e36aE33d508154c91F1fF0Bb17] = true;
		whitelist[0x517eCA408D25F7058812943f0682271A4271BF08] = true;
		whitelist[0x2DcCbFFB389576d2Da4e9B71A9016E213bbD5ec7] = true;
		whitelist[0x1f8A12Ad2F144193B12543ba7fd0410351142858] = true;
		whitelist[0x2A121375edF522F3bf8e0704661626Eb5C86aC8A] = true;
		whitelist[0xD30F2888E7928b52EA5bF4cb1D323e0531aFe272] = true;
		whitelist[0x3B570118B74fa0A39AD7C7FCfd75EF7A7A3e3301] = true;
		whitelist[0x25A6BBD4D8f041B4B14CD703560995a09A74B464] = true;
		whitelist[0x42a32D733BDf680c8741C9d2C286D4adF73C0867] = true;
		whitelist[0x5b2094bc95238Cd5A861eA3Bc8f2e3c0C4678ad6] = true;
		whitelist[0x70B0013c64E3439dE45bAcAa1978146b14cC9F2C] = true;
		whitelist[0x528d4e4E0dbF071eC23013f06D8487BaD5A8a68B] = true;
		whitelist[0x35B64947F786c8B756b35Fd25ef2B9917aCC25d3] = true;
		whitelist[0x3F138407A8893f20FC47b4ef0A9c972c19084a57] = true;
		whitelist[0x8e50b222b2C027259392f9F4d6E39e59c24edfC8] = true;
		whitelist[0xE1fc8b4c3566F5459923CBfadDc1B7741a997c58] = true;
		whitelist[0xA4f76fd64aD5cd460c6FB918Fc075EBCef8b5F9E] = true;
		whitelist[0xDAE7ed1ce27D9fF542Ab03c4aD845ACeb2B23E0C] = true;
		whitelist[0xF1140e2fBE438188dFD2FE1a01C6D24D90eF0CA3] = true;
		whitelist[0xB7a0cF8cc33025A654A73dbae1256828c004b7dc] = true;
		whitelist[0x9349F2246D266445f0D40055c9529F084a3ea74F] = true;
		whitelist[0xa8C14D9Fe2cbDF56E610f8F4647c2776c3505526] = true;
		whitelist[0xbFCf0663Ec8eAbd2090Fdcb36534fc8352BDc042] = true;
		whitelist[0xAF77E6ce8FEf4b096E909Ebe6c475Cb991c27675] = true;
		whitelist[0xBac3346e78f18485575B94AD0b1132017Eccb62f] = true;
		whitelist[0x4F7f9811De292Aa6E7FbBada8a1EB0eAB5d60254] = true;
		whitelist[0x849117D3722dC581e588C1F3B02cB7828BdEf2EF] = true;
		whitelist[0x6c0ea11E09f138d56E61b9dbb86cB7422d4e7183] = true;
		whitelist[0x6661280D2363f69A615AE69f57aDF936a89644ca] = true;
		whitelist[0xbAc9E1Da19FF794Cf1037eC332558C7987C6c506] = true;
		whitelist[0x0B01F1310e7224DAfEd24C3B62d53CeC37d9fAf8] = true;
		whitelist[0x82A0F25b6FE7E406c2c6E7884342164D7A9438c0] = true;
		whitelist[0x297cF79ad1CA102DE119fd5C4593E7c4CD99b13C] = true;
		whitelist[0x52734AA7B37A023BD650355A7Ed91025B1A2147E] = true;
		whitelist[0x418e2e450B7dE452Bc479A4efCd7f4262c6cf79c] = true;
		whitelist[0x97A554cb95EDEc7037292dEAa883864Cb35BC668] = true;
		whitelist[0x16D9fd80d8e3f055ba7793794E811712dcbdD9c2] = true;
		whitelist[0x7EB91dAD1fb797EF65887105f0DF3d0ceafb871C] = true;
		whitelist[0xDf4abd11D93cba45F8bE55E3A41c1c18c6f8e9C1] = true;
		whitelist[0xC17f20335080cD0b7283e042C89F16605f3A085f] = true;
		whitelist[0x542a5651F84145EfAaf8dC470e2adC2922877807] = true;
		whitelist[0xC1Ba5d206EE1F07E54185dA06bfAfbF83367BFDd] = true;
		whitelist[0x4dce3bB119FD5785f5f40B1394fb9b3F4d78096b] = true;
		whitelist[0xE55c69cfD20Cfa25651c72b84383dE6104104Eb4] = true;
		whitelist[0x1077011F38c120973238eF266Dd45edad4a78E99] = true;
		whitelist[0x536122207cdE9c0b261ce01E9Af0EE2743c790bA] = true;
		whitelist[0x92d0060BF437A8f6BD9AC72233Ab8cB866BC63a0] = true;
		whitelist[0x6BD662F8b7258D0e371E18A23d509D045e486635] = true;
		whitelist[0xBA2f3CfC765cCE262579aB6Db69Ac7022bfDf0f2] = true;
		whitelist[0x21426471eBF0b7db0F07216d81a897B5F5554394] = true;
		whitelist[0x6EFc434b7858fc7307d0215142b3c019eeee7F72] = true;
		whitelist[0x13afD331C4D411c0dd81Ea257d6C42b6B8a4BBDd] = true;
		whitelist[0x269e5f8AddFAF05dDfaef856f6A36fa27fbaCc38] = true;
		whitelist[0xE37523f553606C6BbB0d5bD78da6C760B368CA2f] = true;
		whitelist[0x2eFf70000afa05066aF0134A1dF455bd2Cb41763] = true;
		whitelist[0xFA8479b6933EBD2A5921eBe82EE2734f494E3f26] = true;
		whitelist[0x5138C21b2A1a4898ee232F00d57B8f68678A7D99] = true;
		whitelist[0xd0C73ceB728bbD0eE113A7a7e312A0173c833E2c] = true;
		whitelist[0x92eC90D6e692d39B189308621c9B12f33372dDB9] = true;
		whitelist[0x189ecEbfa5D3c5EA82d5172b1069c3305a0a149A] = true;
		whitelist[0x92Cee34282f5ef5F387abE41b2976af83296b316] = true;
		whitelist[0x49E3cF47606a5Da7B11b270A790E2112a467485f] = true;
		whitelist[0x552922eEdfF18324098A18b7CC143E96855db7Cf] = true;
		whitelist[0x4E87AAb2ffC3ddDA8142981273c82Df2b5Cc76D7] = true;
		whitelist[0x38865683F5DD59048CCA3A2e91064a731bdB45A2] = true;
		whitelist[0x82509f1803d292FD4bb9A93abA54aA533D6609Db] = true;
		whitelist[0x6Ac0b41B017347309119e13159878B1F3e3eb410] = true;
		whitelist[0xe74a12e1bEFb0d65a399db1A6e231abD8Cf4E746] = true;
		whitelist[0x0EE15685674C6A0B1fF634d23d02D1Cb650d883A] = true;
		whitelist[0x0700D8a9c0B225946b60F8d24661878CAA6683A2] = true;
		whitelist[0x853D18353Ac666E87dB98c59550F2C7068f55cD7] = true;
		whitelist[0xE77d66e7F0903bCE55794E5f5828d521C27e1584] = true;
		whitelist[0x0c6306c1ff8F0cA8432B761085d5Ce74160A499a] = true;
		whitelist[0x6Ec06f8835F41Cc79BB4ADf25ba3DE13c7A5996a] = true;
		whitelist[0x2bDFC32ed7B113D79d04254848C8550D6Be2057D] = true;
		whitelist[0x6F3bA8A845D18D32bE6985650E449d7c29926F7F] = true;
		whitelist[0xc3Ab4F4451d65299540242bb8Ab3C2c65154B3F6] = true;
		whitelist[0x9Ef6aF5379c6C52a1e545Af2085D85015a6aa6Cd] = true;
		whitelist[0xE2d43dA6A3b36B0E97430e42420BFDE4052D0262] = true;
		whitelist[0xcc073E4c1930a974bbF9f07cfC845E639c3026af] = true;
		whitelist[0xD114B66903A4Fe92a75Bb95e6b3059c0766ed0d9] = true;
		whitelist[0xd2587e936569F12e4e553033C6be96d01440ecB7] = true;
		whitelist[0xd61daEBC28274d1feaAf51F11179cd264e4105fB] = true;
		whitelist[0x68e19ADa86678133FEfDc54A98558746bD56B067] = true;
		whitelist[0x542a5651F84145EfAaf8dC470e2adC2922877807] = true;
		whitelist[0x985B03CDC4Def39ED62785458F339DE0121be4D3] = true;
		whitelist[0x681Cbae1C41e5eeC8411dD8e009fA71F81D03F7F] = true;
		whitelist[0x71EAb2760e640775De36Eed89983741Ae83806C8] = true;
		whitelist[0xd21f21Ed6B663028D6B9fC31f240e6D42A2E401b] = true;
		whitelist[0x5877Af7FC64E26c695806E2Fd7e083c8511e61f1] = true;
		whitelist[0x8149DC18D39FDBa137E43C871e7801E7CF566D41] = true;
		whitelist[0x053E6294400a9268E35Df445624F58087C7F388f] = true;
		whitelist[0x1434A664bbAF93AB2655fEf271E5eC4A2431c2D7] = true;
		whitelist[0xff4160A2355B1fa42722cB63fA482E7061ee40e7] = true;
		whitelist[0x10455d2469b5235F95C2512026307bD77b1511d2] = true;
		whitelist[0x376275c4F9e4fffd8A89a90852F253F8e3373F67] = true;
		whitelist[0x05603561a53de107Ce513fE12ED0B13Cc0Da4ed2] = true;
		whitelist[0xD09bB703CBB6EB64034296Fc94488b6C6AC4d05F] = true;
		whitelist[0x34b5f399cc5A1dD491666c9866941FB8E8D09746] = true;
		whitelist[0x1CBD934Eaf49FE310Ba4E27606029c9dEF0168E3] = true;
		whitelist[0x96Afed3Ea9A4238F860423B701AB94CAE084F369] = true;
		whitelist[0x6232d7a6085D0Ab8F885292078eEb723064a376B] = true;
		whitelist[0xb6E34A8A93031a24C264Be59D0BaC00bcaeF9051] = true;
		whitelist[0x13280bA47862A393494F5a46c1910385aA292bd2] = true;
		whitelist[0x1Ca049Ccd785d1400944070c665B3c3132684373] = true;
		whitelist[0x0f0924A3a5111e7987A23a49Af826D2Ba431342e] = true;
		whitelist[0xc7A0D765C3aF6E2710bA05A56c5E2cA190C2E11e] = true;
		whitelist[0x8Da15F7e6bf20Eae393D0210d0F69eA98fC8Ea5e] = true;
		whitelist[0x9975969F2083694d35448c2a4cC40AfF24566700] = true;
		whitelist[0x564B5E5BEcDF359357C15810Ef172dD9d6Be6279] = true;
		whitelist[0x64174450c49242535B4184e3988CC4145B80526C] = true;
		whitelist[0xF7CB4396Dabe5f86128d03A6781bAFE7844bF6Ff] = true;
		whitelist[0xA732BB434e43E007C74B5f26250EE92380c3d2B6] = true;
		whitelist[0x717ba2d9AE88A92C98EB796D3D7dD2D09755a0d6] = true;
		whitelist[0xb1821263a27069c37AD6c042950c7BA59A7c8eC2] = true;
		whitelist[0xa1fC498f0D5ad41d3d1317Fc1dBcBA54e951a2fb] = true;
		whitelist[0x88A92a8a56e21C51d8C0d402d9a84FC81CcfF60C] = true;
		whitelist[0x4fEf654560d6ad788F4b35A5CD02ed185C12Fbbf] = true;
		whitelist[0x8293Fdc6648dcd00b9194dfa0ab731b51E294F66] = true;
		whitelist[0x3704E8d3a85e253b49cda9e5C6470979D6202336] = true;
		whitelist[0x1793a9D2752A0E65EA66e1D5F536d59717D622a4] = true;
		whitelist[0xe8d0587D82Ae54b0dd1F8E234bA3f0Ce1E2f047A] = true;
		whitelist[0xe81FC42336c9314A9Be1EDB3F50eA9e275C93df3] = true;
		whitelist[0x6a167aBE38959433aaaA984B3d50761aC60ee875] = true;
		whitelist[0xD80Dae31104d2361402128937bcF92A59F13E6E3] = true;
		whitelist[0xbb5D3Fc1E82dCAD48d07ADac292a08d765FD1eFf] = true;
		whitelist[0x2bC99F6C868b14Ea6BdE976CE5310F6115DD1382] = true;
		whitelist[0xAea6D987D521B0e61FD4af5164Ab743E00eeC94f] = true;
		whitelist[0x8Fac841807E21807F511dAf3C04a34cd78661F4c] = true;
		whitelist[0xaEE7E9BB015E1543c8ab3226a9d9615971C4C060] = true;
		whitelist[0x5F652f6443d742078A9AbB1C9e453Ed009BB64F2] = true;
		whitelist[0x8ba60b93055713b86A952102239d894dE4b85AB9] = true;
		whitelist[0xdDF06174511F1467811Aa55cD6Eb4efe0DfFc2E8] = true;
		whitelist[0x4dDAc376f28BE60e1F7642A4D302C6Cf6CAe1D92] = true;
		whitelist[0x41A00092909Aa49bB3144eA576d54C4E3e388BD3] = true;
		whitelist[0x5E78d0c7E548bbD070C84Ef6E199e521f4a135a5] = true;
		whitelist[0x08cF1208e638a5A3623be58d600e35c6199baa9C] = true;
		whitelist[0x4EBee6bA2771C19aDf9AF348985bCf06d3270d42] = true;
		whitelist[0xBc486420659a2009987207649d5d0b401349f679] = true;
		whitelist[0xC9582D09acDec05aa8Fee7fdebb5F10B7E9d039f] = true;
		whitelist[0x24f2112A3fe2bc186ffc7ABbAba34bb49d7b199e] = true;
		whitelist[0x528d4e4E0dbF071eC23013f06D8487BaD5A8a68B] = true;
		whitelist[0x0338CE5020c447f7e668DC2ef778025CE398266B] = true;
		whitelist[0xF7FDB7652171d5C2722B4cDd62c92E90f73c437E] = true;
		whitelist[0x269e5f8AddFAF05dDfaef856f6A36fa27fbaCc38] = true;
		whitelist[0x327F66c77330AD01CBe89DE9523811CBA0c33fE6] = true;
		whitelist[0xb9ab9578a34a05c86124c399735fdE44dEc80E7F] = true;
		whitelist[0xe557fBF5009ed3D3b2a7B2f75c5bc673C0e4D0d0] = true;
		whitelist[0xfFC88fC868A01003Fe5D3FCC389051a365d4f932] = true;
		whitelist[0xF9F40ceaca61Ec55CFb09AF821553c3b068341aa] = true;
		whitelist[0x69469f819AbdF47f0164b7fe905993EBDF09bbE8] = true;
		whitelist[0xa8A2Aa7200B360e9B76fAFe60950a587449a0ed4] = true;
		whitelist[0x38865683F5DD59048CCA3A2e91064a731bdB45A2] = true;
		whitelist[0x4E87AAb2ffC3ddDA8142981273c82Df2b5Cc76D7] = true;
		whitelist[0x6c71b204b394c9B8ADd99Ea37B6d1c2fc2b130FF] = true;
		whitelist[0x58f5CE1BDCB2D87EccC0cA2FD8D5073e4EC316a5] = true;
		whitelist[0x62BA33Ccc4a404456e388456C332D871DaE7ae9e] = true;
		whitelist[0x16D9fd80d8e3f055ba7793794E811712dcbdD9c2] = true;
		whitelist[0x0B455480f26444a76638EAC5b6a5B13B60469758] = true;
		whitelist[0xEf2e060E1569816B37bB923A911eC952b8694f42] = true;
		whitelist[0x0700D8a9c0B225946b60F8d24661878CAA6683A2] = true;
		whitelist[0xCa570FB7Ba1Da03a74C929580Dc17d543bF78b90] = true;
		whitelist[0xD724aDa4d48a795e99e547eb2DC2597B06Ac8392] = true;
		whitelist[0x08295076180ee8A6De5a4221Ab5bcD3f7A61200B] = true;
		whitelist[0x8aDc376F33Fd467FdF3293Df4eAe7De6Fd5CcAf1] = true;
		whitelist[0x7bF925893F7713e00493A67Ef0f0127855AD36be] = true;
		whitelist[0xCcb147f3ef9Cb2e8E616D5bF55C1147d0Be6b371] = true;
		whitelist[0xeAc5f9b3cd48123a69FE69CE93A7F58100A56552] = true;
		whitelist[0x763A7bfDe263168dA6DF5f450b4860ccf76749Fa] = true;
		whitelist[0xB3787093e364AE7419Bf9d0c4709900C0cF3469c] = true;
		whitelist[0x84572C31ACdd30c03982e27b809D30b1eFbCD8f2] = true;
		whitelist[0xeB42B12a965CFc16878A966c635e04f15146c665] = true;
		whitelist[0x69f32dbe156D3c5c116CA8feC75ECeB5148841e5] = true;
		whitelist[0xEF1509c5dCb93AFbE3195D4BB28CCc8660eB4945] = true;
		whitelist[0xac1Eb7459AF366444CC502d9b002E2eEf577C02E] = true;
		whitelist[0xda1D4Bd894709DbD9a140c05bdaedd19afE7fb00] = true;
		whitelist[0x11b03346Faabd4A0c9778D2ABa744aE7C7D62B45] = true;
		whitelist[0xA7D7Ac8Fe7e8693B5599C69cC7d4F6226677845B] = true;
		whitelist[0x06074Ff83C4240c554dE83160E611007D66125d5] = true;
		whitelist[0x0Dcf3968f5dD3A68b9a09E67c1E3eC08a82e6C22] = true;
		whitelist[0xD6b954F59F0Ebb252Edc7796c64BA167A1E2efAB] = true;
		whitelist[0x144b9A09B3d4e88212F69cf21bFdE6e3Eb64420e] = true;
		whitelist[0x82674C58211C0134348B016810Db718b832d4233] = true;
		whitelist[0x4650D0c9E3148A8f66AF374820AA2eCa0A47DAD4] = true;
		whitelist[0xe45aB678768CC7E5BAb6DE02Fad7235d6c615037] = true;
		whitelist[0x21af0A9117ee420CB26c32a49c59220F38F5991b] = true;
		whitelist[0xdDe74f034163192dd2170BB56B9CAc2d45Ce0a36] = true;
		whitelist[0xfc27C589B33b7a52EB0a304d76c0544CA4B496E6] = true;
		whitelist[0x92eC90D6e692d39B189308621c9B12f33372dDB9] = true;
		whitelist[0x003dfd836b5AecC95F0E42F1E1F21879C31E8F46] = true;
		whitelist[0xC17f20335080cD0b7283e042C89F16605f3A085f] = true;
		whitelist[0x5204677EeFA881A16D5F8EC4C5978EC3c1dd3059] = true;
		whitelist[0xc6435031926A631D0f241c9285c98Ea840Ee64DD] = true;
		whitelist[0xFfDe865353Cb473544b8f98965A9D1f284ddA3b5] = true;
		whitelist[0x49E3cF47606a5Da7B11b270A790E2112a467485f] = true;
		whitelist[0xDf4abd11D93cba45F8bE55E3A41c1c18c6f8e9C1] = true;
		whitelist[0xce0E1766269e63a87FB1C1e5C745B1db32b5713d] = true;
		whitelist[0x593bee91EBe3A42e809d07189FCEbf9ca0414447] = true;
		whitelist[0x00bF11233fB3A0C0593129e815D0511870299Bc0] = true;
		whitelist[0xD39F25Fe6Fc80421585A07FCb854D2b11ceBE335] = true;
		whitelist[0x182e0C610c4A855b81169385821C4c8690Af5f3b] = true;
		whitelist[0x7f102a3fa4b786fBDEa615daA797E0f0e41b16e1] = true;
		whitelist[0xf6910D47FbB1F5518d60C721D4189936eCd5a1b6] = true;
		whitelist[0xD9917D5c30160240bDE95f8BA2A26034ABbc0541] = true;
		whitelist[0x8e3eDE4CC366dF012231671863720DCc9C929b16] = true;
		whitelist[0xA8652526111e3f5a78b112c3A59f0e7593033d70] = true;
		whitelist[0x333BE3261D637c822DB11085AF4aD9E59aAA2FfA] = true;
		whitelist[0xfba978799D7a6D67Eac09E2E8c052060804A175f] = true;
		whitelist[0x5C45b39E13c4129dF392072045747DDbcedA1eB9] = true;
		whitelist[0xDC4471ee9DFcA619Ac5465FdE7CF2634253a9dc6] = true;
		whitelist[0x70879832e89e0F307801613aa1DAF2FAe5775A31] = true;
		whitelist[0xE638cb3fA853622B2824CbDab3C27b06E8049651] = true;
		whitelist[0xf1ca4Bf4C325C3078Ec25299601A519eBc6BEA6D] = true;
		whitelist[0xAfAB37e854e2EDb2aa9E2830c6BFcd3eEf5C4C32] = true;
		whitelist[0x33d704D1347bBf81C05104bC41beE19e83C02205] = true;
		whitelist[0x3c6d7CE577E3703b8a93d2b77C20B23BfE23eD98] = true;
		whitelist[0xd26E23aAA39F29e07b299DA734C77765F6866A0E] = true;
		whitelist[0x435592c9DC7Fe4536c958D8f9975630dF18DF0cb] = true;
		whitelist[0xe9e9B22B65F17808880f726334BAAfAA8A124Fa8] = true;
		whitelist[0xBA2f3CfC765cCE262579aB6Db69Ac7022bfDf0f2] = true;
		whitelist[0xd319f112bf73eAe5e3cf06bF8D4076cC5f8B1cD5] = true;
		whitelist[0x55b451320A34CE88Fc8F1A1D9156e2AeB8aaD6Cb] = true;
		whitelist[0xA3C277b8f35881CBdb017E52bcC376B3ce8F21dA] = true;
		whitelist[0x5036e7857fdB7D8CcEAB64fDcC445C3B370f819b] = true;
		whitelist[0xa51449B96801233C23639cc7B3D9d95860E1E7a2] = true;
		whitelist[0x50025A3A50dA7Ae49630c5806b4411B0B7B55821] = true;
		whitelist[0x035E8A0A57f24FD10D447c6cE44524513dd6e09C] = true;
		whitelist[0x5EfDd9027575E7c3d1Fa5d7713462CF79Af5892d] = true;
		whitelist[0xc6334A606bDd3699a553fC47a81796234E217B3e] = true;
		whitelist[0xBe67DE0C3f7650B958aAbDFfF3BBD8D55d5c2Ccd] = true;
		whitelist[0x7e8dA72bA1656F62a5a07B18b23E5d23BcD5ed3d] = true;
		whitelist[0x6F3bA8A845D18D32bE6985650E449d7c29926F7F] = true;
		whitelist[0x78D6F9b69c99d2D972bfdAC24fbD70B973e3b763] = true;
		whitelist[0x45698cdCC733cBA4f8B1150C2f580587adF1Df92] = true;
		whitelist[0x492346B79818f9F4A31C2779b52D1DE2C64DBff7] = true;
		whitelist[0xd7E5A6F7b8B838F1be0856e5D3DD907608E40E50] = true;
		whitelist[0x03753428Ea0A136cE3ABA808419B7230e413CE85] = true;
		whitelist[0x2e274C7Ea1667D37373D6a7eC34201b4F4bB95dC] = true;
		whitelist[0x6a7ea8945D0Cdb9b53030F63b4b26263e4478C8f] = true;
		whitelist[0xc8a38F838b7951AB533be6d378ebE298fb41B25f] = true;
		whitelist[0xBB343898E3cAfd815Ce8184973753fcE6E4341be] = true;
		whitelist[0xD30F2888E7928b52EA5bF4cb1D323e0531aFe272] = true;
		whitelist[0x76fC54b4eC08917fc4a7FC6a72d0BaAff9861ad7] = true;
		whitelist[0x4defA30195094963cFAc7285d8d6E6E523c7f90D] = true;
		whitelist[0x0EDb2533655876b1656243fd6ee9B16401281df8] = true;
		whitelist[0x03F52a039d9665C19a771204493B53B81C9405aF] = true;
		whitelist[0xb78196b3e667841047d1Bb1365AB8fB3d46aB1A8] = true;
		whitelist[0x9006eeF759C79745509E8D99Ebd84eFD75975f3F] = true;
		whitelist[0xE2F130B5c02fFBE322DB7904a8a42198ffDC8EC0] = true;
		whitelist[0x66D30263D3E33dF6fECAFB89Cc6ef6582B248Bcc] = true;
		whitelist[0x06056Dcdc6471439e31e878492f594B6F0D8F9D0] = true;
		whitelist[0x79a074122bE96E1Fc9bDd32Dba04759421D12f90] = true;
		whitelist[0xB8eD097E86b7688F29b5b6Ff649AF573682F6F53] = true;
		whitelist[0x06CF8399E3f1ef9Cd94031a6FaE9F47877F512e7] = true;
		whitelist[0x9B32bf5D8D88Dd5CEF0D32cDFFf2eAB50d2e04b3] = true;
		whitelist[0xcBA7f4f44473e32Dd01cD863622b2B8797681955] = true;
		whitelist[0x43961f20194C1a27888386F8547B91aC23f9d8Ae] = true;
		whitelist[0x8Be7b518155184aa03fbDa531a165c567DA9AFfa] = true;
		whitelist[0x9128a39Fdb22De4cE3594e2e2e8EdD7BD9aBa987] = true;
		whitelist[0xDD8dB9f64512cB13fDfe24565670C603381FcA27] = true;
		whitelist[0xe5A7a206E9a8769f90ca792EbB68E9268231F717] = true;
		whitelist[0x9D16ceDC91b859F2e03d94F479994f795F422e27] = true;
		whitelist[0xb9d1Fb123C779B47269280D0e152Ac32E40b1177] = true;
		whitelist[0xf6Ae21A0586691f7F4Ea86fc4c08731Fa455aCB0] = true;
		whitelist[0x06904f07a74e1d47313cB530AF0487BF705aB099] = true;
		whitelist[0x64B7fcC8C17540139BDd84d00c7261035602Cb66] = true;
		whitelist[0x050920eDA4014e25DED17c346b425239a468d63d] = true;
		whitelist[0xf823825DC97a8c81Ec09D53b6E3F734E76E60cB6] = true;
		whitelist[0x7cB0393740204B1034E58Fddd1580563B6f3c0a3] = true;
		whitelist[0x2fF1bdC41B5c602e90951908ffeD997f3b5D97a6] = true;
		whitelist[0x0d9506F3498c73fA1b26Ec9f8B913834645a8b37] = true;
		whitelist[0x600a782c4D56961f8f72220d4c28b413b9Cf3c87] = true;
		whitelist[0xeB5264d5E08452c4966788c1C63D073B56cbff93] = true;
		whitelist[0xe684AEDcb17D70923dD50aC757ECeDc43d86cc49] = true;
		whitelist[0x38b3bb561700fc263240c4bCfA6F9a5A10167556] = true;
		whitelist[0xD5174e20aa8DCaB93bd7551CcB990b4B9E9f7789] = true;
		whitelist[0x5520082cAfe40F2De90DBDAf29a2ECC606B8f9AF] = true;
		whitelist[0x13454530E32A74faf73FB8210361aa66C3bba5A6] = true;
		whitelist[0xab40ef5d3D86f90a5069df913edcDc4E4B99f9a6] = true;
		whitelist[0x6bd8441EE1e4a1B326a29439A1d225627DfAd071] = true;
		whitelist[0x67ce74c19cdc9FC596B96778b9C17B10d34AF36d] = true;
		whitelist[0xc82a75D564521306e7Ee9eBD530a459292c45Ae7] = true;
		whitelist[0x0E1ca0c78C85457e04DD6F256b290f6c31B7629A] = true;
		whitelist[0x94B60bCCc939Aeb28FeC230659E4603eF17324f7] = true;
		whitelist[0xc252e410E213A9bc3DB942B4C7c6C69AA3cE8718] = true;
		whitelist[0x79FBa65F42731E4a4dB8472f0B2A5b48d0b4E7F9] = true;
		whitelist[0x1F4FD7F98275D44A48E1DDFB184aa125dC8Aa9AE] = true;
		whitelist[0x419Cd8897906fA7A60105b2f0c3369e0e36D8D26] = true;
		whitelist[0xAa73bdecb77AE96c2C73530cA1A276E256cb65e8] = true;
		whitelist[0x075483AD26925E558955Ca1D2679c12D8453a8CA] = true;
		whitelist[0x33cB0C602d9D2965c5538731bAB28F122988f74E] = true;
		whitelist[0xDc610C4766450E3184AfC312ef2224702299219b] = true;
		whitelist[0xfD3414fd643023D73457a7BFD628959E0f55CC97] = true;
		whitelist[0x0778e79130594FA32B0b3eC87E1d9f92AF43BcE7] = true;
		whitelist[0x9D2daC55816Aa70cF0357492E5A111461F912B19] = true;
		whitelist[0x284A9e0f4F7869b3294d1931B9845740A8607586] = true;
		whitelist[0xA5471Bd195552d35f299AFb4196750005e7298F5] = true;
		whitelist[0x04B9Cad474D427576344152FbEa36b996C586076] = true;
		whitelist[0xD1370243a9e83b9641f90C1Afd012BDa729331c4] = true;
		whitelist[0xBEEf32ccA6966bD3Bd0aA02659f829FcC8631a84] = true;
		whitelist[0x6519E6117480D140CD7d33163aC30fD01812f34a] = true;
		whitelist[0x18aEc641D8e2b1108FF5fE048539824b5B62c8E1] = true;
		whitelist[0xd48D8cef2F1A7b29BAFb5E17e8B88bfEBaeC602a] = true;
		whitelist[0x10665581d1ce1ef67593b7770F9fA555C9009C06] = true;
		whitelist[0x7545E91679A6cc1d744690F136fF5c705c2dDB67] = true;
		whitelist[0xF3D9281fa183B74F32B96E1c5244596045f4edE8] = true;
		whitelist[0x9431D1615FA755Faa25A74da7f34C8Bd6963bd0A] = true;
		whitelist[0x51050ec063d393217B436747617aD1C2285Aeeee] = true;
		whitelist[0xf2D499fD020d1b711238461F96DA9A07A137660d] = true;
		whitelist[0x186d562907bB057377d5c87e4f543C434fDB58F4] = true;
		whitelist[0x91cE2EaAa0ae31B8b109E4a2038Fa7aC3e83034f] = true;
		whitelist[0x5e40E0ad7b8b37C63aC1B9039b91E223DD27D688] = true;
		whitelist[0x6A09156e3741955f5fA556f61F5c9546e52c45f7] = true;
		whitelist[0x414be4F8572176Ac908926Cf2A9c328b873F75Bf] = true;
		whitelist[0xBE994cF43F52Fd73FE45ceD29F06D1B08bd1709A] = true;
		whitelist[0x2206e33975EF5CBf8d0DE16e4c6574a3a3aC65B6] = true;
		whitelist[0xB618aaCb9DcDc21Ca69D310A6fC04674D293A193] = true;
		whitelist[0xC77848cDD3D3C91A7c3b25d6443d2871bcbaFFc1] = true;
		whitelist[0x270e3A305495e675d582847D8F3Ac4d10825A690] = true;
		whitelist[0x7807829E002aD30F68c3072B3260bF912B3394Da] = true;
		whitelist[0x4a60A51B200cfC0224645C515530dcB3efFCb370] = true;
		whitelist[0x1f6D31774AD51A60C7b53EeC2C37052F6635235A] = true;
		whitelist[0xaF7031b4f2a1A52338fE6Bd75409e38564838154] = true;
		whitelist[0xb418Bd3d37e947C4B954C3750bF74C99804Fd776] = true;
		whitelist[0x64ab118484c38baEb5B924143ca459706c03953F] = true;
		whitelist[0xCf1DF6C3A26064A05b6437BBdF377fE46ac2d753] = true;
		whitelist[0x822F86864da9fE5ca3cAb3B7438CF6227f459346] = true;
		whitelist[0x8D19a5C86cf176d49419DD7E4EEC7b81B96431c4] = true;
		whitelist[0x8683A90E9fe51AF9e452437f14Fed9241Be9413e] = true;
		whitelist[0x0A4095a90bBe52625599EFd4B698d8d01B32676C] = true;
		whitelist[0x1E6BB25d0068C11331c100e3c7eDb3bb8b98d042] = true;
		whitelist[0x8B6D3eEe9048304aac53Ba571B1889A4f0609474] = true;
		whitelist[0xba6332d3f01D220f1Cc2Fda423Ed89249D495C43] = true;
		whitelist[0x9eaC7914e6dC6889E368dD48E3089706D7536a1b] = true;
		whitelist[0xf6607ad5992f32448D307ddC20f71D88B4fe35A5] = true;
		whitelist[0x93f0C941Da115cff5680F83172248e7644f5369e] = true;
		whitelist[0x768058a4b0054dc1cb025889B2eFD9C2051d2Bf6] = true;
		whitelist[0x2D8f11b3e4010C067Ad964D5d8558e2b61E21f07] = true;
		whitelist[0x277d1523f3993bb40eC647a2236316eAf5A39cF9] = true;
		whitelist[0x14B072f1954DD88131271D597A30e9899B57eb0F] = true;
		whitelist[0x5d96D8F927a7bf5F342017CAF70039B9e9CFC216] = true;
		whitelist[0x51Bd2CCceB74999380c26E401aC87D4afEf092Fe] = true;
		whitelist[0xe31AAf1A3C67D6909Eb7D104A620d3CD85c8411A] = true;
		whitelist[0x95B97AaA76fC57DCd65df419C6ccd73efaE611ad] = true;
		whitelist[0x8C1D0aC50ad00C220936E2f1647405B12B0B91C2] = true;
		whitelist[0x85CdF932E2cf53f8011D09A0088bF06D9dD96179] = true;
		whitelist[0xA289b1a2594bEa59e34DF6A17544Cc308C8e18F8] = true;
		whitelist[0xd23199F1222C418ffC74c385171330B21B16e452] = true;
		whitelist[0x8d17Ff92B8C92Ed3C3f0A99e9A1aB817Fb895BF7] = true;
		whitelist[0x6b7C318467F409A5Af2F0A9d0976Ef7b72d22a62] = true;
		whitelist[0xEf6c1456A2467c9016a443812D0c182706FDF722] = true;
		whitelist[0x265D5CEDbCecf2a70E78D31D0AcC7BE8617de7B9] = true;
		whitelist[0xd0D004B4ce867785D9aB4C684f0497680AA7B6Ae] = true;
		whitelist[0x325296d941a6e2d77f084488676704F8CFEc7b51] = true;
		whitelist[0x55EEeE5F33036885C336a78564522e89B69c26dC] = true;
		whitelist[0xc07A18c4ccE7F95A413515d3D137De47BcFfb495] = true;
		whitelist[0xc3Ab4F4451d65299540242bb8Ab3C2c65154B3F6] = true;
		whitelist[0x418A9a9f182B04EE9BDC5AE0dd0B4f0976dF5Eda] = true;
		whitelist[0xDb2eDCC7880F0071959e2f6713CC335a6690FC84] = true;
		whitelist[0xf19F3d5F1CB45a6953d6B8946917b06431314C00] = true;
		whitelist[0x89831EF83444823b033CBfEbf877a197D39aA231] = true;
		whitelist[0xB82eB1dA53C5e394f8525c7D627dd03640D6bc97] = true;
		whitelist[0xB09D70324fb2c73bC8Ba5c7fc1270Ec0c0546407] = true;
		whitelist[0xB15f55B848B56F80a08759C4064cb2e1957be6c0] = true;
		whitelist[0x46EcB3F576c31290E1A4b359fd993e36E86Ef9e1] = true;
		whitelist[0x3BA3D09f70CED571FE3F629Adc234e200ef5EA46] = true;
		whitelist[0x812DbB12a51a5173cBAE829dD451CD4A79f6a756] = true;
		whitelist[0x07819CD403605c35C94BcFdF386fdD5312D7D706] = true;
		whitelist[0x657A38e6994CB578351376dCDb077330D00665d6] = true;
		whitelist[0x120fb4D4b80DC98BF27341f0D98F0CCedFEeFDd4] = true;
		whitelist[0x767CD29fA0BeFC46690F2547a826152d67dFB189] = true;
		whitelist[0xcE64da4caf4c7D5A65c74Fbacb16E170d300285d] = true;
		whitelist[0x4441fBd5E5E1A5AE0BAD986C015c0DE9a320cE2C] = true;
		whitelist[0x329E630CA8507829B90660c26C555A906f6782e1] = true;
		whitelist[0x008BA4907924f86C62fBb31Fe4A0dFE91c0e6acc] = true;
		whitelist[0x21258055dfd7a287DCC224E3586210F1864c1996] = true;
		whitelist[0xdAE4012B41657B7118324Fe13aF91eEc0EC95acD] = true;
		whitelist[0x9294bb652f4B1392Ff8c266Cc75BA45ba312c124] = true;
		whitelist[0xdcbe2EDb494a5816Fb234b2407877149291d8bA4] = true;
		whitelist[0x10172b1A8fD270C2F4F45561617747ad2a35B31E] = true;
		whitelist[0x25a61B9CB2D749b062fA87b792ca60faEdDdF851] = true;
		whitelist[0xAf981AFA2f5fd50ffEDBB5728FA0fFd2a99b93CE] = true;
		whitelist[0xE3f3EbacD9Af846fd2385F390E400fe520923173] = true;
		whitelist[0xCAaD0665CD8007D692e57188A1C8e38Ea0A38F50] = true;
		whitelist[0x0F4Dc70b4229e859fC25DC8cA4Ea58956359eD83] = true;
		whitelist[0x3d7cdE7EA3da7fDd724482f11174CbC0b389BD8b] = true;
		whitelist[0x97A554cb95EDEc7037292dEAa883864Cb35BC668] = true;
		whitelist[0xD31D14f6B5AeFDaB5fE16DeA29fA46F6B8c15bF2] = true;
		whitelist[0x419fD53f8c5c957Ae2c52A7df6904e986E59db62] = true;
		whitelist[0x9402B3759C8f8f338639566826Fe7A684BA143B0] = true;
		whitelist[0x23FA84013Ba906121D80d839321823F75cE018b6] = true;
		whitelist[0x98011a7b0795F456FfcE7c988369f1149e8AEba2] = true;
		whitelist[0xEa302cF778a1186843Ae10689695349f5388E0D9] = true;
		whitelist[0xaECf6412Cf1A51986185F5718FadD640bae5C7cB] = true;
		whitelist[0xb65aFAa2c59fd94f00D667F651B5D0c800ab99B6] = true;
		whitelist[0x4d0bF3C6B181E719cdC50299303D65774dFB0aF7] = true;
		whitelist[0x22C3378F9842792f9e240B11201E7C2F4901a408] = true;
		whitelist[0xC208C84FC1B7A11ac3C798B396f9c0e5a23CFA38] = true;
		whitelist[0x753e13f134810DFBE55296A910c7961Aa1B839C4] = true;
		whitelist[0x34D7bCeaA2B3cfb1dE368BAA703683EDC666d3f1] = true;
		whitelist[0x2D2c027E0d1A899a1965910Dd272bcaE1cD03c22] = true;
		whitelist[0x6dE12C6478cba122eCec306e765385DF4C95E883] = true;
		whitelist[0xdc52C2E7FC45B30bd5636f8D45BBEBAE4CE87f46] = true;
		whitelist[0xfF5723A2967557D5a6E7277230B35b460f96E56c] = true;
		whitelist[0x79CE43f7F12d7762c0350b28dcC0810695Fb24dD] = true;
		whitelist[0x7E6FF370343468f5Bf8307D05427D1B02fE74E68] = true;
		whitelist[0xB0623C91c65621df716aB8aFE5f66656B21A9108] = true;
		whitelist[0x12F4b06a8cED0c0f35a5094c875a2b8a86562498] = true;
		whitelist[0xe43A5Bda37e98A9fb6F40Bdee4147C7D0C5a7dDE] = true;
		whitelist[0xab35EE8Df2f8dd950cc1cFd38fEf86857374e971] = true;
		whitelist[0x128Db0689C294f934df3f52e73877a78f2d783B5] = true;
		whitelist[0xc48d912C6596a0138e058323fD9929209A66Cfd8] = true;
		whitelist[0x02e04F52Dc954F25831e4edFd1A1086B9feEf801] = true;
		whitelist[0x75291cB8b75d6D0097a95F9F5B5389E20B1Fe40a] = true;
		whitelist[0x7f92C0b4970b8459462DaC9e3256a016B45ee15E] = true;
		whitelist[0xEA5338F40A649b58f15eBA78eF67262558343F03] = true;
		whitelist[0x552922eEdfF18324098A18b7CC143E96855db7Cf] = true;
		whitelist[0xfbA792D508d0f61e6BFD7c5A5bd00802a97AA0b2] = true;
		whitelist[0xb9dBf2caE6Fd864B1F7C2fb3dF5c0ce68D0E6B59] = true;
		whitelist[0x853D18353Ac666E87dB98c59550F2C7068f55cD7] = true;
		whitelist[0xAef9a463CB85e771bD8F3536e04956d30ee31ce2] = true;
		whitelist[0xc0b75b61c6ECFfd77743a8b77BD8a3E7fCbc5a93] = true;
		whitelist[0xa837b0f94974f37e17347A0BB8C448d8F25D0B0B] = true;
		whitelist[0xA95F4f51cc7FfB04e97eF0dDC9B6060c9200eE80] = true;
		whitelist[0x5e58538cc693b1099C68d7fEF963C1f148DaE8CB] = true;
		whitelist[0x4771B65e9A825d2917378F43810F6bAF4ce3F732] = true;
		whitelist[0x35bD3902A2Ed264f1803f78423e71Ee0BD7b189B] = true;
		whitelist[0x068baEE003C32D507a64eD7AF700a0aC7074Fa58] = true;
		whitelist[0xBd87C000fd1222d5dE79D91ef9ff23Aa6d1b0F52] = true;
		whitelist[0x8eBc92675F0182182994B44B204be932565E736D] = true;
		whitelist[0x6Ac40b84f5732cCc2d21ebe71f2ACC4140314843] = true;
		whitelist[0x6963D1743A452FE1A082B76b1432037a12c2C742] = true;
		whitelist[0x41BF39033C732F884A52ddf38F647aD63457CEEC] = true;
		whitelist[0xa5cc3c03994DB5b0d9A5eEdD10CabaB0813678AC] = true;
		whitelist[0xd3A1ab87C8aB81CB093Ef5430A387D127ac523a0] = true;
		whitelist[0x39B557A249706CAC1DFfe157cE5D25fF1791b56F] = true;
		whitelist[0xE0Dd8C40ACC74005C71CE5d02Cd5116A2eEDB1b0] = true;
		whitelist[0xF6f4B3d80884DCf2E602820622cafC1Bcc1F9AFE] = true;
		whitelist[0x95eE9e136f0d5EB6fb5b7b83Bd09b35e21ba55F0] = true;
		whitelist[0x127fa43E17eA1a819cD07692Ee17D4F65E927564] = true;
		whitelist[0x328Ca06CA310EFd4cbf9Cc2DD4B62C7dbC1BB791] = true;
		whitelist[0xC9b5db189631ED9bB35eb795826d90717b43B56A] = true;
		whitelist[0x13FD513c2104941Bc399589b5391957B27392E8b] = true;
		whitelist[0x7F7d6649af37189C3C1CBA4407265218086D5716] = true;
		whitelist[0xA1c256282e215e3040F3Fe5f17bb105C72Ec4E25] = true;
		whitelist[0xCeba00f5c2e0cA4E8dAE4D88EF79190a648B9966] = true;
		whitelist[0x2A3Ce3854762e057BA8296f4Ec18697D69140e1E] = true;
		whitelist[0x6DC16Cb8532967534Ef2BFE8C4eDEE9fD552603e] = true;
		whitelist[0xC2488CcF46573821a02E0dE829f1970dbC14A3E9] = true;
		whitelist[0x6564f96bE476A430Dede03EcD7352Be33B12FC0F] = true;
		whitelist[0x6457A438e924EEeb2aA14C254db044bf774b62Eb] = true;
		whitelist[0xeD66cE7eEe03790056cA5Ba5ee61Bc4F77bA2DED] = true;
		whitelist[0x4c3A392af5FC22253743b0600a4365DF3A7F9893] = true;
		whitelist[0xbA993c1FeE51a4A937bB6a8b7b74cD8DfFDCA1A4] = true;
		whitelist[0xDf9c5Cf591e1338bBA20A26D4177B733713108FD] = true;
		whitelist[0x4Fc83f87639C917A9703F135f4C48a50e54eF8c3] = true;
		whitelist[0x5Ed9e63Ea642DB16B3B6A58E3F867668178ac222] = true;
		whitelist[0x42FB05E09f8A477620dEFe49AF76e577Cbd791D8] = true;
		whitelist[0x775C4B0f9f13fc32548B060ab4bf5eff44B08348] = true;
		whitelist[0x7b5296dB485B599DD8604346163c0DFaC096D553] = true;
		whitelist[0xD6Fd8413B1FaCafcB46b3F7C08d07DaA0fe5E770] = true;
		whitelist[0x01be72263B12fE4D51919786f65bF13FF3E58ebE] = true;
		whitelist[0xa47Fd53CcEc8fe0ec67794AeA9e3Cd392A49b88E] = true;
		whitelist[0x013bbCfF38F4E875B0218E4eB460e0E7c8FFaFc2] = true;
		whitelist[0x8DD6629B2272b4fb384c13E982f8e08Bc8EE001E] = true;
		whitelist[0x1AfC8C45493DFb8176D12a5C5A0469dC4c14f02a] = true;
		whitelist[0xBb179f078BAC0FF4f181F6e01606cCAe883Ef74D] = true;
		whitelist[0x9Be8cbE548110b4F09D932cdfbaC082c9dD98899] = true;
		whitelist[0x41a195cD1b26cA3774f761c5652c9E0841932126] = true;
		whitelist[0x6885863E1aAa726346e9Ea88b7273fe779075E8a] = true;
		whitelist[0x97bac212815DfF849820e34b6F9a58e4C40909De] = true;
		whitelist[0x8Dc9c53B85FC13779C5874be6fD7A20Ce3Cf7e20] = true;
		whitelist[0x83E84CC194E595B43dCEDfBFfC3e0358366307f1] = true;
		whitelist[0x107Fb8867608508eb4B9F69333603fCD632BF330] = true;
		whitelist[0x26983a34F4E6cA1695C7b897904AD9212d042d27] = true;
		whitelist[0xf6FF6beCFe9D0b78424C598352cC8f64D0d1d675] = true;
		whitelist[0x553ea73C8d7932c94830Bfe16d91Dd3931d87305] = true;
		whitelist[0x7fC9435A996E6F07e75c244bd9F345FAAF81AF8C] = true;
		whitelist[0x3D5c457920Ff88a7a42D2aF63d450E5F2da61d14] = true;
		whitelist[0x99F0764BECCAEF7959795c16277a10CA7a80369C] = true;
		whitelist[0x2378598aEf5768d12df9ab72dee9AF37a2741F5A] = true;
		whitelist[0xA58715f1069d82233ba2bFa88058774678b33F05] = true;
		whitelist[0x660157aeDBF8f046b50D6EBd3a4502007aB6cBE7] = true;
		whitelist[0xb0cFeA22b93a4C85C46c55f6e665a77fefC5D197] = true;
		whitelist[0x55e2880c6984f671A78044B4027C899b12d7BA86] = true;
		whitelist[0x64Ad18fd2cdE41578d231955C98A714f8CBaC239] = true;
		whitelist[0x1C12c3FB74aA4658B13bDB744Fc314648311A082] = true;
		whitelist[0x993f5b993e733d7840F25981138DA602430e13Dc] = true;
		whitelist[0x977D3dbf93174f517a52736E1e556B79300CE3cC] = true;
		whitelist[0x22a001Eb8434Dfe92C22Af924A9A0a6ddA82B5e8] = true;
		whitelist[0xAdC3BD4529cbE18291E3f2dB73Cb7630Aba73Cb7] = true;
		whitelist[0xeCC1C3d38460FFc4fd58BECAEF72A90EdF0613a4] = true;
		whitelist[0xb6D089F0b4865F922FE92815A1c90b53598e5AAe] = true;
		whitelist[0x91aD771F1e4978479f7451F76d423093D26ba616] = true;
		whitelist[0xbFd3F0350120Ed7e7c45b722E69D6f5e1a063c6C] = true;
		whitelist[0x2E601885896103318269CA45431B943a6C8Ae39a] = true;
		whitelist[0xE4E565C4a2A5050BA1020314c76420dd52D88Cd6] = true;
		whitelist[0x6375594B4175100055813039CA22476CDDE06328] = true;
		whitelist[0x8C8024bf5f90a06CCeD7D32BAbcCB934942c82f6] = true;
		whitelist[0x0Db99Bf3b52EDa95FD6647C16442EF55815a40A9] = true;
		whitelist[0x9b973568b0664BFcA35e8F0Aa39daEEA737b3fcC] = true;
		whitelist[0x3822881D61803AF91a95847ad20B1bF20A5671B2] = true;
		whitelist[0x02a5c980029cB470Ac89Df2E2de1CF453aEE6558] = true;
		whitelist[0x7b923AaB6126b5F09b141e9cB4fd41bFaA6A4bB2] = true;
		whitelist[0x89032c0cFF4abb9bc490dF104Ec89eff27314909] = true;
		whitelist[0xF848E384e41d09DCe3DcAeD37e1714418e68ea7F] = true;
		whitelist[0x4FFe858b37c9398237246A81885c5d4dCB38245e] = true;
		whitelist[0x7373087E3901DA42A29AA5d585F9343385Fc2908] = true;
		whitelist[0x9f477D97a21389542e0a20879a3899730843dcCD] = true;
		whitelist[0x823dC685e777a7523954388FA7933DA770f49d42] = true;
		whitelist[0xDA86955802A0e8f69F1C8e04090E4dC109fd9653] = true;
		whitelist[0x8683BbBe511B269F1b9dC0108fb6B267Ea764F8e] = true;
		whitelist[0x1AC08405E96E3561893eef86F194acDB9A24D38D] = true;
		whitelist[0xe7779a8C5005098328A1ece6185B82c6A9DBE56D] = true;
		whitelist[0xd8758354945360a603BCbe1bb31C56383f6FefF3] = true;
		whitelist[0x7a2269e15d34FC2a69e4C598A7DC51733ae93638] = true;
		whitelist[0x9643805d1756d8990B5C492a2c3374a4dd29FA80] = true;
		whitelist[0x473888e67636661062daD4CFfC92a39437810313] = true;
		whitelist[0x22720cCDe7Db8141576f844beAfCC9c7B7D602aA] = true;
		whitelist[0x68c3494bAd6011033d10745144B51890861422E9] = true;
		whitelist[0x2eFf70000afa05066aF0134A1dF455bd2Cb41763] = true;
		whitelist[0x0D0b3B531cDBB38F854613969d83334cD73dC7CB] = true;
		whitelist[0x44ddBB35CfeBbafE98e402970517b33d8e925eB3] = true;
		whitelist[0xE076f2722c830d4441ec0BCe158fA1956e8B162E] = true;
		whitelist[0x2D0d77065aB397CcC8D7cCFD847eF46074a93c38] = true;
		whitelist[0x829004098cFd973A574a7c18dce5CD10EAa96Cb0] = true;
		whitelist[0xd7d35C3FbfeAaAA6ad1C9C020ED39764E0A604bb] = true;
		whitelist[0xF6746F1472EA920eee7b793a4d48BE0fEA647Bfe] = true;
		whitelist[0x03eE1E0e4eaa0eF034aC81831FAe674135a4995a] = true;
		whitelist[0xaF2E6340bcF42C39467dD6D86632a2db42C11dc5] = true;
		whitelist[0xBA12D8B01A6Bfe6FFf2250912caB159455Ee87ad] = true;
		whitelist[0x51e13ff041D86dcc4B8126eD58050b7C2BA2c5B0] = true;
		whitelist[0x78c4B4A8BB8C7366b80F470D7dBeb3932e5261aF] = true;
		whitelist[0xBd8e9e39ad49D2607805b77951C9b284E4E8CF31] = true;
		whitelist[0x71211a75C7995aA0a3f3FbF666ccb9446cE051B3] = true;
		whitelist[0x254B8073B057942235756B7E7249fB5Ca60753Ef] = true;
		whitelist[0x86Fd708A7762B5cb8625f794263516b95B22e129] = true;
		whitelist[0xEaf7D511a1956c9D297EFBB2D81b528B37D1d8D7] = true;
		whitelist[0x2a7B50f2FbdEfd9CAFF33cb386d87269EF5aBfCd] = true;
		whitelist[0xBa1fA72bE53A1693dE4867DeA60fA9f041073BEF] = true;
		whitelist[0x7FF50D24C87F3A4E0c3C527bBB563715cE6E71c5] = true;
		whitelist[0xF43479102a0d24d068a7912B092689000d9Cc5F0] = true;
		whitelist[0x7a18960043093E89d804A30D5664Ce769cd153A1] = true;
		whitelist[0x989057259D3a0D75c4C0E21584E296bBF044E722] = true;
		whitelist[0x50491bf5d8EA8d23AADeB482be496590DAb34fb7] = true;
		whitelist[0x915782DB070B286375C4B757f63fC9a81c3E93F7] = true;
		whitelist[0x4dd5D12a6b16224b4d234F0A06De1587db190679] = true;
		whitelist[0xc3B39978C872B3DD3A52Ebe34A6A3B08De7762E8] = true;
		whitelist[0x7a9DC8eEaf5022cECd60C54A042343484ce6C065] = true;
		whitelist[0x469B786bd2416eb6EB832741f2FD536F60a355D3] = true;
		whitelist[0x523A16DCF25698a9992327BD0c1d9832c82b8A4D] = true;
		whitelist[0x559d92d2bF798c4310e5b71001B6351c3c96005C] = true;
		whitelist[0xcfadBa5101911D04189331ff9F6e42fE44567439] = true;
		whitelist[0xD5D4aAFb3B2217607e5B5B5526Eb6932f8DF130F] = true;
		whitelist[0x6e3f8E093Fe749398aac60515686fC4FC4baC514] = true;
		whitelist[0xfD2307923C117e384b3aa9E34Bfec419Cb66a14d] = true;
		whitelist[0x2847E472A7F56c1693A815F2CA50F30d3d263F4E] = true;
		whitelist[0xaB4bE3171994fEa9F6717DbE1D2f7839295e7688] = true;
		whitelist[0xF6b11609c3A5bCDEbA0EAB46799A3ed7C1323db8] = true;
		whitelist[0xcC4f052FCDf3C94cc5acDec24E415248dAC9eEc2] = true;
		whitelist[0x094F8EECDf916aA47E5382c1c1E83888bCC03dfF] = true;
		whitelist[0x7E9631b460DE70F5b089594C4aC83Ce7026cd0B2] = true;
		whitelist[0x00C994c17976B06b6A7b22460E9001ECdb25c511] = true;
		whitelist[0xf2439241881964006369c0e2377D45F3740f48a0] = true;
		whitelist[0x4EfeceA2A42E1E73737e4dda7234e999A84Ca60B] = true;
		whitelist[0x179891636BAeAf21c5DEA72Ff9144fc4e4f48680] = true;
		whitelist[0x87Aa1150cAF247a35f303AA051568a81FeCa11a2] = true;
		whitelist[0xaDba5Ea1525C5aE27A0f98408C8E5D67e28c754c] = true;
		whitelist[0x1E94b256C7B0B07c7c0AEd932d12F03034c601Ab] = true;
		whitelist[0x1aD42FB475192C8C0a2Fc7D0DF6faC4F71142c58] = true;
		whitelist[0xAb30f11201d6D53215729D45DC05a0966C237922] = true;
		whitelist[0xf4f5AC536B4E39dAe47855744C311A87361337d8] = true;
		whitelist[0x4065a1D266B93001E7DF796735C68070E2154fa4] = true;
		whitelist[0x612aFa0059F72905f78f45fD147Cda08311b24eB] = true;
		whitelist[0xb48d6C33A96F5519C82569b478fcD723b3A94a2A] = true;
		whitelist[0x501D63B672E92274Ec7dCd4474751D8F62933386] = true;
		whitelist[0x370F75f54907AA06584892A86F891536DB5C4F49] = true;
		whitelist[0xf21E7aF6777b9a8F1eB57A94B5F1501e68eBFb91] = true;
	}
}