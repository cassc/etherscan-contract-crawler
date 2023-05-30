// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import './ERC721Delegate/ERC721Delegate.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './libraries/TransferHelper.sol';
import './libraries/StreamLibrary.sol';
import './interfaces/IStreamNFT.sol';

/**
 * @title An NFT representation of ownership of time vesting tokens that vest continuously per second
 * @notice The time vesting tokens are redeemable by the owner of the NFT
 * @notice each NFT has a vestingAdmin that can revoke the NFT and pull and unvested tokens back to it at any time
 * @notice this bound NFT collection cannot be transferred
 * @notice it uses the Enumerable extension to allow for easy lookup to pull balances of one account for multiple NFTs
 * it also uses a new ERC721 Delegate contract that allows users to delegate their NFTs to other wallets for the purpose of voting
 * @author alex michelsen aka icemanparachute
 */

contract StreamVestingNFT is ERC721Delegate, ReentrancyGuard {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  /// @dev baseURI is the URI directory where the metadata is stored
  string private baseURI;
  /// @dev bool to ensure uri has been set before admin can be deleted
  bool private uriSet;
  /// @dev admin for setting the baseURI;
  address private admin;

  mapping(bool => address) private nftLockers;

  /// @dev the Stream is the storage in a struct of the tokens that are currently being streamed
  /// @dev token is the token address being streamed
  /// @dev amount is the total amount of tokens in the stream, which is comprised of the balance and the remainder
  /// @dev start is the start date when token stream begins, this can be set at anytime including past and future
  /// @dev cliffDate is an optional field to add a single cliff date prior to which the tokens cannot be unlocked
  /// @dev rate is the number of tokens per second being streamed
  /// @dev vestingAdmin is the address of a vesting administor that can revoke NFTs and pull unvested tokens to its wallet any time.
  /// @dev unlockDate is the date set for an optional lockup period, that the vested tokens may be subject to
  /// @dev in the case where there is an unlockDate, this is enforced via vested tokens being transferred to and minting an NFT of either the StreamingHedgeys or StreamingBoundHedgeys - determined by the true or false of this param
  struct Stream {
    address token;
    uint256 amount;
    uint256 start;
    uint256 cliffDate;
    uint256 rate;
    address vestingAdmin;
    uint256 unlockDate;
    bool transferableNFTLocker;
  }

  mapping(uint256 => Stream) public streams;

  ///@notice Events when a new NFT (future) is created and one with a Future is redeemed (burned)
  event NFTCreated(
    uint256 indexed id,
    address indexed recipient,
    address indexed token,
    uint256 amount,
    uint256 start,
    uint256 cliffDate,
    uint256 end,
    uint256 rate,
    address vestingAdmin,
    uint256 unlockDate,
    bool transferableNFTLocker
  );

  event NFTRevoked(uint256 indexed id, uint256 balance, uint256 remainder);
  /// @notice event when the NFT is redeemed, there are two redemption types, partial and full redemption
  /// if the remainder == 0 then it is a full redemption and the NFT is burned, otherwise it is a partial redemption
  event NFTRedeemed(uint256 indexed id, uint256 balance, uint256 remainder, uint256 newStart);
  /// @notice event for when a new URI is set for the NFT metadata linking
  event URISet(string newURI);

  event AdminDeleted(address _admin);

  /// @notice the constructor function has two params:
  /// @param name is the name of the collection of NFTs
  /// @param symbol is the symbol for the NFT collection, typically an abbreviated version of the name
  constructor(
    string memory name,
    string memory symbol,
    address transferNFTLocker,
    address nontransferNFTLocker
  ) ERC721(name, symbol) {
    require(transferNFTLocker != address(0) && nontransferNFTLocker != address(0));
    admin = msg.sender;
    nftLockers[true] = transferNFTLocker;
    nftLockers[false] = nontransferNFTLocker;
  }

  /// @dev internal function used by the standard ER721 function tokenURI to retrieve the baseURI privately held to visualize and get the metadata
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  /// @notice function to set the base URI after the contract has been launched, only the admin can call
  /// @param _uri is the new baseURI for the metadata
  function updateBaseURI(string memory _uri) external {
    require(msg.sender == admin, 'SV01');
    baseURI = _uri;
    uriSet = true;
    emit URISet(_uri);
  }

  /// @notice function to delete the admin once the uri has been set
  function deleteAdmin() external {
    require(msg.sender == admin, 'SV01');
    require(uriSet, 'not set');
    delete admin;
    emit AdminDeleted(msg.sender);
  }

  /// @notice createNFT function is the function to mint a new NFT and simultaneously create a time vesting stream of tokens
  /// @param recipient is the recipient of the NFT. It can be the self minted to oneself, or minted to a different address than the caller of this function
  /// @param token is the token address of the tokens that will be vesting inside the stream
  /// @param amount is the total amount of tokens to be locked and vesting for the duration of the streaming unlock period
  /// @param start is the start date for when the tokens start to become vested, this can be past dated, present or future dated using unix timestamp
  /// @param cliffDate is an optional parameter to allow a future single cliff date where tokens will be vested.
  /// If the start date of vest is prior to the cliff, then on the cliff anything vested from the start will immediately be vested at the cliffdate
  /// @param rate is the rate tokens are continuously vesting, in seconds
  /// @param vestingAdmin is the admin of the vesting contract who has the enormous power to revoke the vesting stream at any time prior to full vest date
  function createNFT(
    address recipient,
    address token,
    uint256 amount,
    uint256 start,
    uint256 cliffDate,
    uint256 rate,
    address vestingAdmin
  ) external nonReentrant {
    _createNFT(recipient, token, amount, start, cliffDate, rate, vestingAdmin, 0, false);
  }

  /// @notice createLockedNFT function is the function to mint a new NFT and simultaneously create a time vesting stream of tokens,
  /// with the caveat that vested tokens are subjext to a lockup period, such that even once tokens are vested they can only be redeemed after the unlock date has passed
  /// @param recipient is the recipient of the NFT. It can be the self minted to oneself, or minted to a different address than the caller of this function
  /// @param token is the token address of the tokens that will be vesting inside the stream
  /// @param amount is the total amount of tokens to be locked and vesting for the duration of the streaming unlock period
  /// @param start is the start date for when the tokens start to become vested, this can be past dated, present or future dated using unix timestamp
  /// @param cliffDate is an optional parameter to allow a future single cliff date where tokens will be vested.
  /// If the start date of vest is prior to the cliff, then on the cliff anything vested from the start will immediately be vested at the cliffdate
  /// @param rate is the rate tokens are continuously vesting, in seconds
  /// @param vestingAdmin is the admin of the vesting contract who has the enormous power to revoke the vesting stream at any time prior to full vest date
  /// @param unlockDate is an optional field to insert a date that vested tokens unlock after. In the case of tokens being revoked, they will be transferred to another Hedgey NFT
  /// @param transferableNFTLocker is a bool that describes if vested tokens, when still locked and  get revoked, mint a hedgey NFT that is transferrable or not transferrable
  function createLockedNFT(
    address recipient,
    address token,
    uint256 amount,
    uint256 start,
    uint256 cliffDate,
    uint256 rate,
    address vestingAdmin,
    uint256 unlockDate,
    bool transferableNFTLocker
  ) external nonReentrant {
    _createNFT(recipient, token, amount, start, cliffDate, rate, vestingAdmin, unlockDate, transferableNFTLocker);
  }

  function _createNFT(
    address recipient,
    address token,
    uint256 amount,
    uint256 start,
    uint256 cliffDate,
    uint256 rate,
    address vestingAdmin,
    uint256 unlockDate,
    bool transferableNFTLocker
  ) internal {
    require(recipient != address(0) && recipient != vestingAdmin, 'SV02');
    require(token != address(0), 'SV03');
    require(amount > 0, 'SV04');
    require(rate > 0 && rate <= amount, 'SV05');
    _tokenIds.increment();
    uint256 newItemId = _tokenIds.current();
    uint256 end = StreamLibrary.endDate(start, rate, amount);
    require(cliffDate <= end && (unlockDate <= end + 3650 days), 'SV12');
    TransferHelper.transferTokens(token, msg.sender, address(this), amount);
    streams[newItemId] = Stream(token, amount, start, cliffDate, rate, vestingAdmin, unlockDate, transferableNFTLocker);
    _safeMint(recipient, newItemId);
    emit NFTCreated(
      newItemId,
      recipient,
      token,
      amount,
      start,
      cliffDate,
      end,
      rate,
      vestingAdmin,
      unlockDate,
      transferableNFTLocker
    );
  }

  /// @dev function to delegate specific tokens to another wallet for voting
  /// @param delegate is the address of the wallet to delegate the NFTs to
  /// @param tokenIds is the array of tokens that we want to delegate
  function delegateTokens(address delegate, uint256[] memory tokenIds) external {
    for (uint256 i; i < tokenIds.length; i++) {
      _delegateToken(delegate, tokenIds[i]);
    }
  }

  /// @dev this function is to delegate all NFTs to another wallet address
  /// it pulls any tokens of the owner and delegates the NFT to the delegate address
  /// @param delegate is the address of the delegate
  function delegateAllNFTs(address delegate) external {
    uint256 balance = balanceOf(msg.sender);
    for (uint256 i; i < balance; i++) {
      uint256 tokenId = _tokenOfOwnerByIndex(msg.sender, i);
      _delegateToken(delegate, tokenId);
    }
  }

  /// @notice function to redeem a single or multiple NFT streams
  /// @param tokenIds is an array of tokens that are passed in to be redeemed
  function redeemNFTs(uint256[] memory tokenIds) external nonReentrant {
    _redeemNFTs(tokenIds);
  }

  /// @notice function to claim for all of my owned NFTs
  /// @dev pulls the balance and uses the enumerate function to redeem each NFT based on their index id
  /// this function will not revert if there is no balance, it will simply redeem all NFTs owned by the msg.sender that have a balance
  function redeemAllNFTs() external nonReentrant {
    uint256 balance = balanceOf(msg.sender);
    uint256[] memory tokenIds = new uint256[](balance);
    for (uint256 i; i < balance; i++) {
      //check the balance of the vest first
      uint256 tokenId = _tokenOfOwnerByIndex(msg.sender, i);
      tokenIds[i] = tokenId;
    }
    _redeemNFTs(tokenIds);
  }

  /// @dev function for the vestingAdmin to revoke tokens if someone is no longer supposed to recieve their vesting stream
  /// @param tokenIds are the tokens that are going to be revoked
  function revokeNFTs(uint256[] memory tokenIds) external nonReentrant {
    for (uint256 i; i < tokenIds.length; i++) {
      _revokeNFT(msg.sender, tokenIds[i]);
    }
  }

  /// @dev function to redeem the multiple NFTs
  /// @dev internal method used for the redeemNFT and redeemAllNFTs to process multiple and avoid reentrancy
  function _redeemNFTs(uint256[] memory tokenIds) internal {
    for (uint256 i; i < tokenIds.length; i++) {
      (uint256 balance, ) = streamBalanceOf(tokenIds[i]);
      if (balance > 0 && streams[tokenIds[i]].unlockDate <= block.timestamp) {
        _redeemNFT(msg.sender, tokenIds[i]);
      }
    }
  }

  /// @dev internal redeem function that performs all of the necessary checks, updates to storage and transfers of tokens to the NFT holder
  /// @param holder is the owner of the NFT, the msg.sender from the external calls
  /// @param tokenId is the id of the NFT
  function _redeemNFT(address holder, uint256 tokenId) internal {
    require(ownerOf(tokenId) == holder, 'SV06');
    Stream memory stream = streams[tokenId];
    (uint256 balance, uint256 remainder) = StreamLibrary.streamBalanceAtTime(
      stream.start,
      stream.cliffDate,
      stream.amount,
      stream.rate,
      block.timestamp
    );
    if (balance == stream.amount) {
      delete streams[tokenId];
      _burn(tokenId);
    } else {
      streams[tokenId].amount -= balance;
      streams[tokenId].start = block.timestamp;
    }
    TransferHelper.withdrawTokens(stream.token, holder, balance);
    emit NFTRedeemed(tokenId, balance, remainder, block.timestamp);
  }

  /// @notice the intenral revoke function that the vestingAdmin may call to revoke tokens
  /// @dev this will delete the vesting stream, transfer any unvested tokens to the VestingAdmin
  /// @dev this will transfer any vested tokens to the holder, however if the tokens are still locked, then
  /// instead of receiving the tokens the holder will receive a new NFT with the locked tokens and a single unlock date
  /// @param vestingAdmin is the vesting admin of the vest stream
  /// @param tokenId is the NFT token ID to be revoked
  function _revokeNFT(address vestingAdmin, uint256 tokenId) internal {
    Stream memory stream = streams[tokenId];
    require(stream.vestingAdmin == vestingAdmin, 'SV09');
    (uint256 balance, uint256 remainder) = StreamLibrary.streamBalanceAtTime(
      stream.start,
      stream.cliffDate,
      stream.amount,
      stream.rate,
      block.timestamp
    );
    require(remainder > 0, 'SV10');
    address holder = ownerOf(tokenId);
    delete streams[tokenId];
    _burn(tokenId);
    TransferHelper.withdrawTokens(stream.token, vestingAdmin, remainder);
    if (balance > 0) {
      if (stream.unlockDate > block.timestamp) {
        mintLockedNFT(holder, stream.token, balance, stream.unlockDate, stream.transferableNFTLocker);
      } else {
        TransferHelper.withdrawTokens(stream.token, holder, balance);
      }
    }

    emit NFTRevoked(tokenId, balance, remainder);
  }

  /// @dev internal function for when tokens are revoked, but there is an amount vested that is still locked
  /// @dev this will mint a new NFT and lock the tokens with a new stream
  /// @param holder is the holder of the NFT who is receiving the locked tokens
  /// @param token is the token address to be locked
  /// @param amount is the amount of tokens to be locked - the vested balance
  /// @param unlockDate is the single date when the vested tokens become unlocked
  function mintLockedNFT(
    address holder,
    address token,
    uint256 amount,
    uint256 unlockDate,
    bool transferableNFTLockers
  ) internal {
    address nftLocker = nftLockers[transferableNFTLockers];
    SafeERC20.safeIncreaseAllowance(IERC20(token), nftLocker, amount);
    IStreamNFT(nftLocker).createNFT(holder, token, amount, unlockDate, unlockDate, amount);
  }

  /// @dev funtion to get the current balance and remainder of a given stream, using the current block time
  /// @param tokenId is the NFT token ID
  function streamBalanceOf(uint256 tokenId) public view returns (uint256 balance, uint256 remainder) {
    Stream memory stream = streams[tokenId];
    (balance, remainder) = StreamLibrary.streamBalanceAtTime(
      stream.start,
      stream.cliffDate,
      stream.amount,
      stream.rate,
      block.timestamp
    );
  }

  /// @dev function to calculate the end date in seconds of a given unlock stream
  /// @param tokenId is the NFT token ID
  function getStreamEnd(uint256 tokenId) external view returns (uint256 end) {
    Stream memory stream = streams[tokenId];
    end = StreamLibrary.endDate(stream.start, stream.rate, stream.amount);
  }

  /// @dev lockedBalances is a function that will enumerate all of the tokens of a given holder, and aggregate those balances up
  /// this is useful for snapshot voting and other view methods to see the total balances of a given user for a single token
  /// @param holder is the owner of the NFTs
  /// @param token is the address of the token that is locked by each of the NFTs
  function lockedBalances(address holder, address token) external view returns (uint256 lockedBalance) {
    uint256 holdersBalance = balanceOf(holder);
    for (uint256 i; i < holdersBalance; i++) {
      uint256 tokenId = _tokenOfOwnerByIndex(holder, i);
      Stream memory stream = streams[tokenId];
      if (token == stream.token) {
        lockedBalance += stream.amount;
      }
    }
  }

  /// @dev delegatedBAlances is a function that will enumerate all of the tokens of a given delegate, and aggregate those balances up
  /// this is useful for snapshot voting and other view methods to see the total balances of a given user for a single token
  /// @param delegate is the wallet that has been delegated NFTs
  /// @param token is the address of the token that is locked by each of the NFTs
  function delegatedBalances(address delegate, address token) external view returns (uint256 delegatedBalance) {
    uint256 delegateBalance = balanceOfDelegate(delegate);
    for (uint256 i; i < delegateBalance; i++) {
      uint256 tokenId = tokenOfDelegateByIndex(delegate, i);
      Stream memory stream = streams[tokenId];
      if (token == stream.token) {
        delegatedBalance += stream.amount;
      }
    }
  }

  /// @dev these NFTs cannot be transferred
  function _transfer(address from, address to, uint256 tokenId) internal virtual override {
    revert('Not transferrable');
  }
}