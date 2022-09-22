// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../libs/fota/RewardAuth.sol";
import "../interfaces/IGameMiningPool.sol";
import "../interfaces/IFOTAGame.sol";
import "../interfaces/ICitizen.sol";
import "../interfaces/IFOTAPricer.sol";
import "../interfaces/IGameNFT.sol";
import "../libs/fota/Math.sol";
import "../interfaces/IFarm.sol";
import "../interfaces/IFOTAToken.sol";
import "../interfaces/ILandLordManager.sol";

contract RewardManager is RewardAuth, PausableUpgradeable {
  using Math for uint;

  struct Reward {
    uint mission;
    uint userAmount;
    uint farmShareAmount;
    uint referralShareAmount;
    uint landLordShareAmount;
  }
  struct ClaimCondition {
    uint minHero;
    uint[] numberOfHero;
    uint[] maxRewardAccordingToHero;
    uint systemMaxClaimPerDay;
    uint userMaxClaimPerDay;
  }
  IGameNFT public heroNft;
  IGameMiningPool public gameMiningPool;
  IFOTAGame public gameProxyContract;
  ICitizen public citizen;
  IFOTAPricer public fotaPricer;
  IFarm public farm;
  ClaimCondition public claimCondition;
  IFOTAToken public fotaToken;
  ILandLordManager public landLordManager;
  uint public farmShare; // decimal 3
  uint public referralShare; // decimal 3
  uint public landLordShare; // decimal 3
  uint public startTime;
  uint public secondInADay;
  uint public rewardingDays;
  uint public dailyQuestReward;
  uint public pveWinDailyQuestCondition;
  uint public pvpWinDailyQuestCondition;
  uint public dualWinDailyQuestCondition;
  uint public userMaxPendingPerDay;
  address public treasuryAddress;
  mapping (address => mapping (uint => Reward[])) public rewards;
  mapping (address => mapping (uint => uint)) public userDailyPending;
  mapping (address => bool) public blockedUsers;
  mapping (address => uint) public userPending;
  mapping (address => uint) public userClaimed;
  mapping (address => mapping (uint => bool)) public userDailyRewardReleased;
  mapping (address => mapping (uint => bool)) public claimMarker;
  mapping (uint => uint) public dailyClaimed;
  mapping (address => mapping (uint => uint)) public userDailyClaimed;

  event DailyQuestRewardUpdated(uint amount, uint timestamp);
  event UserMaxPendingPerDayUpdated(uint amount, uint timestamp);
  event DailyQuestConditionUpdated(uint pve, uint pvp, uint dual, uint timestamp);
  event UserBlockUpdated(address indexed _user, bool blocked, uint timestamp);
  event ClaimConditionUpdated(uint minHero, uint[] numberOfHero, uint[] maxRewardAccordingToHero, uint systemMaxClaimPerDay, uint userMaxClaimPerDay, uint timestamp);
  event RewardRecorded(address indexed user, uint mission, uint fotaProfitable, uint farmShareAmount, uint referralShareAmount, uint landLordShareAmount);
  event RewardingDayUpdated(uint rewardingDay, uint timestamp);
  event Claimed(address indexed _user, uint _totalFotaDistributed, uint _fotaAmount, uint _dayCallClaimed);
  event ReferralShare(address indexed _inviterOrTreasury, address _user, uint _fotaAmount, uint _usdAmount);

  function initialize(address _mainAdmin, address _citizen, address _fotaPricer) public initializer {
    super.initialize(_mainAdmin);
    citizen = ICitizen(_citizen);
    fotaPricer = IFOTAPricer(_fotaPricer);
//    fotaToken = IFOTAToken(0x0A4E1BdFA75292A98C15870AeF24bd94BFFe0Bd4);
//    gameMiningPool = IFOTAToken(0x0A4E1BdFA75292A98C15870AeF24bd94BFFe0Bd4);
//    rewardingDays = 14; // TODO
//    secondInADay = 86400; // 24 * 60 * 60
    rewardingDays = 3;
    secondInADay = 600; // 24 * 60 * 60
    dailyQuestReward = 1e18;
    userMaxPendingPerDay = 300e18;
    claimCondition.minHero = 2;
    claimCondition.numberOfHero = [2, 5];
    claimCondition.maxRewardAccordingToHero = [100e18, 150e18];
    claimCondition.systemMaxClaimPerDay = 500e18;
    claimCondition.userMaxClaimPerDay = 100e18;
    farmShare = 3000;
    referralShare = 2000;
    landLordShare = 1000;
  }

  function getClaimCondition() external view returns (uint, uint[] memory, uint[] memory, uint, uint) {
    return (claimCondition.minHero, claimCondition.numberOfHero, claimCondition.maxRewardAccordingToHero, claimCondition.systemMaxClaimPerDay, claimCondition.userMaxClaimPerDay);
  }

  function claim() public whenNotPaused {
    uint dayPassed = getDaysPassed();
    uint dayToClaim = dayPassed - rewardingDays;
    require(!claimMarker[msg.sender][dayToClaim], "RewardManager: See you next time.");
    require(rewards[msg.sender][dayToClaim].length > 0, "RewardManager: You have no reward to claim today.");
    claimMarker[msg.sender][dayToClaim] = true;

    uint userMaxReward = _validateUser(msg.sender);
    uint distributedToUser;
    uint distributedToFarm;
    uint distributedToReferralOrTreasury;
    uint totalDistributed = 0;

    address inviterOrTreasury = citizen.getInviter(msg.sender);
    bool validInviter = _validateInviter(inviterOrTreasury);
    if (!validInviter) {
      inviterOrTreasury = treasuryAddress;
    }
    for (uint i = 0; i < rewards[msg.sender][dayToClaim].length; i++) {
      if (distributedToUser < userMaxReward) {
        if (distributedToUser.add(rewards[msg.sender][dayToClaim][i].userAmount) >= userMaxReward) {
          distributedToUser = userMaxReward;
        } else {
          distributedToUser = distributedToUser.add(rewards[msg.sender][dayToClaim][i].userAmount);
        }
      }
      distributedToFarm += rewards[msg.sender][dayToClaim][i].farmShareAmount;
      distributedToReferralOrTreasury += rewards[msg.sender][dayToClaim][i].referralShareAmount;

      gameMiningPool.releaseGameAllocation(address(this), rewards[msg.sender][dayToClaim][i].landLordShareAmount);
      landLordManager.giveReward(rewards[msg.sender][dayToClaim][i].mission, rewards[msg.sender][dayToClaim][i].landLordShareAmount);
      totalDistributed += distributedToUser + distributedToFarm + distributedToReferralOrTreasury + rewards[msg.sender][dayToClaim][i].landLordShareAmount;
    }

    if (distributedToFarm > 0) {
      gameMiningPool.releaseGameAllocation(address(this), distributedToFarm);
      farm.fundFOTA(distributedToFarm);
    }

    if (distributedToReferralOrTreasury > 0) {
      gameMiningPool.releaseGameAllocation(inviterOrTreasury, distributedToReferralOrTreasury);
      emit ReferralShare(inviterOrTreasury, msg.sender, distributedToReferralOrTreasury, distributedToReferralOrTreasury);
    }

    userDailyClaimed[msg.sender][dayPassed] = distributedToUser;
    dailyClaimed[dayPassed] += distributedToUser;
    gameMiningPool.releaseGameAllocation(msg.sender, distributedToUser);
    emit Claimed(msg.sender, totalDistributed, distributedToUser, dayPassed);
  }

  function addPVEReward(uint _mission, address _user, uint _reward, uint[] calldata _heroIds) external onlyGameContract returns (uint, bool) {
    uint dayPassed = getDaysPassed();
    require(userDailyPending[_user][dayPassed] < userMaxPendingPerDay, "RewardManager: user reach max pending in day");
    bool dailyQuestCompleted = _checkCompleteDailyQuest(_user, dayPassed);
    if (dailyQuestCompleted) {
      _reward += dailyQuestReward;
    }
    uint farmShareAmount = _reward * farmShare / 100000;
    uint referralShareAmount = _reward * referralShare / 100000;
    uint userShare = _reward.sub(farmShareAmount).sub(referralShareAmount);
    uint landLordShareAmount = userShare * landLordShare / 100000;
    userShare = userShare.sub(landLordShareAmount);
    // userShare will be in FOTA from now
//    userShare = _getUserProfitableBasedOnHeroes(userShare, _heroIds);
    if (userDailyPending[_user][dayPassed] + userShare >= userMaxPendingPerDay) {
      userShare = userMaxPendingPerDay - userDailyPending[_user][dayPassed];
    }
    userDailyPending[_user][dayPassed] += userShare;
    farmShareAmount = _convertUsdToFota(farmShareAmount);
    referralShareAmount = _convertUsdToFota(referralShareAmount);
    landLordShareAmount = _convertUsdToFota(landLordShareAmount);
    rewards[_user][dayPassed].push(Reward(_mission, userShare, farmShareAmount, referralShareAmount, landLordShareAmount));
    emit RewardRecorded(_user, _mission, userShare, farmShareAmount, referralShareAmount, landLordShareAmount);
    return (userShare, dailyQuestCompleted);
  }

  function getDaysPassed() public view returns (uint) {
    if (startTime == 0) {
      return 0;
    }
    uint timePassed = block.timestamp - startTime;
    return timePassed / secondInADay;
  }

  function getUserTodayReward(address _user) external view returns (uint userTodayReward) {
    uint dayToClaim = getDaysPassed() - rewardingDays;
    require(!claimMarker[_user][dayToClaim], "RewardManager: See you next time.");
    require(rewards[_user][dayToClaim].length > 0, "RewardManager: You have no reward to claim today.");

    uint userMaxReward = _validateUser(_user);
    userTodayReward = 0;

    for (uint i = 0; i < rewards[_user][dayToClaim].length; i++) {
      if (userTodayReward < userMaxReward) {
        if (userTodayReward.add(rewards[_user][dayToClaim][i].userAmount) >= userMaxReward) {
          userTodayReward = userMaxReward;
        } else {
          userTodayReward = userTodayReward.add(rewards[_user][dayToClaim][i].userAmount);
        }
      }
    }
  }

  // PRIVATE FUNCTIONS

  function _validateUser(address _user) private view returns (uint) {
    uint dayPassed = getDaysPassed();
    require(!blockedUsers[_user], "RewardManager: Your wallet is currently blocked.");
    uint userHero = heroNft.balanceOf(_user);
    require(userHero >= claimCondition.minHero, "RewardManager: Buy more heroes to claim.");
    uint userMaxReward = _getUserMaxRewardAccordingToHero(userHero);
    require(userMaxReward > 0, "RewardManager: Reward or hero condition invalid.");
    if (dailyClaimed[dayPassed] + userMaxReward >= claimCondition.systemMaxClaimPerDay) {
      userMaxReward = claimCondition.systemMaxClaimPerDay.sub(dailyClaimed[dayPassed]);
    }
    if (userDailyClaimed[_user][dayPassed] + userMaxReward >= claimCondition.userMaxClaimPerDay) {
      userMaxReward = claimCondition.userMaxClaimPerDay - userDailyClaimed[_user][dayPassed];
    }
    return userMaxReward;
  }

  function _getUserMaxRewardAccordingToHero(uint _userHero) private view returns (uint) {
    for(uint i = claimCondition.numberOfHero.length - 1; i >= 0 ; i--) {
      if (_userHero >= claimCondition.numberOfHero[i]) {
        return claimCondition.maxRewardAccordingToHero[i];
      }
    }
    return 0;
  }

  function _checkCompleteDailyQuest(address _user, uint _dayPassed) private returns (bool) {
    if (!userDailyRewardReleased[_user][_dayPassed]) {
      uint winPVE = gameProxyContract.getTotalPVEWinInDay(_user);
      uint winPVP = gameProxyContract.getTotalPVPWinInDay(_user);
      uint winDUAL = gameProxyContract.getTotalDUALWinInDay(_user);
      bool gameCondition = winPVE >= pveWinDailyQuestCondition && winPVP >= pvpWinDailyQuestCondition && winDUAL >= dualWinDailyQuestCondition;
      if (gameCondition) {
        userDailyRewardReleased[_user][_dayPassed] = true;
        return true;
      }
    }
    return false;
  }

  function _validateInviter(address _inviter) private view returns (bool) {
    return gameProxyContract.validateInviter(_inviter);
  }

  function _getUserProfitableBasedOnHeroes(uint _userShare, uint[] calldata _heroIds) private returns (uint) {
    uint userProfitable;
    uint profitShared = _userShare / _heroIds.length;
    for(uint i = 0; i < _heroIds.length; i++) {
      userProfitable += heroNft.increaseTotalProfited(_heroIds[i], profitShared);
    }
    return userProfitable;
  }

  function _convertUsdToFota(uint _amount) private view returns (uint) {
    return _amount * 1000 / fotaPricer.fotaPrice();
  }

  // ADMIN FUNCTIONS

  function start(uint _startTime) external onlyMainAdmin {
    require(startTime == 0, "RewardManager: startTime had been initialized");
    require(_startTime >= 0 && _startTime < block.timestamp - secondInADay, "RewardManager: must be earlier yesterday");
    startTime = _startTime;
  }

  function updateSecondInADay(uint _secondInDay) external onlyMainAdmin {
    secondInADay = _secondInDay;
  }

  function updateTreasuryAddress(address _newAddress) external onlyMainAdmin {
    require(_newAddress != address(0), "Invalid address");
    treasuryAddress = _newAddress;
  }

  function updateGameProxyContract(address _gameProxy) external onlyMainAdmin {
    gameProxyContract = IFOTAGame(_gameProxy);
  }

  function setShares(uint _referralShare, uint _farmShare, uint _landLordShare) external onlyMainAdmin {
    require(_referralShare > 0 && _referralShare <= 10000);
    referralShare = _referralShare;
    require(_farmShare > 0 && _farmShare <= 10000);
    farmShare = _farmShare;
    require(_landLordShare > 0 && _landLordShare <= 10000);
    landLordShare = _landLordShare;
  }

  function updateDailyQuestReward(uint _newReward) external onlyMainAdmin {
    dailyQuestReward = _newReward;
    emit DailyQuestRewardUpdated(dailyQuestReward, block.timestamp);
  }

  function updateUserMaxPendingPerDay(uint _userMaxPendingPerDay) external onlyMainAdmin {
    userMaxPendingPerDay = _userMaxPendingPerDay;
    emit UserMaxPendingPerDayUpdated(userMaxPendingPerDay, block.timestamp);
  }

  function updateDailyQuestCondition(uint _pveWinDailyQuestCondition, uint _pvpWinDailyQuestCondition, uint _dualWinDailyQuestCondition) external onlyMainAdmin {
    pveWinDailyQuestCondition = _pveWinDailyQuestCondition;
    pvpWinDailyQuestCondition = _pvpWinDailyQuestCondition;
    dualWinDailyQuestCondition = _dualWinDailyQuestCondition;
    emit DailyQuestConditionUpdated(pveWinDailyQuestCondition, pvpWinDailyQuestCondition, dualWinDailyQuestCondition, block.timestamp);
  }

  function setContracts(address _heroNft, address _gameMiningPool, address _fotaToken, address _landLordManager, address _farmAddress) external onlyMainAdmin {
    heroNft = IGameNFT(_heroNft);
    gameMiningPool = IGameMiningPool(_gameMiningPool);
    fotaToken = IFOTAToken(_fotaToken);
    landLordManager = ILandLordManager(_landLordManager);
    require(_farmAddress != address(0), "Invalid address");
    farm = IFarm(_farmAddress);
    fotaToken.approve(_landLordManager, type(uint).max);
    fotaToken.approve(_farmAddress, type(uint).max);
  }

  function updateFotaPricer(address _pricer) external onlyMainAdmin {
    require(_pricer != address(0), "Invalid address");
    fotaPricer = IFOTAPricer(_pricer);
  }

  function updateBlockedUser(address _user, bool _blocked) external onlyMainAdmin {
    blockedUsers[_user] = _blocked;
    emit UserBlockUpdated(_user, _blocked, block.timestamp);
  }

  function updateClaimCondition(
    uint _minHero,
    uint[] calldata _numberOfHero,
    uint[] calldata _maxRewardAccordingToHero,
    uint _systemMaxClaimPerDay,
    uint _userMaxClaimPerDay
  ) external onlyMainAdmin {
    require(_systemMaxClaimPerDay > dailyClaimed[getDaysPassed()], "RewardManager: systemMaxClaimPerDay must be greater than dailyClaimed");
    require(_numberOfHero.length > 0 &&
      _numberOfHero.length == _maxRewardAccordingToHero.length &&
      _minHero >= _numberOfHero[0], "RewardManager: data invalid");
    for (uint i = 0; i < _numberOfHero.length - 1; i++) {
      require(_numberOfHero[i] < _numberOfHero[i + 1], "RewardManager: number of hero is duplicated or wrong order");
    }
    claimCondition.minHero = _minHero;
    claimCondition.numberOfHero = _numberOfHero;
    claimCondition.maxRewardAccordingToHero = _maxRewardAccordingToHero;
    claimCondition.systemMaxClaimPerDay = _systemMaxClaimPerDay;
    claimCondition.userMaxClaimPerDay = _userMaxClaimPerDay;
    emit ClaimConditionUpdated(_minHero, _numberOfHero, _maxRewardAccordingToHero, _systemMaxClaimPerDay, _userMaxClaimPerDay, block.timestamp);
  }

  function updateRewardingDays(uint _rewardingDays) external onlyMainAdmin {
    require(_rewardingDays > 0, "RewardManager: data invalid");
    rewardingDays = _rewardingDays;
    emit RewardingDayUpdated(_rewardingDays, block.timestamp);
  }

  function updatePauseStatus(bool _paused) external onlyMainAdmin {
    if(_paused) {
      _pause();
    } else {
      _unpause();
    }
  }

  function syncPendingReward(address _user, uint[] calldata _pendingDays, uint[][] calldata _fotaPrices) external onlyMainAdmin {
    uint pendingDay;
    for (uint dayIndex = 0; dayIndex < _pendingDays.length; dayIndex++) {
      pendingDay = _pendingDays[dayIndex];
      require(!claimMarker[_user][pendingDay], "RewardManager: user has claimed this day reward");
      require(rewards[_user][pendingDay].length == _fotaPrices[dayIndex].length, "RewardManager: price data invalid");
      for (uint gameIndex = 0; gameIndex < _fotaPrices[dayIndex].length; gameIndex++) {
        rewards[_user][pendingDay][gameIndex].userAmount = rewards[_user][pendingDay][gameIndex].userAmount * 1000 / _fotaPrices[dayIndex][gameIndex];
        rewards[_user][pendingDay][gameIndex].farmShareAmount = rewards[_user][pendingDay][gameIndex].farmShareAmount * 1000 / _fotaPrices[dayIndex][gameIndex];
        rewards[_user][pendingDay][gameIndex].referralShareAmount = rewards[_user][pendingDay][gameIndex].referralShareAmount * 1000 / _fotaPrices[dayIndex][gameIndex];
        rewards[_user][pendingDay][gameIndex].landLordShareAmount = rewards[_user][pendingDay][gameIndex].landLordShareAmount * 1000 / _fotaPrices[dayIndex][gameIndex];
        userDailyPending[_user][pendingDay] += rewards[_user][pendingDay][gameIndex].userAmount;
      }
    }
  }
}