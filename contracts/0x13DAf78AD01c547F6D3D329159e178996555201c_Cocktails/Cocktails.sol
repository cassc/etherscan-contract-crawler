/**
 *Submitted for verification at Etherscan.io on 2023-03-31
*/

/**
 *Submitted for verification at Etherscan.io on 2022-02-21
*/

/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;








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
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;



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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

pragma solidity ^0.8.0;

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Assumes the number of issuable tokens (collection size) is capped and fits in a uint128.
 *
 * Does not support burning tokens to address(0).
 */
contract ERC721A is
  Context,
  ERC165,
  IERC721,
  IERC721Metadata,
  IERC721Enumerable
{
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

  uint256 private currentIndex = 1;

  uint256 internal immutable collectionSize;
  uint256 internal immutable maxBatchSize;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // Mapping from token ID to ownership details
  // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
  mapping(uint256 => TokenOwnership) private _ownerships;

  // Mapping owner address to address data
  mapping(address => AddressData) private _addressData;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  /**
   * @dev
   * `maxBatchSize` refers to how much a minter can mint at a time.
   * `collectionSize_` refers to how many tokens are in the collection.
   */
  constructor(
    string memory name_,
    string memory symbol_,
    uint256 maxBatchSize_,
    uint256 collectionSize_
  ) {
    require(
      collectionSize_ > 0,
      "ERC721A: collection must have a nonzero supply"
    );
    require(maxBatchSize_ > 0, "ERC721A: max batch size must be nonzero");
    _name = name_;
    _symbol = symbol_;
    maxBatchSize = maxBatchSize_;
    collectionSize = collectionSize_;
  }

  /**
   * @dev See {IERC721Enumerable-totalSupply}.
   */
  function totalSupply() public view override returns (uint256) {
    return currentIndex;
  }

  /**
   * @dev See {IERC721Enumerable-tokenByIndex}.
   */
  function tokenByIndex(uint256 index) public view override returns (uint256) {
    require(index < totalSupply(), "ERC721A: global index out of bounds");
    return index;
  }

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   * This read function is O(collectionSize). If calling from a separate contract, be sure to test gas first.
   * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    override
    returns (uint256)
  {
    require(index < balanceOf(owner), "ERC721A: owner index out of bounds");
    uint256 numMintedSoFar = totalSupply();
    uint256 tokenIdsIdx = 0;
    address currOwnershipAddr = address(0);
    for (uint256 i = 0; i < numMintedSoFar; i++) {
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
    revert("ERC721A: unable to get token of owner by index");
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == type(IERC721Enumerable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) public view override returns (uint256) {
    require(owner != address(0), "ERC721A: balance query for the zero address");
    return uint256(_addressData[owner].balance);
  }

  function _numberMinted(address owner) internal view returns (uint256) {
    require(
      owner != address(0),
      "ERC721A: number minted query for the zero address"
    );
    return uint256(_addressData[owner].numberMinted);
  }

  function ownershipOf(uint256 tokenId)
    internal
    view
    returns (TokenOwnership memory)
  {
    require(_exists(tokenId), "ERC721A: owner query for nonexistent token");

    uint256 lowestTokenToCheck;
    if (tokenId >= maxBatchSize) {
      lowestTokenToCheck = tokenId - maxBatchSize + 1;
    }

    for (uint256 curr = tokenId; curr >= lowestTokenToCheck; curr--) {
      TokenOwnership memory ownership = _ownerships[curr];
      if (ownership.addr != address(0)) {
        return ownership;
      }
    }

    revert("ERC721A: unable to determine the owner of token");
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) public view override returns (address) {
    return ownershipOf(tokenId).addr;
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
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";
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
  function approve(address to, uint256 tokenId) public override {
    address owner = ERC721A.ownerOf(tokenId);
    require(to != owner, "ERC721A: approval to current owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721A: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId, owner);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) public view override returns (address) {
    require(_exists(tokenId), "ERC721A: approved query for nonexistent token");

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public override {
    require(operator != _msgSender(), "ERC721A: approve to caller");

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    _transfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
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
  ) public override {
    _transfer(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, _data),
      "ERC721A: transfer to non ERC721Receiver implementer"
    );
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   */
  function _exists(uint256 tokenId) internal view returns (bool) {
    return tokenId < currentIndex;
  }

  function _safeMint(address to, uint256 quantity) internal {
    _safeMint(to, quantity, "");
  }

  /**
   * @dev Mints `quantity` tokens and transfers them to `to`.
   *
   * Requirements:
   *
   * - there must be `quantity` tokens remaining unminted in the total collection.
   * - `to` cannot be the zero address.
   * - `quantity` cannot be larger than the max batch size.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(
    address to,
    uint256 quantity,
    bytes memory _data
  ) internal {
    uint256 startTokenId = currentIndex;
    require(to != address(0), "ERC721A: mint to the zero address");
    // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
    require(!_exists(startTokenId), "ERC721A: token already minted");
    require(quantity <= maxBatchSize, "ERC721A: quantity to mint too high");

    _beforeTokenTransfers(address(0), to, startTokenId, quantity);

    AddressData memory addressData = _addressData[to];
    _addressData[to] = AddressData(
      addressData.balance + uint128(quantity),
      addressData.numberMinted + uint128(quantity)
    );
    _ownerships[startTokenId] = TokenOwnership(to, uint64(block.timestamp));

    uint256 updatedIndex = startTokenId;

    for (uint256 i = 0; i < quantity; i++) {
      emit Transfer(address(0), to, updatedIndex);
      require(
        _checkOnERC721Received(address(0), to, updatedIndex, _data),
        "ERC721A: transfer to non ERC721Receiver implementer"
      );
      updatedIndex++;
    }

    currentIndex = updatedIndex;
    _afterTokenTransfers(address(0), to, startTokenId, quantity);
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
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
  ) private {
    TokenOwnership memory prevOwnership = ownershipOf(tokenId);

    bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
      getApproved(tokenId) == _msgSender() ||
      isApprovedForAll(prevOwnership.addr, _msgSender()));

    require(
      isApprovedOrOwner,
      "ERC721A: transfer caller is not owner nor approved"
    );

    require(
      prevOwnership.addr == from,
      "ERC721A: transfer from incorrect owner"
    );
    require(to != address(0), "ERC721A: transfer to the zero address");

    _beforeTokenTransfers(from, to, tokenId, 1);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId, prevOwnership.addr);

    _addressData[from].balance -= 1;
    _addressData[to].balance += 1;
    _ownerships[tokenId] = TokenOwnership(to, uint64(block.timestamp));

    // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
    // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
    uint256 nextTokenId = tokenId + 1;
    if (_ownerships[nextTokenId].addr == address(0)) {
      if (_exists(nextTokenId)) {
        _ownerships[nextTokenId] = TokenOwnership(
          prevOwnership.addr,
          prevOwnership.startTimestamp
        );
      }
    }

    emit Transfer(from, to, tokenId);
    _afterTokenTransfers(from, to, tokenId, 1);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits a {Approval} event.
   */
  function _approve(
    address to,
    uint256 tokenId,
    address owner
  ) private {
    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  uint256 public nextOwnerToExplicitlySet = 0;

  /**
   * @dev Explicitly set `owners` to eliminate loops in future calls of ownerOf().
   */
  function _setOwnersExplicit(uint256 quantity) internal {
    uint256 oldNextOwnerToSet = nextOwnerToExplicitlySet;
    require(quantity > 0, "quantity must be nonzero");
    uint256 endIndex = oldNextOwnerToSet + quantity - 1;
    if (endIndex > collectionSize - 1) {
      endIndex = collectionSize - 1;
    }
    // We know if the last one in the group exists, all in the group exist, due to serial ordering.
    require(_exists(endIndex), "not enough minted yet for this cleanup");
    for (uint256 i = oldNextOwnerToSet; i <= endIndex; i++) {
      if (_ownerships[i].addr == address(0)) {
        TokenOwnership memory ownership = ownershipOf(i);
        _ownerships[i] = TokenOwnership(
          ownership.addr,
          ownership.startTimestamp
        );
      }
    }
    nextOwnerToExplicitlySet = endIndex + 1;
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
      try
        IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data)
      returns (bytes4 retval) {
        return retval == IERC721Receiver(to).onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721A: transfer to non ERC721Receiver implementer");
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
   * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   */
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}

  /**
   * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
   * minting.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero.
   * - `from` and `to` are never both zero.
   */
  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}
}

/*
 *  Claim reserved NFTs 
 *  Created by entertainm.io
 */

pragma solidity ^0.8.0;

abstract contract CocktailClaimer {
    
    mapping( address => uint256 ) public stakerReserveLog;
    
    constructor() {
        setStakerAccess();
    }
    
    function setStakerAccess() internal {
      stakerReserveLog[ address(0x05a7a6234699399f0151D151D541E2c78B539683)  ] = 303;
      stakerReserveLog[ address(0x61481241bfB332757F02AF23FdC4655B555Bf9B2)  ] = 276;
      stakerReserveLog[ address(0xee6443d4eaeC0F72C721F7a714576DcF957fd67F)  ] = 210;
      stakerReserveLog[ address(0x642b339dff1B16efc62cC6c4EEC570307630E7ff)  ] = 145;
      stakerReserveLog[ address(0xc67452f4a50667f752cF41F5477488f8f5aA6B67)  ] = 100;
      stakerReserveLog[ address(0xa651b9E7d79d98cB07910Edd3e7952ebbD961f63)  ] = 92;
      stakerReserveLog[ address(0x4cBD07e1b723eC2334c5c33dFC92DA94cbF8994C)  ] = 88;
      stakerReserveLog[ address(0x8537BeFc73f2a8e3f8dB3a2314105A9F78528897)  ] = 85;
      stakerReserveLog[ address(0xfC6FcCD05A4e82C787888D9597C29527bf7310EF)  ] = 84;
      stakerReserveLog[ address(0x962Fb10CBE3E16757bFDef1863e277255a42D633)  ] = 80;
      stakerReserveLog[ address(0x3A6e48a9715AaDe7BC6b69aF435114721F9f6FE4)  ] = 78;
      stakerReserveLog[ address(0x61E1c9393CF4315638357BeCc8c75e5104EC2f01)  ] = 76;
      stakerReserveLog[ address(0x962Fb10CBE3E16757bFDef1863e277255a42D633)  ] = 73;
      stakerReserveLog[ address(0x8a305afD6521624dbd733FE41BD8Dd0Bb1eccB78)  ] = 73;
      stakerReserveLog[ address(0xF17f3Aa92518bAAA22C6cEC81744Dbb52321A4dD)  ] = 71;
      stakerReserveLog[ address(0xa8cAe97E267C10Ec56acfd9b808A284df3C4b00C)  ] = 70;
      stakerReserveLog[ address(0xd14543Be408f93559dc3017747797A5Ed251f825)  ] = 70;
      stakerReserveLog[ address(0x60314c86B99a2a108E5097fc2688AA1E3c30Be30)  ] = 68;
      stakerReserveLog[ address(0xBC54d698C48f8Da2531cC68F9Ca38aD27a1BDA4E)  ] = 68;
      stakerReserveLog[ address(0xAD4F5c944c49675cf275d8C674d9696b68B5D66D)  ] = 67;
      stakerReserveLog[ address(0x5874D43f23CafDebe7c9D913607dED8208Ed0AfA)  ] = 65;
      stakerReserveLog[ address(0xFCBE0C7c07fff72a3DCBfE69fe177515D6b5d926)  ] = 65;
      stakerReserveLog[ address(0x67eb29ED8C67C98575dD9cd49FdcE25B1218a5EE)  ] = 61;
      stakerReserveLog[ address(0x71F494b08dF932C87252B1129C24B45A5E77A9c6)  ] = 61;
      stakerReserveLog[ address(0xCA779fb29e1168321312a22CC0099BF910081F8f)  ] = 60;
      stakerReserveLog[ address(0x91F9068A506AcD5fD93399484f7D505733e65ba5)  ] = 60;
      stakerReserveLog[ address(0xc4795879b02091EDC192642A463d76A49D8CB4a6)  ] = 59;
      stakerReserveLog[ address(0xCcC596132a67c67915493BCCC9edE57fBcf64944)  ] = 56;
      stakerReserveLog[ address(0x1cf6f1A13084c8FBb750049Ed85C1FB2026792CE)  ] = 55;
      stakerReserveLog[ address(0x4505D32D3A6E42C3c9634FFa6E9a1925eD006b6d)  ] = 54;
      stakerReserveLog[ address(0x5791Aa30053389A755eB4D3D2b6Fbf4B3eBa927B)  ] = 54;
      stakerReserveLog[ address(0xA5f8756147A4ebFB40Bd32f4c789534B9Fc1E017)  ] = 53;
      stakerReserveLog[ address(0x1AC0475be8cBd5c6E547Eb5e71cDB223223a4b70)  ] = 52;
      stakerReserveLog[ address(0x0e279033eA931f98908cc52E1ABFCa60118CAeBA)  ] = 51;
      stakerReserveLog[ address(0x0c187Bc2DCcc26eD234a05e42801FA4E864Cf225)  ] = 50;
      stakerReserveLog[ address(0x86059d01E0C19e4fFb60b640D70C8bDF70082517)  ] = 49;
      stakerReserveLog[ address(0x67360FbbF936d0a16A718D136cA23e3F4910C15A)  ] = 48;
      stakerReserveLog[ address(0x1325c1F1310b8B44E450d22aa2cc72f9C6A02884)  ] = 48;
      stakerReserveLog[ address(0x02943c31E8ec7F64135D5635C54f60b377fe9c27)  ] = 47;
      stakerReserveLog[ address(0xB222147D7b97552FF3D3E8B2136f2Ccff98414A2)  ] = 46;
      stakerReserveLog[ address(0xBCCf45dE0226D4f7f102aF139E392392785a2243)  ] = 45;
      stakerReserveLog[ address(0x6744AC367Ba5F3bf3e9Fc32FB6fa0d721A1EA98a)  ] = 44;
      stakerReserveLog[ address(0x9D06117F640737B55140FF6Fa7d157748F70c946)  ] = 44;
      stakerReserveLog[ address(0x057eCa916B7207320b1916514dA3316f36546C85)  ] = 44;
      stakerReserveLog[ address(0xf71eA5dB26888f1f38E7DE3375030f32861c0803)  ] = 43;
      stakerReserveLog[ address(0x144757a24B61Cee2e593ADe64DA776759D786d73)  ] = 40;
      stakerReserveLog[ address(0xD5E35b78258118035E9A1767Fc3b0E07D2CE1234)  ] = 40;
      stakerReserveLog[ address(0x75b7328C016b840Af82Bf3fF01Daf0CDAFCec2fD)  ] = 39;
      stakerReserveLog[ address(0x4b31e16736B7c856224bffFBD0470d15F349779e)  ] = 38;
      stakerReserveLog[ address(0x05EF5F4e81Ec078F685f8e033580D3F93fF1609C)  ] = 38;
      stakerReserveLog[ address(0x8f85BDCbAD363bD67Bed3C1704B22f72e6679Eac)  ] = 38;
      stakerReserveLog[ address(0x72fa4Dba92817737FEA04430a5c5fB2D01467583)  ] = 37;
      stakerReserveLog[ address(0x618c74F416EcbC2215FC77bA4A70Da792FB5EDAF)  ] = 36;
      stakerReserveLog[ address(0x69D739E7BB3a52Fa381A9b1378a89C6A2959DfDb)  ] = 35;
      stakerReserveLog[ address(0x083578AcDA99E03B2E716676366577269943C980)  ] = 34;
      stakerReserveLog[ address(0x00aC4FBcABea927b5A56D1ef7Aa943d7e16Cd02C)  ] = 34;
      stakerReserveLog[ address(0xB6d69aa58B9eBAF211De055a3E4482c2a7074551)  ] = 34;
      stakerReserveLog[ address(0xAe3046078cd009072E131cC15564dAD94cBe985D)  ] = 34;
      stakerReserveLog[ address(0x8085840f492D93AA262059a99182952386cd5E91)  ] = 34;
      stakerReserveLog[ address(0xA678aAbf920B8B115d50b4FA72b6c6Fe692a5719)  ] = 33;
      stakerReserveLog[ address(0x1eAbb754B4a537DE37290435DAB29a2b36B2e55a)  ] = 33;
      stakerReserveLog[ address(0xC7086014ABeB5C730CC75D92F7439544039ad424)  ] = 32;
      stakerReserveLog[ address(0x9AF4b2Af4075dAb09b70A5195252EE356B2D31C0)  ] = 32;
      stakerReserveLog[ address(0x8e2a0c5A5CefBF95a04072ff5953b7F45810C2A9)  ] = 32;
      stakerReserveLog[ address(0x9683778152EddEE1636BAf20794d511461baeEd8)  ] = 31;
      stakerReserveLog[ address(0x2393930f99940f03994fEAc50704FF6F7eE521de)  ] = 31;
      stakerReserveLog[ address(0xb501F77A64Ebc732860c8f064665800C318b4847)  ] = 31;
      stakerReserveLog[ address(0xb5C00d898D3B2E776487c7E88F5b78592343309e)  ] = 31;
      stakerReserveLog[ address(0x2cEa922beDd4796265DDA912DEb2B5f61032F55F)  ] = 30;
      stakerReserveLog[ address(0xAB674D86bF1943C060cF0C3D8103A09F5299599C)  ] = 30;
      stakerReserveLog[ address(0x97EDF63009f01C259943595E65275C0A74eC9Efa)  ] = 30;
      stakerReserveLog[ address(0x860b661966De597b4154743DB5A09186fC81b565)  ] = 30;
      stakerReserveLog[ address(0x2309a6CCC10694F9811BB97e290Bb5B6675333Ce)  ] = 30;
      stakerReserveLog[ address(0x956978542459c88Da3B6573E9C6c159f67c0F955)  ] = 30;
      stakerReserveLog[ address(0x651741aD4945bE1B8fEC753168DA613FC2060c01)  ] = 29;
      stakerReserveLog[ address(0xDdA1C76e1805ACa2ed609Aec485FB43C54737075)  ] = 29;
      stakerReserveLog[ address(0x5528680C692adbfe993E4587567e69F7Ac65B12C)  ] = 29;
      stakerReserveLog[ address(0x84F1F7Ec4a5503d2A113C026d02Fc5F1EB9c899D)  ] = 29;
      stakerReserveLog[ address(0x41317e7cA1b415e3BEDA6e98346fa23e01d8D0B1)  ] = 29;
      stakerReserveLog[ address(0x27805aB336a56433397bABAFc3253d52Be8a7762)  ] = 28;
      stakerReserveLog[ address(0x6A329d74b030d0c4DD1669EAFeAeeCC534803E40)  ] = 28;
      stakerReserveLog[ address(0x01c7bc82925521e971C75eb50fE5E2b97f11F872)  ] = 28;
      stakerReserveLog[ address(0xB8cC38a0CDD8297dA6186E589aDf4D3EB41deA12)  ] = 28;
      stakerReserveLog[ address(0x62A090cb090379B6a8620BFa42577ECa1de5Aa13)  ] = 28;
      stakerReserveLog[ address(0xCf96368b5Bcf8656cE22C4df496102D9E71d279f)  ] = 28;
      stakerReserveLog[ address(0x2CE55667462e85B5D7A7a28BFaF5772199DcB666)  ] = 28;
      stakerReserveLog[ address(0xbc8944cA268E51cDB7726Ed3baB7d87C78796aAf)  ] = 27;
      stakerReserveLog[ address(0xDd8463c7e803d6A5E8711010cFfAfd977B54f744)  ] = 27;
      stakerReserveLog[ address(0xDAe527C4b4B466404055ae5BAA783454F7c5b59A)  ] = 27;
      stakerReserveLog[ address(0x892e1b672A437a89b1fDc6e310d96E8BFB16cdEf)  ] = 27;
      stakerReserveLog[ address(0x3ED9300270419eB20035fd3A18F9B3aba4A0ae23)  ] = 26;
      stakerReserveLog[ address(0x8D322ff8Dc31A44C682855979165f20b972112DB)  ] = 26;
      stakerReserveLog[ address(0x18C55b22FA947A9663438032048f9bcEc3c92e9A)  ] = 25;
      stakerReserveLog[ address(0x2cB66B548E687442E0ae603AEB1f7bCACc2A6F1f)  ] = 25;
      stakerReserveLog[ address(0xEd76E6b7E643A4476033c75Cb1f1fAeAe4cA12D9)  ] = 25;
      stakerReserveLog[ address(0xea4680339ad21382cd28ABbB274CfAC3df3E54a6)  ] = 25;
      stakerReserveLog[ address(0x4f7Cca651a6452941f617C5A461C5A55700330D7)  ] = 25;
      stakerReserveLog[ address(0xB1A30ecA11563e0F484E65cc4BbefC7715F1CE25)  ] = 25;
      stakerReserveLog[ address(0x91a693B30F5C1f04713a7228FC0676Db212dBc3F)  ] = 25;
      stakerReserveLog[ address(0x68AfA499A37878C73c2C51456a315C098B74Bd83)  ] = 24;
      stakerReserveLog[ address(0xd1c2c1eB4e3469F35769d7fb354fBD531b6e9c91)  ] = 24;
      stakerReserveLog[ address(0x4F83724a0Ec3F66e6cAc92b43916442Cf54f586d)  ] = 24;
      stakerReserveLog[ address(0x7E7c1A3541d2ff134f755ca58512B703906f2785)  ] = 24;
      stakerReserveLog[ address(0xa965dF87B467f25D7BbFA66f222bcBA299BDa3a8)  ] = 24;
      stakerReserveLog[ address(0xb2767629602Cf390168d4FFa52d283E894B01222)  ] = 24;
      stakerReserveLog[ address(0xD0BB6e64e1C6dEbADD41298E0fF39676630F03a8)  ] = 24;
      stakerReserveLog[ address(0x9C980F6069C241a5EbBE0A232F285Cce34131eF9)  ] = 24;
      stakerReserveLog[ address(0x850AF43e6728f225867aF041bc2a1E13437eC3d3)  ] = 24;
      stakerReserveLog[ address(0x207e2d5eA39cB9E38d1DD9Ba251707f1084694D8)  ] = 24;
      stakerReserveLog[ address(0xEa6f0dFd94b87Ba819310e7A430167474D0C7c6b)  ] = 24;
      stakerReserveLog[ address(0xaAA397b4Dce9AE40Aea19fD8695aC104f3bcA614)  ] = 23;
      stakerReserveLog[ address(0x64744bdF0312BAfaF82B1Fa142A1Bd72606F9Ea0)  ] = 23;
      stakerReserveLog[ address(0xf83A6d15eC451225A6B5a683BC2f85bf4dc35d13)  ] = 22;
      stakerReserveLog[ address(0x92b449114420c1b3F10324491727De57809f9Cc8)  ] = 22;
      stakerReserveLog[ address(0x104DEa01de4A993797444CC2c4619D48E76E0446)  ] = 22;
      stakerReserveLog[ address(0xcd00A56D065982ff5339A98C9f1f34f0A515A329)  ] = 22;
      stakerReserveLog[ address(0x816F81C3fA8368CDB1EaaD755ca50c62fdA9b60D)  ] = 22;
      stakerReserveLog[ address(0xb531320805C5BED1D46AEaDcF4F008FDF172DBDa)  ] = 22;
      stakerReserveLog[ address(0x00D4da27deDce60F859471D8f595fDB4aE861557)  ] = 22;
      stakerReserveLog[ address(0xb4dDF0235C74f7AF2E48f659607f6EA2F8616A5b)  ] = 21;
      stakerReserveLog[ address(0x12D7A3Fe8378E5aFce12581FfFa87d75855EB656)  ] = 21;
      stakerReserveLog[ address(0x4494d7FB34930cC147131d405bB21027Aded12f4)  ] = 21;
      stakerReserveLog[ address(0x3625645f0ceE90204F7c373aA55c1Ae262891693)  ] = 21;
      stakerReserveLog[ address(0x7754fCeA38769a9f3c3F99540d070240CA43351a)  ] = 21;
      stakerReserveLog[ address(0xE210Fa629e53721f46c9B28fE13dA66bf8a1fEFf)  ] = 21;
      stakerReserveLog[ address(0x1762DB6963c5F02EEDe0c3234d1d65B08595D032)  ] = 21;
      stakerReserveLog[ address(0x73f2Ab5dc5F47F9231149fCC24b3cBbC487D1AFb)  ] = 21;
      stakerReserveLog[ address(0x2445d9b342b8AD807d49334a0aaA928B07ba4aD4)  ] = 21;
      stakerReserveLog[ address(0x4476ab2c11b74576aa3abfAb19dde0aaDcFCA238)  ] = 21;
      stakerReserveLog[ address(0x459EE9ef16151a2946187c3139BE084D1dBA8d08)  ] = 21;
      stakerReserveLog[ address(0xf0EFedb980345dF4FC1175432B6C968efB221F80)  ] = 21;
      stakerReserveLog[ address(0x525baf5Fe2B580f8E867e45F3BC3556d6E9842E4)  ] = 21;
      stakerReserveLog[ address(0xACe9620B9Af1C0bb3ABC45E630CDEEbF2de4E023)  ] = 21;
      stakerReserveLog[ address(0xE421E19c69FFaEbE5f1548fDBa81D4b4Ad98688e)  ] = 21;
      stakerReserveLog[ address(0xa02E16777707446d626fDF1Fb17d9a9318F3EccA)  ] = 20;
      stakerReserveLog[ address(0xbB4aDec274c273818bA9473712F231a966A7F74A)  ] = 20;
      stakerReserveLog[ address(0xa73557ea8892d52E445A8c973B8a097a21189B96)  ] = 20;
      stakerReserveLog[ address(0x819fF8A68dc7440c63C5aDb810034380F3635E18)  ] = 20;
      stakerReserveLog[ address(0x4a9b4cea73531Ebbe64922639683574104e72E4E)  ] = 20;
      stakerReserveLog[ address(0x087CBAdf474d6248Ade1B06e3cC938cB34510F94)  ] = 20;
      stakerReserveLog[ address(0x00e68122d283cc3837E221cE7B2e08C1231BC269)  ] = 20;
      stakerReserveLog[ address(0xDA8D38d78589EDcf3F306ca122e1646aF913660D)  ] = 20;
      stakerReserveLog[ address(0x8fCF586D3B6fC5Bff8D2c612D56f18c2A0B992D4)  ] = 20;
      stakerReserveLog[ address(0x84F4EF52aC791aE14eE5935e4aa0427E271B347E)  ] = 20;
      stakerReserveLog[ address(0x9E6f98de1Bc2e28663492057552C5323C93A0996)  ] = 20;
      stakerReserveLog[ address(0x2455ca300C8EdfC9c96fb1FaB620621E19145233)  ] = 20;
      stakerReserveLog[ address(0xE6D860d6B04A00D55AEda46fB402a3d9A2Bce20c)  ] = 20;
      stakerReserveLog[ address(0x0c187Bc2DCcc26eD234a05e42801FA4E864Cf225)  ] = 19;
      stakerReserveLog[ address(0x086D87e70CEe08b5D33134c4445933AC9c13AC8a)  ] = 18;
      stakerReserveLog[ address(0x8EeC49C06322ad8181ca3bbAb3899507977Bb9D8)  ] = 18;
      stakerReserveLog[ address(0xD4BCE9c082e315b8E3D0A79bFB5c6daA36e9531B)  ] = 18;
      stakerReserveLog[ address(0x8D10af78548099A5b2Cf4f2ddE02CF14f6f8c2CE)  ] = 18;
      stakerReserveLog[ address(0x1Ee6FCa6b9BD318f13927a50c160C9B1ec6D7933)  ] = 18;
      stakerReserveLog[ address(0x623C04dd784cd3a937AB8511BbB165C872223A32)  ] = 18;
      stakerReserveLog[ address(0x885ADC65E090D56716fc897f4e2c505e0E620caB)  ] = 18;
      stakerReserveLog[ address(0x1a25D2e22289d4d49a98b9e5b4ed7383B106F746)  ] = 17;
      stakerReserveLog[ address(0x870Bf9b18227aa0d28C0f21689A21931aA4FE3DE)  ] = 17;
      stakerReserveLog[ address(0x9EC02aAE4653bd59aC2cE64A135c22Ade5c1856A)  ] = 17;
      stakerReserveLog[ address(0xE5E456AB0361e6Aba3325f84101F704adD175216)  ] = 17;
      stakerReserveLog[ address(0x3329dD0622d5ecA89a69e9C9D4854461136ef15b)  ] = 17;
      stakerReserveLog[ address(0xe62622CEC75cf038ff1246fB54fA88e5fA7a8D1e)  ] = 17;
      stakerReserveLog[ address(0x0783FD17d11589b59Ef7837803Bfb046c025C5Af)  ] = 16;
      stakerReserveLog[ address(0xA6f18cd918AE7b37e34aA59efC42849c1C973B9F)  ] = 16;
      stakerReserveLog[ address(0x9A55930661d1D8c594193f1CB3556c790c064781)  ] = 16;
      stakerReserveLog[ address(0x64fC6C7CAd57482844f239D9910336a03E6Ce831)  ] = 16;
      stakerReserveLog[ address(0xdbd690D439f47DFb5e76aCaDE43bAe4b9872cc70)  ] = 16;
      stakerReserveLog[ address(0x06A687b25900E4Fecb97b0212aD5590eD0467722)  ] = 16;
      stakerReserveLog[ address(0x36bD90e9785C8cffc576e70F946dEdb063Ffb418)  ] = 16;
      stakerReserveLog[ address(0xe269b26E1162B459410dC258945707720BB2b961)  ] = 16;
      stakerReserveLog[ address(0xb8E19Ee65163783CC335d158563fE867948e8005)  ] = 15;
      stakerReserveLog[ address(0xB3D5441c756dB13E3999551bd8191aB8C528e5fF)  ] = 15;
      stakerReserveLog[ address(0xf66ff43d0CF416F97eF2EACb190bC99Dc4436391)  ] = 15;
      stakerReserveLog[ address(0x0a1AA3d5C4dcae7F9b3E9F3b59EA36E4F8Fcf4f4)  ] = 15;
      stakerReserveLog[ address(0x706F652335bBE76Aae4f94bB68Fc2D8A53eF41E4)  ] = 15;
      stakerReserveLog[ address(0x6f04cc236BBdAbD0fd7A6DE77F47dc6843581151)  ] = 15;
      stakerReserveLog[ address(0x5e44357be9c3b4CeAbb30bD0E0A336608eCa0a3b)  ] = 14;
      stakerReserveLog[ address(0x59b8130B9b1Aa6313776649B17326AA668f7b7a6)  ] = 14;
      stakerReserveLog[ address(0x1180a73095e514Ac230538220828FD3C8b7a9909)  ] = 14;
      stakerReserveLog[ address(0x03F21d18402F65cEe60c9604f1C55ad6A2bf064e)  ] = 14;
      stakerReserveLog[ address(0xF86B48F340c88Af60eE0248E2e6Fd47358b62ED3)  ] = 14;
      stakerReserveLog[ address(0x91Bc36DB6925fD051A02e4dcB6804A736741e456)  ] = 13;
      stakerReserveLog[ address(0xeEcB0bA3Fb18C1Dd05228942E4b53E64E05C032B)  ] = 13;
      stakerReserveLog[ address(0x0F64B91bbb3cb3F32090a1aEC6C1B7de6381ff5a)  ] = 13;
      stakerReserveLog[ address(0xaF8B39955b7fa6497990A438b42BE5BD69D51816)  ] = 13;
      stakerReserveLog[ address(0xB18150275285BeCfcBb717f65B10Df2d211D5a02)  ] = 13;
      stakerReserveLog[ address(0x8E4544c1f65B02c8193fD6E24c127907BCfDfB8a)  ] = 13;
      stakerReserveLog[ address(0xC3EDF9a3aDB11B96Ded85E4B322D65dB127759dD)  ] = 13;
      stakerReserveLog[ address(0xcD1d1CCA481b0518639C8C6d3705A46d7a44d8FC)  ] = 13;
      stakerReserveLog[ address(0xBC058EcC77D40dB30a5AF8E1Ddc6bFA64bda195E)  ] = 12;
      stakerReserveLog[ address(0xc0234756810Da1FcE0551140C662586196f1869D)  ] = 12;
      stakerReserveLog[ address(0x18cF068bCf46fCcf4e3A3C96DC38291E03806908)  ] = 12;
      stakerReserveLog[ address(0xf43e716984D54C3D33Ee96fBB1b8F101d6c22C1C)  ] = 12;
      stakerReserveLog[ address(0xBeEA0c453B6400E56bE8394a3cAA7834b5881bb2)  ] = 12;
      stakerReserveLog[ address(0x4Fb7d58c887A7196b41B131bB1b5b50ebAc574cE)  ] = 12;
      stakerReserveLog[ address(0xb466716FE072B5D893dA56307B9063440CEd633A)  ] = 12;
      stakerReserveLog[ address(0xbA3E7a9E411feEd3CDa09aB4a8eDD3314E6b83Dd)  ] = 12;
      stakerReserveLog[ address(0xDA42629D5D0BdD2255560304043c78E7D736bc76)  ] = 12;
      stakerReserveLog[ address(0xcC6acBA2dF17134D18C94eaDa2B3399FDbfFC490)  ] = 12;
      stakerReserveLog[ address(0x5B8B6f909Eb67bCae679593E91d5bE3f14E9c5f3)  ] = 12;
      stakerReserveLog[ address(0x63C1f24400F053ff148c1476EE7d087AB108Dac3)  ] = 12;
      stakerReserveLog[ address(0xAE5559b20e871Dce1521bc2d3586E4E313BeDF34)  ] = 12;
      stakerReserveLog[ address(0x2B355cfaCd1F6453FeCe399f6399140Bc71ca437)  ] = 12;
      stakerReserveLog[ address(0x070fB67FBb8d73050C83088851e3862FfaBc15Cb)  ] = 12;
      stakerReserveLog[ address(0xbF1a53e1f37A886C68557ED827889D3AA7ED2589)  ] = 12;
      stakerReserveLog[ address(0x9f0046f1408268F302410c58bb399cd7a6865E2F)  ] = 12;
      stakerReserveLog[ address(0x7399e85324B71818D246d22fa090537Bff84e896)  ] = 11;
      stakerReserveLog[ address(0x00AfF2d72e92db35e3dB58fFCA62B3FC72B97422)  ] = 11;
      stakerReserveLog[ address(0x748C189a2321f9EeC6aa4f42e989c3Fae769bAb3)  ] = 11;
      stakerReserveLog[ address(0xAECDf6A9b599C7159803379e5F69FdCE5Fc49c2c)  ] = 11;
      stakerReserveLog[ address(0x90Ad1c591e114977cdBF2A718BC7C3D322981020)  ] = 11;
      stakerReserveLog[ address(0x4B0aeFb0cC74D521E4487084d1C9B88e35f9C80c)  ] = 11;
      stakerReserveLog[ address(0xa52d3dE9c8b0b21462F2C3A7a730C278ceC9eafC)  ] = 10;
      stakerReserveLog[ address(0xdBee763Cd99A5c443Af1971973f63f393B0bAc54)  ] = 10;
      stakerReserveLog[ address(0x1f8125672be2255C8541DeE989dbC16D3EA9304e)  ] = 10;
      stakerReserveLog[ address(0x918b84c61d5Fe6C0E57fbf6499216649Ed5C4AC1)  ] = 10;
      stakerReserveLog[ address(0x05265c4695e895177365d9AdCc291eD8ee6cfFbE)  ] = 10;
      stakerReserveLog[ address(0xc849a2a35145D609C46145F3a50e02913eD8990B)  ] = 10;
      stakerReserveLog[ address(0x86Aa372b6Dc962563D3c5eAB9c5457AE9bC56AC1)  ] = 10;
      stakerReserveLog[ address(0x69e69571d0d07EdBEde6c43849e8d877573eE6bf)  ] = 10;
      stakerReserveLog[ address(0xBD4222550deC41F66aF8B311D748dBF7c1e95768)  ] = 9;
      stakerReserveLog[ address(0x374D6392fCa56f3A96Fe6f9464d1A06B71379805)  ] = 9;
      stakerReserveLog[ address(0x3d3b44e1b9372Ff786aF1f160793AC580B2b22ae)  ] = 9;
      stakerReserveLog[ address(0x92fb6b5BC7f49b02E1d44c78FC5e671893F0E531)  ] = 9;
      stakerReserveLog[ address(0xc07fC1EA22B212AC109F951CebAAc119ccBC8413)  ] = 9;
      stakerReserveLog[ address(0xBbd5454fbA0D4269a70890A29D8A4816f439d737)  ] = 9;
      stakerReserveLog[ address(0xca31F049c9Cd8c0bc2B47FAc67aF658D6DA52a73)  ] = 9;
      stakerReserveLog[ address(0x5B4190c4376208BbCa4a27bB391425249469904E)  ] = 9;
      stakerReserveLog[ address(0xf10B2795F94dD6fE1EE70EC7c01cF071c4aDB524)  ] = 9;
      stakerReserveLog[ address(0x03bD7E336698a490EA51A4ECf2D4c06cC6ea3856)  ] = 9;
      stakerReserveLog[ address(0x483921291bBF0b5a32ECc20f698419AE55fB2eBc)  ] = 9;
      stakerReserveLog[ address(0x3d1a11dAAC4922F136d045aD85F2cAcC604A31C9)  ] = 9;
      stakerReserveLog[ address(0xeE4B71C36d17b1c70E438F8204907C5e068229cc)  ] = 8;
      stakerReserveLog[ address(0x9D47C98EB709603Aa82514F96b6EfA7939F2eDc1)  ] = 8;
      stakerReserveLog[ address(0x9886B7321D711754F9301300d4834ED839485462)  ] = 8;
      stakerReserveLog[ address(0xB7dB6634fFbF3af457d88c72f609433297cB1487)  ] = 8;
      stakerReserveLog[ address(0x1982d5A43bDcDf9C8F04a04Cf3665Fb03596Da80)  ] = 8;
      stakerReserveLog[ address(0xc52DDB928cEd386F3Fe8924CccCD71745ba11Ac9)  ] = 8;
      stakerReserveLog[ address(0xCb942dC11C304AB8F623417e26F4458c2a727fA7)  ] = 8;
      stakerReserveLog[ address(0xBd1A1fb692242676D7814dbB31a5Ee8c75EA656b)  ] = 8;
      stakerReserveLog[ address(0xfB1B0097517A29f9fDb7De750735cBC554E7791D)  ] = 8;
      stakerReserveLog[ address(0xDF8465e364C5Ba32bDB44D83B302Bd163622A263)  ] = 8;
      stakerReserveLog[ address(0xb00eC779b29C368953781B54cB231D202f388fbB)  ] = 8;
      stakerReserveLog[ address(0xc8467e8e6CF6380d99c644D3C9e183a537E90DC1)  ] = 8;
      stakerReserveLog[ address(0x140f7985c6BcC3A4c526394bd310cbc008BE4b1b)  ] = 8;
      stakerReserveLog[ address(0x5B5938604F7Ca00809f253cF6a2CFCB6Ab3F5992)  ] = 8;
      stakerReserveLog[ address(0xa7e9154dcE8c8aa1F395E17DD1F8b146aB799E4E)  ] = 8;
      stakerReserveLog[ address(0xB51E9b77d4973c4Dc3659A8d4E2fAD97F3723c73)  ] = 8;
      stakerReserveLog[ address(0x158f76b84E75B32ff3f80E026d47B3411c126250)  ] = 8;
      stakerReserveLog[ address(0x74C07Af588761e355Cc5319af150903B8333D1A4)  ] = 8;
      stakerReserveLog[ address(0x3a9C13AC4fB665cAB94A9555FF6Cc3ab4bbEDF5B)  ] = 8;
      stakerReserveLog[ address(0x1F61d37984288d815992b078B86f0f4610F79d0B)  ] = 8;
      stakerReserveLog[ address(0xcA059495aEB6a2ca3ab5Da0c6aeBa3F5944861F5)  ] = 8;
      stakerReserveLog[ address(0x49699e3eecdd72208B8B1D78CE3407F994d9f699)  ] = 7;
      stakerReserveLog[ address(0x303D80F0A4D997Fb48906772bfc6C5c0919a9319)  ] = 7;
      stakerReserveLog[ address(0x3a32affF419bC3a41c68Ddf793917CEdc6FF9Ad4)  ] = 7;
      stakerReserveLog[ address(0xF3998fd8f25Fe2Dcb53817746d3f51f78C7E35C1)  ] = 7;
      stakerReserveLog[ address(0x8925F18736637FcEac3Ed0e6D5871DF6809C5E94)  ] = 7;
      stakerReserveLog[ address(0x1499C87F66F369d5691Fe3ce807577c6f10DF992)  ] = 7;
      stakerReserveLog[ address(0xfa8ddaf49B3CB17B34F4Ab25299262fcbff5b6F5)  ] = 7;
      stakerReserveLog[ address(0xbE8050F2317417b9F9023D39776cC9dF74696131)  ] = 7;
      stakerReserveLog[ address(0xEE4925E025638cCF539c0292401d80071f7Efa24)  ] = 7;
      stakerReserveLog[ address(0x70353c3d40eA238423feBa3b7CB4be3F7406B6aE)  ] = 7;
      stakerReserveLog[ address(0xdaf749ba6328404285c7D86ccf8B01D5c1A24876)  ] = 7;
      stakerReserveLog[ address(0x838df7E0AC4EfCF27cB1C1Dd0EA18CB6cE366468)  ] = 7;
      stakerReserveLog[ address(0xC375AF9666078099A4CA193B3252Cc19F2af464B)  ] = 7;
      stakerReserveLog[ address(0xf8a6D7D51DFa46737D9010CED261155490c40Ed0)  ] = 6;
      stakerReserveLog[ address(0x8a285fa9529656864630095927335120208d3756)  ] = 6;
      stakerReserveLog[ address(0x7D55C7Dd860B2fBDa37ecAC08d7A2238CB6C03D3)  ] = 6;
      stakerReserveLog[ address(0xdDd1918AC0D873eb02feD2ac24251da75d983Fed)  ] = 6;
      stakerReserveLog[ address(0xBFF1e5D812C83C9392F45038270632CffC1Bc565)  ] = 6;
      stakerReserveLog[ address(0xb8255a69C09988D6d79083EebF538508743E7e80)  ] = 6;
      stakerReserveLog[ address(0x46d1A8BbF5bfFD0b804a83c13a719208fE2EE30c)  ] = 6;
      stakerReserveLog[ address(0x71D01033f8ffb379935C0d0e8474f45E6f92A972)  ] = 6;
      stakerReserveLog[ address(0x614F7863b421BDcDd62b5F504033957E80410555)  ] = 6;
      stakerReserveLog[ address(0x5a05cf16532d44732d11570C62c7983002795112)  ] = 6;
      stakerReserveLog[ address(0x8Cb88124230179014Ca7631b2dA5cA3bda5AbA00)  ] = 6;
      stakerReserveLog[ address(0x9DBE0cB89Fc07be11829475cEefBa667210b5797)  ] = 6;
      stakerReserveLog[ address(0x076462f6ac9cDC6995583b02f3AfE656E175580B)  ] = 6;
      stakerReserveLog[ address(0x6868B90BA68E48b3571928A7727201B9efE1D374)  ] = 6;
      stakerReserveLog[ address(0xe0B37eB3b7999642DeaD977CAD65A8b7C7e62073)  ] = 6;
      stakerReserveLog[ address(0x1D4C48320d293da6f416bb7ea444f3f638eBF464)  ] = 6;
      stakerReserveLog[ address(0xdDf6A1c1136C2B42481ad085d818F5BAbfD84849)  ] = 6;
      stakerReserveLog[ address(0x160b4A6Df57598C7e4e1B24371fA8E7EDa9244cd)  ] = 6;
      stakerReserveLog[ address(0x033b53EF4Ba5225160B78cF6CD7Ab08C8d5DBDa6)  ] = 6;
      stakerReserveLog[ address(0x53D93958403620EF1B9798f80369577aE809E1F3)  ] = 5;
      stakerReserveLog[ address(0x3cF9b27Fb14E83bf6b837C9981C961D377bB5d56)  ] = 5;
      stakerReserveLog[ address(0xC7622c949295BcBF40C4e6Ebd6F20db7Deb6746f)  ] = 5;
      stakerReserveLog[ address(0x33f065E9112D661f24C582F72688b02710795c6c)  ] = 5;
      stakerReserveLog[ address(0x43AEf37A726B41195BBe53428eF0E672aBAbba6B)  ] = 5;
      stakerReserveLog[ address(0x82c4D6Ab092A226d2e4f7c917990E0389390A3e8)  ] = 5;
      stakerReserveLog[ address(0x24855A2B42456BAdb4a628955c89388578Afb4A3)  ] = 5;
      stakerReserveLog[ address(0xAE3FA8178136D753Aae723a4dB62c9505e6477eb)  ] = 5;
      stakerReserveLog[ address(0x8b413FA207fcB8716d3E5F3b0a8880884a9fa1a7)  ] = 5;
      stakerReserveLog[ address(0xf60E43108D347Fe3B2191d76915741eacA6871B1)  ] = 5;
      stakerReserveLog[ address(0xf6fb5914115523ee81098047876F223E00Fc4Cdc)  ] = 5;
      stakerReserveLog[ address(0x2deE87d48f2ff96c284bF48f825D3f0333d89421)  ] = 5;
      stakerReserveLog[ address(0x32B461A21A88a65C29d5F88E27F986a14720E31c)  ] = 5;
      stakerReserveLog[ address(0xbB9Cba66efdb4831CA8139d76E8EB73c32C61848)  ] = 5;
      stakerReserveLog[ address(0xd4Cf55516c6b0A8e345195cdf58Acd6b83a2371F)  ] = 5;
      stakerReserveLog[ address(0x7d31bcFC94dc75823B2d08406D6a0f5aCa443989)  ] = 5;
      stakerReserveLog[ address(0x7444615a969c485A665Cd230A3d2083F38000781)  ] = 5;
      stakerReserveLog[ address(0x5ECbFfF5d7105C4bE407718BA3beEe78208b5581)  ] = 5;
      stakerReserveLog[ address(0x353c3ED77276D7c51c2AE0dE974557FdB7645CB2)  ] = 5;
      stakerReserveLog[ address(0x3722A8bBA8AeEcAcb5ef45208822bf935FBADb75)  ] = 5;
      stakerReserveLog[ address(0x0BFE9d38AE7ebB9213C4799bB82d70358F190aB6)  ] = 5;
      stakerReserveLog[ address(0x1A8EB494c2CEB2241C1572e663ff23211dEDf8Fc)  ] = 5;
      stakerReserveLog[ address(0x4C886776E556AAF3b59d3dcb4D0C8ade80C2Cb99)  ] = 5;
      stakerReserveLog[ address(0xa6aE8542F21108a84Eb065352d721e12D513F649)  ] = 5;
      stakerReserveLog[ address(0x7Fc7BfC4b36EbA867B60b62b9BB8aEacF3822062)  ] = 5;
      stakerReserveLog[ address(0xD781B34cbcE3c73f815D4a3b887c045E97BC2537)  ] = 5;
      stakerReserveLog[ address(0x32F0D391d7a2dA65E3995aF2D95192A0D07EC5ee)  ] = 5;
      stakerReserveLog[ address(0x174D444dc751433d238AD20975f01957a2C48741)  ] = 4;
      stakerReserveLog[ address(0xba75a436Eb388D6066E7859bd306669228d286F2)  ] = 4;
      stakerReserveLog[ address(0x621Ef8816661e837113b9975Fc82eA0086E8c8a4)  ] = 4;
      stakerReserveLog[ address(0x26E939aA71aea569a5df4FFCD89D618e47CaAe9F)  ] = 4;
      stakerReserveLog[ address(0x6891818d6D2fd16BAd34b49b10898EEdeefdE815)  ] = 4;
      stakerReserveLog[ address(0xd075D6339a075BdB4C5c9387abB2309e995851A6)  ] = 4;
      stakerReserveLog[ address(0x49945c2505D1330E071d49EF0c1bC724fddB650D)  ] = 4;
      stakerReserveLog[ address(0x38c86E5482BAC05Ff58A6F8EC6762E2a0DDb6Ef5)  ] = 4;
      stakerReserveLog[ address(0xD75a9fEb0dE749d2fb4C50EAc1Dc9ab561c6baa5)  ] = 4;
      stakerReserveLog[ address(0xCC1cE6B57a8DEbb3aB7cE6C1174A4EfFddf06b82)  ] = 4;
      stakerReserveLog[ address(0x048f8800D392fB97d34F813A6AC0E0F0F1ACf4FB)  ] = 4;
      stakerReserveLog[ address(0x645c829E92159CF1783744060cf86d26D9C38f5a)  ] = 4;
      stakerReserveLog[ address(0x5D6891b4451812dc670df87A63417e3d8273AE0E)  ] = 4;
      stakerReserveLog[ address(0xeAFf5514f3afaA6C398974E42F636f261ea9F617)  ] = 4;
      stakerReserveLog[ address(0xcDD38E23C7c59b5e5Ab9778c1552bE8bB3A00eab)  ] = 4;
      stakerReserveLog[ address(0xdad836760e9eeBD3d71E2Be2B5293cc360086346)  ] = 4;
      stakerReserveLog[ address(0x9Fc3c8BefB44DAAA07A66f05d3E0236B921b640A)  ] = 4;
      stakerReserveLog[ address(0xbAF45f436ae220747e449278A752017cC4708A6b)  ] = 4;
      stakerReserveLog[ address(0xC58BD7961088bC22Bb26232b7973973322E272f5)  ] = 4;
      stakerReserveLog[ address(0x7c7ec2Ef96e05582a0Bc999ba1613b2C235EfC20)  ] = 4;
      stakerReserveLog[ address(0xB040a24428A4BaB1F7DE05F017da8260d66625E2)  ] = 4;
      stakerReserveLog[ address(0x234Eb49594Be19ECc691F1E934fa27CD452ba8f1)  ] = 4;
      stakerReserveLog[ address(0x6e1eDe3BC2b7e16a48EB32b52D8De2925D907751)  ] = 4;
      stakerReserveLog[ address(0xA6D9107E7C6394141806217Dc207EbF3813b7443)  ] = 4;
      stakerReserveLog[ address(0x9Ae78e799b17F0ED3Af4C5aFCBA2cCbF5af4e905)  ] = 4;
      stakerReserveLog[ address(0xB9ACD89942Fbb70BEf9a8047858dFd3A8293c1eF)  ] = 4;
      stakerReserveLog[ address(0x81CE0B8dc0627355D75B9768304F1e7A09E125de)  ] = 4;
      stakerReserveLog[ address(0xa60b72668418Fb0d9928aE46cB79dbeb43e7C11E)  ] = 4;
      stakerReserveLog[ address(0x6E5a09e4C23A289e267aDD0207AC2F7f055147C0)  ] = 4;
      stakerReserveLog[ address(0x14861fc9b5C09A8E4c0551d122B1b6e0a662Ba30)  ] = 4;
      stakerReserveLog[ address(0x6b442eBAD72f3f400EC3C9b4Bb860E0913590456)  ] = 4;
      stakerReserveLog[ address(0xFfb8C9ec9951B1d22AE0676A8965de43412CeB7d)  ] = 4;
      stakerReserveLog[ address(0xf1db31022Ce06524E4fD36693dA2D485840b1543)  ] = 4;
      stakerReserveLog[ address(0xCf32E148528E51A62C8AA7959704D34075b2CC53)  ] = 4;
      stakerReserveLog[ address(0x55D2Fdaaa9c7358b0dE7f5c029577adF7d73702f)  ] = 4;
      stakerReserveLog[ address(0x118815Ec2Ef909dff5b9432B1f5C0f109c66176D)  ] = 4;
      stakerReserveLog[ address(0x190B11439a55Fc772E566EBa1A6D07D5b85a63D0)  ] = 4;
      stakerReserveLog[ address(0xF8DdE82f0875fCAe2F71b9c2B8e94f8f68a765C1)  ] = 4;
      stakerReserveLog[ address(0xB6354dC70143f869A1Ed0Bc7ad4B65d83d67284F)  ] = 4;
      stakerReserveLog[ address(0xC77320D1B3B4237fE0DD934Ec969483FEAeA45eD)  ] = 4;
      stakerReserveLog[ address(0x6A9af06aCC9fea0d75382FdaD8DbBaa41BbFa62d)  ] = 4;
      stakerReserveLog[ address(0x23a8F8fBA69cAad4De27feBfa883EfEa7c564bc6)  ] = 4;
      stakerReserveLog[ address(0xF69bC34B73DA823e18A6960975fB865a29B218A1)  ] = 4;
      stakerReserveLog[ address(0x064d875e4F384b5B1204F8Af98737C6f90da34e8)  ] = 4;
      stakerReserveLog[ address(0xFBd7bf4bf3EE2032848d21d6c6140C2400EC8553)  ] = 3;
      stakerReserveLog[ address(0xacc40f85dB13B527C7319e2913733C17631B39b7)  ] = 3;
      stakerReserveLog[ address(0xE1e09b606c35c61026aDF7FA7Bb33Fe6E6194064)  ] = 3;
      stakerReserveLog[ address(0x4F5B280f83B6e0453eE725cD45252110f3EaA762)  ] = 3;
      stakerReserveLog[ address(0x0Db9355ECAe0c997B45955697b4D591E2953e0b1)  ] = 3;
      stakerReserveLog[ address(0x0f8c9b0Bb3fa32f89B18E89C0B75548A81832b79)  ] = 3;
      stakerReserveLog[ address(0xeF214340E0EefD7D9ccC0FD6449fF03b04c4f305)  ] = 3;
      stakerReserveLog[ address(0xaBd5E7f0551F389b052c70d3efcbD7027E774996)  ] = 3;
      stakerReserveLog[ address(0x84a31330851D7450114F9De4673F8dCA7486d4E3)  ] = 3;
      stakerReserveLog[ address(0x448ceDfE28Ad81DC803034D98203097B4EE61E3c)  ] = 3;
      stakerReserveLog[ address(0x5b6c57D0C7959f20E900f1e71a1D691a6EC0E978)  ] = 3;
      stakerReserveLog[ address(0xd4c4dd385b97CD1d4823458BC69B579fC89a59F9)  ] = 3;
      stakerReserveLog[ address(0xC0AF213DDBB9Eb3D35912024FFE972B6640A4263)  ] = 3;
      stakerReserveLog[ address(0xc9bd8D37302bFa4CDDB8afad3a03cd187f3F2318)  ] = 3;
      stakerReserveLog[ address(0xc744Cf8f58DB2D7dEC3e9251008dE7f449E87b8c)  ] = 3;
      stakerReserveLog[ address(0xEac7705Fd1a2c1F401c129e18AfF65E4f6b4e073)  ] = 3;
      stakerReserveLog[ address(0x9fdD1691133603aC39f01654C1f5A17b8D9F7D40)  ] = 3;
      stakerReserveLog[ address(0xb5475DB885A6d3714edFf8d5ea3bE13bAd3a7319)  ] = 3;
      stakerReserveLog[ address(0x3A877A566fb0cE052e07C1B2A6bC7158FA1C23b4)  ] = 2;
      stakerReserveLog[ address(0x16Ada50F49aa18258AAB2243f0ED88676b8FAf0a)  ] = 2;
      stakerReserveLog[ address(0x07544F73A6f2c195D879d41d6237d163239aDc98)  ] = 2;
      stakerReserveLog[ address(0x45A50017FbC8D22160B36aF631aC214D580BAC59)  ] = 2;
      stakerReserveLog[ address(0x34AEbd219E365fd86497cd47290B72e702D30A82)  ] = 2;
      stakerReserveLog[ address(0xbb49FFc7344f2aBa266Abc329985014F1e3d6d1C)  ] = 2;
      stakerReserveLog[ address(0x7D86bE945E7f2524d59158f04c1B536855429068)  ] = 2;
      stakerReserveLog[ address(0x0bCb948037C91a3E98E830d91d18C682f380cc50)  ] = 2;
      stakerReserveLog[ address(0x26f3052A3Efd44754BB3061C675943CBB2B690f0)  ] = 2;
      stakerReserveLog[ address(0x12d676Db9C781ADFD1CB440ae328a538c32Da373)  ] = 2;
      stakerReserveLog[ address(0x2ECbEc5e4c300F88A957A1193bdFE6173baa39db)  ] = 2;
      stakerReserveLog[ address(0x6D45f8B052b77fF5Ba1461552a932C39E82330BA)  ] = 2;
      stakerReserveLog[ address(0x2AE0368b9c636955C93896091BF876D69665dCE4)  ] = 2;
      stakerReserveLog[ address(0xEe2982F69756867448b5A03558BE786388bf97ED)  ] = 2;
      stakerReserveLog[ address(0x3fc6C08e329954CE19384c6a70fB578791bCcC7E)  ] = 2;
      stakerReserveLog[ address(0x71626C8187912DE8376E86BB92bD572172b49eEe)  ] = 2;
      stakerReserveLog[ address(0x730CdB1402De8b7cc79067D80C375aaFd2c27591)  ] = 2;
      stakerReserveLog[ address(0x05740Bc573E9c6Bd423ac65D85D53FCb51A60DA2)  ] = 2;
      stakerReserveLog[ address(0xCe4A367116CceC25B50347387C9003305F660a61)  ] = 1;
      stakerReserveLog[ address(0x4CDe3b62417E91eED9D3f4B0eC4356Be0D734ba3)  ] = 1;
      stakerReserveLog[ address(0x5eF25c9e0E0c17257f437087A1fc629c1151c5e9)  ] = 1;
      stakerReserveLog[ address(0xa9BFef8ccfd99Eb9eC0581727843562cCD6dea04)  ] = 1;
      stakerReserveLog[ address(0xB4D9B517bdEE3D55d49aBac0D751B651954d402F)  ] = 1;
      stakerReserveLog[ address(0xcBDc0Fe85E092EEFcD292f2aeC41892CBB323EDE)  ] = 1;
      stakerReserveLog[ address(0x1AB74Bd73E80FC3368300d7EBD0f6E88ed02EfFC)  ] = 1;
      stakerReserveLog[ address(0xaF446267b0aa14258Ae8789D2dC5aEf9E9088A4b)  ] = 1;
      stakerReserveLog[ address(0xa4b6b09F63827b1823E381244e6C92E7aB41DDc5)  ] = 1;
      stakerReserveLog[ address(0x487B8E5A6b162367C9E46E9040248360C0ea6166)  ] = 1;
      stakerReserveLog[ address(0x5fdD6566c2a603925E0e077C9c342DDE7c06BF00)  ] = 1;
      stakerReserveLog[ address(0x6E47a768206673169eC07544544e37749DFA8B0D)  ] = 1;
      stakerReserveLog[ address(0x3A97B4a3F3960beDcCf3bae177612e36caBafDBa)  ] = 1;
      stakerReserveLog[ address(0xAb717EBa54aFdd7AC48BBAbE7C8223a48E9D4284)  ] = 1;
      stakerReserveLog[ address(0xDc0BD0523Ba5dE706A259EceAa597e03C7B28371)  ] = 1;
      stakerReserveLog[ address(0x2F754C908A3031348189b10a4C05C59A6F7e9077)  ] = 1;
      stakerReserveLog[ address(0x404F583833d0a05156FF6003da652B6031eBCB55)  ] = 1;
      stakerReserveLog[ address(0x63AAC522d1a29d1a4F58268b823Cad36BA764102)  ] = 1;
      stakerReserveLog[ address(0xFB5091128491B61C3298Fd18B4Cd9Be6212D78Dd)  ] = 1;
      stakerReserveLog[ address(0x4A06e76EeE09820df9ED94EA76C4c8DE06fc2818)  ] = 1;
      stakerReserveLog[ address(0x895980246D1854fE1340741a5CA0d823aFA9A98e)  ] = 1;
    }
}


pragma solidity ^0.8.0;

contract Cocktails is ERC721A, Ownable, CocktailClaimer {

    uint public MAX_TOKENS = 6969;
    string private _baseURIextended;
    bool public publicSaleIsActive = false;
    bool public stakerSaleIsActive = false;
    uint256 public basePrice;
    bool public barIsOpen;

    uint256 public cooldown = 86400;

    mapping ( uint256 => uint256 ) public mBarCooldown;
    mapping ( address => bool ) public claims;
    
    event LogCocktailDrink(address clubber, uint256 cocktailId, uint256 pricePaid);
    
    constructor() ERC721A("Cocktails", "COCKTAIL", 350, 6969) {
    }

    function cocktailClaim() public {
        require(claims[msg.sender] == false, "Address already claimed.");
        if (publicSaleIsActive) {
            if (stakerReserveLog[msg.sender] == 0) {
              require(totalSupply() + 1 <= MAX_TOKENS, "Mint exceeds the max supply of the collection.");
              claims[msg.sender] = true;
              _safeMint(msg.sender, 1);
            } else {
              require(totalSupply() + stakerReserveLog[msg.sender] <= MAX_TOKENS, "Mint exceeds the max supply of the collection.");
              claims[msg.sender] = true;
              _safeMint(msg.sender, stakerReserveLog[msg.sender]);
            }
        } else {
            require(stakerSaleIsActive, "Staker claim must be active to mint NFTs");
            require(totalSupply() + stakerReserveLog[msg.sender] <= MAX_TOKENS, "Mint exceeds the max supply of the collection.");
            require(stakerReserveLog[msg.sender] > 0, "Address has not enough cocktail tickets");
            claims[msg.sender] = true;
            _safeMint(msg.sender, stakerReserveLog[msg.sender]);
        }
    }

    function drinkCocktail(uint256 cocktailId) public payable {
        require(barIsOpen == true, "Bar is closed.");
        require(mBarCooldown[cocktailId] <= block.timestamp - cooldown, "Cooldown on cocktail active");
        require(ownerOf(cocktailId) != msg.sender, "Drinker can't use his own cocktail.");
        require(basePrice <= msg.value, "Eth value is wrong.");
        mBarCooldown[cocktailId] = block.timestamp;
        payable(ownerOf(cocktailId)).transfer(msg.value / 2);
        emit LogCocktailDrink(msg.sender, cocktailId, msg.value);
    }

    function airdropNft(address userAddress, uint numberOfTokens) public onlyOwner {
        require(totalSupply() + numberOfTokens <= MAX_TOKENS);
         _safeMint(userAddress, numberOfTokens);
    }

    function setBaseURI(string memory baseURI_) public onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function flipPublicMintState() public onlyOwner {
        publicSaleIsActive = !publicSaleIsActive;
    }

    function flipStakerSaleState() public onlyOwner {
        stakerSaleIsActive = !stakerSaleIsActive;
    }

    function changeCooldown(uint256 newCooldown) public onlyOwner {
        cooldown = newCooldown;
    }

    function getHolderTokens(address _owner) public view virtual returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function changeBasePrice(uint256 newRarityPrice) public onlyOwner {
        basePrice = newRarityPrice;
    }

    function flipBarIsOpen() public onlyOwner {
        barIsOpen = !barIsOpen;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}