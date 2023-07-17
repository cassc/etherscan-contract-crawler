/**
 *Submitted for verification at Etherscan.io on 2023-06-30
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^ 0.8.0;

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
    function supportsInterface(bytes4 interfaceId) external view returns(bool);
}


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^ 0.8.0;


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
  function supportsInterface(bytes4 interfaceId) public view virtual override returns(bool) {
    return interfaceId == type(IERC165).interfaceId;
  }
}

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^ 0.8.0;

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
  function balanceOf(address owner) external view returns(uint256 balance);

  /**
   * @dev Returns the owner of the `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function ownerOf(uint256 tokenId) external view returns(address owner);

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
  function safeTransferFrom(address from, address to, uint256 tokenId) external;

  /**
   * @dev Transfers `tokenId` token from `from` to `to`.
   *
   * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
   * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
   * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
  function setApprovalForAll(address operator, bool approved) external;

  /**
   * @dev Returns the account approved for `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function getApproved(uint256 tokenId) external view returns(address operator);

  /**
   * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
   *
   * See {setApprovalForAll}
   */
  function isApprovedForAll(address owner, address operator) external view returns(bool);
}

// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^ 0.8.0;

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
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
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

  /**
   * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
   * `nonReentrant` function in the call stack.
   */
  function _reentrancyGuardEntered() internal view returns(bool) {
    return _status == _ENTERED;
  }
}

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^ 0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

/**
 * @dev Returns the amount of tokens in existence.
 */
function totalSupply() external view returns(uint256);

/**
 * @dev Returns the amount of tokens owned by `account`.
 */
function balanceOf(address account) external view returns(uint256);

/**
 * @dev Moves `amount` tokens from the caller's account to `to`.
 *
 * Returns a boolean value indicating whether the operation succeeded.
 *
 * Emits a {Transfer} event.
 */
function transfer(address to, uint256 amount) external returns(bool);

/**
 * @dev Returns the remaining number of tokens that `spender` will be
 * allowed to spend on behalf of `owner` through {transferFrom}. This is
 * zero by default.
 *
 * This value changes when {approve} or {transferFrom} are called.
 */
function allowance(address owner, address spender) external view returns(uint256);

/**
 * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
 *
 * Returns a boolean value indicating whether the operation succeeded.
 *
 * IMPORTANT: Beware that changing an allowance with this method brings the risk
 * that someone may use both the old and the new allowance by unfortunate
 * transaction ordering. One possible solution to mitigate this race
 * condition is to first reduce the spender's allowance to 0 and set the
 * desired value afterwards:
 * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
 *
 * Emits an {Approval} event.
 */
function approve(address spender, uint256 amount) external returns(bool);

/**
 * @dev Moves `amount` tokens from `from` to `to` using the
 * allowance mechanism. `amount` is then deducted from the caller's
 * allowance.
 *
 * Returns a boolean value indicating whether the operation succeeded.
 *
 * Emits a {Transfer} event.
 */
function transferFrom(address from, address to, uint256 amount) external returns(bool);
}

error PriceNotMet(address nftAddress, uint256 tokenId, uint256 price);
error ItemNotForSale(address nftAddress, uint256 tokenId);
error NotListed(address nftAddress, uint256 tokenId);
error AlreadyListed(address nftAddress, uint256 tokenId);
error NoProceeds();
error NotOwner();
error NotApprovedForMarketplace();
error PriceMustBeAboveZero();

contract Marketplace is ReentrancyGuard {



  enum PriceType {
    ETHER,
    TOKEN
  }

    struct Listing {
        uint256 price;
        address seller;
        address nftAddress;
        uint256 tokenId;
        Payment payment;
  }

    struct Payment {
    PriceType priceType;
    address tokenAddress;
  }

    event ItemListed(
    address indexed seller,
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 price,
    Payment payment
  );

    event ItemCanceled(
    address indexed seller,
    address indexed nftAddress,
    uint256 indexed tokenId,
    Payment payment
  );

    event ItemBought(
    address indexed buyer,
    address indexed nftAddress,
    uint256 indexed tokenId,
    uint256 price,
    Payment payment
  );

  mapping(address => mapping(uint256 => Listing)) private s_listings;

        uint256 listingCounter;

        address admin;

    modifier onlyOwner() {
        require(msg.sender == admin, "Only owner can call this function");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

  Listing[] private s_listingsArray;

    modifier notListed(address nftAddress, uint256 tokenId, address owner) {
        Listing memory listing = s_listings[nftAddress][tokenId];
    if (listing.price > 0) {
      revert("Already listed");
    }
    _;
  }

    modifier isOwner(address nftAddress, uint256 tokenId, address spender) {
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId);
    if (spender != owner) {
      revert("Not owner");
    }
    _;
  }

    modifier isListed(address nftAddress, uint256 tokenId) {
        Listing memory listing = s_listings[nftAddress][tokenId];
    if (listing.price <= 0) {
      revert("Not listed");
    }
    _;
  }


  function isApprovedForMarketplace(address nftAddress, uint256 tokenId) internal view returns(bool) {
        IERC721 nft = IERC721(nftAddress);
        address approved = nft.getApproved(tokenId);
    return approved == address(this) || nft.isApprovedForAll(msg.sender, address(this));
  }

  function listItem(
    address nftAddress,
    uint256 tokenId,
    uint256 price,
    Payment memory payment
  ) external notListed(nftAddress, tokenId, msg.sender) isOwner(nftAddress, tokenId, msg.sender) {
    require(price > 0, "Price must be above zero");

    
      require(isApprovedForMarketplace(nftAddress, tokenId), "Not approved for marketplace");

    {
      s_listings[nftAddress][tokenId] = Listing(price, msg.sender, nftAddress, tokenId, payment);
      s_listingsArray.push(Listing(price, msg.sender, nftAddress, tokenId, payment));
    }
    listingCounter++;

    emit ItemListed(msg.sender, nftAddress, tokenId, price, payment);
  }




  function cancelListing(address nftAddress, uint256 tokenId, Payment memory payment) external nonReentrant {
    Listing storage listing = s_listings[nftAddress][tokenId];
    require(listing.seller == msg.sender, "Not the seller");
    listingCounter--;
    delete s_listings[nftAddress][tokenId];

    uint256 listingIndex;
    uint256 length = s_listingsArray.length;
    for (uint256 i = 0; i < length; i++) {
      if (s_listingsArray[i].nftAddress == nftAddress && s_listingsArray[i].tokenId == tokenId) {
        listingIndex = i;
        break;
      }
    }

    if (listingIndex != 0) {
      s_listingsArray[listingIndex] = s_listingsArray[length - 1];
      s_listingsArray.pop();
        emit ItemCanceled(msg.sender, nftAddress, tokenId, payment);
    }
  }





  function buyItem(address nftAddress, uint256 tokenId, Payment memory payment) external payable nonReentrant {
    Listing memory listing = s_listings[nftAddress][tokenId];
    require(listing.price > 0, "Item not listed");
    

    IERC721 nft = IERC721(nftAddress);
    require(nft.ownerOf(tokenId) == listing.seller, "Seller no longer owner");

    require(listing.payment.priceType == PriceType.ETHER || listing.payment.priceType == PriceType.TOKEN, "Invalid payment type");

    if (listing.payment.priceType == PriceType.ETHER) {
      require(msg.value >= listing.price, "Insufficient payment");
      nft.safeTransferFrom(listing.seller, msg.sender, tokenId);
      (bool success, ) = payable(listing.seller).call{ value: listing.price } ("");
      require(success, "Payment failed");
    } else {
    IERC20 token = IERC20(listing.payment.tokenAddress);
      require(token.allowance(msg.sender, address(this)) >= listing.price, "Token allowance not enough");
      require(token.transferFrom(msg.sender, listing.seller, listing.price), "Transfer failed");
      nft.safeTransferFrom(listing.seller, msg.sender, tokenId);
    }

    delete s_listings[nftAddress][tokenId];
    for (uint i = 0; i < s_listingsArray.length; i++) {
      if (s_listingsArray[i].nftAddress == nftAddress && s_listingsArray[i].tokenId == tokenId) {
        delete s_listingsArray[i];
        listingCounter--;
        break;
      }
    }
    
    emit ItemBought(msg.sender, nftAddress, tokenId, listing.price, payment);
  }


  function updateListing(
    address nftAddress,
    uint256 tokenId,
    uint256 newPrice,
    Payment memory payment
  )
  external
  isListed(nftAddress, tokenId)
  nonReentrant
  isOwner(nftAddress, tokenId, msg.sender)
  {
    if (newPrice == 0) {
      revert("Price must be above zero");
    }
    s_listings[nftAddress][tokenId].price = newPrice;
        

        emit ItemListed(msg.sender, nftAddress, tokenId, newPrice, payment);
  }

    function cancelAnyListing(address nftAddress, uint256 tokenId) external onlyOwner {
        Listing storage listing = s_listings[nftAddress][tokenId];
        require(listing.price > 0, "Listing does not exist");

        listingCounter--;
        delete s_listings[nftAddress][tokenId];

        uint256 listingIndex;
        uint256 length = s_listingsArray.length;
        for (uint256 i = 0; i < length; i++) {
            if (s_listingsArray[i].nftAddress == nftAddress && s_listingsArray[i].tokenId == tokenId) {
                listingIndex = i;
                break;
            }
        }

        if (listingIndex != 0) {
            s_listingsArray[listingIndex] = s_listingsArray[length - 1];
            s_listingsArray.pop();
        }

        emit ItemCanceled(admin, nftAddress, tokenId, listing.payment);
    }

}