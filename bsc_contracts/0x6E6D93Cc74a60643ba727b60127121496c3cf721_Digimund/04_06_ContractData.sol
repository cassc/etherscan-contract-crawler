//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "./Authorized.sol";
contract ContractData is Authorized {
  string public name = "Digimund";
  string public url = "www.digimund.one";
  struct AccountInfo {
    address up;
    uint unlockedLevel;
    bool registered;
    uint depositTime;
    uint lastWithdraw;
    uint depositMin;
    uint depositTotal;
    uint depositCounter;
    uint bonusFidelidade;
    uint saqueLib;
  }
  struct AccountEarnings {
    uint receivedPassiveAmount;
    uint receivedTotalAmount;
    uint directBonusAmount;
    uint directBonusAmountTotal;
    uint levelBonusAmount;
    uint levelBonusAmountTotal;
  }
  struct MoneyFlow {
    uint passive;
    uint direct;
    uint bonus;
  }
  struct NetworkCheck {
    uint count;
    uint deposits;
    uint depositTotal;
    uint depositCounter;
  }
  mapping(address => AccountInfo) public accountsInfo;
  mapping(address => AccountEarnings) public accountsEarnings;
  mapping(address => address[]) public accountsRefs;
  mapping(address => uint[]) public accountsFlow;
  mapping(address => address[]) public accountsShared;
  mapping(address => address[]) public accountsInShare;
  uint16[] _passiveBonusLevel = new uint16[](10);
  uint public minAllowedDeposit = 0.1 ether;
  uint public maxAllowedDeposit = 10 ether;
  uint public minAmountToLvlUp = 0.1 ether;
  uint public minAmountToGetBonus = 0.1 ether;
  uint public constant timeFrame = 1 days;
  uint public constant timeToWithdraw = 1 days;
  uint public constant dailyRentability = 13;
  uint public constant directBonus = 10;
  uint public constant maxWithdrawPercentPerTime = 40;
  uint public constant networkFeePercent = 10;
  uint public constant wpmFeePercent = 40;
  uint public constant maxPercentToWithdraw = 215;
  uint public constant maxPercentToReceive = 215;
  uint public holdPassiveOnDrop = 85;
  bool public distributePassiveNetwork = true;
  uint public maxBalance;
  uint public networkSize;
  uint public networkDeposits;
  uint public networkWithdraw;
  address networkReceiver;
  address wpmReceiver;
  uint cumulativeNetworkFee;
  uint cumulativeWPMFee;
  uint composeDeposit;
  address constant mainNode = 0x492c4f0c082ED79Ab5D6A1Ac8cB40144f2788DED;
  address public networkReceiverA=0x2FB1261b484582aE71f32FB95ccD46EC79dbC23A;
  address public networkReceiverB=0xBa6844C1B06a5A5903256450F312087fCd7797a0;
  address public networkReceiverC=0xc4535c6d2A1F7bD458b6C244fC72EcE3817579E4;
  address public networkReceiverD=0x3bAb09dD282b4af1dc30311e9B00bF8530d00097;
  address public networkReceiverE=0x06E2a19ce54DE6B49c1E7126E83c682dBC430F8C;
  address public networkReceiverF=0x492c4f0c082ED79Ab5D6A1Ac8cB40144f2788DED;
  address public networkReceiverG=0xfd88D767D1aD8b7502eDB3d81E8EefAaf8f37dEc;
  constructor() {
    _passiveBonusLevel[0] = 100;
    _passiveBonusLevel[1] = 80;
    _passiveBonusLevel[2] = 60;
    _passiveBonusLevel[3] = 60;
    _passiveBonusLevel[4] = 40;
    _passiveBonusLevel[5] = 40;
    _passiveBonusLevel[6] = 30;
    _passiveBonusLevel[7] = 30;
    _passiveBonusLevel[8] = 20;
    _passiveBonusLevel[9] = 10;
  }
  event WithdrawLimitReached(address indexed addr, uint amount);
  event Withdraw(address indexed addr, uint amount);
  event NewDeposit(address indexed addr, uint amount);
  event NewUpgrade(address indexed addr, uint amount);
  event DirectBonus(address indexed addr, address indexed from, uint amount);
  event LevelBonus(address indexed addr, address indexed from, uint amount);
  event ReferralRegistration(address indexed addr, address indexed referral);
  event NewDonationDeposit(address indexed addr, uint amount, string message);
  function setMinAllowedDeposit(uint minValue) external isAuthorized(1) {
    minAllowedDeposit = minValue;
  }
  function setMaxAllowedDeposit(uint maxValue) external isAuthorized(1) {
    maxAllowedDeposit = maxValue;
  }
  function setMinAmountToLvlUp(uint minValue) external isAuthorized(1) {
    minAmountToLvlUp = minValue;
  }
  function setMinAmountToGetBonus(uint minValue) external isAuthorized(1) {
    minAmountToGetBonus = minValue;
  }
  function setHoldPassiveOnDrop(uint value) external isAuthorized(1) {
    holdPassiveOnDrop = value;
  }
  function setNetworkReceiver(address receiver) external isAuthorized(0) {
    networkReceiver = receiver;
  }
  function setWpmReceiver(address receiver) external isAuthorized(0) {
    wpmReceiver = receiver;
  }
  function buildOperation(uint8 opType, uint value) internal view returns (uint res) {
    assembly {
      let entry := mload(0x40)
      mstore(entry, add(shl(200, opType), add(add(shl(160, timestamp()), shl(120, number())), value)))
      res := mload(entry)
    }
  }
  function getShares(address target) external view returns (address[] memory shared, address[] memory inShare) {
    shared = accountsShared[target];
    inShare = accountsInShare[target];
  }
  function getFlow(
    address target,
    uint limit,
    bool asc
  ) external view returns (uint[] memory flow) {
    uint[] memory list = accountsFlow[target];
    if (limit == 0) limit = list.length;
    if (limit > list.length) limit = list.length;
    flow = new uint[](limit);
    if (asc) {
      for (uint i = 0; i < limit; i++) flow[i] = list[i];
    } else {
      for (uint i = 0; i < limit; i++) flow[i] = list[(limit - 1) - i];
    }
  }
  function getMaxLevel(address sender) public view returns (uint) {
    uint currentUnlockedLevel = accountsInfo[sender].unlockedLevel;
    uint lockLevel = accountsInfo[sender].depositMin >= minAmountToGetBonus ? 10 : 0;
    if (lockLevel < currentUnlockedLevel) return lockLevel;
    return currentUnlockedLevel;
  }
  function visualizar(address sender) private view returns (uint){
    return accountsInfo[sender].bonusFidelidade;
  }
  function calculatePassive(
    address sender,
    uint depositTime,
    uint depositMin,
    uint receivedTotalAmount,
    uint receivedPassiveAmount
  ) public view returns (uint) {
    if (depositTime == 0 || depositMin == 0) return 0;
    uint passive = ((((depositMin * dailyRentability) / 1000) * (block.timestamp - depositTime)) / timeFrame) - receivedPassiveAmount;
    uint remainingAllowed = ((depositMin * visualizar(sender)) / 100) - receivedTotalAmount; // MAX TO RECEIVE
    return passive >= remainingAllowed ? remainingAllowed : passive;
  }
  function getAccountNetwork(
    address sender,
    uint minLevel,
    uint maxLevel
  ) public view returns (NetworkCheck[] memory) {
    maxLevel = maxLevel > _passiveBonusLevel.length || maxLevel == 0 ? _passiveBonusLevel.length : maxLevel;
    NetworkCheck[] memory network = new NetworkCheck[](maxLevel);
    for (uint i = 0; i < accountsRefs[sender].length; i++) {
      _getAccountNetworkInner(accountsRefs[sender][i], 0, minLevel, maxLevel, network);
    }
    return network;
  }
  function _getAccountNetworkInner(
    address sender,
    uint level,
    uint minLevel,
    uint maxLevel,
    NetworkCheck[] memory network
  ) internal view {
    if (level >= minLevel) {
      network[level].count += 1;
      network[level].deposits += accountsInfo[sender].depositMin;
      network[level].depositCounter += accountsInfo[sender].depositCounter;
      network[level].depositTotal += accountsInfo[sender].depositTotal;
    }
    if (level + 1 >= maxLevel) return;
    for (uint i = 0; i < accountsRefs[sender].length; i++) {
      _getAccountNetworkInner(accountsRefs[sender][i], level + 1, minLevel, maxLevel, network);
    }
  }
  function getMultiAccountNetwork(
    address[] memory senders,
    uint minLevel,
    uint maxLevel
  ) external view returns (NetworkCheck[] memory network) {
    for (uint x = 0; x < senders.length; x++) {
      NetworkCheck[] memory partialNetwork = getAccountNetwork(senders[x], minLevel, maxLevel);
      for (uint i = 0; i < maxLevel; i++) {
        network[i].count += partialNetwork[i].count;
        network[i].deposits += partialNetwork[i].deposits;
        network[i].depositTotal += partialNetwork[i].depositTotal;
        network[i].depositCounter += partialNetwork[i].depositCounter;
      }
    }
  }
  function getMultiLevelAccount(
    address[] memory senders,
    uint currentLevel,
    uint maxLevel
  ) public view returns (bytes memory results) {
    for (uint x = 0; x < senders.length; x++) {
      if (currentLevel == maxLevel) {
        for (uint i = 0; i < accountsRefs[senders[x]].length; i++) {
          results = abi.encodePacked(results, accountsRefs[senders[x]][i]);
        }
      } else {
        results = abi.encodePacked(results, getMultiLevelAccount(accountsRefs[senders[x]], currentLevel + 1, maxLevel));
      }
    }
  }
  function getAccountEarnings(address sender)
    external
    view
    returns (
      AccountInfo memory accountI,
      AccountEarnings memory accountE,
      MoneyFlow memory total,
      MoneyFlow memory toWithdraw,
      MoneyFlow memory toMaxEarning,
      MoneyFlow memory toReceiveOverMax,
      uint level,
      uint directs,
      uint time
    )
  {
    accountI = accountsInfo[sender];
    accountE = accountsEarnings[sender];
    address localSender = sender;
    uint depositMin = accountsInfo[localSender].depositMin;
    uint directBonusAmount = accountsEarnings[localSender].directBonusAmount;
    uint levelBonusAmount = accountsEarnings[localSender].levelBonusAmount;
    uint receivedTotalAmount = accountsEarnings[localSender].receivedTotalAmount;
    uint passive = calculatePassive(
      localSender,
      accountsInfo[localSender].depositTime,
      depositMin,
      receivedTotalAmount,
      accountsEarnings[localSender].receivedPassiveAmount
    );
    total = MoneyFlow(passive, directBonusAmount, levelBonusAmount);
    if (localSender == mainNode) depositMin = type(uint).max / 1e5;
    uint remainingWithdraw = ((depositMin * visualizar(localSender)) / 100) - receivedTotalAmount;
    uint toRegisterPassive = passive >= remainingWithdraw ? remainingWithdraw : passive;
    remainingWithdraw = remainingWithdraw - toRegisterPassive;
    uint toRegisterDirect = directBonusAmount >= remainingWithdraw ? remainingWithdraw : directBonusAmount;
    remainingWithdraw = remainingWithdraw - toRegisterDirect;
    uint toRegisterBonus = levelBonusAmount >= remainingWithdraw ? remainingWithdraw : levelBonusAmount;
    passive -= toRegisterPassive;
    directBonusAmount -= toRegisterDirect;
    levelBonusAmount -= toRegisterBonus;
    toWithdraw = MoneyFlow(toRegisterPassive, toRegisterDirect, toRegisterBonus);
    remainingWithdraw = ((depositMin * visualizar(localSender)) / 100) - (receivedTotalAmount + toRegisterPassive + toRegisterDirect + toRegisterBonus); 
    toRegisterPassive = passive >= remainingWithdraw ? remainingWithdraw : passive;
    remainingWithdraw = remainingWithdraw - toRegisterPassive;
    toRegisterDirect = directBonusAmount >= remainingWithdraw ? remainingWithdraw : directBonusAmount;
    remainingWithdraw = remainingWithdraw - toRegisterDirect;
    toRegisterBonus = levelBonusAmount >= remainingWithdraw ? remainingWithdraw : levelBonusAmount;
    passive -= toRegisterPassive;
    directBonusAmount -= toRegisterDirect;
    levelBonusAmount -= toRegisterBonus;
    toMaxEarning = MoneyFlow(toRegisterPassive, toRegisterDirect, toRegisterBonus);
    toReceiveOverMax = MoneyFlow(passive, directBonusAmount, levelBonusAmount);
    level = getMaxLevel(localSender);
    directs = accountsRefs[localSender].length;
    time = block.timestamp;
  }
}