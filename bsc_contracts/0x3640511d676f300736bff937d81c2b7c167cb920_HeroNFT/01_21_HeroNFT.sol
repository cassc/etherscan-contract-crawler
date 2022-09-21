// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./BaseNFT.sol";
import "../libs/fota/ArrayUtil.sol";
import "../libs/fota/StringUtil.sol";
import "../interfaces/IEnergyManager.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/IFOTAPricer.sol";
import "../interfaces/IMarketPlace.sol";

contract HeroNFT is BaseNFT {
  using StringUtil for string;
  using ArrayUtil for uint[];

  struct Hero {
    uint16 id;
    uint createdAt;
    uint8 level;
    uint32 experience;
    uint ownPrice;
    uint failedUpgradingAmount;
    uint[3] skills;
    uint totalProfited;
  }

  mapping (uint => Hero) public heroes;
  mapping (bytes24 => bool) private heroNames;
  mapping (uint16 => string) public mappingHeroRace;
  mapping (uint16 => string) public mappingHeroClass;
  mapping (uint16 => string) public mappingHeroName;
  mapping (uint16 => uint[7]) private strengthIndexReferences;
  mapping (uint16 => uint[7]) private strengthBonuses;
  mapping (uint8 => uint32) public experienceCheckpoint;

  uint16 public countId;
  IEnergyManager public energyManager;
  uint public totalSupply;
  uint public profitRate;
  mapping (address => uint[]) private ownerHeroes;
  mapping (address => bool) exclusives;
  IMarketPlace public marketPlace;
  mapping (uint => uint) public fotaOwnPrices;
  mapping (uint => uint) public heroTotalProfitedInFota;
  IFOTAPricer public fotaPricer;
  uint public fotaProfitRate;

  event NewClassAdded(
    uint16 classId,
    string klass,
    uint[7] strengths
  );
  event LevelUp(
    uint tokenId,
    uint level,
    uint nextLevelCheckpoint
  );
  event ExperienceUp(
    uint tokenId,
    uint32 experience
  );
  event ExperienceCheckpointUpdated(
    uint16 level,
    uint32 experience
  );
  event BaseStrengthUpdated(
    uint16 classId,
    uint[7] baseStrength
  );
  event StrengthBonusUpdated(
    uint16 classId,
    uint[7] strengthBonus
  );
  event SkillUp(
    uint tokenId,
    uint index,
    uint level
  );
  event HeroRaceUpdated(
    uint16 classId,
    string race
  );
  event HeroClassUpdated(
    uint16 classId,
    string klass
  );
  event HeroNameUpdated(
    uint16 classId,
    string name
  );
  event HeroInfoUpdated(
    uint tokenId,
    uint8 level,
    uint32 experience,
    uint[3] skills
  );
  event TotalProfitedUpdated(
    uint tokenId,
    uint totalProfited,
    uint totalFOTAProfited
  );
  event FOTATotalProfitedUpdated(
    uint tokenId,
    uint fotaTotalProfited
  );
  event ProfitRateUpdated(
    uint profitRate,
    uint fotaProfitRate
  );

  function initialize(
    address _mainAdmin,
    string calldata _name,
    string calldata _symbol
  ) override public initializer {
    BaseNFT.initialize(_mainAdmin, _name, _symbol);
  }

  function mintHero(address _owner, uint16 _classId, uint _price, uint _index) onlyMintAdmin public returns (uint) {
    return _mint(_owner, _classId, _price, _index);
  }

  function mintHeroes(address _owner, uint16 _classId, uint _price, uint _quantity) onlyMintAdmin external {
    for(uint i = 0; i < _quantity; i++) {
      _mint(_owner, _classId, _price, i);
    }
  }

  function getHero(uint _tokenId) external view returns (string memory, string memory, string memory, uint16, uint, uint8, uint32) {
    return (
      mappingHeroRace[heroes[_tokenId].id],
      mappingHeroClass[heroes[_tokenId].id],
      mappingHeroName[heroes[_tokenId].id],
      heroes[_tokenId].id,
      heroes[_tokenId].createdAt,
      heroes[_tokenId].level,
      heroes[_tokenId].experience
    );
  }

  function getHeroSkills(uint _tokenId) external view returns (uint, uint, uint) {
    return (
      heroes[_tokenId].skills[0],
      heroes[_tokenId].skills[1],
      heroes[_tokenId].skills[2]
    );
  }

  function getClassId(uint _tokenId) external view returns (uint16) {
    return heroes[_tokenId].id;
  }

  function getCreator(uint _tokenId) override external view returns (address) {
    return creators[heroes[_tokenId].id];
  }

  function getStrengthIndexReferences(uint16 _classId) external view returns (uint, uint, uint, uint, uint, uint, uint) {
    return (
      strengthIndexReferences[_classId][0],
      strengthIndexReferences[_classId][1],
      strengthIndexReferences[_classId][2],
      strengthIndexReferences[_classId][3],
      strengthIndexReferences[_classId][4],
      strengthIndexReferences[_classId][5],
      strengthIndexReferences[_classId][6]
    );
  }

  function getStrengthBonuses(uint16 _classId) external view returns (uint, uint, uint, uint, uint, uint, uint) {
    return (
      strengthBonuses[_classId][0],
      strengthBonuses[_classId][1],
      strengthBonuses[_classId][2],
      strengthBonuses[_classId][3],
      strengthBonuses[_classId][4],
      strengthBonuses[_classId][5],
      strengthBonuses[_classId][6]
    );
  }

  function reachMaxProfit(uint _tokenId) public view returns (bool) {
    require(_exists(_tokenId), "Hero not found");
    (uint usdProfitable, uint fotaProfitable) = _getMaxProfitable(_tokenId);
    Hero storage hero = heroes[_tokenId];
    return hero.totalProfited >= usdProfitable || heroTotalProfitedInFota[_tokenId] >= fotaProfitable;
  }

  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenId
  ) internal override {
    super._beforeTokenTransfer(_from, _to, _tokenId);
    if (_to == address(0)) {
      delete heroes[_tokenId];
      totalSupply--;
    } else {
      if (!exclusives[_to]) {
        if (_from == address(0) || !reachMaxProfit(_tokenId)) {
          energyManager.updatePoint(_to, 1);
        }
        ownerHeroes[_to].push(_tokenId);
      }
    }
    if (_from == address(0)) {
      totalSupply++;
    } else if (!exclusives[_from]) {
      if (!reachMaxProfit(_tokenId)) {
        energyManager.updatePoint(_from, -1);
      }
      ownerHeroes[_from].removeElementFromArray(_tokenId);
    }
  }

  // PRIVATE FUNCTIONS

  function _mint(address _owner, uint16 _classId, uint _price, uint _index) private returns (uint) {
    require(_classId >= 1 && _classId <= countId, 'NFT: Invalid class');
    uint newId = _genNewId(_index);
    _mint(_owner, newId);
    heroes[newId].id = _classId;
    heroes[newId].level = 1;
    heroes[newId].createdAt = block.timestamp;
    heroes[newId].ownPrice = _price;
    heroes[newId].skills = [1, 0, 0];
    fotaOwnPrices[newId] = _convertUsdToFota(_price);
    return newId;
  }

  function _levelUp(uint _tokenId) private {
    heroes[_tokenId].level += 1;
    emit LevelUp(_tokenId, heroes[_tokenId].level, experienceCheckpoint[heroes[_tokenId].level + 1]);
  }

  function getOwnerHeroes(address _owner) external view returns(uint[] memory) {
    return ownerHeroes[_owner];
  }

  function getOwnerTotalHeroThatNotReachMaxProfit(address _owner) external view returns(uint) {
    uint totalHero;
    uint[] memory ids = ownerHeroes[_owner];
    for(uint i = 0; i < ids.length; i++) {
      if (!reachMaxProfit(ids[i])) {
        totalHero += 1;
      }
    }
    return totalHero;
  }

  function tokenURI(uint _tokenId) public view override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
    uint16 classId = heroes[_tokenId].id;
    string memory classIdStr = Strings.toString(classId);
    string memory domain = block.chainid == 56 ? 'https://marketplace.fota.io' : 'https://dev-marketplace.fota.io';

    return string(abi.encodePacked(domain, '/metadata/heroes/', classIdStr, '.json'));
  }

  // ADMIN FUNCTIONS

  function syncExistHeroes(uint[] calldata _tokenIds) external onlyMainAdmin {
    for (uint i = 0; i < _tokenIds.length; i++) {
      Hero storage hero = heroes[_tokenIds[i]];
      require(hero.level == 0, "Invalid hero");
      hero.level = 1;
      hero.skills[0] = 1;
    }
  }

  function syncFOTAOwnPrice(uint[] calldata _tokenIds, uint[] calldata _fotaOwnPrices) onlyContractAdmin external {
    require(_tokenIds.length == _fotaOwnPrices.length, "Data invalid");
    for (uint i = 0; i < _tokenIds.length; i++) {
      fotaOwnPrices[_tokenIds[i]] = _fotaOwnPrices[i];
      emit AllOwnPriceUpdated(_tokenIds[i], heroes[_tokenIds[i]].ownPrice, _fotaOwnPrices[i]);
    }
  }

  function syncFOTAProfited(uint[] calldata _tokenIds, uint[] calldata _fotaProfited) onlyContractAdmin external {
    require(_tokenIds.length == _fotaProfited.length, "Data invalid");
    for (uint i = 0; i < _tokenIds.length; i++) {
      heroTotalProfitedInFota[_tokenIds[i]] = _fotaProfited[i];
      emit FOTATotalProfitedUpdated(_tokenIds[i], _fotaProfited[i]);
    }
  }

  function updateBaseStrengths(uint16 _classId, uint[7] calldata _strengths) external onlyMainAdmin {
    strengthIndexReferences[_classId] = _strengths;
    emit BaseStrengthUpdated(_classId, _strengths);
  }

  function updateStrengthBonus(uint16 _classId, uint[7] calldata _strengthBonuses) external onlyMainAdmin {
    strengthBonuses[_classId] = _strengthBonuses;
    emit StrengthBonusUpdated(_classId, _strengthBonuses);
  }

  function updateExperienceCheckpoint(uint8 _level, uint32 _experience) external onlyMainAdmin {
    experienceCheckpoint[_level] = _experience;
    emit ExperienceCheckpointUpdated(_level, _experience);
  }

  function updateOwnPrice(uint _tokenId, uint _ownPrice) override onlyMintAdmin external {
    Hero storage hero = heroes[_tokenId];
    hero.ownPrice = _ownPrice;
    uint tokenOwnPrice = _convertUsdToFota(_ownPrice);
    fotaOwnPrices[_tokenId] = tokenOwnPrice;
    emit OwnPriceUpdated(_tokenId, _ownPrice);
  }

  function updateAllOwnPrices(uint _tokenId, uint _ownPrice, uint _fotaOwnPrice) onlyMintAdmin external {
    Hero storage hero = heroes[_tokenId];
    hero.ownPrice = _ownPrice;
    fotaOwnPrices[_tokenId] = _fotaOwnPrice;
    emit AllOwnPriceUpdated(_tokenId, _ownPrice, _fotaOwnPrice);
  }

  function increaseTotalProfited(uint _tokenId, uint _amount) onlyMintAdmin external returns (uint) {
    Hero storage hero = heroes[_tokenId];
    (uint maxProfitable, uint maxFOTAProfitable) = _getMaxProfitable(_tokenId);

    // check max fota
    uint fotaProfitable = _convertUsdToFota(_amount);
    if (heroTotalProfitedInFota[_tokenId] + fotaProfitable >= maxFOTAProfitable) {
      fotaProfitable = maxFOTAProfitable - heroTotalProfitedInFota[_tokenId];
    }

    // check max usdf
    uint profitAble = _convertFotaToUsd(fotaProfitable);
    if (hero.totalProfited + profitAble >= maxProfitable) {
      profitAble = maxProfitable - hero.totalProfited;
      fotaProfitable = _convertUsdToFota(profitAble);
    }

    heroTotalProfitedInFota[_tokenId] += fotaProfitable;
    hero.totalProfited += profitAble;
    emit TotalProfitedUpdated(_tokenId, hero.totalProfited, heroTotalProfitedInFota[_tokenId]);
    return fotaProfitable;
  }

  function updateProfitRate(uint _profitRate, uint _fotaProfitRate) onlyMainAdmin external {
    profitRate = _profitRate;
    fotaProfitRate = _fotaProfitRate;
    emit ProfitRateUpdated(_profitRate, _fotaProfitRate);
  }

  function experienceUp(uint _tokenId, uint32 _experience) external onlyGameContract {
    if (heroes[_tokenId].experience + _experience >= experienceCheckpoint[heroes[_tokenId].level + 1]) {
      heroes[_tokenId].experience = experienceCheckpoint[heroes[_tokenId].level + 1];
      if (heroes[_tokenId].level % 5 == 1 || heroes[_tokenId].level % 5 == 3) {
        _levelUp(_tokenId);
      }
    } else {
      heroes[_tokenId].experience += _experience;
    }
    emit ExperienceUp(_tokenId, heroes[_tokenId].experience);
  }

  function skillUp(uint _tokenId, uint8 _index) external onlyUpgradingContract {
    _validateSkillIndex(_tokenId, _index);
    heroes[_tokenId].skills[_index] += 1;
    _levelUp(_tokenId);
    emit SkillUp(_tokenId, _index, heroes[_tokenId].skills[_index]);
  }

  function addHeroClass(string calldata _race, string calldata _class, string calldata _name, uint[7] calldata _strengths, address _creator) external onlyMainAdmin {
    require(!heroNames[_name.toBytes24()], "Name exists");
    heroNames[_name.toBytes24()] = true;
    countId += 1;

    mappingHeroRace[countId] = _race;
    mappingHeroClass[countId] = _class;
    mappingHeroName[countId] = _name;
    strengthIndexReferences[countId] = _strengths;
    creators[countId] = _creator;
    emit NewClassAdded(countId, _class, _strengths);
  }

  function updateHeroRace(uint16 _classId, string calldata _race) external onlyMainAdmin {
    mappingHeroRace[_classId] = _race;
    emit HeroRaceUpdated(_classId, _race);
  }

  function updateHeroClass(uint16 _classId, string calldata _class) external onlyMainAdmin {
    mappingHeroClass[_classId] = _class;
    emit HeroClassUpdated(_classId, _class);
  }

  function updateHeroName(uint16 _classId, string calldata _name) external onlyMainAdmin {
    require(!heroNames[_name.toBytes24()], "Name exists");
    heroNames[mappingHeroName[_classId].toBytes24()] = false;
    heroNames[_name.toBytes24()] = true;
    mappingHeroName[_classId] = _name;
    emit HeroNameUpdated(_classId, _name);
  }

  function updateHeroInfo(uint _tokenId, uint8 _level, uint32 _experience, uint[3] calldata _skills) external onlyMintAdmin {
    require(_level > 0, "400");
    heroes[_tokenId].level = _level;
    heroes[_tokenId].experience = _experience;
    heroes[_tokenId].skills = _skills;
    emit HeroInfoUpdated(_tokenId, _level, _experience, _skills);
  }

  function updateEnergyManager(address _energyManager) external onlyMainAdmin {
    energyManager = IEnergyManager(_energyManager);
  }

  function bulkUpdateOwnPrice(uint[] calldata _tokenIds, uint[] calldata _ownPrices) external onlyMainAdmin {
    require(_tokenIds.length == _ownPrices.length, "HeroNFT: 401");
    for(uint i = 0; i < _tokenIds.length; i++) {
      heroes[_tokenIds[i]].ownPrice = _ownPrices[i];
      emit OwnPriceUpdated(_tokenIds[i], _ownPrices[i]);
    }
  }

  function updateExclusive(address _address, bool _status) external onlyMainAdmin {
    exclusives[_address] = _status;
  }

  function setOwnerHeroes(address[] calldata owners, uint[][] calldata nftIds) external onlyMainAdmin {
    require(owners.length == nftIds.length, "Invalid length data");

    for (uint i = 0; i < owners.length; i++) {
      address owner = owners[i];
      ownerHeroes[owner] = nftIds[i];
    }
  }

  function setFOTAPricer(address _fotaPricer) external onlyMainAdmin {
    fotaPricer = IFOTAPricer(_fotaPricer);
  }

  // PRIVATE FUNCTIONS

  function _validateSkillIndex(uint _tokenId, uint8 _index) private view {
    uint8 levelMod5 = uint8(heroes[_tokenId].level % 5);
    require(levelMod5 != 1 && levelMod5 != 3, "Level invalid");
    uint8 skillIndex = levelMod5 == 0 ? 0 : levelMod5 == 2 ? 1 : 2;
    require(_index == skillIndex, "Skill type invalid");
    require(heroes[_tokenId].experience == experienceCheckpoint[heroes[_tokenId].level + 1], "Experience invalid");
  }

  function _getMaxProfitable(uint _tokenId) private view returns (uint, uint) {
    Hero storage hero = heroes[_tokenId];
    uint usdProfitable = hero.ownPrice * profitRate / 100;
    uint fotaProfitable = fotaOwnPrices[_tokenId] * fotaProfitRate / 100;
    return (usdProfitable, fotaProfitable);
  }

  function _convertUsdToFota(uint _amount) private view returns (uint) {
    return _amount * 1000 / fotaPricer.fotaPrice();
  }

  function _convertFotaToUsd(uint _amount) private view returns (uint) {
    return _amount * fotaPricer.fotaPrice() / 1000;
  }

}