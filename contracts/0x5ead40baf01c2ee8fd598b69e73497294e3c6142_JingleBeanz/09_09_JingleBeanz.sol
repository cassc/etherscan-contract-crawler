// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";
import { IERC721 } from "openzeppelin-contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "openzeppelin-contracts/token/ERC1155/IERC1155.sol";
import { IERC721Receiver } from "openzeppelin-contracts/token/ERC721/IERC721Receiver.sol";
import { IERC1155Receiver } from "openzeppelin-contracts/token/ERC1155/IERC1155Receiver.sol";

enum State{ UNOPENED, SUBMISSION, GIFTING, CLOSED }

struct Gift {
  uint256 nextTouch;
  uint256 poolIndex;
  uint256 stolenCount;
  uint256 tokenId;
  address tokenContract;
}

/// @notice An implmentation of an NFT Secret Santa experiment.
/// @author JingleBeanz (github.com/heyskylark/jingle-beanz/jingle-contract/src/JingleBeanz.sol)
contract JingleBeanz is Ownable {
  /*//////////////////////////////////////////////
                      ERRORS
  //////////////////////////////////////////////*/

  error WrongState(State _currentState, State _requiredState);

  error AlreadySubmitted();

  error InvalidGift();

  error Unauthorized();

  error AlreadyHaveGift();

  error AlreadyOwnedGift();

  error GiftCooldownNotComplete();

  error GiftDoesNotExist();

  error MaxGiftSteals();

  error NoGiftOwner();

  error ZeroAddress();

  error OwnerWithdrawLocked();

  /*//////////////////////////////////////////////
                      EVENTS
  //////////////////////////////////////////////*/

  event Submitted(
    address indexed _from,
    uint256 indexed giftId,
    address tokenContract,
    uint256 tokenId
  );

  event Gifted(address indexed _to, uint256 indexed giftId);

  event Stolen(address indexed _from, address indexed _to, uint256 indexed giftId);

  event Withdraw(address indexed _to, uint256 indexed giftId);

  event StateChange(State indexed _state);

  /*//////////////////////////////////////////////
                      MODIFIERS
  //////////////////////////////////////////////*/

  /// @notice only allows submitted senders to make calls
  modifier onlySubmitted() {
    if (_giftGiver[msg.sender] == 0) revert Unauthorized();
    _;
  }

  /// @notice only allows a call to be made when the contract is set to a specific state
  modifier onlyWhenState(State _state) {
    if (_state != state) revert WrongState(state, _state);
    _;
  }

  /*//////////////////////////////////////////////
              JINGLE METADATA STORAGE
  //////////////////////////////////////////////*/

  State public state;

  uint256 public giftId;
  
  uint256 public poolSize;

  bytes32 public userMerkleRoot;

  bytes32 public giftMerkleRoot;

  uint256 private seed;

  uint256 private withdrawReleaseDate;

  uint256 constant public STEAL_COOLDOWN = 6 hours;

  /// @dev lockout so owner can withdraw and raffle off stray gifts that were never picked up (5 day game + 14 day lockout)
  uint256 constant public OWNER_WITHDRAW_LOCKOUT = 19 days;

  /*//////////////////////////////////////////////
                    GIFT STORAGE
  //////////////////////////////////////////////*/

  /// @notice a mapping to keep track of all unclaimed gifts in a pool
  /// @dev cheaper to swap gift IDs outside of the pool size than whole gift struct
  /// @dev due to being unsure of the final array size until after submissions are closed I figuered mapping would be more efficient
  mapping(uint256 => uint256) internal _giftPool;

  /// @notice a mapping of gift IDs to gift
  mapping(uint256 => Gift) internal _gift;

  function gift(uint256 _giftId) public view returns (Gift memory returnGift) {
    returnGift = _gift[_giftId];
    if (returnGift.tokenContract == address(0)) revert GiftDoesNotExist();
  }

  /// @notice a mapping of gift giver address to gift ID
  mapping(address => uint256) internal _giftGiver;

  function giftGiver(address _giver) public view returns (uint256) {
    if (_giver == address(0)) {
      revert ZeroAddress();
    }

    return _giftGiver[_giver];
  }

  /// @notice given a gift ID returns current owner of claimed gift
  mapping(uint256 => address) internal _ownerOf;

  function ownerOf(uint256 _giftId) public view returns (address giftOwner) {
    if ((giftOwner = _ownerOf[_giftId]) == address(0)) revert NoGiftOwner();
  }

  /// @notice returns the gift ID the address owns
  mapping(address => uint256) internal _ownsGift;

  function ownsGift(address _owner) public view returns (uint256) {
    if (_owner == address(0)) {
      revert ZeroAddress();
    }

    return _ownsGift[_owner];
  }

  /// @notice a mapping to check if a user has been in contact with a gift before
  mapping(address => mapping(uint256 => bool)) internal _touchedGift;

  function touchedGift(address _user, uint256 _giftId) public view returns (bool) {
    if (_user == address(0)) {
      revert ZeroAddress();
    }

    return _touchedGift[_user][_giftId];
  }

  /*//////////////////////////////////////////////
                    CONSTRUCTOR
  //////////////////////////////////////////////*/

  constructor(bytes32 _userMerkleRoot, bytes32 _giftMerkleRoot) {
    state = State.UNOPENED;
    userMerkleRoot = _userMerkleRoot;
    giftMerkleRoot = _giftMerkleRoot;

    withdrawReleaseDate = block.timestamp + OWNER_WITHDRAW_LOCKOUT;
  }

  /*//////////////////////////////////////////////
                    JINGLE LOGIC
  //////////////////////////////////////////////*/

  /// @notice used for a caller to submit a gift and participate in the Secret Santa. The submitting user can only submit once.
  /// @param _tokenId the ID of the gifted token
  /// @param _tokenContract the contract address for the token contract
  /// @param _userMerkleProof merkle proof to check if caller is whitelisted
  /// @param _giftMerkleProof merkle proof of the submitted token gift address
  function submitGift(
    uint256 _tokenId,
    address _tokenContract,
    bytes32[] calldata _userMerkleProof,
    bytes32[] calldata _giftMerkleProof
  ) public onlyWhenState(State.SUBMISSION) {
    if (!isUserWhiteListed(msg.sender, _userMerkleProof)) revert Unauthorized();
    if (!isTokenApproved(_tokenContract, _giftMerkleProof)) revert InvalidGift();
    if (_giftGiver[msg.sender] != 0) revert AlreadySubmitted();

    // Would be insane if 2^256 - 1 gifts were gifted
    unchecked {
      giftId++;
      poolSize++;
    }

    Gift memory newGift = Gift({
      nextTouch: 0,
      poolIndex: poolSize,
      stolenCount: 0,
      tokenId: _tokenId,
      tokenContract: _tokenContract
    });

    _giftGiver[msg.sender] = giftId;
    _gift[giftId] = newGift;
    _giftPool[poolSize] = giftId;

    if (isERC721(_tokenContract)) {
      IERC721(_tokenContract).safeTransferFrom(msg.sender, address(this), _tokenId);
    } else {
      IERC1155(_tokenContract).safeTransferFrom(msg.sender, address(this), _tokenId, 1, "");
    }

    emit Submitted(msg.sender, giftId, _tokenContract, _tokenId);
  }

  /// @notice if the caller does not already have a gift, this function will give them a gift randomly from the gift pool
  function getRandomGift() public onlySubmitted onlyWhenState(State.GIFTING) returns (uint256) {    
    return internalGetRandomGift();
  }

  function internalGetRandomGift() internal returns (uint256) {
    if (_ownsGift[msg.sender] != 0) revert AlreadyHaveGift();

    uint256 randomPoolIndex = getRandomPoolIndex();
    uint256 id = _giftPool[randomPoolIndex];

    /// @dev swaps the claimed gift with the last valid gift in the pool then shrinks the pool size
    if (randomPoolIndex < poolSize) {
      _giftPool[randomPoolIndex] = _giftPool[poolSize--];
    } else {
      unchecked {
        poolSize--;
      }
    }

    _gift[id].nextTouch = block.timestamp + STEAL_COOLDOWN;
    _ownerOf[id] = msg.sender;
    _ownsGift[msg.sender] = id;
    _touchedGift[msg.sender][id] = true;

    emit Gifted(msg.sender, id);

    return id;
  }

  /// @notice if the caller does not have a gift, this allows the caller to steal a gift from another user
  /// @param _giftId the ID of the gift the caller wants to steal
  function stealGift(uint256 _giftId) public onlySubmitted onlyWhenState(State.GIFTING) {
    if (_ownsGift[msg.sender] != 0) revert AlreadyHaveGift();
    /// @dev caller can't steal a gift they already owned
    if (_touchedGift[msg.sender][_giftId]) revert AlreadyOwnedGift();

    address prevOwner = _ownerOf[_giftId];

    /// @dev can't steal a gift from nobody
    if (prevOwner == address(0)) revert NoGiftOwner();

    Gift storage stolenGift = _gift[_giftId];
    /// @dev only 1 steal every 6 hours
    if (block.timestamp < stolenGift.nextTouch) revert GiftCooldownNotComplete();
    /// @dev max steals for a gift is 2
    if (stolenGift.stolenCount == 2) revert MaxGiftSteals();

    stolenGift.nextTouch = block.timestamp + STEAL_COOLDOWN;
    unchecked {
      stolenGift.stolenCount++;
    }

    _ownerOf[_giftId] = msg.sender;
    _ownsGift[msg.sender] = _giftId;
    _ownsGift[prevOwner] = 0;
    _touchedGift[msg.sender][_giftId] = true;

    emit Stolen(prevOwner, msg.sender, _giftId);
  }

  /// @notice allows the caller to transfer out their gifted token after the games have ended
  function withdrawGift() public onlySubmitted onlyWhenState(State.CLOSED) returns (uint256) {
    /// @dev If no gift in possesion, grab random gift from pool
    uint256 id = _ownsGift[msg.sender];
    if (id == 0) {
      id = internalGetRandomGift();
    }

    /// @dev prevent re-entry to take multiple ERC-1155
    delete _giftGiver[msg.sender];

    Gift memory withdrawnGift = _gift[id];
    uint256 withdrawnGiftId = withdrawnGift.tokenId;
    address contractAddress = withdrawnGift.tokenContract;
    giftTransfer(contractAddress, withdrawnGiftId);

    emit Withdraw(msg.sender, id);

    return id;
  }

  /// @notice allows the caller to withdraw their gift while submissions are still open
  function withdrawFromGame() public onlySubmitted onlyWhenState(State.SUBMISSION) {
    uint256 id = _giftGiver[msg.sender];
    Gift memory withdrawnGift = _gift[id];
    uint256 withdrawnGiftPoolIndex = withdrawnGift.poolIndex;

    /// @dev swap only necessary when in the middle of the pool
    if (withdrawnGiftPoolIndex < poolSize) {
      uint256 endOfPoolGiftId = _giftPool[poolSize--];
      Gift storage endOfPoolGift = _gift[endOfPoolGiftId];
      endOfPoolGift.poolIndex = withdrawnGiftPoolIndex;

      /// @dev swaps the withdrawn gift with the last valid gift in the pool then shrinks the pool size
      /// @dev no need to delete the gift outside of the poolSize after the decrement since it'll be ignored or replaced during next gift submit
      _giftPool[withdrawnGiftPoolIndex] = endOfPoolGiftId;
    } else {
      /// @dev should never be able to underflow since more gifts can't be withdrawn than submitted
      unchecked {
        poolSize--;
      }
    }

    delete _giftGiver[msg.sender];
    delete _gift[id];

    address withdrawnGiftContract = withdrawnGift.tokenContract;
    uint256 withdrawnGiftTokenId = withdrawnGift.tokenId;
    giftTransfer(withdrawnGiftContract, withdrawnGiftTokenId);

    emit Withdraw(msg.sender, id);
  }

  /*//////////////////////////////////////////////
                    OWNER LOGIC
  //////////////////////////////////////////////*/

  function changeGameState(uint8 _state) public onlyOwner {
    state = State(_state);

    emit StateChange(state);
  }

  function updateUserMerkleRoot(bytes32 _userMerkleRoot) public onlyOwner {
    userMerkleRoot = _userMerkleRoot;
  }

  function updateGiftMerkleRoot(bytes32 _giftMerkleRoot) public onlyOwner {
    giftMerkleRoot = _giftMerkleRoot;
  }

  /// @notice owner can withdraw gifts after withdraw lockout period (2 weeks) to raffle off
  function withdrawGift(uint256 _giftId) public onlyOwner {
    if (block.timestamp < withdrawReleaseDate) revert OwnerWithdrawLocked();

    Gift memory withdrawnGift = _gift[_giftId];
    if (withdrawnGift.tokenContract == address(0)) revert GiftDoesNotExist();

    address withdrawnGiftContract = withdrawnGift.tokenContract;
    uint256 withdrawnGiftTokenId = withdrawnGift.tokenId;
    giftTransfer(withdrawnGiftContract, withdrawnGiftTokenId);

    emit Withdraw(msg.sender, _giftId);
  }

  /*//////////////////////////////////////////////
            PRIVATE/INTERNAL JINGLE LOGIC
  //////////////////////////////////////////////*/

  function giftTransfer(address withdrawnGiftContract, uint256 withdrawnGiftTokenId) private {
    if (isERC721(withdrawnGiftContract)) {
      IERC721(withdrawnGiftContract).safeTransferFrom(address(this), msg.sender, withdrawnGiftTokenId);
    } else {
      IERC1155(withdrawnGiftContract).safeTransferFrom(address(this), msg.sender, withdrawnGiftTokenId, 1, "");
    }
  }

  /// @notice check if the given user is whitelisted to join the game
  function isUserWhiteListed(
    address _user,
    bytes32[] calldata _merkleProof
  ) internal view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(_user));
    return MerkleProof.verify(_merkleProof, userMerkleRoot, leaf);
  }

  /// @notice checks if the given token contract address exists in the merkle tree
  function isTokenApproved(
    address _tokenAddress,
    bytes32[] calldata _merkleProof
  ) internal view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(_tokenAddress));
    return MerkleProof.verify(_merkleProof, giftMerkleRoot, leaf);
  }

  /// @notice a psuedo random function to pick a gift randomly from the pool (Thanks Valhalla for the seed idea)
  function getRandomPoolIndex() internal returns (uint256) {
    return (uint256(keccak256(
      abi.encodePacked(
        block.timestamp,
        block.difficulty,
        ++seed
      )
    )) % poolSize) + 1;
  }

  /// @notice used to determine if the given contract is ERC-721
  function isERC721(address _contract) internal view returns (bool) {
    // Check if the contract implements the ERC721 interface
    return IERC721(_contract).supportsInterface(type(IERC721).interfaceId);
  }

  /*//////////////////////////////////////////////
                ON RECIEVE LOGIC
  //////////////////////////////////////////////*/

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) public pure returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }

  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes calldata
  ) public pure returns(bytes4) {
    return IERC1155Receiver.onERC1155Received.selector;
  }
}