/**
 *Submitted for verification at BscScan.com on 2023-05-01
*/

// Sources flattened with hardhat v2.10.1 https://hardhat.org

// File @openzeppelin/contracts/utils/introspection/[email protected]

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

// File @openzeppelin/contracts/token/ERC721/[email protected]

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
  function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// File @openzeppelin/contracts/token/ERC721/[email protected]

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

// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

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

// File @openzeppelin/contracts/utils/[email protected]

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
  function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
  function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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

// File @openzeppelin/contracts/utils/[email protected]

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

// File @openzeppelin/contracts/utils/[email protected]

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

// File @openzeppelin/contracts/utils/introspection/[email protected]

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

// File @openzeppelin/contracts/token/ERC721/[email protected]

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
  function transferFrom(address from, address to, uint256 tokenId) public virtual override {
    //solhint-disable-next-line max-line-length
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

    _transfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
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
  function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
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
  function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
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
  function _transfer(address from, address to, uint256 tokenId) internal virtual {
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
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}
}

// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

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

// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

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
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
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

// File @openzeppelin/contracts/security/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
  /**
   * @dev Emitted when the pause is triggered by `account`.
   */
  event Paused(address account);

  /**
   * @dev Emitted when the pause is lifted by `account`.
   */
  event Unpaused(address account);

  bool private _paused;

  /**
   * @dev Initializes the contract in unpaused state.
   */
  constructor() {
    _paused = false;
  }

  /**
   * @dev Returns true if the contract is paused, and false otherwise.
   */
  function paused() public view virtual returns (bool) {
    return _paused;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  modifier whenNotPaused() {
    require(!paused(), "Pausable: paused");
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  modifier whenPaused() {
    require(paused(), "Pausable: not paused");
    _;
  }

  /**
   * @dev Triggers stopped state.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  function _pause() internal virtual whenNotPaused {
    _paused = true;
    emit Paused(_msgSender());
  }

  /**
   * @dev Returns to normal state.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  function _unpause() internal virtual whenPaused {
    _paused = false;
    emit Unpaused(_msgSender());
  }
}

// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721Pausable is ERC721, Pausable {
  /**
   * @dev See {ERC721-_beforeTokenTransfer}.
   *
   * Requirements:
   *
   * - the contract must not be paused.
   */
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
    super._beforeTokenTransfer(from, to, tokenId);

    require(!paused(), "ERC721Pausable: token transfer while paused");
  }
}

// File @openzeppelin/contracts/access/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
  /**
   * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
   *
   * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
   * {RoleAdminChanged} not being emitted signaling this.
   *
   * _Available since v3.1._
   */
  event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

  /**
   * @dev Emitted when `account` is granted `role`.
   *
   * `sender` is the account that originated the contract call, an admin role
   * bearer except when using {AccessControl-_setupRole}.
   */
  event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

  /**
   * @dev Emitted when `account` is revoked `role`.
   *
   * `sender` is the account that originated the contract call:
   *   - if using `revokeRole`, it is the admin role bearer
   *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
   */
  event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

  /**
   * @dev Returns `true` if `account` has been granted `role`.
   */
  function hasRole(bytes32 role, address account) external view returns (bool);

  /**
   * @dev Returns the admin role that controls `role`. See {grantRole} and
   * {revokeRole}.
   *
   * To change a role's admin, use {AccessControl-_setRoleAdmin}.
   */
  function getRoleAdmin(bytes32 role) external view returns (bytes32);

  /**
   * @dev Grants `role` to `account`.
   *
   * If `account` had not been already granted `role`, emits a {RoleGranted}
   * event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   */
  function grantRole(bytes32 role, address account) external;

  /**
   * @dev Revokes `role` from `account`.
   *
   * If `account` had been granted `role`, emits a {RoleRevoked} event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   */
  function revokeRole(bytes32 role, address account) external;

  /**
   * @dev Revokes `role` from the calling account.
   *
   * Roles are often managed via {grantRole} and {revokeRole}: this function's
   * purpose is to provide a mechanism for accounts to lose their privileges
   * if they are compromised (such as when a trusted device is misplaced).
   *
   * If the calling account had been granted `role`, emits a {RoleRevoked}
   * event.
   *
   * Requirements:
   *
   * - the caller must be `account`.
   */
  function renounceRole(bytes32 role, address account) external;
}

// File @openzeppelin/contracts/access/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
  struct RoleData {
    mapping(address => bool) members;
    bytes32 adminRole;
  }

  mapping(bytes32 => RoleData) private _roles;

  bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

  /**
   * @dev Modifier that checks that an account has a specific role. Reverts
   * with a standardized message including the required role.
   *
   * The format of the revert reason is given by the following regular expression:
   *
   *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
   *
   * _Available since v4.1._
   */
  modifier onlyRole(bytes32 role) {
    _checkRole(role, _msgSender());
    _;
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
  }

  /**
   * @dev Returns `true` if `account` has been granted `role`.
   */
  function hasRole(bytes32 role, address account) public view override returns (bool) {
    return _roles[role].members[account];
  }

  /**
   * @dev Revert with a standard message if `account` is missing `role`.
   *
   * The format of the revert reason is given by the following regular expression:
   *
   *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
   */
  function _checkRole(bytes32 role, address account) internal view {
    if (!hasRole(role, account)) {
      revert(
        string(
          abi.encodePacked(
            "AccessControl: account ",
            Strings.toHexString(uint160(account), 20),
            " is missing role ",
            Strings.toHexString(uint256(role), 32)
          )
        )
      );
    }
  }

  /**
   * @dev Returns the admin role that controls `role`. See {grantRole} and
   * {revokeRole}.
   *
   * To change a role's admin, use {_setRoleAdmin}.
   */
  function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
    return _roles[role].adminRole;
  }

  /**
   * @dev Grants `role` to `account`.
   *
   * If `account` had not been already granted `role`, emits a {RoleGranted}
   * event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   */
  function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
    _grantRole(role, account);
  }

  /**
   * @dev Revokes `role` from `account`.
   *
   * If `account` had been granted `role`, emits a {RoleRevoked} event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   */
  function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
    _revokeRole(role, account);
  }

  /**
   * @dev Revokes `role` from the calling account.
   *
   * Roles are often managed via {grantRole} and {revokeRole}: this function's
   * purpose is to provide a mechanism for accounts to lose their privileges
   * if they are compromised (such as when a trusted device is misplaced).
   *
   * If the calling account had been granted `role`, emits a {RoleRevoked}
   * event.
   *
   * Requirements:
   *
   * - the caller must be `account`.
   */
  function renounceRole(bytes32 role, address account) public virtual override {
    require(account == _msgSender(), "AccessControl: can only renounce roles for self");

    _revokeRole(role, account);
  }

  /**
   * @dev Grants `role` to `account`.
   *
   * If `account` had not been already granted `role`, emits a {RoleGranted}
   * event. Note that unlike {grantRole}, this function doesn't perform any
   * checks on the calling account.
   *
   * [WARNING]
   * ====
   * This function should only be called from the constructor when setting
   * up the initial roles for the system.
   *
   * Using this function in any other way is effectively circumventing the admin
   * system imposed by {AccessControl}.
   * ====
   */
  function _setupRole(bytes32 role, address account) internal virtual {
    _grantRole(role, account);
  }

  /**
   * @dev Sets `adminRole` as ``role``'s admin role.
   *
   * Emits a {RoleAdminChanged} event.
   */
  function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
    bytes32 previousAdminRole = getRoleAdmin(role);
    _roles[role].adminRole = adminRole;
    emit RoleAdminChanged(role, previousAdminRole, adminRole);
  }

  function _grantRole(bytes32 role, address account) private {
    if (!hasRole(role, account)) {
      _roles[role].members[account] = true;
      emit RoleGranted(role, account, _msgSender());
    }
  }

  function _revokeRole(bytes32 role, address account) private {
    if (hasRole(role, account)) {
      _roles[role].members[account] = false;
      emit RoleRevoked(role, account, _msgSender());
    }
  }
}

// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

pragma solidity ^0.8.0;

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
  /**
   * @dev Burns `tokenId`. See {ERC721-_burn}.
   *
   * Requirements:
   *
   * - The caller must own `tokenId` or be an approved operator.
   */
  function burn(uint256 tokenId) public virtual {
    //solhint-disable-next-line max-line-length
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
    _burn(tokenId);
  }
}

// File contracts/interfaces/MHIERC20.sol

pragma solidity ^0.8.0;

interface MHIERC20 {
  function approve(address to, uint256 tokenId) external;

  function transferFrom(address from, address to, uint256 value) external;

  function transfer(address recipient, uint256 amount) external returns (bool);

  function balanceOf(address owner) external view returns (uint256 balance);

  function allowance(address owner, address spender) external view returns (uint256);

  function burn(uint256 amount) external;

  function burn(address from, uint256 amount) external;

  function burnFrom(address account, uint256 amount) external;

  function decimals() external view returns (uint8);

  function mint(address to, uint256 amount) external;

  function totalSupply() external view returns (uint256);
}

// File contracts/interfaces/IResult.sol

pragma solidity ^0.8.9;

interface IResult {
  function get(address a, uint256 b, uint256 c, uint256 d, uint256 e) external view returns (uint256);
}

// File contracts/interfaces/IBoosterData.sol

pragma solidity ^0.8.9;

/// @custom:security-contact [email protected]
interface IBoosterData {
  struct CharacterData {
    string name;
    string imageUrl;
    uint256[] traits;
    uint256 collection;
  }

  function pull(uint256 _index) external returns (CharacterData memory);

  function totalSets() external view returns (uint256);
}

// File contracts/interfaces/IPlayerBonus.sol

pragma solidity ^0.8.9;

interface IPlayerBonus {
  function bonusOf(address _playerAddress) external view returns (uint256);

  function detailedBonusOf(address _playerAddress) external view returns (uint256);

  function bonusWithFortuneOf(address account) external view returns (uint256, uint256);

  function resetBonusOf(address _playerAddress) external;

  function setStashOf(address _playerAddress, uint256 _stash) external;

  function setMythicMintsOf(address _playerAddress, uint256 _mythicMints) external;

  function incrementMythicsOf(address _playerAddress) external;

  function setSpecialOf(address _playerAddress, uint256 _special) external;

  function setAllOf(address _playerAddress, uint256 _stash, uint256 _mythicMints, uint256 _special) external;
}

// File contracts/interfaces/IMhdaoNftCharacter.sol

pragma solidity ^0.8.9;

interface IMhdaoNftCharacter {
  struct NftCharacter {
    uint256 id; // the NFT ID
    string name; // is an empty string up until the owner sets it
    string imageUrl; // is an empty string up until the owner sets it
    address owner; // the current owner
    uint256 type_; // 0 for none, 1 for mouse, 2 for ghost, 3+ for exotic
    uint256 rarity; // 0 for none, 1 for common, 2 for rare, 3 for epic, 4 for legendary, 5 for mythic, 6 for supreme
    uint256[] traits; // from 0 to 2 traits, that are numbers from 1 to 50 (initially)
    uint256[] skills; // multipliers for the farming of [sc/hc, ec/cc, nuts, crafting, advanced crafting] (all have to be acquired, all go up to 3)
    uint256 baseFarm; // how many Weis of BCT this NFT will generate per cycle
    uint256 agility; // improves Ranks
    uint256 rank; // multiplies the base farm by rank/10
    uint256 farmPerBlock; // the final farm per block
    uint256 squadId; // the squad ID this NFT is in
    uint256 collection; // the collection this NFT belongs to
  }
}

// File contracts/interfaces/IMhdaoBooster.sol

pragma solidity ^0.8.9;

interface IMhdaoBooster {
  struct Booster {
    address address_; // the address of the booster
    address boosterData; // the address of the booster data contract (has names, traits, and imageURLs); if 0x0, use the default values
    string name; // the name of the booster
    string tokensDefaultUri; // the base URI for the tokens that can be unboxed
    uint256 type_; // 1 for mouse, 2 for ghost, 3+ for exotic
    uint256 rarity; // each booster has a defined NFT rarity: it will always mint NFTs of that rarity
    uint256 baseFarmBoost; // how many Weis of BONUS BCT this NFT will generate per cycle
    bool accepted; // whether this booster is accepted by the contract
  }
}

// File contracts/interfaces/IMhdaoPlayer.sol

pragma solidity ^0.8.9;

interface IMhdaoPlayer {
  struct Player {
    uint256 bctToClaim; // available to claim
    uint256 etherealBct; // cannot be withdrawn
    uint256 lastWithdrawalBlock; // last withdraw block
    uint256 registeredAt; // when the player registered (block number)
    address mentor; // the player's mentor gets 0.5% of the player's farmed BCT (extra, not taking from the player)
    uint256 mentorLevel; // multiplies the mentor's reward by mentorLevel, starts at 1 and goes up to 10
    uint256 merchantLevel; // identifies merchants, the higher, the more fees they collect
    uint256[] squads; // a dynamic list of Squad Ids
  }
}

// File contracts/interfaces/IMhdaoFarmSimplified.sol

pragma solidity ^0.8.9;

interface IMhdaoFarmSimplified {
  function recalculateSquadFarming(uint256 squadIndex) external;

  function isSquadOnQuest(uint256 squadIndex) external view returns (bool);

  function addTo(address playerAddress, uint256 amount, uint256[] memory _resources) external;

  function mentorOf(address playerAddress) external view returns (address mentor, uint256 mentorLevel);

  function getPlayer(address playerAddress) external view returns (IMhdaoPlayer.Player memory);

  function payWithBalance(
    address account,
    uint256 bctAmount,
    uint256[] memory _resources
  ) external returns (uint256[] memory);

  function spendBctFrom(address account, uint256 amount, bool ethereal) external;
}

// File contracts/utils/AntiMevLock.sol

pragma solidity 0.8.9;

contract AntiMevLock {
  uint256 public lockPeriod; // in blocks
  mapping(address => uint256) internal _lockedUntil;

  modifier onlyUnlockedSender() {
    require(!_isMevLocked(msg.sender), "cooldown");
    _mevLock(msg.sender);
    _;
  }

  modifier onlyUnlocked(address account) {
    require(!_isMevLocked(account), "cooldown");
    _mevLock(account);
    _;
  }

  function _setLockPeriod(uint256 _lockPeriod) internal {
    lockPeriod = _lockPeriod;
  }

  function _mevLock(address account) internal {
    _lockedUntil[account] = block.number + lockPeriod;
  }

  function _mevUnlock(address account) internal {
    _lockedUntil[account] = 0;
  }

  function _isMevLocked(address account) internal view returns (bool) {
    return _lockedUntil[account] > block.number;
  }
}

// File contracts/erc721/MhdaoNft.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//import "../interfaces/IMhdaoMigrationCharacter.sol";

/**
 * @title MHDAO NFT
 * @dev This is an ERC721 that knows how to crack boosters open
 * in order to mint new tokens. We call that "unboxing". Boosters
 * are trusted ERC20 contracts.
 */
contract MhdaoNft is AntiMevLock, AccessControl, ERC721Enumerable, ERC721Burnable, ERC721Pausable {
  bytes32 private constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
  bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 private constant BURNER_ROLE = keccak256("BURNER_ROLE");
  bytes32 private constant UPDATER_ROLE = keccak256("UPDATER_ROLE");
  bytes32 private constant MIGRATOR_ROLE = keccak256("MIGRATOR_ROLE");
  uint256 private constant DEFAULT_MIN_BASE_FARM = 200 * 1E9; // 200 gwei
  uint256 private constant MAX_AGILITY = 5;
  uint256 private constant AGILITY_CEILING = 6;

  MHIERC20 public oldMouseHero;
  MHIERC20 public oldGhostVillain;
  IPlayerBonus public playerBonus;
  IMhdaoFarmSimplified public farm;

  uint256 public tokenIdTracker;
  IResult private _result;

  string public baseTokenURI;

  uint256 public totalNumberOfTraits; // total number of traits that exist

  /// @notice NFTs minted by this contract, along with their metadata
  mapping(uint256 => IMhdaoNftCharacter.NftCharacter) public nftCharacters;

  /// @notice Users may unbox one of these booster boxes
  mapping(address => IMhdaoBooster.Booster) public boosters;

  /// @notice The rarity factor for each rarity level
  mapping(uint256 => uint256) public rarityAndTypeFactor;

  /// @notice lentFrom is the address that lent the NFT to the player
  mapping(uint256 => address) public lentFrom;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _baseTokenURI,
    address _resultAddress,
    address _oldMouseContract,
    address _oldGhostContract,
    uint256 _lockPeriod
  ) ERC721(_name, _symbol) {
    baseTokenURI = _baseTokenURI;

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(OPERATOR_ROLE, msg.sender);
    _setupRole(MINTER_ROLE, msg.sender);
    _setupRole(BURNER_ROLE, msg.sender);
    _setupRole(UPDATER_ROLE, msg.sender);

    rarityAndTypeFactor[1] = 1; // Common
    for (uint256 i = 1; i < 10; i++) {
      // Up to rarity 10, (1023 as multiplier is the max value)
      rarityAndTypeFactor[i + 1] = 2 ** (i + 1) - 1;
    }

    _result = IResult(_resultAddress);

    oldMouseHero = MHIERC20(_oldMouseContract);
    oldGhostVillain = MHIERC20(_oldGhostContract);

    totalNumberOfTraits = 50;

    _setLockPeriod(_lockPeriod);
  }

  //////////////////////////
  // Getters
  function getBooster(address boosterAddress) public view returns (IMhdaoBooster.Booster memory) {
    return boosters[boosterAddress];
  }

  function getNft(uint256 tokenId) public view returns (IMhdaoNftCharacter.NftCharacter memory) {
    return nftCharacters[tokenId];
  }

  function getNfts(uint256[] memory tokenIds) public view returns (IMhdaoNftCharacter.NftCharacter[] memory) {
    IMhdaoNftCharacter.NftCharacter[] memory nfts = new IMhdaoNftCharacter.NftCharacter[](tokenIds.length);

    for (uint i = 0; i < tokenIds.length; i++) {
      nfts[i] = nftCharacters[tokenIds[i]];
    }

    return nfts;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    return nftCharacters[tokenId].imageUrl;
  }

  function squadOf(uint256 tokenId) external view returns (uint256) {
    return nftCharacters[tokenId].squadId;
  }

  function farmPerBlockOf(uint256 tokenId) external view returns (uint256) {
    return nftCharacters[tokenId].farmPerBlock;
  }

  function rarityOf(uint256 tokenId) external view returns (uint256) {
    return nftCharacters[tokenId].rarity;
  }

  function typeOf(uint256 tokenId) external view returns (uint256) {
    return nftCharacters[tokenId].type_;
  }

  function rarityTypeAndSkillsOf(uint256 tokenId) external view returns (uint256, uint256, uint256[] memory) {
    return (nftCharacters[tokenId].rarity, nftCharacters[tokenId].type_, nftCharacters[tokenId].skills);
  }

  function rarityTypeRankAndSkillsOf(
    uint256 tokenId
  ) external view returns (uint256, uint256, uint256, uint256[] memory) {
    return (
      nftCharacters[tokenId].rarity,
      nftCharacters[tokenId].type_,
      nftCharacters[tokenId].rank,
      nftCharacters[tokenId].skills
    );
  }

  function traitsOf(uint256 tokenId) external view returns (uint256[] memory) {
    return nftCharacters[tokenId].traits;
  }

  /**
   * @notice Lists all the NFTs IDs owned by `_owner`
   * @param _owner The address to consult
   * @return A list of NFT IDs belonging to `_owner`
   */
  function tokensOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(_owner);
    uint256[] memory tokensId = new uint256[](tokenCount);
    for (uint256 i = 0; i < tokenCount; i++) {
      tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }

    return tokensId;
  }

  /**
   * @notice Returns all NFTs owned by `_owner` along with their metadata
   * @param _owner The address to consult
   * @return A list of NFTs belonging to `_owner`
   */
  function nftsOfOwner(address _owner) external view returns (IMhdaoNftCharacter.NftCharacter[] memory) {
    uint256 tokenCount = balanceOf(_owner);
    IMhdaoNftCharacter.NftCharacter[] memory nfts = new IMhdaoNftCharacter.NftCharacter[](tokenCount);
    for (uint256 i = 0; i < tokenCount; i++) {
      nfts[i] = getNft(tokenOfOwnerByIndex(_owner, i));
    }

    return nfts;
  }

  function paginatedNftsOfOwner(
    address _owner,
    uint256 page,
    uint256 pageSize
  ) external view returns (IMhdaoNftCharacter.NftCharacter[] memory) {
    uint256 tokenCount = balanceOf(_owner);
    uint256 startingIndex = page * pageSize;

    require(startingIndex < tokenCount);

    uint256 limit = startingIndex + pageSize;
    if (limit > tokenCount) {
      limit = tokenCount;
    }

    IMhdaoNftCharacter.NftCharacter[] memory nfts = new IMhdaoNftCharacter.NftCharacter[](pageSize);
    for (uint256 i = startingIndex; i < limit; i++) {
      nfts[i] = getNft(tokenOfOwnerByIndex(_owner, i));
    }

    return nfts;
  }

  function isOnQuest(uint256 tokenId) public view returns (bool) {
    if (nftCharacters[tokenId].squadId == 0) return false;

    return farm.isSquadOnQuest(nftCharacters[tokenId].squadId);
  }

  function collectionOf(uint256 tokenId) external view returns (uint256) {
    return nftCharacters[tokenId].collection;
  }

  /// @dev Mandatory override
  function supportsInterface(
    bytes4 interfaceId
  ) public view override(AccessControl, ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  //////////////////////////
  // User-called Functions
  /**
   * @notice Burns 1 booster `boosterAddress` in exchange for 1 NFT
   * @param boosterAddress The address of the booster
   */
  function unboxBooster(address boosterAddress) public whenNotPaused onlyUnlockedSender {
    // Get the booster's data
    IMhdaoBooster.Booster memory booster = boosters[boosterAddress];
    // Make sure we accept the booster
    require(booster.accepted, "invB");
    _mevLock(msg.sender);

    // BurnFrom the booster, fail hard if it can't
    MHIERC20 trustedBoosterContract = MHIERC20(boosterAddress);
    trustedBoosterContract.burn(msg.sender, 100); // 100 cents

    string memory _name;
    string memory _imageUrl;
    uint256[] memory _traits;
    uint256 _collection;
    if (booster.boosterData != address(0)) {
      IBoosterData boosterData = IBoosterData(booster.boosterData);
      uint256 result = _result.get(msg.sender, 1, boosterData.totalSets(), 357, balanceOf(msg.sender));
      IBoosterData.CharacterData memory charData = boosterData.pull(result);
      _name = charData.name;
      _imageUrl = charData.imageUrl;
      _traits = charData.traits;
      _collection = charData.collection;
    } else {
      _name = "";
      _imageUrl = "";
      _traits = _rollTraits(msg.sender, booster.rarity);
    }

    _newNftChar(_name, _imageUrl, msg.sender, booster.type_, booster.rarity, 0, _traits, _collection, tokenIdTracker);

    _doMint(msg.sender);
  }

  function migrateFromMouseHaunt(
    address from,
    uint256[][] memory characters,
    bool force
  ) public onlyRole(MIGRATOR_ROLE) {
    for (uint256 i = 0; i < characters.length; i++) {
      uint256[] memory character = characters[i];
      // if it's a mouse, burn from the mice contract; if it's a ghost, burn from the ghosts contract
      if (!force) {
        if (character[1] == 1) {
          oldMouseHero.burn(character[0]);
        } else if (character[1] == 2) {
          oldGhostVillain.burnFrom(from, character[0]);
        }
      }

      // Bonus farm for the first 100 characters of each type
      uint256 farmBoost = character[0] < 100 ? 100 - character[0] : 0;

      // the collection or genesis bonus in 10%s; reindeer gives 30% bonus, genesis 30% bonus, christmas 10% bonus
      farmBoost += 10 * character[4];

      // create the traits array
      uint256[] memory traits = new uint256[](2);
      traits[0] = character[5];
      traits[1] = character[6];

      // An empty name and/or image means that the website will use the default ones for the type
      uint256 id = i + tokenIdTracker;
      _newNftChar("", "", from, character[1], character[2], character[3] * 5, traits, 0, id);

      if (farmBoost > 0) {
        nftCharacters[id].baseFarm += (nftCharacters[id].baseFarm * farmBoost) / 100;
        nftCharacters[id].farmPerBlock = _calculateFarmPerBlock(id);
      }
    }

    _mintMany(from, characters.length);
    uint256[] memory res = new uint256[](2);

    uint256 lootBonus = characters.length * 10;
    res[0] = lootBonus; // Super Cheese
    res[1] = lootBonus; // Shiny Fish
    farm.addTo(from, characters.length * 300 * 1E18, res);
  }

  //////////////////////////
  // UPDATER functions
  function lendTo(address from, address to, uint256 tokenId) public onlyRole(UPDATER_ROLE) {
    lentFrom[tokenId] = from;
    _transfer(from, to, tokenId);
  }

  function backToOwner(uint256 tokenId) public onlyRole(UPDATER_ROLE) {
    address borrower = lentFrom[tokenId];
    lentFrom[tokenId] = address(0);
    address owner = ownerOf(tokenId);
    _transfer(owner, borrower, tokenId);
  }

  /**
   * @notice Used by other MH systems, such as Sacrifice, to burn old NFTs and mint new NFTs
   * @param account The address to burn from
   * @param tokenId The tokenId to burn
   */
  function burnFrom(address account, uint256 tokenId) public onlyRole(BURNER_ROLE) {
    require(ownerOf(tokenId) == account, "owner");

    _burn(tokenId);
  }

  function setRank(uint256 tokenId, uint256 newRank) public onlyRole(UPDATER_ROLE) {
    require(!isOnQuest(tokenId), "onQ");

    nftCharacters[tokenId].rank = newRank;
    nftCharacters[tokenId].farmPerBlock = _calculateFarmPerBlock(tokenId);

    _updateSquadFarming(tokenId);
  }

  function setCollection(uint256 tokenId, uint256 newCollection) public onlyRole(UPDATER_ROLE) {
    require(!isOnQuest(tokenId), "onQ");

    nftCharacters[tokenId].collection = newCollection;

    _updateSquadFarming(tokenId);
  }

  function setTraits(uint256 tokenId, uint256[] memory traits) public onlyRole(UPDATER_ROLE) {
    require(!isOnQuest(tokenId), "onQ");

    nftCharacters[tokenId].traits = traits;

    _updateSquadFarming(tokenId);
  }

  function setAgility(uint256 tokenId, uint256 _agility) external onlyRole(UPDATER_ROLE) {
    require(!isOnQuest(tokenId), "onQ");
    require(_agility <= MAX_AGILITY, "max");

    nftCharacters[tokenId].agility = _agility;
    nftCharacters[tokenId].farmPerBlock = _calculateFarmPerBlock(tokenId);

    _updateSquadFarming(tokenId);
  }

  function setNameAndImage(
    uint256 tokenId,
    string memory newName,
    string memory newImageUrl
  ) external onlyRole(UPDATER_ROLE) {
    nftCharacters[tokenId].name = newName;
    nftCharacters[tokenId].imageUrl = newImageUrl;
  }

  function rerollTraits(uint256 tokenId) external onlyRole(UPDATER_ROLE) {
    require(!isOnQuest(tokenId), "onQ");

    uint256 numberOfTraits = nftCharacters[tokenId].traits.length;
    uint fakeRarity;
    if (numberOfTraits <= 2) {
      fakeRarity = 2; // will reroll 2 traits
    } else {
      fakeRarity = 5; // will reroll 3 traits
    }

    nftCharacters[tokenId].traits = _rollTraits(ownerOf(tokenId), nftCharacters[tokenId].rarity);
    _updateSquadFarming(tokenId);
  }

  function legendaryRerollTraits(uint256 tokenId, uint256 chosenTrait) external onlyRole(UPDATER_ROLE) {
    require(!isOnQuest(tokenId), "onQ");

    nftCharacters[tokenId].traits = _rollTraits(ownerOf(tokenId), nftCharacters[tokenId].rarity);
    nftCharacters[tokenId].traits[0] = chosenTrait;

    _updateSquadFarming(tokenId);
  }

  function setSquad(uint256 tokenId, uint256 squadId) external onlyRole(UPDATER_ROLE) {
    nftCharacters[tokenId].squadId = squadId;
  }

  function setBaseFarm(uint256 tokenId, uint256 newBaseFarm) external onlyRole(UPDATER_ROLE) {
    nftCharacters[tokenId].baseFarm = newBaseFarm;
    nftCharacters[tokenId].farmPerBlock = _calculateFarmPerBlock(tokenId);

    _updateSquadFarming(tokenId);
  }

  function setRarityAndType(
    uint256 tokenId,
    uint256 newRarity,
    uint256 newType_,
    uint256 newBaseFarm
  ) external onlyRole(UPDATER_ROLE) {
    IMhdaoNftCharacter.NftCharacter storage character = nftCharacters[tokenId];
    character.rarity = newRarity;
    character.type_ = newType_;
    character.baseFarm = newBaseFarm;
    character.farmPerBlock = _calculateFarmPerBlock(tokenId);

    _updateSquadFarming(tokenId);
  }

  function setSkills(uint256 tokenId, uint256[] memory _skills) external onlyRole(UPDATER_ROLE) {
    nftCharacters[tokenId].skills = _skills;
  }

  function setRankAgilityAndSkills(
    uint256 tokenId,
    uint256 _rank,
    uint256 _agility,
    uint256[] memory skills
  ) external onlyRole(UPDATER_ROLE) {
    nftCharacters[tokenId].rank = _rank;
    nftCharacters[tokenId].agility = _agility;
    nftCharacters[tokenId].skills = skills;
  }

  function mint(
    string memory _name,
    string memory _imageUrl,
    address _owner,
    uint256 type_,
    uint256 _rarity,
    uint256 _rank,
    uint256[] memory _traits,
    uint256 _collection
  ) external onlyRole(UPDATER_ROLE) {
    _newNftChar(_name, _imageUrl, _owner, type_, _rarity, _rank, _traits, _collection, tokenIdTracker);
    _doMint(_owner);
  }

  //////////////////////////
  // Internal functions
  function _newNftChar(
    string memory _name,
    string memory _imageUrl,
    address _owner,
    uint256 type_,
    uint256 _rarity,
    uint256 _rank,
    uint256[] memory _traits,
    uint256 _collection,
    uint256 _id
  ) private {
    uint256 baseFarm = _getBaseFarm(type_, _rarity);

    uint256[] memory skills = new uint256[](4);
    skills[0] = 1;
    skills[1] = 1;
    skills[2] = 0;
    skills[3] = 0;

    nftCharacters[_id] = IMhdaoNftCharacter.NftCharacter({
      id: _id,
      name: _name,
      imageUrl: _imageUrl,
      owner: _owner,
      type_: type_,
      rarity: _rarity,
      traits: _traits,
      skills: skills,
      baseFarm: baseFarm,
      agility: 0,
      rank: _rank,
      farmPerBlock: _calculateFarmPerBlock(baseFarm, _rank, 0),
      squadId: 0,
      collection: _collection
    });

    if (_rarity >= 5) {
      // call the incrementMythics in playerBonus
      playerBonus.incrementMythicsOf(_owner);
    }
  }

  function _updateSquadFarming(uint256 tokenId) internal {
    if (nftCharacters[tokenId].squadId != 0) {
      farm.recalculateSquadFarming(nftCharacters[tokenId].squadId);
    }
  }

  function _doMint(address to) private {
    uint256 id = tokenIdTracker;
    tokenIdTracker++;
    _mint(to, id);
  }

  function _mintMany(address to, uint256 amount) private {
    uint256 id = tokenIdTracker;

    for (uint256 i = 0; i < amount; i++) {
      _mint(to, id++);
    }

    tokenIdTracker = id;
  }

  // Farm per block without rank and synergy
  function _getBaseFarm(uint256 type_, uint256 rarity) private view returns (uint256) {
    return DEFAULT_MIN_BASE_FARM * rarityAndTypeFactor[rarity] * rarityAndTypeFactor[type_];
  }

  function _rollTraits(address to, uint256 rarity) private view returns (uint256[] memory) {
    uint256 traitCount = _traitCountByRarity(rarity);
    uint256[] memory traits = new uint256[](traitCount);

    for (uint256 i = 0; i < traitCount; i++) {
      traits[i] = (_result.get(to, 1, totalNumberOfTraits, 2 + i, balanceOf(to)));
    }

    return traits;
  }

  function _traitCountByRarity(uint256 rarity) private pure returns (uint256) {
    if (rarity == 1) {
      return 1;
    } else if (rarity >= 2 && rarity <= 4) {
      return 2;
    } else {
      return 3;
    }
  }

  // Farm per block with rank and agility
  function _calculateFarmPerBlock(uint256 tokenId) internal view returns (uint256) {
    IMhdaoNftCharacter.NftCharacter memory nftCharacter = nftCharacters[tokenId];

    return _calculateFarmPerBlock(nftCharacter.baseFarm, nftCharacter.rank, nftCharacter.agility);
  }

  // Overload with all params
  function _calculateFarmPerBlock(uint256 baseFarm, uint256 rank, uint256 agility) internal pure returns (uint256) {
    return baseFarm + ((baseFarm * rank) / 10) / (AGILITY_CEILING - agility);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
    super._beforeTokenTransfer(from, to, tokenId);
    require(nftCharacters[tokenId].squadId == 0, "inSquad");
    require(lentFrom[tokenId] == address(0), "lent");
  }

  //////////////////////////
  // OPERATOR functions
  /**
   * @notice Recovers any ERC20 tokens that were mistakenly sent to this contract
   * @param tokenAddress The address of the token to recover
   * @param to The address to send the tokens to
   * @param amount The amount of tokens to send
   */
  function recoverERC20(address tokenAddress, address to, uint256 amount) external onlyRole(OPERATOR_ROLE) {
    MHIERC20(tokenAddress).transfer(to, amount);
  }

  /**
   * @notice Recovers any ERC721 that was mistakenly sent to this contract
   * @param tokenAddress The address of the token to recover
   * @param to The address to send the ERC721 to
   * @param tokenId The tokenId of ERC721 to send
   */
  function recoverERC721(address tokenAddress, address to, uint256 tokenId) external onlyRole(OPERATOR_ROLE) {
    IERC721(tokenAddress).safeTransferFrom(address(this), to, tokenId);
  }

  function pause() external onlyRole(OPERATOR_ROLE) {
    _pause();
  }

  /**
   * @notice Allow a pauser to unpause the contract
   */
  function unpause() external onlyRole(OPERATOR_ROLE) {
    _unpause();
  }

  /**
   * @notice Define the accepted booster boxes
   * @param boosterList List containing the boosters objects
   */
  function setAcceptedBoosters(IMhdaoBooster.Booster[] memory boosterList) external onlyRole(OPERATOR_ROLE) {
    for (uint256 i = 0; i < boosterList.length; i++) {
      boosters[boosterList[i].address_] = boosterList[i];
    }
  }

  function setFarm(address _farm) external onlyRole(OPERATOR_ROLE) {
    farm = IMhdaoFarmSimplified(_farm);
  }

  function setPlayerBonus(address _playerBonus) external onlyRole(OPERATOR_ROLE) {
    playerBonus = IPlayerBonus(_playerBonus);
  }

  function setOldContracts(address mouse, address ghost) external onlyRole(OPERATOR_ROLE) {
    oldMouseHero = MHIERC20(mouse);
    oldGhostVillain = MHIERC20(ghost);
  }
}