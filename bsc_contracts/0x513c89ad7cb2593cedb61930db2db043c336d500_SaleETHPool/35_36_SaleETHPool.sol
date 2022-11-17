// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "../libraries/TransferHelper.sol";

contract SaleETHPool is OwnableUpgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
  using SafeMathUpgradeable for uint256;
  using CountersUpgradeable for CountersUpgradeable.Counter;

  bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

  enum MatchStatus {
    NA,
    Won,
    Draw,
    Loss
  }

  struct MatchInfo {
    uint256 team1Id;
    uint256 team2Id;
    uint256 team1Goals;
    uint256 team2Goals;
    MatchStatus status;
    uint256 amount;
    uint256 startTime;
    bytes32 root;
    mapping(address => bool) isClaimed;
    uint256 timestamp;
    bool forceDone;
  }

  uint256 public constant NUMBER_OF_MATCHES = 64;
  uint256 public constant NUMBER_OF_TEAMS = 32;

  uint256 public constant GRACE_PERIOD = 1 days;

  uint256 public saleETH;
  uint256 public distributedETH;

  CountersUpgradeable.Counter private _matchCounter;
  mapping(uint256 => MatchInfo) public matches;

  event UpdateMatch(uint256 indexed id, uint256 team1Id, uint256 team2Id, uint256 startTime, uint256 amount);
  event UpdateResultOfMatch(
    uint256 indexed id,
    uint256 team1Goals,
    uint256 team2Goals,
    MatchStatus status,
    bytes32 root
  );

  event ClaimReward(address indexed user, uint256 amount);

  function initialize() external initializer {
    OwnableUpgradeable.__Ownable_init();
    AccessControlUpgradeable.__AccessControl_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  receive() external payable {
    saleETH = saleETH.add(msg.value);
  }

  function updateMatch(
    uint256 _id,
    uint256 _team1Id,
    uint256 _team2Id,
    uint256 _startTime
  ) external {
    require(hasRole(UPDATER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "updateMatch: invalid role");
    MatchInfo storage _match = matches[_id];
    require(!_match.forceDone, "updateMatch: the match is over");
    require(_match.timestamp == 0 && _match.amount == 0, "updateMatch: the match is over");
    require(_team1Id < NUMBER_OF_TEAMS && _team2Id < NUMBER_OF_TEAMS, "updateMatch: invalid params");
    uint256 current = _matchCounter.current();
    uint256 amount = saleETH.sub(distributedETH).div(NUMBER_OF_MATCHES.sub(current));
    require(amount > 0, "updateMatch: the reward needs to be > 0");
    distributedETH = distributedETH.add(amount);
    _matchCounter.increment();
    _match.amount = amount;
    _match.team1Id = _team1Id;
    _match.team2Id = _team2Id;
    _match.startTime = _startTime;

    emit UpdateMatch(_id, _team1Id, _team2Id, _startTime, amount);
  }

  function _updateResultOfMatch(
    uint256 _id,
    uint256 _team1Goals,
    uint256 _team2Goals,
    bytes32 _root
  ) internal {
    MatchInfo storage _match = matches[_id];
    require(!_match.forceDone, "_updateResultOfMatch: the match is over");
    require(
      _match.timestamp == 0 || _match.timestamp.add(GRACE_PERIOD) > block.timestamp,
      "_updateResultOfMatch: the match is over"
    );
    MatchStatus status;
    if (_team1Goals < _team2Goals) {
      status = MatchStatus.Loss;
    } else if (_team1Goals == _team2Goals) {
      status = MatchStatus.Draw;
    } else {
      status = MatchStatus.Won;
    }

    _match.status = status;
    _match.team1Goals = _team1Goals;
    _match.team2Goals = _team2Goals;
    _match.root = _root;
    _match.timestamp = block.timestamp;

    emit UpdateResultOfMatch(_id, _team1Goals, _team2Goals, status, _root);
  }

  function updateResultOfMatch(
    uint256 _id,
    uint256 _team1Goals,
    uint256 _team2Goals,
    bytes32 _root
  ) external {
    require(
      hasRole(UPDATER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
      "updateResultOfMatch: invalid role"
    );
    _updateResultOfMatch(_id, _team1Goals, _team2Goals, _root);
  }

  function forceUpdateResultOfMatch(
    uint256 _id,
    uint256 _team1Goals,
    uint256 _team2Goals,
    bytes32 _root
  ) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "forceUpdateResultOfMatch: invalid role");
    _updateResultOfMatch(_id, _team1Goals, _team2Goals, _root);
    matches[_id].forceDone = true;
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
    MatchInfo memory _match = matches[_id];
    if (
      (!_match.forceDone && (_match.timestamp == 0 || _match.timestamp.add(GRACE_PERIOD) > block.timestamp)) ||
      !_verify(_match.root, _leaf(_id, _account, _shares), _proof) ||
      matches[_id].isClaimed[_account]
    ) {
      return 0;
    }
    return _match.amount.mul(_shares).div(1e18);
  }

  function claimReward(
    uint256 _id,
    uint256 _shares,
    bytes32[] memory _proof
  ) external {
    MatchInfo storage _match = matches[_id];
    require(
      _match.forceDone || (_match.timestamp != 0 && _match.timestamp.add(GRACE_PERIOD) <= block.timestamp),
      "claimReward: the match is not over"
    );
    uint256 amount = pendingReward(_id, msg.sender, _shares, _proof);
    require(amount > 0, "claimReward: nothing to claim");
    _match.isClaimed[msg.sender] = true;
    TransferHelper.safeTransferETH(msg.sender, amount);

    emit ClaimReward(msg.sender, amount);
  }
}