/**
 *Submitted for verification at Etherscan.io on 2022-10-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function UintToString(uint256 value) internal pure returns (string memory) {
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

  uint256 private currentIndex = 0;

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
        ? string(abi.encodePacked(baseURI, tokenId.UintToString()))
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

//Behold, I present to you... The Code
contract Code is ERC721A, Ownable {

  using Strings for uint256;

  string[555] internal Codes = [
    "LO","FIRST!","PSSST.... PSSST... YOU WANNA MAKE SOME REAL MOTHERFUCKIN MONEY?","HODL","RUB THE SCREEN TO CLAIM YOUR 3 WISHES","APES. TOGETHER. STRONG.","BLESSED BE THY INVESTMENT PORTFOLIO","WILL YOU KEEP ME SAFE?","THERE IS NO 'I' IN WAGMI","A MAN MUST HAVE A CODE","SELL THIS AND BUY YOURSELF A SPACESHIP SON",":)","HOW DO YOU DO FELLOW KIDS?","I CAN DO ANYTHING","I'M THE KING OF THE WORLD!","YOU ARE THE SPECIAL, MOST EXTRAORDINARY PERSON IN THE UNIVERSE!","I LOVE MY MOM","THE FUTURE IS NOW OLD MAN","WHAT IF I TOLD YOU, YOU ARE IN A SIMULATION RIGHT NOW","I'M NOT A QUITTER","THE JOURNEY OF A THOUSAND MILES BEGINS WITH ONE STEP","STOP PAPERING","WHAT AM I WORTH TO YOU?","OH NO SOMETHING WENT WRONG! YOU WEREN'T SUPPOSED TO GET THIS!","YOU KNOW, I'M SOMETHING OF AN NFT MYSELF","I WON'T FUD","GO TOUCH GRASS","WHATEVER YOU CHOOSE TO DO IN LIFE, YOU'LL BE GREAT AT IT","DON'T WORRY! WE ARE TRYING TO GET YOU OUT OF THE SIMULATION","BUY THE DIP","NFT OWNER GETS ALL THE ETH THEY LIST FOR","IF I DIE, DELETE MY BROWSER HISTORY","LETS PUT A SMILE ON THAT FACE","GM","BEFORE DOING ANYTHING, ASK YOURSELF... WOULD AN IDIOT DO THIS?","I WANT US TO BE EXCLUSIVE","BOOM! BIG REVEAL! I TURNED MYSELF INTO AN NFT!","I'VE CAUGHT A BAD CASE OF THE FOMO","WORLD'S BEST DAD!","FORTUNE FAVORS THE BRAVE","I'M AWESOME","THIS NFT WILL GRANT YOU THE POWER OF IMMORTALITY","THIS NFT LOVES YOU","MAY THE FORCE BE WITH YOU","FEAR WILL NOT RULE ME","I CAME BACK FROM THE FUTURE TO TELL MY PAST SELF TO BUY THIS","MO MONEY, MO PROBLEMS","I DON'T UNDERCUT THE FLOOR, I LET THE FLOOR COME TO ME","I AM SATOSHI NAKAMOTO","IT'S ONE SMALL STEP FOR A MAN, ONE GIANT LEAP FOR MANKIND","TODAY IS GOING TO BE A GREAT DAY","LIFE HACK: IF YOU DON'T TRY, YOU CAN'T FAIL... RIGHT? RIGHT???","IT DOESN'T HAPPEN TO EVERY GUY","THIS TEXT IS UNAVAILABLE AT THIS TIME, CHECK BACK LATER","I TOLD YOU SO","WE SHALL OVERCOME","OH YEAH BABY","I BOUGHT THIS NFT AND THEN MY FATHER TOLD ME HE WAS PROUD OF ME","WELCOME TO THE REAL WORLD. IT SUCKS. YOU'RE GONNA LOVE IT.","OH GOSH LOOK AT THE TIME IT'S 4:20 SOMEWHERE","IF YOU HIDE UNDER A BLANKET, THE GHOSTS CAN'T GET TO YOU","BUY LOW, SELL HIGH","ON BEHALF OF THE COMMUNITY, I THANK YOU FOR YOUR PURCHASE","YOU KNOW WHAT MUST BE DONE","DRUGS ARE BAD, MMKAY","NO SACRIFICE, NO VICTORY","FUGAYZI, FUGAZI. IT'S A WHAZY. IT'S A WOOZIE. IT'S FAIRY DUST!","I'M A GAMER GIRL, IF YOU BUY THIS NFT I'LL BE YOUR GIRLFRIEND","I'M A VIRGIN","NICE","WHAT'S THE WORST THAT CAN HAPPEN?","MY STRANGE ADDICTION IS THAT I CAN'T STOP MINTING NFTS","DON'T YOU DARE","YOU CAN'T HANDLE THE TRUTH!","YOU'RE SUCH A GOOD FREN","NEVER GONNA SAY GOODBYE","CARPE DIEM","5G TOWERS SPREAD COVID","WORLD'S BEST MOM!","IT IS NEVER TOO LATE TO BE WHO YOU MIGHT HAVE BEEN","DO THE RIGHT THING","IT'S GLUTEN-FREE","DEEZ NFTS","WE ARE ALL EQUALS","DON'T WORRY, YOU GOT A GOOD ONE","CATCH ME OUTSIDE HOW BOUT THAT","I'M SPEECHLESS","YO, CAN YOU HOLD THIS BAG REAL QUICK? BRB","SEIZE THE DAY","SEND NUDE NFTS","LOOK INSIDE","I AM THE ALPHA MALE","THEY THOUGHT I WAS A JOKE","YOU CAN'T LIVE LIFE WITHOUT A CODE","I AM A SHAPE-SHIFTING LIZARD","I WANT YOU TO DEAL WITH YOUR PROBLEMS BY BECOMING RICH!","FUCK ME! NO I MEAN REALLY. PLEASE FUCK ME. I HAVE MONEY!","ALIENS INVADED THE MOON ON JULY 20TH, 1969","I'M A DEGEN","THIS IS THE WAY","I'M BATMAN","MY FATHER THINKS THIS IS A BAD INVESTMENT","TAKE A CHILL PILL","LOVE YOURSELF","SMOKING KILLS","EXCUSE ME, I'M VEGAN","WHAT IF WE USED 100 PERCENT OF OUR BRAINS?","I ACTUALLY LIKED THE BEE MOVIE","PEACE BE UPON YOU","BROS BEFORE HOES","FINANCIAL ADVICE: BUY THE CODE",":!","MAKE YOUR DREAMS COME TRUE","THIS IS GOING TO 0","I DON'T KNOW WHAT TO DO! MY WHOLE BRAIN IS CRYING!","OMAE WA MOU SHINDERU!","PLACEHOLDER","I BOUGHT THIS NFT FROM AN IDIOT","ROADS? WHERE WE'RE GOING WE DON'T NEED ROADS","STOP PUTTING IT OFF","I AM THE DANGER","TRUE BEAUTY IS ON THE INSIDE","I'M WORTH IT! YOU'LL SEE. YOU'LL ALL SEE!","I LOST MY SEED PHRASE! HAS ANYONE SEEN MY LITTLE PONY NOTEBOOK?","10 OUT OF 10 BEST NFT EVER!","SOMETIMES I START A SENTENCE AND I DON'T KNOW WHERE IT'S GOING","I'M NOT A VAMPIRE I JUST LIKE DRINKING WINE AND GOING OUT LATE","HELP! I'M BEING HELD IN THIS WALLET AGAINST MY WILL!","LOOK ON THE BRIGHT SIDE","ROSEBUD","FUCK! I FAT-FINGERED THE LISTING PRICE! DON'T BUY!","WHEN THE GOING GETS TOUGH, THE TOUGH GET GOING","FLOOR GO BRRR!","SHOW ME THE MONEY!","I'LL BE BACK","I'M A REAL BOY!","SELL IF YOU DON'T WANNA MAKE IT","GLOBAL WARMING IS MELTING THE ABOMINABLE SNOWMAN!","MY PRECIOUS","1X LUCKY NFT: HOLDING THIS ITEM WILL BRING YOU GOOD LUCK","GO AHEAD, MAKE MY DAY","GROUND CONTROL TO MAJOR TOM","YOU HAVE BEEN COMPROMISED PROCEED TO THE EXTRACTION POINT","NFTS, I CHOOSE YOU!","LIVE LONG AND PROSPER!","YOU. SHALL. NOT. PASS!","NO REGRETS","NOT SLEEPING ON THIS","GIRLS DON'T POOP... NOT THE PRETTY ONES","AH SHIT, HERE WE GO AGAIN","EWWW","ALL IS WELL","I HAD BLUE WAFFLES FOR BREAKFAST","OKAY BOOMER","MY STRANGE ADDICTION IS CONSTANTLY CHECKING FLOOR PRICES","YOU ONLY LIVE ONCE, BUT IF YOU DO IT RIGHT, ONCE IS ENOUGH","YOU MISS 100 PERCENT OF THE SHOTS YOU NEVER TAKE","I KNOW I SAID THE WORLD WOULD END TODAY BUT IT'LL END TOMORROW","LIFE IS TOO SHORT","IT ALWAYS SEEMS IMPOSSIBLE UNTIL IT'S DONE","I BOUGHT THIS NFT AND THEN MY DAD LEFT TO GET MILK","SLOW AND STEADY WINS THE RACE","SMELLS LIKE UPDOG IN HERE","YOU KNOW NOTHING","BELIEVE IT!","THIS NFT IS CURSED. YOU WILL BE VISITED BY THE BOOGEYMAN.","HELLO? ANYBODY THERE?","IT'S ALIVE. IT'S ALIVE!","BUYING THIS NFT WILL CHANGE YOUR LIFE, ITS THE BUTTERFLY EFFECT","GOOD PURCHASE!","NEVER GONNA MAKE YOU CRY","THE FUTURE BELONGS TO THOSE WHO PREPARE FOR IT TODAY","THIS GUY FUCKS! AM I RIGHT?","OH FUCK YEAH!","THIS NFT IS AWESOME, CHANGE MY MIND","WHO AM I?","WHAT'S AN ABSURD AMOUNT FOR A PICTURE ON THE INTERNET?","*DICK PIC*","I HAVE NO IDEA WHAT'S GOING ON, BUT I AM EXCITED","LUCKY YOU","JUST DANCE","WHY SO SERIOUS?","BELIEVE IN YOURSELF","I'M CONFUSED... WHEN DO WE GET OUR ICE CREAM?","8 AM - SOMEONE POISONS THE COFFEE","IF I SELL THIS, I'M NGMI","ABOVE ALL ELSE, DON'T FORGET TO HAVE FUN","I GOT LOST IN THE BERMUDA TRIANGLE","DO NOT TOUCH","NEVER GONNA RUN AROUND AND DESERT YOU","YOU ARE NOT ALONE","CAN ANYBODY HEAR ME? OR AM I TALKING TO MYSELF?","WE WILL! WE WILL! ROCK YOU!","MAY THE ODDS BE EVER IN YOUR FAVOR","NOTICE ME SENPAI","GIVE IT YOUR BEST SHOT","EAT MY SHORTS!","SHOUT 'EXIT SIMULATION!' TO EXIT THE SIMULATION","I AM THE HACKERMAN","FUCK! I KNEW I SHOULD HAVE BOUGHT MORE!","CONGRAJA-FUCKING-LATIONS","GET OFF YOUR LAZY ASS!","SIMON SAYS HOLD THIS NFT","I BOUGHT THIS NFT AND NOW I'M BROKE","A HACKER STOLE THIS NFT! DON'T BUY IT!","YOU HAD ME AT NFT","LIVE LIFE TO THE FULLEST","VIOLENCE IS NEVER THE ANSWER","I LIKE TO BE LIKED. I ENJOY BEING LIKED. I HAVE TO BE LIKED!","GUY BUYS THIS NFT... INSTANTLY REGRETS IT!","MATH IS FUN","THIS IS GARBAGE","HEHE THEY DON'T KNOW I OWN A CODE NFT","IF YOU BUY THIS, IT'S THE TOP SIGNAL","I SLAYED THE DRAGON IN THE MOUNTAIN","LMAO SUCKER!","MOM! PLEASE! PLEASE BUY ME THIS NFT! ALL THE COOL KIDS HAVE ONE","ANYTHING CAN HAPPEN","NFTS ARE THE WAVE OF THE FUTURE, THESE THINGS SELL THEMSELVES","NEVER GONNA TELL A LIE AND HURT YOU","I WILL BRING HONOR TO MY FAMILY","MAMA SAYS LIFE IS LIKE A BOX OF CHOCOLATES","XD","WHAT WERE YOU THINKING?","YOU WON'T BELIEVE WHAT THIS NFT CAN DO. IT WILL BLOW YOUR MIND!","NO NO NO ANYTHING BUT THE CONVERTER!","STRIVE FOR GREATNESS, NOT FOR ETH","WITH GREAT ETHEREUM, COMES GREAT SWEEPING RESPONSIBILITY","I WAS WALKING AND THEN SUDDENLY! I TRIPPED ON THE BLOCKCHAIN!","IT'S BIG BRAIN TIME","EVERYBODY BETRAY ME! I'M FED UP WITH THIS WORLD!","THOSE ARE ROOKIE NUMBERS! YOU GOTTA PUMP THOSE NUMBERS UP!","I HAVE UNDERINVESTED... BY A LOT","I'M NOT USUALLY THE BUTT OF THE JOKE, I'M USUALLY THE FACE","I GOT LEFT AT THE ALTER","NOBODY EXISTS ON PURPOSE. EVERYBODY'S GONNA DIE SOMEDAY.","YOU IS KIND. YOU IS SMART. YOU IS IMPORTANT.","WHAT HAPPENED TO THE FLOOR PRICE?","YES LADIES, I OWN THIS NFT. FORM A SINGLE FILE LINE PLEASE.","NOBODY KNOWS IF IT'S GOING UP, DOWN OR FUCKING SIDEWAYS","NEVER GONNA LET YOU DOWN","WE LIVE IN A SOCIETY","TO NFT OR NOT TO NFT?","YO MAMA SO FAT","I'M A WINNER","WHAT ARE YOU DOING STEP-BRO?","A MONSTER LIVES UNDER YOUR BED","I CAN'T FIND MY WALLET AND KEYS","I WANNA BE THE VERY BEST! LIKE NO ONE EVER WAS!","THIS NFT HACKED ME! DON'T SIGN ANY TRANSACTIONS!","YOU ARE MADE OF STUPID","*BADUM TISS*","IT'S OVER! WE HAVE THE HIGH FLOOR!","PLEASE BUY THIS! I HAVE MOUTHS TO FEED!","ACTIONS HAVE CONSEQUENCES","YOU'RE THE RETARDED OFFSPRING OF MONKEYS. CONGRATULATIONS.","NO REFUNDS","BUY THIS NFT. YOU WON'T BELIEVE WHAT HAPPENS NEXT!","WHAT DID IT COST?","DON'T LET YOUR DREAMS BE DREAMS","LEMME SMASH","HOPE YOU HAVE A FANTASTIC DAY FULL OF POSITIVITY AND HAPPINESS","FUCK YOU","FRIENDS DON'T LIE","WINDS HOWLING","IN THE NAME OF THE LORD I COMMAND YOU TO BUY THIS NFT","YOU KEEP DOING YOU","I'VE BEEN BAMBOOZLED","THIS IS GOING TO BE LEGEN-WAIT-FOR-IT-DARY. LEGENDARY!","I'M A GNOME AND YOU'VE BEEN GNOOOMED!","BETTER LATE THAN NEVER","SAVE THE PLANET!","DO MORE","THE PEN IS MIGHTIER THAN THE SWORD","IF (SMART) THEN (HOLD)","THIS IS FINE","YOLO","I KNOW KUNG-FU","NO CHEATING","THE NAME'S BOND, JAMES BOND","WE LIKE TO HAVE FUN AROUND HERE","THE PROPHECY FORETOLD THE COMING OF CRYPTO","SUIT UP!","WANT A BIGGER PEE PEE? BUY THIS","FINALLY! MY GREAT EVIL PLAN IS SET IN MOTION! MUAHA MUAHAHAA!!!","THE END IS NEAR","RAID AREA 51! FREE THE ALIENS!","OKAY GOOGLE, HOW DO I CONVERT BINARY TO ENGLISH?","I SIMP FOR NFTS","UNIVERSAL HEALTHCARE IS A HUMAN RIGHT","LOGIC IS THE BEGINNING OF WISDOM, NOT THE END","WHAT YOU SEE IS WHAT YOU GET","YOU'RE JUST JEALOUS I OWN THIS NFT","FINE! LIST ME BITCH! I DARE YOU! LETS SEE WHAT HAPPENS!","ANYWAY, HOW'S YOUR SEX LIFE?","JUST KEEP SWIMMING","TAKE THE RED PILL, I'LL SHOW YOU HOW DEEP THE RABBIT HOLE GOES","WHEN LIFE GIVES YOU ETH, MINT NFTS","JUST HAVE A LITTLE FAITH","I AM HUMAN","WAIT! DON'T SELL YET, THE FLOOR WILL PUMP A LITTLE HIGHER","THEY SAID I COULDN'T DO IT","IT GOES ON","I AM YOUR FATHER","WHY DID YOU EVEN BUY THIS SHITTY NFT?","I GOT THE VACCINE AND NOW I'M ARTISTIC","THIS SOUNDS LIKE A GET RICH QUICK SCHEME","SAY NO TO DRUGS","I BOUGHT THIS NFT AND NOW I'M SEXY","BUY THIS! IT'S AN EASY 2X","ELEMENTARY, MY DEAR WATSON","RUG PULL! HAHA! YOU JUST GOT RUGGED!","HATERS GONNA HATE","A LION DOESN'T CONCERN HIMSELF WITH THE OPINIONS OF SHEEP","TO THE MOON!","CALL ME DIAMOND HANDS","WE HAVE NOTHING TO FEAR BUT FEAR ITSELF","I'LL JUST BE FIPPIN BURGERS TILL THIS MOONS","HEY BABY, YOU WANNA HAVE A GOOD TIME?","APPRECIATE THE LITTLE THINGS","I'M A BARBIE GIRL, IN THIS BARBIE WORLD!","LIFE IS EITHER A DARING ADVENTURE OR NOTHING AT ALL","SHH! DON'T TELL ON ME TO THE TAXMAN","EASY PEASY, LEMON SQUEEZY","NFT OWNER'S DREAMS COME TRUE!","WINTER IS COMING","I BOUGHT THIS NFT AND NOW I HAVE A BIG PEE PEE","PINEAPPLE BELONGS ON A PIZZA","NEVER GIVE UP","THINK OUTSIDE THE BOX","IT'S JUST A SOCIAL EXPERIMENT BRO","RULE 34: IF IT EXISTS, THERE IS PORN OF IT","WELL, I DON'T MEAN TO BRAG BUT I HAVE KISSED OVER FOUR WOMEN",":'C","LEGALIZE PSYCHEDELICS","YIPPIE-KI-YAY, MOTHERFUCKER!","I AM THE ONE WHO KNOCKS","PLEASE PLEASE PLEASE SOMEONE BUY THIS! I NEED LIQUIDITY NOW!","DREAM BIG AND DARE TO FAIL","THERE'S A LOT OF BEAUTY IN ORDINARY THINGS","WHATCHA GONNA DO TODAY?","LIFE'S WHAT HAPPENS TO YOU WHILE YOU'RE BUSY MAKING OTHER PLANS","PROBABLY NOTHING","I'M NON-FUNGIBLE TOKEN RIIICK!","KNOCK KNOCK","I BOUGHT THIS NFT AND THAT'S HOW I GOT OUT OF THE FRIEND ZONE","THE EARTH IS FLAT","I DRINK AND I KNOW THINGS","HELLO? WHERE AM I? LET ME OUT! OR I'M CALLING THE CYBER POLICE!","THERE'S NO PLACE LIKE HOME","MY MOM SAYS I'M SPECIAL","REPORTING: EVERYTHING'S GOOD, THEY'VE BOUGHT IT","WHERE WERE YOU? YOU WERE LOOKING AT OTHER NFTS, WEREN'T YOU?","I BOUGHT THIS NFT AND NOW I'M ONE OF THE COOL KIDS","NO REST FOR THE WICKED","IT WAS THE BEST OF TIMES, IT WAS THE WORST OF TIMES","LOOK AT THIS ONE, IT'S JUST MARVELOUS. DON'T YOU THINK?","CRYPTOCURRENCY IS A BUBBLE... A BUBBLE-BLOWING PARTY!","SEND DICK PIC NFTS","98 PERCENT OF PEOPLE WON'T GET THIS","HAKUNA MATATA","EH, WHAT'S UP DOC?","WUBBA LUBBA DUB DUB!","THIS MESSAGE HAS TRAVELLED THROUGH SPACE AND TIME TO INFORM YOU","WILL YOU MARRY ME?","I'M HOPELESS AND AWKWARD AND DESPERATE FOR LOVE!","YOU WERE THE CHOSEN ONE!","I'M THANKFUL","TO INFINITY AND BEYOND!","I BOUGHT THIS NFT AND NOW I SEE DEAD PEOPLE","KEEP CALM AND CARRY ON","SHH... IT'S A SECRET","IS THIS AN NFT?","POST-PURCHASE CLARITY HITS HARD","GREETINGS FELLOW HUMANS","PUCK PUCK PAKAAAK","I AM LEGEND","IT WAS AT THIS MOMENT THAT HE KNEW... HE FUCKED UP","IF YOU MULTIPLY A CENTURY, YOU GET A PRETTY NICE MEMBER","OH CAPTAIN! MY CAPTAIN!","YOU'VE BEEN BRAINWASHED","HOW YOU DOIN?","NO LOW BALL OFFERS. I KNOW WHAT I HAVE.","WHY THE FUCK DID THE STUPID CHICKEN CROSS THE ROAD? WHY?","ARE YA WINNIN SON?","DID YOU REMEMBER TO TAKE YOUR MEDS TODAY?","SAY THE MAGIC WORDS","BINGO","ALL POWER TO THE PEOPLE","OKAY BUY THIS, FLIP IT QUICK AND LET THE NEXT GUY HOLD THE BAG","FP THIS LOW IS HIGH-KEY SUS, NO CAP","I'M TOO OLD FOR THIS SHIT","ISN'T THIS KICK-YOU-IN-THE-CROTCH, SPIT-ON-YOUR-NECK FANTASTIC?","FASTEN YOUR SEATBELTS. IT'S GOING TO BE A BUMPY RIDE!","DELIST! DELIST! DELIST!","ARE YOU DUMPING ME?","LIVE AS IF YOU WERE TO DIE TOMORROW","CLASSIFIED","NFT 101 - A SCREENSHOT OF AN NFT DOES NOT MEAN YOU OWN THE NFT","I BOUGHT THIS NFT, THAT'S WHY MY WIFE LEFT ME AND TOOK THE KIDS","THE FLOOR IS LAVA!","*DUN DUN DUUUUUN*","GO FUCK YOURSELF","YO YO YO YO N TO THE F TO THE T YA SEE!",":P","DO NOT BUY THIS! I WILL REGRET SELLING IT TO YOU","REMEMBER... ALL I OFFER YOU IS THE TRUTH. NOTHING MORE.","I HAVE A DREAM","SUCCESS IS NOT FINAL AND FAILURE IS NOT FATAL","DO WHAT YOU LOVE","CLIMATE CHANGE IS REAL!","WAIT A MINUTE, WHO ARE YOU?","TO LIVE IS TO RISK IT ALL","NOT LISTING THIS BELOW FLOOR, PINKY PROMISE","HEY LOOK MA I MADE IT!","WE ARE CLEARED FOR TAKE-OFF","STUPID IS AS STUPID DOES","YOU MATTER","YUM I LIKE EATING BOOGERS","CAN SOMEONE HELP ME? I'M TRYING TO MINT THIS NFT","SMOKE WEED EVERYDAY","I HOPE I MAKE THE NICE LIST THIS CHRISTMAS","1X UNLUCKY NFT: HOLDING THIS ITEM WILL BRING YOU BAD LUCK","YES I CAN","I DESERVE HAPPINESS","OH YEAH, IT'S ALL COMING TOGETHER","I DESERVE BETTER","I'M WATCHING YOU","TIME TO SWEEP THE FLOOR","SHARE THIS WITH 5 PEOPLE OR YOU WILL HAVE BAD LUCK","I BOUGHT THIS NFT AND THEN I FOUND TRUE LOVE","HELLO? RICH PEOPLE? I'LL BE JOINING YOU... YES, I'LL HOLD.","BY OWNING THIS NFT I HEREBY ACCEPT THE HARVEST OF MY ORGANS","I'VE COME FROM THE FUTURE TO WARN YOU THE WORLD WILL END ON THE","ALIENS ARE STEALING OUR COWS GOD DAMN IT!","EAT SLEEP NFT REPEAT","THAT'S WHAT SHE SAID","DON'T WASTE A SINGLE DAY","HELP! HELP! THIS PSYCHO TRAPPED ME IN HIS SHITTY WALLET! EWWW!","I'M PREGNANT","UWU","ARE YOU FROM TENNESSEE? BECAUSE YOU ARE THE ONLY 10 I SEE","I APED IN","I AM THE GOAT",":(","TODAY, I CONSIDER MYSELF THE LUCKIEST MAN ON THE FACE OF EARTH","HURRY UP AND LIST! BEFORE THE FLOOR CRASHES!","LIKE TAKING CANDY FROM A BABY","FAKE IT TILL YOU MAKE IT","WHO'S A GOOD BOY? YOU! YES YOU ARE! YOU'RE A GOOD BOY!","DON'T, EVER, FOR ANY REASON, DO ANYTHING, TO ANYONE, WHATSOEVER","YOU CRACKED THE CODE","HELLO WORLD","I BOUGHT THIS NFT AND THEN, I LOST MY VIRGINITY","THE FBI IS MONITORING YOU","JUST DO IT!","I WANT PEOPLE TO BE AFRAID OF HOW MUCH THEY LOVE ME","ONLY GOOD VIBES","C'MON DO IT! SIGN THAT TRANSACTION. SEE WHAT HAPPENS!","I LOVE YOU","TAKE PROFITS","MODERN PROBLEMS REQUIRE MODERN SOLUTIONS","YOU MUST BE THE CHANGE YOU WISH TO SEE IN THE WORLD","THE ILLUMINATI CONTROL THE WORLD ORDER","COME ON BARBIE LETS GO PARTY!","I'M FOREVER 21","BEAUTY IS IN THE EYE OF THE BEHOLDER","I EAT RAINBOWS AND POOP BUTTERFLIES","THE AVOCADO TASTE IS ABSENT... FALSE, I'LL JUST ADD SOME HONEY","NOOO, YOU'RE AN NFT","DO OR DO NOT. THERE IS NO TRY.","THE FIRST RULE OF NFT CLUB: YOU TALK ABOUT NFT CLUB","NO, YOU DON'T LOVE ME, YOU'RE JUST GONNA SELL ME OFF TO SOMEONE","BACK IN MY DAY, WE USED TO HAVE GOOD OLD-FASHIONED PAINTINGS","*PLOP* *PLOP* *FLUSH*","THIS IS MY LIFE!","DO SOMETHING THAT MAKES YOU FEEL ALIVE","DINOSAURS NEVER EXISTED","WHEN YOU PLAY THE GAME OF NFTS YOU EITHER WIN OR YOU GO TO 0","BE YOURSELF","*FART*","WITCHES KIDNAP KIDS AND COOK EM IN A BIG STEW","YOU'RE PERFECT","I... DECLARE... BANKRUPTCY!","OH. MY. GOD.","I GOT THIS","YOU TALKIN' TO ME?","CROP CIRCLES ARE MADE BY ALIENS","I'M A 1 OF 1","OK OK OK I NEED THE PRICE TO GO UP","SHOOT FOR THE STARS","I AM FREE","AGH! YOU DON'T GET IT DAD! THIS IS A FINANCIAL ASSET!","KNOWLEDGE IS POWER","LET IT GO","I BOUGHT THIS NFT AND NOW I'M IRRESISTIBLE TO WOMEN","BACK IN MY DAY, WE DIDN'T HAVE NFTS","ACTIONS SPEAK LOUDER THAN WORDS","SEX IS GREAT BUT HAVE YOU EVER MINTED A RARE NFT?","HELLO DARKNESS MY OLD FRIEND","01000011 01001111 01000100 01000101","WHEN I GET SAD, I STOP BEING SAD AND BE AWESOME INSTEAD","I MARRIED A PFP NFT","MY DAD MADE HIS FACE WINK, JUST FOR A BRIEF SECOND","IF I LIST THIS, I'VE GONE CRAZY! SEND ME TO A PSYCH WARD","IT IS FORETOLD THAT CRYPTO SHALL REACH THE HEAVENS!","WHETHER YOU THINK YOU CAN OR YOU THINK YOU CAN'T, YOU'RE RIGHT","I LIKE BIG BUTTS AND I CAN NOT LIE","STOP FRIVOLOUS SPENDING! CUT IT TO JUST WATER, BREAD AND NFTS!","LEARN FROM YOUR MISTAKES","HOW MUCH DO YOU THINK THIS IS WORTH?","YOU HAVE SOMETHING IN YOUR TEETH","DO YOU HAVE ANY IDEA WHO YOU'RE TALKING TO?","WAKE UP","GIRLS HAVE COOTIES","IT'S A WONDERFUL LIFE","NOTHING TO SEE HERE, MOVE ALONG","I SAW BIGFOOT","DON'T SELL ME... PRETTY PLEASE?","YEAH, SCIENCE!","SPEAK YOUR MIND","WHY ARE YOU THE WAY THAT YOU ARE?","DON'T BE AN IDIOT","FACE YOUR FEARS","I LIKE YOU, YOU'RE COOL","BUY AND HOLD THIS NFT. GOD WILLS IT!","I AM INEVITABLE","I'M ON TOP OF THE WORLD!","DO WHAT YOU CAN'T","OH NO NO NO NO, THIS IS DEFINITELY NOT A RUG PULL! TRUST ME!","STONKS","THERE ARE ALWAYS A MILLION REASONS NOT TO DO SOMETHING","SIZE DOESN'T MATTER","LEGALIZE MARIJUANA","SAVE LOCH NESS FROM THIS MONSTROUS POLLUTING!","HOLD ME","IT'S ALL FAKE NEWS","MY DAD IS MY HERO","YOU'RE BEAUTIFUL","VALAR MORGHULIS","I BOUGHT THIS NFT AND THAT'S WHY MY GIRLFRIEND DUMPED ME","LIFE IS GOOD","THE MOON LANDING WAS FAKE","GONNA TELL MY KIDS THIS IS CRYPTOPUNKS","ASTALA VISTA, BABY!","DON'T PANIC! WAGMI!","I SHIT THE BED","NEVER GONNA GIVE YOU UP","I HAVE A GIRLFRIEND! SHE JUST GOES TO A DIFFERENT METAVERSE","AH, I SEE YOU ARE A MAN OF CULTURE","WHAZAAA","IT'S SIMPLE PONZINOMICS, MORE PEOPLE INVEST, MORE MONEY WE MAKE","LEPRECHAUNS CONTROL THE SUPPLY OF GOLD","THE DUDE ABIDES","*-*"
  ];

  string internal URIStart = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 2000 2000'><style>@font-face{font-family:'font';src:url(data:application/font-woff2;charset=utf-8;base64,d09GMgABAAAAAAcQAA8AAAAAFYAAAAa2AAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP0ZGVE0cGh4bdBxABmAAgnIRCAqXSJAoC24AATYCJAOBWAQgBYcIB4EkG20QUVRympB9eWCToasY/oO5Gk+G2eowOyWatqb50k0heNr4Dwh3TA48Wi4jqN8P3bv3AwgSUZFDmYlOysZXkiw7GRCqLHSnNnC01ubFfN8FUzl79RKxkDRkMs1DJVSi8bzt3v5dhEPP04A0w3S+715fybLlF/kqsfPe/52Id7PyMSZNjmBbwCbjY0KafmyVz9f/2t7doVoT19WEUuoiTPRC8HXi37jYChnISHnwK+Xdt3xns0l3eVGJTjad0pRAODRC7c3O/ntzcyWlLUtrKaXsHXRheDEKYWu3GAsOhezGIzTGKK6xFfHjReFwpY26Ii5xVf9PDAE/XucA/Pz/GPydHnhFQzN6gRRYRVMhEWi0axljf3J+HZSnUUwDuiflLAQw4fEfk22Ml1gxC1wmTSrJwUSnIJpZkgXe0TsGK8w1nrsTFWZXNb15woq6f1hxEMuPLh/gkYNsqm0gjvyG/iYgffFnGyEagvqH7R/SS12gboCvgHJXLoBxdBQUDKOBVxgCw5hOgXZSDDDCyqfXbv/8q3RH3AIGex+/Ft/4pnqAhnWLWsLxRyI1lMpTa2rr6jU0NjW3tLa94U8D+N37v89qszucLrfH6/MHgqFwJBqLJ0D8rUI8sgFrAK+AA1DOAco/AupBAlKwNA9GuiIp0ngrWRXFFalIHWVRtsBuBbKdPat9SaLjqq61GX3yAiyYYB3AWV22kM8t63bJZyf05Ww/mR95xS7mvYOdUT0gfs1q48ZORqaNGoGNuHGrxsZOjZoaGYWxE8H2R4HbA4hH52HKSeO4WTwZcTLLo/er+7sKfVTBY3LacuVaA6JNpaQ5DFJryd2Bcy5g6igEuriRJch6vAG/1ryw15k+adOHHnUdvM2jXyIwajNGudR5zk4O0qPBR3ds0qSHbgzzus4Ecj6QPGAqEo2FZ6qcvNAShETa9qKADvrGrGtpwT7ZrykECXX0jgtC3vcFku8Ce6cHY+rsRAGlPI/2eGO6KCtx+D6xToOu5FRGaD7wrS7GG+2jQPEgz158H8aD6Brq3GIy8m+Wp7bi2OENARNBOLFsST13GnQ18sb6PWpQO6YIj0Bc8T0kknLutafwRVv01HFbkN5JK1BrD+8pvbrVxjNQ/xr4F/SF1H0FnmmbrtnKJ5dQHRcTK0E+PFuydMuq5yZuoVNLpzwKb8mlQUMFy8XMoucysoxid/dl7jxPPoIGvYb2r4tm/5fKJ3lOkOhFjfb3DWitOIJgYRIpylU1Cj8qpVriJ/R1mag/02P20ANSYxClJHoUbiOw6zj+N61nY1ykosMYBkqzHOr7DQwF92MkoPI3OI6GOVwgZKH9J2bqoa39a7hgjBj1sAjvklMzA+8Mjud9jUMMYxyN2uPyHxapF005rIiMxAvJbImeEM68/Id2rhh52ahTHwqmfUbMdVgDrqBw9GT2VLre1i7tDI9aAtIlneXTmYKC+uMBCDa9Iq7Pkpp3x9HVj7diQW1o6NGzIZk+8ONvq4QD69ykPqvndO7nXYRVAOYaOsPPvHPBNDnKDGu0WXZW4fM6rnyaISLqaWXhjdX/+3G20PG4z5RSQs+4u+y8uROAvjM7dPKvrl/oF3ev2kGX/iLWdYydmgF0TOtJpzEWMOK0tu/MYPuboCn1AAGF3bDIynudynp1EDX01YXvfPhG1iNJ/+cK6mb+8z4dHhN6zLpAUy81FtTNDEkLVC27AI2gNeijAPICoCwcMIvv5HB1VdQcoDeCG50bxAxWSMFhFV0XB0iBiR8jsMaIAYJ4U7tnDFE1YBJkMgyyyVRvRxYbxmVlWlvWqPVN1pp0Kxs0upLNJn3Klpj0LVutRS2vqDMvr0VyKm9w833LLXF+eMV3gcHce4DERGQSTEajkKn4U0fllC2j1GHScijnkDUnskptNu0cfmxIXN/uSJ9OKUqD9FqN3gFNrtPMTlxLKscd80p6hQXBp8rRkCxsMr6ORCGISZdVRlWJwDfXnCjCoFZKM3EGSIy5RxVG55koAmdMc+2MeciSPMw3evu8tgjwJqcS4xzMRYUkI6cKMUuO2BNVbinpiTgFpauhXIAWwHQjVjJVFb25Z2J2yZkiakll5kJKhv4UITlFhLAlk+Y1lm/BnMKDhnAqIqMVyMiOCQV3044dekUkTneI3IEBtSlYLPJ4hhQTFe8q2YIK4+LyB6bRgUc3XRFf5RqIjKKoNGrSrEWbdjJyCkoqahpaOnoGRiZWNnYOTi5uHl4+fgFBIWERUTFxCR06denWo1effgPFrH2abuTJ6H5tjFPJUrGOyTE=) format('woff2')}</style><rect width='100%' height='100%'/><defs><filter id='filter' x='0' y='0' width='100%' height='100%'><feGaussianBlur result='blurOut' stdDeviation='5'/><feBlend in='SourceGraphic' in2='blurOut' mode='multiply'/></filter><mask id='mask'><rect width='100%' height='100%' fill='#fff' fill-opacity='.90'/><rect x='-15%' width='15%' height='100%' fill='#fff' transform='skewX(-10)'><animate attributeName='x' from='-15%' to='115%' dur='10s' repeatCount='indefinite'/></rect></mask></defs>";

  mapping(uint256 => bool) public isDecoded;

  mapping(bytes1 => string) BinaryMap;
  function SetMapping() internal {

    BinaryMap [0x20] = "00100000 " ; //Space
    BinaryMap [0x21] = "00100001 " ; //!
    BinaryMap [0x27] = "00100111 " ; //'
    BinaryMap [0x28] = "00101000 " ; //(
    BinaryMap [0x29] = "00101001 " ; //)
    BinaryMap [0x2A] = "00101010 " ; //*
    BinaryMap [0x2C] = "00101100 " ; //,
    BinaryMap [0x2D] = "00101101 " ; //-
    BinaryMap [0x2E] = "00101110 " ; //.
    BinaryMap [0x3A] = "00111010 " ; //:
    BinaryMap [0x3F] = "00111111 " ; //?
    
    BinaryMap [0x41] = "01000001 " ;//A
    BinaryMap [0x42] = "01000010 " ;//B
    BinaryMap [0x43] = "01000011 " ;//C
    BinaryMap [0x44] = "01000100 " ;//D
    BinaryMap [0x45] = "01000101 " ;//E
    BinaryMap [0x46] = "01000110 " ;//F
    BinaryMap [0x47] = "01000111 " ;//G
    BinaryMap [0x48] = "01001000 " ;//H
    BinaryMap [0x49] = "01001001 " ;//I
    BinaryMap [0x4A] = "01001010 " ;//J
    BinaryMap [0x4B] = "01001011 " ;//K
    BinaryMap [0x4C] = "01001100 " ;//L
    BinaryMap [0x4D] = "01001101 " ;//M
    BinaryMap [0x4E] = "01001110 " ;//N
    BinaryMap [0x4F] = "01001111 " ;//O
    BinaryMap [0x50] = "01010000 " ;//P
    BinaryMap [0x51] = "01010001 " ;//Q
    BinaryMap [0x52] = "01010010 " ;//R
    BinaryMap [0x53] = "01010011 " ;//S
    BinaryMap [0x54] = "01010100 " ;//T
    BinaryMap [0x55] = "01010101 " ;//U
    BinaryMap [0x56] = "01010110 " ;//V
    BinaryMap [0x57] = "01010111 " ;//W
    BinaryMap [0x58] = "01011000 " ;//X
    BinaryMap [0x59] = "01011001 " ;//Y
    BinaryMap [0x5A] = "01011010 " ;//Z

    BinaryMap [0x30] = "00110000 " ;//0
    BinaryMap [0x31] = "00110001 " ;//1
    BinaryMap [0x32] = "00110010 " ;//2
    BinaryMap [0x33] = "00110011 " ;//3
    BinaryMap [0x34] = "00110100 " ;//4
    BinaryMap [0x35] = "00110101 " ;//5
    BinaryMap [0x36] = "00110110 " ;//6
  //BinaryMap [0x37] = "00110111 " ;//7
    BinaryMap [0x38] = "00111000 " ;//8
    BinaryMap [0x39] = "00111001 " ;//9
  }

  constructor() ERC721A("THE CODE", "CODE", 10, 555) {
    SetMapping();
  }

  bool public mintingEnabled;
  function ToggleMinting() external onlyOwner {
    mintingEnabled = !mintingEnabled;
  }

  mapping(address => uint8) addressMinted;
  function mint() external payable{
    require(mintingEnabled, "Wait for it");
    require(msg.value == 55500000000000000, "Mint price for The Code");
    require(addressMinted[_msgSender()] < 1 ,"Hey no refills");
    require(totalSupply() + 1 <= collectionSize, "Sold out!");
    addressMinted[_msgSender()]++;
    _safeMint(_msgSender(), 1); 
  }

  function TheCodeMints(uint mintAmount) external onlyOwner{
    require(totalSupply() + mintAmount <= collectionSize, "Not enough supply");
    _safeMint(_msgSender(), mintAmount);
  }

  function Decode(uint256 tokenId, string memory DecodedMessage) external{
    require(ownerOf(tokenId) == _msgSender(),"You don't own this code");
    require(!isDecoded[tokenId],"You already have the Decoded message");
    require(keccak256(bytes(DecodedMessage)) == keccak256(bytes(Codes[tokenId])), "Decoded input is incorrect");
    isDecoded[tokenId] = true;
  }

  function Encode(uint256 tokenId) external{
    require(ownerOf(tokenId) == _msgSender(),"You don't own this code");
    require(isDecoded[tokenId],"You already have the Encoded message");
    isDecoded[tokenId] = false;
  }

  mapping(uint256 => string) Color;
  function TextColor(uint256 tokenId, string memory color) external {
    require(ownerOf(tokenId) == _msgSender());
    Color[tokenId] = color;
  }

  function getCode(uint256 tokenId) public view returns (string memory) {
    require(isDecoded[tokenId],"First, you must decode your code");
    return Codes[tokenId];
  }

  function HexToBinary(bytes memory BytesData) private view returns (string[] memory) {
    uint pointer;
    uint inc;
    string[] memory Binary = new string[](21);
    while (pointer < BytesData.length){
      for (uint three = 0; three < 3 ; three++) {
        if (pointer < BytesData.length){
          Binary[inc]  =  string(abi.encodePacked (Binary[inc] , BinaryMap[BytesData[pointer]]));                      
          pointer++;  
          }
        }
        inc++;
    }
    return Binary;
  }

  function HexToEnglish(bytes calldata BytesData) public pure returns(string[] memory){
    uint counter;
    uint pointerFrom;
    uint pointerTill = 22;
    bytes memory MemoryData = BytesData;
    string[] memory English = new string[](3);
    bytes memory temp;

    uint remaining = BytesData.length;
    while (remaining > 22){
      while (MemoryData[pointerTill] != hex"20" && BytesData.length -1 > pointerTill){
        pointerTill++;
      }
      if (MemoryData[pointerTill] == hex"20"){
        temp = BytesData[pointerFrom:pointerTill];
        English[counter] = string(temp);
        remaining = BytesData.length - pointerTill;
        pointerFrom = pointerTill +1;
        pointerTill+=20;
        counter++;
      }else {               
        remaining = 3;
      }  
    }
    if (remaining > 0){
      temp = BytesData[pointerFrom:BytesData.length];
      English[counter] = string(temp);
    }
    return(English);
  }

  function tokenURI(uint256 tokenId) override public view returns (string memory) {
    string memory output;
    string[22] memory parts;
  
    if (!isDecoded[tokenId]){
      string[] memory Binary = HexToBinary(bytes(Codes[tokenId]));
      string memory json;
      if (keccak256(bytes(Color[tokenId])) == keccak256(bytes(""))){
        parts[0] = "<text x='6%' y='8%' style='fill:#0f0;font-family:font;font-size:64px;letter-spacing:.32em;text-anchor:left' mask='url(#mask)' filter='url(#filter)'>";
      }else{
        parts[0] =string(abi.encodePacked("<text x='6%' y='8%' style='fill:", Color[tokenId], ";font-family:font;font-size:64px;letter-spacing:.32em;text-anchor:left' mask='url(#mask)' filter='url(#filter)'>"));
      }
        parts[1] =  string(abi.encodePacked( Binary[0] , "<tspan x='6%' dy='1.35em'>"));
      for (uint i2 = 1 ; i2<21; i2++){
        parts[i2+1] = string(abi.encodePacked( Binary[i2] , "</tspan><tspan x='6%' dy='1.35em'>"));
      }
      
      output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7]));
      output = string(abi.encodePacked(output, parts[8], parts[9], parts[10], parts[11], parts[12], parts[13]));
      output = string(abi.encodePacked(output, parts[14], parts[15], parts[16], parts[17], parts[18], parts[19]));
      output = string(abi.encodePacked(URIStart, output, parts[20], parts[21], "</tspan></text></svg>"));
     
      json = Base64.encode(bytes(abi.encodePacked('{"name": "CODE #', tokenId.UintToString(), '", "attributes": [{"trait_type": "State","value":"Encoded"} , {"trait_type": "Color","value":"',Color[tokenId],'"}], "description": "The Code speaks to you, it speaks for you, it speaks for itself, its meaning is open to interpretation. Never be speechless with this in your wallet.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}')));
      output = string(abi.encodePacked("data:application/json;base64,", json));
    }
    else if (isDecoded[tokenId]){
      string[] memory English = this.HexToEnglish(bytes(Codes[tokenId]));
      string memory json;
      if (keccak256(bytes(Color[tokenId])) == keccak256(bytes(""))){
        parts[1] = "<text x='50%' y='47%' style='fill:#0f0;font-family:font;font-size:85px;text-anchor:middle' mask='url(#mask)' filter='url(#filter)'>";
      }else{
        parts[1] = string(abi.encodePacked("<text x='50%' y='47%' style='fill:", Color[tokenId], ";font-family:font;font-size:85px;text-anchor:middle' mask='url(#mask)' filter='url(#filter)'>"));
      }
      parts[2] =  string(abi.encodePacked( English[0] , "<tspan x='50%' dy='1.3em'>"));
      parts[3] =  string(abi.encodePacked( English[1] , "</tspan><tspan x='50%' dy='1.3em'>"));
      parts[4] =  string(abi.encodePacked( English[2] , "</tspan></text></svg>"));            
      output = string(abi.encodePacked(URIStart, parts[1], parts[2], parts[3], parts[4]));
    
      json = Base64.encode(bytes(abi.encodePacked('{"name": "CODE #', tokenId.UintToString(), '", "attributes": [{"trait_type": "State","value":"Decoded"} , {"trait_type": "Color","value":"',Color[tokenId],'"}], "description": "The Code speaks to you, it speaks for you, it speaks for itself, its meaning is open to interpretation. Never be speechless with this in your wallet.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}')));
      output = string(abi.encodePacked("data:application/json;base64,", json)); 
    }
    return output;
  }

  function withdraw() external onlyOwner {
    bool success = payable(_msgSender()).send(address(this).balance);
    require(success, "Payment did not go through!");
  }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
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