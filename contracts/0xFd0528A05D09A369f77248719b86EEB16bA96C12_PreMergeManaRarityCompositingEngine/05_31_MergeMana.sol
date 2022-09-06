// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import './RendererPropsStorage.sol';
import './interfaces/IDataStorage.sol';
import './Merge.sol';

import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@abf-monorepo/protocol/contracts/renderers/LayerCompositeRenderer.sol';
import '@abf-monorepo/protocol/contracts/libraries/BytesUtils.sol';

contract MergeMana is Ownable {
  using Strings for uint256;

  Merge public merge;

  bool public emergencyShutdown = false;

  // mana
  uint256 public numDecimals;

  IDataStorage public baseManaStorage;
  uint256 public baseManaMultiplier;

  mapping(address => bool) public manaModifier;

  mapping(uint256 => uint256) public boostedMana;
  mapping(uint256 => uint256) public consumedMana;

  // decay
  uint256 public manaDecayPerBlock;
  uint256 public manaDecayStartBlock;

  // boost
  uint256 public manaBoostRitualMultiplier;
  uint256 public maxManaBoostRitualBalance;

  // channeling
  bool public isChannelingRitualActive = false;
  mapping(uint256 => uint256) public channelingRitualDestinationTokenId;
  mapping(uint256 => uint256) public channeledMana;
  mapping(uint256 => uint256) public numChanneledToTokenId;

  event ChangedEmergencyShutdown(bool shutdown);
  event ConsumedMana(uint256 tokenId, uint256 amount);
  event IncreasedMana(uint256 tokenId, uint256 amount);
  event ChanneledStatue(uint256 from, uint256 to, uint256 amount);
  event BoostedMana(address booster, uint256 tokenId, uint256 amount);

  struct DeployMergeManaConfig {
    address merge;
    address baseManaStorage;
    uint256 manaBoostRitualMultiplier;
    uint256 maxManaBoostRitualBalance;
    uint256 baseManaMultiplier;
    uint256 numDecimals;
  }

  constructor(DeployMergeManaConfig memory config) {
    merge = Merge(config.merge);
    manaBoostRitualMultiplier = config.manaBoostRitualMultiplier;
    baseManaStorage = IDataStorage(config.baseManaStorage);
    maxManaBoostRitualBalance = config.maxManaBoostRitualBalance;
    baseManaMultiplier = config.baseManaMultiplier;
    numDecimals = config.numDecimals;
  }

  function setNumDecimals(uint256 _numDecimals) public onlyOwner {
    numDecimals = _numDecimals;
  }

  function setBaseManaStorage(address _baseManaStorage) public onlyOwner {
    baseManaStorage = IDataStorage(_baseManaStorage);
  }

  function setBaseManaMultiplier(uint256 _baseManaMultiplier) public onlyOwner {
    baseManaMultiplier = _baseManaMultiplier;
  }

  function setMaxManaBoostRitualBalance(uint256 _maxManaBoostRitualBalance)
    public
    onlyOwner
  {
    maxManaBoostRitualBalance = _maxManaBoostRitualBalance;
  }

  function setManaBoostRitualMultiplier(uint256 _manaBoostRitualMultiplier)
    public
    onlyOwner
  {
    manaBoostRitualMultiplier = _manaBoostRitualMultiplier;
  }

  function setManaDecayPerBlock(uint256 _manaDecayPerBlock) public onlyOwner {
    manaDecayPerBlock = _manaDecayPerBlock;
  }

  function setManaDecayStartBlock(uint256 _manaDecayStartBlock)
    public
    onlyOwner
  {
    manaDecayStartBlock = _manaDecayStartBlock;
  }

  function setManaModifier(address _manaModifier, bool status)
    public
    onlyOwner
  {
    manaModifier[_manaModifier] = status;
  }

  function setMerge(address _merge) public onlyOwner {
    merge = Merge(_merge);
  }

  function setIsChannelingRitualActive(bool _isChannelingRitualActive)
    public
    onlyOwner
  {
    isChannelingRitualActive = _isChannelingRitualActive;
    emit ChangedEmergencyShutdown(isChannelingRitualActive);
  }

  function setEmergencyShutdown(bool shutdown) public onlyOwner {
    emergencyShutdown = shutdown;
    emit ChangedEmergencyShutdown(shutdown);
  }

  function isMergeByDifficulty() public view virtual returns (bool) {
    return (block.difficulty > (2**64)) || (block.difficulty == 0);
  }

  modifier onlyIsNotShutdown() {
    require(!emergencyShutdown, 'MergeMana: Emergency shutdown is in place');
    _;
  }

  modifier onlyIsNotMergeOrChannelingNotActive() {
    require(
      !isMergeByDifficulty() && !isChannelingRitualActive,
      'MergeMana: Action only can occur before merge'
    );
    _;
  }

  modifier onlyIsChannelingRitualActive() {
    require(
      isChannelingRitualActive,
      'MergeMana: Action only can occur after merge'
    );
    _;
  }

  modifier onlyManaModifier() {
    require(manaModifier[msg.sender], 'MergeMana: Not a mana modifier');
    _;
  }

  /**
   * Mana based logic
   */

  function getTotalMana(uint256 id) public view returns (uint256) {
    return getInherentMana(id) + getBoostedMana(id) + getChanneledMana(id);
  }

  function getTotalManaWithNoPenalties(uint256 id)
    public
    view
    returns (uint256)
  {
    return
      getInherentManaWithNoPenalties(id) + boostedMana[id] + channeledMana[id];
  }

  function getTotalManaPenalties(uint256 id) public view returns (uint256) {
    uint256 decay = getManaDecay();
    uint256 consumedAmount = consumedMana[id];
    return decay + consumedAmount;
  }

  function getChanneledMana(uint256 id) public view returns (uint256) {
    uint256 totalPenalties = getTotalManaPenalties(id);
    if (totalPenalties > channeledMana[id]) {
      return 0;
    }
    return channeledMana[id] - totalPenalties;
  }

  function getBoostedMana(uint256 id) public view returns (uint256) {
    uint256 totalPenalties = getTotalManaPenalties(id);

    if (totalPenalties > channeledMana[id]) {
      uint256 leftOverManaPenalty = totalPenalties - channeledMana[id];
      if (leftOverManaPenalty > boostedMana[id]) {
        return 0;
      }
      return boostedMana[id] - leftOverManaPenalty;
    }

    return boostedMana[id];
  }

  function getInherentManaWithNoPenalties(uint256 id)
    public
    view
    returns (uint256)
  {
    if (channelingRitualDestinationTokenId[id] != 0) {
      return 0;
    }
    if (address(baseManaStorage) == address(0)) {
      return 0;
    }
    return
      uint256(uint8(baseManaStorage.indexToData(id)[0])) * baseManaMultiplier;
  }

  function getInherentMana(uint256 id) public view returns (uint256) {
    uint256 lowerMana = boostedMana[id] + channeledMana[id];
    uint256 totalPenalties = getTotalManaPenalties(id);
    uint256 inherentManaWithNoPenalties = getInherentManaWithNoPenalties(id);

    if (totalPenalties > lowerMana) {
      uint256 leftOverManaPenalty = totalPenalties - lowerMana;
      if (leftOverManaPenalty > inherentManaWithNoPenalties) {
        return 0;
      }
      return inherentManaWithNoPenalties - leftOverManaPenalty;
    }

    return inherentManaWithNoPenalties;
  }

  function getManaDecay() public view returns (uint256) {
    if (manaDecayStartBlock == 0) {
      return 0;
    }
    return (block.number - manaDecayStartBlock) * manaDecayPerBlock;
  }

  function consumeMana(uint256 id, uint256 amount)
    public
    onlyIsNotShutdown
    onlyManaModifier
  {
    require(
      amount <= getTotalMana(id),
      'MergeMana: Can not consume more mana than what exists in statue'
    );
    consumedMana[id] += amount;
    emit ConsumedMana(id, amount);
  }

  function increaseMana(uint256 id, uint256 amount)
    public
    onlyIsNotShutdown
    onlyManaModifier
  {
    if (channelingRitualDestinationTokenId[id] == 0) {
      boostedMana[id] += amount;
    } else {
      channeledMana[channelingRitualDestinationTokenId[id]] += amount;
    }
    emit IncreasedMana(id, amount);
  }

  function _channelMana(uint256 from, uint256 to) internal {
    uint256 inherentManaAndBoostedMana = getInherentMana(from) +
      getBoostedMana(from);
    channeledMana[to] += inherentManaAndBoostedMana;
    numChanneledToTokenId[to]++;
    channelingRitualDestinationTokenId[from] = to;
    boostedMana[from] = 0;
    emit ChanneledStatue(from, to, inherentManaAndBoostedMana);
  }

  function safeChannelManaRitual(uint256[] memory from, uint256 to)
    public
    onlyIsChannelingRitualActive
    onlyIsNotShutdown
  {
    for (uint256 i = 0; i < from.length; ++i) {
      if (to != 0 && channelingRitualDestinationTokenId[from[i]] == 0) {
        _channelMana(from[i], to);
      }
    }
  }

  function channelManaRitual(uint256[] memory from, uint256 to)
    public
    onlyIsChannelingRitualActive
    onlyIsNotShutdown
  {
    for (uint256 i = 0; i < from.length; ++i) {
      require(to != 0, 'MergeMana: Can not channel to tokenId zero');
      require(
        channelingRitualDestinationTokenId[from[i]] == 0,
        'MergeMana: Mana has already been channeled'
      );
      _channelMana(from[i], to);
    }
  }

  function getBoostManaRitualAmount(address booster)
    public
    view
    returns (uint256)
  {
    uint256 balance = merge.balanceOf(booster);
    return
      manaBoostRitualMultiplier *
      (
        balance > maxManaBoostRitualBalance
          ? maxManaBoostRitualBalance
          : balance
      ) *
      merge.getCurrentRarityScore(booster);
  }

  function _boostMana(uint256 tokenId, uint256 amount) internal {
    boostedMana[tokenId] = amount;
    emit BoostedMana(msg.sender, tokenId, amount);
  }

  function manaBoostRitual(uint256[] memory tokenIds)
    public
    onlyIsNotMergeOrChannelingNotActive
    onlyIsNotShutdown
  {
    uint256 boostedManaAmount = getBoostManaRitualAmount(msg.sender);
    for (uint256 i = 0; i < tokenIds.length; ++i) {
      require(
        merge.ownerOf(tokenIds[i]) == msg.sender,
        'MergeMana: Can not boost token you do not own'
      );
      require(
        boostedMana[tokenIds[i]] == 0,
        'MergeMana: Can not boost tokens that are already boosted'
      );
      _boostMana(tokenIds[i], boostedManaAmount);
    }
  }

  function safeManaBoostRitual(uint256[] memory tokenIds)
    public
    onlyIsNotMergeOrChannelingNotActive
    onlyIsNotShutdown
  {
    uint256 boostedManaAmount = getBoostManaRitualAmount(msg.sender);
    for (uint256 i = 0; i < tokenIds.length; ++i) {
      if (
        merge.ownerOf(tokenIds[i]) == msg.sender &&
        boostedMana[tokenIds[i]] == 0
      ) {
        _boostMana(tokenIds[i], boostedManaAmount);
      }
    }
  }
}