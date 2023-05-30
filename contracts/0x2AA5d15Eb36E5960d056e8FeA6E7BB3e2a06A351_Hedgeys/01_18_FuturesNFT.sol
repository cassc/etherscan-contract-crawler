// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './libraries/TransferHelper.sol';

/**
 * @title An NFT representation of ownership of time locked tokens
 * @notice The time locked tokens are redeemable by the owner of the NFT
 * @notice The NFT is basic ERC721 with an ownable usage to ensure only a single owner call mint new NFTs
 * @notice it uses the Enumerable extension to allow for easy lookup to pull balances of one account for multiple NFTs
 */
contract Hedgeys is ERC721Enumerable, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  /// @dev handles weth in case WETH is being held - this allows us to unwrap and deliver ETH upon redemption of a timelocked NFT with ETH
  address payable public weth;
  /// @dev baseURI is the URI directory where the metadata is stored
  string private baseURI;
  /// @dev this is a counter used so that the baseURI can only be set once after deployment
  uint8 private uriSet = 0;

  /// @dev the Future is the storage in a struct of the tokens that are time locked
  /// @dev the Future contains the information about the amount of tokens, the underlying token address (asset), and the date in which they are unlocked
  struct Future {
    uint256 amount;
    address token;
    uint256 unlockDate;
  }

  /// @dev this maping maps the _tokenIDs from Counters to a Future struct. the same _tokenIDs that is set for the NFT id is mapped to the futures
  mapping(uint256 => Future) public futures;

  constructor(address payable _weth, string memory uri) ERC721('Hedgeys', 'HDGY') {
    weth = _weth;
    baseURI = uri;
  }

  receive() external payable {}

  /**
   * @notice The external function creates a Future position
   * @notice This function does not accept ETH, must send in WETH to lock ETH
   * @notice A Future position is the combination of an NFT and a Future struct with the same _tokenID storing both information separately but with the same index
   * @notice Anyone can mint an NFT & create a futures Struct, so long as they have sufficient tokens to lock up
   * @notice A user can mint the NFT to themselves, passing in their address to the first parameter, or they can directly mint an NFT to someone else
   * @param _holder is the owner of the minted NFT and the owner of the locked tokens
   * @param _amount is the amount with full decimals of the tokens being locked into the future
   * @param _token is the address of the tokens that are being delivered to this contract to be held and locked
   * @param _unlockDate is the date in UTC in which the tokens can become redeemed - evaluated based on the block.timestamp
   */
  function createNFT(
    address _holder,
    uint256 _amount,
    address _token,
    uint256 _unlockDate
  ) external nonReentrant returns (uint256) {
    /// @dev increment our counter by 1
    _tokenIds.increment();
    /// @dev set our newItemID do the current counter uint
    uint256 newItemId = _tokenIds.current();
    /// @dev require that the amount is not 0, address is not the 0 address, and that the expiration date is actually beyond now
    require(_amount > 0 && _token != address(0) && _unlockDate > block.timestamp, 'NFT01');
    /// @dev using the same newItemID we generate a Future struct recording the token address (asset), the amount of tokens (amount), and time it can be unlocked (_unlockDate)
    futures[newItemId] = Future(_amount, _token, _unlockDate);
    /// @dev pulls funds from the msg.sender into this contract for escrow to be locked until the unlockDate has passed
    TransferHelper.transferTokens(_token, msg.sender, address(this), _amount);
    /// @dev this safely mints an NFT to the _holder address at the current counter index newItemID.
    /// @dev _safeMint ensures that the receiver address can receive and handle ERC721s - which is either a normal wallet, or a smart contract that has implemented ERC721 receiver
    _safeMint(_holder, newItemId);
    /// @dev emit an event with the details of the NFT id minted, plus the attributes of the locked tokens
    emit NFTCreated(newItemId, _holder, _amount, _token, _unlockDate);
    return newItemId;
  }

  /// @dev internal function used by the standard ER721 function tokenURI to retrieve the baseURI privately held to visualize and get the metadata
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  /// @notice function to set the base URI after the contract has been launched, only once - this is done by the admin
  /// @notice there is no actual on-chain functions that require this URI to be anything beyond a blank string ("")
  /// @param _uri is the
  function updateBaseURI(string memory _uri) external {
    /// @dev this function can only be called once - when the public variable uriSet is set to 0
    require(uriSet == 0, 'NFT02');
    /// @dev update the baseURI with the new _uri
    baseURI = _uri;
    /// @dev set the public variable uriSet to 1 so that this function cannot be called anymore
    /// @dev cheaper to use uint8 than bool for this admin safety feature
    uriSet = 1;
    /// @dev emit event of the update uri
    emit URISet(_uri);
  }

  /// @notice this is the external function that actually redeems an NFT position
  /// @notice returns true if the function is successful
  /// @dev this function calls the _redeemFuture(...) internal function which handles the requirements and checks
  function redeemNFT(uint256 _id) external nonReentrant returns (bool) {
    /// @dev calls the internal _redeemNFT function that performs various checks to ensure that only the owner of the NFT can redeem their NFT and Future position
    _redeemNFT(payable(msg.sender), _id);
    return true;
  }

  /**
   * @notice This internal function, called by redeemNFT to physically burn the NFT and redeem their Future position which distributes the locked tokens to its owner
   * @dev this function does five things: 1) Checks to ensure only the owner of the NFT can call this function
   * @dev 2) it checks that the tokens can actually be unlocked based on the time from the expiration
   * @dev 3) it burns the NFT - removing it from storage entirely
   * @dev 4) it also deletes the futures struct from storage so that nothing can be redeemed from that storage index again
   * @dev 5) it withdraws the tokens that have been locked - delivering them to the current owner of the NFT
   * @param _holder is the owner of the NFT calling the function
   * @param _id is the unique id of the NFT and unique id of the Future struct
   */
  function _redeemNFT(address payable _holder, uint256 _id) internal {
    /// @dev ensure that only the owner of the NFT can call this function
    require(ownerOf(_id) == _holder, 'NFT03');
    /// @dev pull the future data from storage and keep in memory to check requirements and disribute tokens
    Future memory future = futures[_id];
    /// @dev ensure that the unlockDate is in the past compared to block.timestamp
    /// @dev ensure that the future has not been redeemed already and that the amount is greater than 0
    require(future.unlockDate < block.timestamp && future.amount > 0, 'NFT04');
    /// @dev emit an event of the redemption, the id of the NFt and details of the future (locked tokens)  - needs to happen before we delete the future struct and burn the NFT
    emit NFTRedeemed(_id, _holder, future.amount, future.token, future.unlockDate);
    /// @dev burn the NFT
    _burn(_id);
    /// @dev delete the futures struct so that the owner cannot call this function again
    delete futures[_id];
    /// @dev physically deliver the tokens to the NFT owner
    TransferHelper.withdrawPayment(weth, future.token, _holder, future.amount);
  }

  ///@notice Events when a new NFT (future) is created and one with a Future is redeemed (burned)
  event NFTCreated(uint256 _i, address _holder, uint256 _amount, address _token, uint256 _unlockDate);
  event NFTRedeemed(uint256 _i, address _holder, uint256 _amount, address _token, uint256 _unlockDate);
  event URISet(string newURI);
}