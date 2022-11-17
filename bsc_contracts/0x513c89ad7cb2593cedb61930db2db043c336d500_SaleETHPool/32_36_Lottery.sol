// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

import "../libraries/TransferHelper.sol";

import "../interfaces/INFTSport.sol";

contract Lottery is IERC721ReceiverUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
  using SafeMathUpgradeable for uint256;
  using CountersUpgradeable for CountersUpgradeable.Counter;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

  enum RoundStatus {
    UNLOCK,
    LOCK
  }

  struct RoundInfo {
    uint256 amount;
    bytes32 root;
    mapping(address => bool) isClaimed;
    uint256 lockTime;
    uint256 unlockTime;
    uint256 result;
    uint256 timestamp;
  }

  INFTSport public nftSport;

  mapping(address => EnumerableSetUpgradeable.UintSet) private _users;
  mapping(uint256 => RoundInfo) public rounds;
  CountersUpgradeable.Counter private _roundCounter;

  event CreateRound(uint256 indexed id, uint256 amount, uint256 lockTime);
  event UpdateRoundResult(uint256 indexed id, bytes32 root, uint256 result, uint256 timestamp);

  event Deposit(address indexed user, uint256[] tokenIds);
  event Withdraw(address indexed user, uint256[] tokenIds);
  event ClaimReward(address indexed user, uint256 amount);

  function initialize(INFTSport _nftSport) external initializer {
    OwnableUpgradeable.__Ownable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

    nftSport = _nftSport;
  }

  function getStatus(uint256 _id) public view returns (RoundStatus) {
    if (_roundCounter.current() <= _id) {
      return RoundStatus.UNLOCK;
    }
    RoundInfo memory round = rounds[_id];
    if (round.lockTime >= block.timestamp) {
      return RoundStatus.UNLOCK;
    } else {
      if (round.unlockTime == 0) {
        return RoundStatus.LOCK;
      } else {
        return RoundStatus.UNLOCK;
      }
    }
  }

  function getRoundLength() external view returns (uint256) {
    return _roundCounter.current();
  }

  function createRound(uint256 _lockTime) external payable onlyOwner {
    uint256 id = _roundCounter.current();
    require(id == 0 || rounds[id - 1].unlockTime != 0, "createRound: invalid id");
    require(msg.value != 0, "createRound: invalid msg.value");
    _roundCounter.increment();
    RoundInfo storage round = rounds[id];
    round.amount = msg.value;
    round.lockTime = _lockTime;

    emit CreateRound(id, msg.value, _lockTime);
  }

  function updateRoundResult(
    uint256 _id,
    bytes32 _root,
    uint256 _result
  ) external onlyOwner {
    require(_id < _roundCounter.current() && getStatus(_id) == RoundStatus.LOCK, "updateRoundResult: invalid status");
    RoundInfo storage round = rounds[_id];
    round.root = _root;
    round.unlockTime = block.timestamp;
    round.result = _result;
    round.timestamp = block.timestamp;

    if (_root == bytes32(0)) {
      TransferHelper.safeTransferETH(owner(), round.amount);
    }

    emit UpdateRoundResult(_id, _root, _result, block.timestamp);
  }

  struct TokenInfo {
    uint256 tokenId;
    uint256 teamId;
  }

  function getBalance(address _account) external view returns (TokenInfo[] memory) {
    uint256 length = nftSport.balanceOf(_account);
    TokenInfo[] memory tokens = new TokenInfo[](length);
    for (uint256 i = 0; i < length; i++) {
      uint256 tokenId = nftSport.tokenOfOwnerByIndex(_account, i);
      uint256 teamId = nftSport.nftToTeam(tokenId);
      tokens[i] = TokenInfo(tokenId, teamId);
    }
    return tokens;
  }

  function getDepositedBalance(address _account) external view returns (TokenInfo[] memory) {
    uint256 length = _users[_account].length();
    TokenInfo[] memory tokens = new TokenInfo[](length);
    for (uint256 i = 0; i < length; i++) {
      uint256 tokenId = _users[_account].at(i);
      uint256 teamId = nftSport.nftToTeam(tokenId);
      tokens[i] = TokenInfo(tokenId, teamId);
    }
    return tokens;
  }

  function deposit(uint256[] memory _tokenIds) external {
    RoundStatus status = getStatus(_roundCounter.current());
    require(status == RoundStatus.UNLOCK, "deposit: invalid round status");
    EnumerableSetUpgradeable.UintSet storage user = _users[msg.sender];
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      nftSport.safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
      user.add(_tokenIds[i]);
    }

    emit Deposit(msg.sender, _tokenIds);
  }

  function withdraw(uint256[] memory _tokenIds) external {
    require(getStatus(_roundCounter.current()) == RoundStatus.UNLOCK, "withdraw: invalid round status");
    EnumerableSetUpgradeable.UintSet storage user = _users[msg.sender];
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      require(user.contains(_tokenIds[i]), "withdraw: invalid _tokenIds");
      nftSport.safeTransferFrom(address(this), msg.sender, _tokenIds[i]);
      user.remove(_tokenIds[i]);
    }

    emit Withdraw(msg.sender, _tokenIds);
  }

  function _leaf(
    uint256 _id,
    address _account,
    uint256 _shares
  ) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_id, _account, _shares));
  }

  function _verify(
    bytes32 root,
    bytes32 leaf,
    bytes32[] memory proof
  ) internal pure returns (bool) {
    return MerkleProofUpgradeable.verify(proof, root, leaf);
  }

  function pendingReward(
    uint256 _id,
    address _account,
    uint256 _shares,
    bytes32[] memory _proof
  ) public view returns (uint256) {
    RoundInfo memory round = rounds[_id];
    if (
      round.unlockTime == 0 ||
      !_verify(round.root, _leaf(_id, _account, _shares), _proof) ||
      rounds[_id].isClaimed[_account]
    ) {
      return 0;
    }
    return round.amount.mul(_shares).div(1e18);
  }

  function claimReward(
    uint256 _id,
    uint256 _shares,
    bytes32[] memory _proof
  ) external {
    RoundInfo storage round = rounds[_id];
    require(round.unlockTime != 0, "claimReward: the round is not done");
    uint256 amount = pendingReward(_id, msg.sender, _shares, _proof);
    require(amount > 0, "claimReward: nothing to claim");
    round.isClaimed[msg.sender] = true;
    TransferHelper.safeTransferETH(msg.sender, amount);

    emit ClaimReward(msg.sender, amount);
  }

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external override returns (bytes4) {
    operator;
    from;
    tokenId;
    data;
    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }
}