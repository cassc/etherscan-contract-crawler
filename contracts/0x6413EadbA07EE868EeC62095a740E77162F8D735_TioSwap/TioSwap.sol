/**
 *Submitted for verification at Etherscan.io on 2023-05-15
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

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
}

// File: contracts/TioSwap.sol

pragma solidity >=0.8.0 <0.9.0;




/**
 * @author tioswap team
 * @title trustless ERC721|ERC1155 Nfts trading
 */
contract TioSwap is ReentrancyGuard {
  bytes4 constant IERC721_INTERFACE_ID = 0x80ac58cd;
  bytes4 constant IERC1155_INTERFACE_ID = 0xd9b67a26;

  uint96 constant TYPE_ERC721 = 1;
  //uint96 constant TYPE_ERC1155 = 2;

  uint96 constant STATUS_LISTED = 1;
  uint96 constant STATUS_COMPLETED = 2;
  uint96 constant STATUS_CANCELLED = 3;

  uint96 constant OPTION_YES = 1;

  // TYPES
  enum ContractState {
    Working,
    Paused
  }

  struct NftSet {
    address contractAddress; // 20 bytes
    uint96 nftType; // 12 bytes
    uint[] tokenIds;
    uint[] amounts; // for ERC-1155 collection
  }

  struct Trade {
    bytes32 tradeId;
    address seller; // 20 bytes
    uint96 useFreeTxn; // 12 bytes
    address buyer; // 20 bytes
    uint96 status; // 12 bytes
    uint price;
    uint fee;
    uint feeDiscount;
    NftSet[] collection;
  }

  struct NewTradeArgs {
    NftSet[] collection;
    address buyer; // 20 bytes
    address referrer; // 20 bytes
    uint96 useFreeTxn; // 12 bytes
    uint price;
  }

  struct FeeConfig {
    uint feeBase;
    uint feePortion;
    uint minFee;
  }

  struct ReferralConfig {
    uint maxFeeDiscount;
    uint128 maxFreeRef;
    uint128 freeTxnsForInviter;
  }

  // STATES
  address public owner;
  address public commissionHolder;
  ContractState public contractStatus;

  // WETH contract address
  address public PaymentTokenAddress;

  // fee parameters
  FeeConfig public feeConfig;

  // referral parameters
  ReferralConfig public referralConfig;

  // all stored trades
  mapping(bytes32 => Trade) trades;
  // list of trade ids of users
  mapping(address => bytes32[]) userTradeIds;
  // referrer of any user
  mapping(address => address) userReferrer;
  // number of trades of each user
  mapping(address => uint) userTradesCount;
  // number of sold trades of each user
  mapping(address => uint) userSoldTradesCount;
  // number of invited friends of each user
  mapping(address => uint) userInvitesCount;
  // number of free txns of each user
  mapping(address => uint) userFreeTxns;

  uint public tradesCount; // total trades count from the beginning, initial value is 0

  // EVENTS
  event LogContractStatusChanged(ContractState newStatus);
  event LogCommissionRateUpdated(FeeConfig newFeeConfig);
  event LogReferralInfoUpdated(ReferralConfig newReferralConfig);
  event LogNewTradeCreated(bytes32 tradeId, address indexed _seller, address indexed _buyer, Trade newTrade);
  event LogTradeStatusChanged(bytes32 tradeId, address indexed _seller, address indexed _buyer, uint96 newStatus);
  event LogTradePriceChanged(bytes32 tradeId, address indexed _buyer, uint newPrice);
  event LogTradeBuyerChanged(bytes32 tradeId, address indexed oldBuyer, address indexed newBuyer);
  event LogUserFreeTxnsChanged(address indexed user, uint newAmount, bytes32 fromTradeId);
  event LogUserTradesCountChanged(address indexed user, uint count);
  event LogUserSoldTradesCountChanged(address indexed user, uint count);

  // MODIFIERS
  modifier onlyOwner {
    require(msg.sender == owner, 'For-Owner');
    _;
  }

  modifier onlySeller(bytes32 tradeId) {
    require(msg.sender == trades[tradeId].seller, 'For-Seller');
    _;
  }

  modifier onlyCommissionHolder {
    require(msg.sender == commissionHolder, 'For-Commission-Holder');
    _;
  }

  modifier isListedTrade(bytes32 tradeId) {
    require(trades[tradeId].status == STATUS_LISTED, 'Not-Listed-Trade');
    _;
  }

  modifier isWorkingContract {
    require(contractStatus == ContractState.Working, 'Paused-Contract');
    _;
  }

  modifier validateTradePrice(uint price) {
    require(calculateFee(price) >= feeConfig.minFee, 'Fee-Too-Low');
    _;
  }

  // CONSTRUCTOR
  constructor(
    address _PaymentTokenAddress,
    address _commissionHolder,
    FeeConfig memory _feeConfig,
    ReferralConfig memory _referralConfig
  )
  {
    require(!nullAddress(_PaymentTokenAddress), 'Invalid-Payment-Address');
    require(!nullAddress(_commissionHolder), 'Invalid-Commision-Holder-Addess');
    require(_feeConfig.feePortion < _feeConfig.feeBase, 'Invalid-Fee-Config');

    owner = msg.sender;
    commissionHolder = _commissionHolder;
    contractStatus = ContractState.Working;

    // WETH token
    PaymentTokenAddress = _PaymentTokenAddress;

    // initial commission fee
    feeConfig = _feeConfig;

    // initial referral settings
    referralConfig = _referralConfig;
  }

  // RECEIVE

  // FALLBACK

  // EXTERNAL

  /**
  * @notice change contract owner to another address
  * Only owner can call this function
  *
  * @param newOwner address of new owner
  */
  function changeOwner(address newOwner)
    external
    onlyOwner
  {
    require(!nullAddress(newOwner), 'Invalid-Owner');

    owner = newOwner;
  }

  /**
   * @notice change the contract status
   * Only owner can call this function
   *
   * @param newStatus new status of contract
   * if this value is not from ContractState enum, txn'll be reverted.
   */
  function updateContractStatus(ContractState newStatus)
    external
    onlyOwner
  {
    contractStatus = newStatus;
    emit LogContractStatusChanged(contractStatus);
  }

  /**
   * @notice Adjust the commission fee
   * Only owner can call this function
   *
   * @param newFeeConfig commission fee settings
   */
  function adjustFeeConfig(FeeConfig calldata newFeeConfig)
    external
    onlyOwner
  {
    require(newFeeConfig.feePortion < newFeeConfig.feeBase, 'Invalid-Fee-Config');

    feeConfig = newFeeConfig;
    emit LogCommissionRateUpdated(feeConfig);
  }

  /**
   * @notice Adjust the Referral Config
   * Only owner can call this function
   *
   * @param newReferralConfig referral settings
   */
  function adjustReferralConfig(ReferralConfig calldata newReferralConfig)
    external
    onlyOwner
  {
    referralConfig = newReferralConfig;
    emit LogReferralInfoUpdated(referralConfig);
  }

  /**
   * @notice update one user free txns
   * Only owner can call this function to reward user free txns
   *
   * @param user address of user
   * @param amount amount of free txns to reward
   */
  function rewardFreeTxns(address user, int amount)
    external
    onlyOwner
  {
    // if tradeId is 0 => rewarded free txns, not from referral scheme
    updateUserFreeTxns(user, amount, 0);
  }

  /**
  * @notice change commissionHolder to another address
  * Only commissionHolder can call this function
  *
  * @param newHolder address of new holder
  */
  function changeCommissionHolder(address newHolder)
    external
    onlyCommissionHolder
  {
    require(!nullAddress(newHolder), 'Invalid-Holder');

    commissionHolder = newHolder;
  }

  /**
   * @notice create new trade
   *
   * @param args parameters for creating new trade
   *
   * @dev collection need to be put in following structure
   * [
   *   {
   *     contractAddress: tokenAddress0,
   *     nftType: erc721|erc1155,
   *     tokenIds: [tokenId0, tokenId1, ...],
   *     amounts: [tokenId0_amount, tokenId1_amount,...]
   *   },
   *   ...
   * ]
   *
   * All collections MUST have approveAll set to TioSwap contract
   * All NFTs will still be seller's assets.
   */
  function createTrade(NewTradeArgs calldata args)
    external
    nonReentrant
    isWorkingContract
    validateTradePrice(args.price)
  {
    bool noReferrerArgument = nullAddress(args.referrer);
    bool noSavedReferrer = nullAddress(userReferrer[msg.sender]);

    require(args.collection.length > 0, 'Empty-Collection');
    require(args.buyer != msg.sender, 'Invalid-Buyer');

    // referrer argument
    require(
      noReferrerArgument
      ||
      (
        // has no saved referrer
        noSavedReferrer
        &&
        // referrer must not be caller
        args.referrer != msg.sender
        &&
        // referrer must be qualified account
        userSoldTradesCount[args.referrer] > 0
        &&
        // seller must be new user
        userTradesCount[msg.sender] == 0
      ),
      'Referrer-Not-Accepted'
    );

    // free txn requirement
    require(
      (args.useFreeTxn != OPTION_YES)
      ||
      (noReferrerArgument && userFreeTxns[msg.sender] > 0),
      'No-Free-Txn'
    );

    // init new trade
    bytes32 newTradeId = keccak256(abi.encodePacked(tradesCount++));
    Trade storage newTrade = trades[newTradeId];

    // verify all collections
    for(uint i = 0; i < args.collection.length; i++) {
      address _contract = args.collection[i].contractAddress;
      uint[] memory tokenIds = args.collection[i].tokenIds;
      bool isErc721 = (args.collection[i].nftType == TYPE_ERC721);
      uint numberOfTokens = tokenIds.length;

      // verify contract
      bool collectionCheck = (
        (numberOfTokens > 0)
        &&
        (
          (
            isErc721
            &&
            IERC721(_contract).supportsInterface(IERC721_INTERFACE_ID)
            &&
            IERC721(_contract).isApprovedForAll(msg.sender, address(this))
          )
          ||
          (
            !isErc721
            &&
            numberOfTokens == args.collection[i].amounts.length
            &&
            IERC1155(_contract).supportsInterface(IERC1155_INTERFACE_ID)
            &&
            IERC1155(_contract).isApprovedForAll(msg.sender, address(this))
          )
        )
      );

      // check contract compliance
      if (collectionCheck) {
        // ERC721 COLLECTION
        if (isErc721) {
          // check owner of each token
          uint j = 0;
          while (j < numberOfTokens && collectionCheck){
            collectionCheck = (IERC721(_contract).ownerOf(tokenIds[j]) == msg.sender);
            j++;
          }
        }
        // ERC1155 COLLECTION
        else {
          // check balance of each tokens
          address[] memory accounts = new address[](numberOfTokens);
          uint j = 0;
          while (j < numberOfTokens && collectionCheck) {
            accounts[j] = msg.sender;
            // zero amount?
            if (args.collection[i].amounts[j] == 0)
              collectionCheck = false;
            j++;
          }

          // balance batch call
          uint[] memory tokenBalances;
          if (collectionCheck)
            tokenBalances = IERC1155(_contract).balanceOfBatch(accounts, tokenIds);

          // check balance
          j = 0;
          while (j < numberOfTokens && collectionCheck) {
            collectionCheck = (tokenBalances[j] >= args.collection[i].amounts[j]);
            j++;
          }
        }
      }

      // revert on failed collection
      if (!collectionCheck)
        revert('Collection-Check-Fail');

      // pick this collection
      newTrade.collection.push(args.collection[i]);
    }

    // store new trade
    newTrade.tradeId = newTradeId;
    newTrade.status = STATUS_LISTED;
    newTrade.seller = msg.sender;
    newTrade.buyer = args.buyer;
    newTrade.price = args.price;
    newTrade.fee = calculateFee(args.price);

    // referrer is only saved once
    if (noSavedReferrer && !noReferrerArgument)
      userReferrer[msg.sender] = args.referrer;

    // seller wants to use 1 free txn
    if (args.useFreeTxn == OPTION_YES) {
      newTrade.useFreeTxn = OPTION_YES;

      // remove 1 free txn
      updateUserFreeTxns(msg.sender, -1, newTradeId);
    }

    // add this trade to seller trades list
    userTradeIds[msg.sender].push(newTradeId);

    // increase seller trades count
    increaseUserTradesCount(msg.sender);

    // emit new trade event
    emit LogNewTradeCreated(newTradeId, msg.sender, newTrade.buyer, newTrade);
  }

  /**
   * @notice update trade price
   * Only seller can call this function on Listed trades only
   * Fee will be re-racalculated & verified
   *
   * @param tradeId id of the trade
   * @param newPrice new price
   */
  function changeTradePrice(bytes32 tradeId, uint newPrice)
    external
    isWorkingContract
    onlySeller(tradeId)
    validateTradePrice(newPrice)
    isListedTrade(tradeId)
  {
    Trade storage trade = trades[tradeId];
    trade.price = newPrice;
    trade.fee = calculateFee(newPrice);
    emit LogTradePriceChanged(tradeId, trade.buyer, newPrice);
  }

  /**
   * @notice update the buyer address that seller want to sell to
   * Only seller can call this function on Listed trades only
   *
   * @param tradeId id of the trade
   * @param newBuyer address of new buyer
   */
  function changeTradeBuyer(bytes32 tradeId, address newBuyer)
    external
    isWorkingContract
    onlySeller(tradeId)
    isListedTrade(tradeId)
  {
    require(newBuyer != msg.sender, 'Invalid-Buyer');

    emit LogTradeBuyerChanged(tradeId, trades[tradeId].buyer, newBuyer);
    trades[tradeId].buyer = newBuyer;
  }

  /**
   * @notice seller cancel the trade
   * Only seller can call this function on Listed trades only
   *
   * @param tradeId id of the trade
   */
  function cancelTrade(bytes32 tradeId)
    external
    isWorkingContract
    onlySeller(tradeId)
    isListedTrade(tradeId)
  {
    Trade storage trade = trades[tradeId];

    // update trade status first
    trade.status = STATUS_CANCELLED;

    // add 1 freeTxn back to user if 1 freeTxn is used to create this trade
    if (trade.useFreeTxn == OPTION_YES)
      updateUserFreeTxns(msg.sender, 1, tradeId);

    emit LogTradeStatusChanged(tradeId, trade.seller, trade.buyer, STATUS_CANCELLED);
  }

  /**
   * @notice buyer finalizes the trade
   * The trade MUST be in Listed status
   *  - 1. buyer needs to approve WETH transfer permission
   *  - 2. an amount of full price will be transfered to TioSwap smartcontract
   *  - 3. the nfts will be sent to buyer
   *  - 4. the amount of ether minus commission fee after discount will be sent to seller
   *
   * @param tradeId id of the trade
   * @param checkPrice the price that buyer sees and agrees to buy
   */
  function finalizeTrade(bytes32 tradeId, uint checkPrice)
    external
    isWorkingContract
    isListedTrade(tradeId)
    nonReentrant
  {
    Trade storage trade = trades[tradeId];

    address seller = trade.seller;
    address buyer = trade.buyer;
    address referrer = userReferrer[seller];

    require(
      (msg.sender != seller)
      &&
      (nullAddress(buyer) || buyer == msg.sender)
      &&
      (trade.price == checkPrice),
      'Invalid-Caller|Price'
    );

    // transfer all NFTs from seller to buyer
    for(uint i = 0; i < trade.collection.length; i++) {
      address _contract = trade.collection[i].contractAddress;
      uint[] memory tokenIds = trade.collection[i].tokenIds;

      // erc721 token transfer
      if (trade.collection[i].nftType == TYPE_ERC721) {
        for(uint j = 0; j < tokenIds.length; j++) {
          // not have return value
          IERC721(_contract)
            .safeTransferFrom(
              seller,
              msg.sender,
              tokenIds[j]
            );
        }
      } else {
        // erc1155 batch transfer
        // not have return value
        IERC1155(_contract)
          .safeBatchTransferFrom(
            seller,
            msg.sender,
            tokenIds,
            trade.collection[i].amounts,
            ''
          );
      }
    }

    // default fee discount
    uint feeDiscount = referralConfig.maxFeeDiscount;

    // this is the 1st trade of invitee
    if (!nullAddress(referrer) && userSoldTradesCount[seller] == 0) {
      // count invites for referrer
      userInvitesCount[referrer]++;

      // reward referrer free txns
      if (userInvitesCount[referrer] <= referralConfig.maxFreeRef)
        updateUserFreeTxns(referrer, int(int128(referralConfig.freeTxnsForInviter)), tradeId);
    } else if (trade.useFreeTxn != OPTION_YES) {
      feeDiscount = 0;
    }

    // maximum discount is the calculated fee
    if (feeDiscount > trade.fee)
      feeDiscount = trade.fee;

    // calculate the actual fee after discount
    uint feeAfterDiscount = trade.fee - feeDiscount;

    // transfer amount of (WETH - (fee - discount)) to seller
    if (IERC20(PaymentTokenAddress).transferFrom(msg.sender, seller, (trade.price - feeAfterDiscount)) == false)
      revert('Payment-Fail');

    // transfer commission fee to commissionHolder
    if ((feeAfterDiscount > 0) && (IERC20(PaymentTokenAddress).transferFrom(msg.sender, commissionHolder, feeAfterDiscount) == false))
      revert('Commission-Fail');

    // save fee discount
    trade.feeDiscount = feeDiscount;

    // update trade buyer
    if (nullAddress(buyer)) {
      trade.buyer = msg.sender;
      emit LogTradeBuyerChanged(tradeId, address(0x0), msg.sender);
    }

    // add this trade to buyer trades list
    userTradeIds[msg.sender].push(tradeId);

    // increase number of trades of buyer
    increaseUserTradesCount(msg.sender);

    // update success trade count for seller
    increaseUserSoldTradesCount(seller);

    // completed status
    trade.status = STATUS_COMPLETED;
    emit LogTradeStatusChanged(tradeId, trade.seller, trade.buyer, STATUS_COMPLETED);
  }

  // PUBLIC FUNCTIONS

  /**
   * @notice get the trade by id
   *
   * @param tradeId id of the trade
   *
   * @return trade data
   */
  function getTrade(bytes32 tradeId) external view returns (Trade memory) {
    return trades[tradeId];
  }

  /**
   * @notice get trade ids of one user
   *
   * @param user address of user
   *
   * @return array of trade ids
   */
  function getUserTradeIds(address user) external view returns (bytes32[] memory) {
    return userTradeIds[user];
  }

  /**
   * @notice get total trades count of one user
   *
   * @param user address of user
   *
   * @return number of trades (seller and buyer sides)
   */
  function getUserTradesCount(address user) external view returns (uint) {
    return userTradesCount[user];
  }

  /**
   * @notice get referrer address of one user
   *
   * @param user address of user
   *
   * @return user's referrer
   */
  function getUserReferrer(address user) external view returns (address) {
    return userReferrer[user];
  }

  /**
   * @notice get sold trades count of one user
   *
   * @param user address of user
   *
   * @return number of user's sold tr
   */
  function getUserSoldTradesCount(address user) external view returns (uint) {
    return userSoldTradesCount[user];
  }

  /**
   * @notice get the referral count of one user
   *
   * @param user address of user
   *
   * @return number of user's referral
   */
  function getUserInvitesCount(address user) external view returns (uint) {
    return userInvitesCount[user];
  }

  /**
   * @notice get the number of free txns of one user
   *
   * @param user address of user
   *
   * @return number of user's free txns
   */
  function getUserFreeTxns(address user) external view returns (uint) {
    return userFreeTxns[user];
  }

  // INTERNAL FUNCTIONS

  /**
   * calculate actual fee
   */
  function calculateFee(uint price) internal view returns (uint) {
    return (price * feeConfig.feePortion) / feeConfig.feeBase;
  }

  /**
   * not null address check
   */
  function nullAddress(address _address) internal pure returns (bool) {
    return _address == address(0x0);
  }

  // PRIVATE FUNCTIONS

  /**
   * update user freeTxns, emit the event
   */
  function updateUserFreeTxns(address user, int amount, bytes32 tradeId) private {
    int _amount = int(userFreeTxns[user]) + amount;
    userFreeTxns[user] = _amount > 0 ? uint(_amount) : 0;
    emit LogUserFreeTxnsChanged(user, userFreeTxns[user], tradeId);
  }

  /**
   * increase user total trades count by 1, emit the event
   */
  function increaseUserTradesCount(address user) private {
    userTradesCount[user]++;
    emit LogUserTradesCountChanged(user, userTradesCount[user]);
  }

  /**
   * increate user sold trades count by 1, emit the event
   */
  function increaseUserSoldTradesCount(address user) private {
    userSoldTradesCount[user]++;
    emit LogUserSoldTradesCountChanged(user, userSoldTradesCount[user]);
  }

}