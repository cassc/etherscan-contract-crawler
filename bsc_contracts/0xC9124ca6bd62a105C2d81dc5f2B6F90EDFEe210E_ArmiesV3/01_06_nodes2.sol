// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./coin.sol";

interface ReadI {
  function checkArmyAmount(address) external view returns (uint256);

  function checkSpecOpsAmount(address) external view returns (uint256);

  function checkSpaceForceAmount(address) external view returns (uint256);

  function checkPlayers() external view returns (uint256);

  function checkTimestamp(address) external view returns (uint256);

  function readRefCode(address) external view returns (uint256);

  function checkRefed(address) external view returns (bool);

  function readReferals(address) external view returns (address[] memory);

  function checkRefMoney(address) external view returns (uint256);
}

contract ArmiesV3 {
  address private Owner;
  AI private tokenContract1;
  IERC20 private tokenContract2;
  ReadI private oldGameContract;

  uint8 tokendecimals;

  // Army Attributes.
  uint256 taxAmount = 15;
  uint8 constant armyPrice = 100;
  uint256 specOpsPrice = 0.015 ether;
  uint8 constant specOpsPriceInArmies = 10;
  uint256 spaceForcePrice = 0.15 ether;
  uint8 constant spaceForcePriceInSpecOps = 10;
  uint256 starPrice = 0.1 ether;
  uint256[] armyRefPerc = [2000, 1000, 500, 250, 125];
  uint256 constant armyYieldTime = 27;
  uint256 armyYield = 156250;

  bool armiespaused = true;

  // Contract Variables.
  uint256 totalArmies = 0;
  uint256 totalSpecOps = 0;
  uint256 totalSpaceForce = 0;
  uint256 totalPlayers = 0;
  address[] playerList;

  // User structure
  struct User {
    bool merged;
    // Army stats
    uint256 armies;
    uint256 specOps;
    uint256 spaceForce;
    uint8 stars;
    uint256 timestamp;
    uint256 buffer;
    // Referral values
    uint256 refCode;
    bool refed;
    address[] referals;
    address referrer;
    uint256 refMoney;
  }
  mapping(address => User) users;

  mapping(uint256 => address) refOwner;

  mapping(address => bool) blacklists;

  event Ownership(
    address indexed owner,
    address indexed newOwner,
    bool indexed added
  );

  constructor(
    AI _tokenContract1,
    IERC20 _tokenContract2,
    ReadI _oldGameContract,
    address _owner
  ) {
    Owner = _owner;
    tokenContract1 = _tokenContract1;
    tokenContract2 = _tokenContract2;
    oldGameContract = _oldGameContract;
    tokendecimals = tokenContract1.decimals();
  }

  modifier OnlyOwners() {
    require((msg.sender == Owner), "You are not the owner of the token");
    _;
  }

  modifier BlacklistCheck() {
    require(blacklists[msg.sender] == false, "You are in the blacklist");
    _;
  }

  modifier ArmiesStopper() {
    require(armiespaused == false, "Armies code is currently stopped.");
    _;
  }

  event ArmiesCreated(address indexed who, uint256 indexed amount);
  event SpecOpsCreated(address indexed who, uint256 indexed amount);
  event SpaceForceCreated(address indexed who, uint256 indexed amount);
  event StarsCreated(address indexed who, uint256 indexed amount);

  event Blacklist(
    address indexed owner,
    address indexed blacklisted,
    bool indexed added
  );

  // # User Write functions

  function createArmies(uint256 _amount) public ArmiesStopper BlacklistCheck {
    uint256 userBalance = tokenContract2.balanceOf(msg.sender);
    uint256 bonus = 0;
    uint256 price = _amount * armyPrice * 10 ** tokendecimals;
    User storage currentUser = users[msg.sender];

    if (!currentUser.merged) {
      if (
        (oldGameContract.checkArmyAmount(msg.sender) > 0) ||
        (oldGameContract.checkSpecOpsAmount(msg.sender) > 0) ||
        (oldGameContract.checkSpaceForceAmount(msg.sender) > 0)
      ) {
        _merge(msg.sender);
      } else {
        currentUser.merged = true;
      }
    }
    if (currentUser.refed && ((currentUser.buffer + _amount) / 10 > 0)) {
      bonus = (currentUser.buffer + _amount) / 10;
      currentUser.buffer = (currentUser.buffer + _amount) % 10;
    }

    _transferClaimToRef(msg.sender);

    require(userBalance >= price, "You do not have enough SOLDAT!");
    tokenContract2.transferFrom(msg.sender, address(this), price);

    if (
      currentUser.armies == 0 &&
      currentUser.specOps == 0 &&
      currentUser.spaceForce == 0
    ) {
      totalPlayers += 1;
      playerList.push(msg.sender);
    }

    currentUser.armies += _amount + bonus;
    totalArmies += _amount + bonus;

    if (currentUser.timestamp == 0) {
      currentUser.timestamp = block.timestamp;
    }

    emit ArmiesCreated(msg.sender, _amount + bonus);
  }

  function reinvest(uint256 _amount) public ArmiesStopper BlacklistCheck {
    User storage currentUser = users[msg.sender];
    require(((block.timestamp - currentUser.timestamp) / armyYieldTime) > 0);
    uint256 userBalance = currentUser.refMoney + checkArmyMoney(msg.sender);
    uint256 price = _amount * armyPrice * 10 ** tokendecimals;
    require(userBalance >= price, "You do not have enough SOLDAT!");

    if (currentUser.refed) {
      _refDistribute(msg.sender, price);
    }
    uint256 left = userBalance - price;
    currentUser.timestamp +=
      ((block.timestamp - currentUser.timestamp) / armyYieldTime) *
      armyYieldTime;

    currentUser.refMoney = left;

    currentUser.armies += _amount;
    totalArmies += _amount;

    emit ArmiesCreated(msg.sender, _amount);
  }

  function claimArmyMoney(address _who) public ArmiesStopper BlacklistCheck {
    User storage currentUser = users[_who];
    require(((block.timestamp - currentUser.timestamp) / armyYieldTime) > 0);
    uint256 _amount = checkArmyMoney(_who);
    require(_amount + currentUser.refMoney > 0);

    if (currentUser.refed) {
      _refDistribute(_who, _amount);
    }

    currentUser.timestamp +=
      ((block.timestamp - currentUser.timestamp) / armyYieldTime) *
      armyYieldTime;
    uint256 _tax = ((_amount + currentUser.refMoney) * taxAmount) / 100;

    tokenContract2.transfer(_who, _amount + currentUser.refMoney - _tax);
    currentUser.refMoney = 0;
  }

  function createSpecOps(
    uint256 _amount
  ) public payable ArmiesStopper BlacklistCheck {
    User storage currentUser = users[msg.sender];
    uint256 userArmies = checkArmyAmount(msg.sender);
    uint256 price = _amount * specOpsPrice;
    uint256 priceInArmies = _amount * specOpsPriceInArmies;

    require(msg.value >= price, "Not enough BNB provided!");
    require(
      userArmies >= priceInArmies,
      "The army amount is lower than the requirement"
    );

    _transferClaimToRef(msg.sender);

    currentUser.armies -= priceInArmies;
    currentUser.specOps += _amount;

    totalArmies -= priceInArmies;
    totalSpecOps += _amount;

    emit SpecOpsCreated(msg.sender, _amount);
  }

  function createSpaceForce(
    uint256 _amount
  ) public payable ArmiesStopper BlacklistCheck {
    User storage currentUser = users[msg.sender];
    uint256 userSpecOps = checkSpecOpsAmount(msg.sender);
    uint256 price = _amount * spaceForcePrice;
    uint256 priceInSpecOps = _amount * spaceForcePriceInSpecOps;

    require(msg.value >= price, "The amount is lower than the requirement");
    require(
      userSpecOps >= priceInSpecOps,
      "The army amount is lower than the requirement"
    );

    _transferClaimToRef(msg.sender);

    currentUser.specOps -= priceInSpecOps;
    currentUser.spaceForce += _amount;

    totalSpecOps -= priceInSpecOps;
    totalSpaceForce += _amount;

    emit SpaceForceCreated(msg.sender, _amount);
  }

  function createStars(
    uint8 _amount
  ) public payable ArmiesStopper BlacklistCheck {
    User storage currentUser = users[msg.sender];

    require(_amount != 0, "You cannot create 0 stars.");

    require(
      _amount <= 3 - currentUser.stars,
      "You cannot create more than 3 stars."
    );

    uint256 price = _amount * starPrice;
    require(msg.value >= price, "The amount is lower than the requirement.");

    _transferClaimToRef(msg.sender);
    currentUser.stars += _amount;

    emit StarsCreated(msg.sender, _amount);
  }

  function getRefd(uint256 _ref) public {
    address _referree = msg.sender;
    User storage currentUser = users[msg.sender];
    address _referrer = readRef(_ref);
    address[] memory _addresses = readRefLevels(_referrer);
    for (uint8 i = 0; i < _addresses.length; ) {

      require(
        _addresses[i] != msg.sender,
        "You cannot enter your own referral chain"
      );
      i++;
    }
    require(
      currentUser.armies == 0 &&
        currentUser.specOps == 0 &&
        currentUser.spaceForce == 0,
      "You are not eligible to getting referred!"
    );
    require(refOwner[_ref] != address(0), "Referral code does not exist!");
    require(_referrer != msg.sender, "You cannot refer yourself!");
    require(currentUser.refed == false, "You are already referred!");
    currentUser.referrer = _referrer;
    users[_referrer].referals.push(_referree);
    currentUser.refed = true;
  }

  function createRef() public {
    User storage currentUser = users[msg.sender];
    require(currentUser.refCode == 0, "You already have a referral code.");
    uint256 rand = uint256(
      keccak256(abi.encodePacked(msg.sender, block.number - 1))
    );
    uint256 result = uint256(rand % (10 ** 12));
    require(
      readRef(result) == address(0),
      "Generated code already exists. Transaction has been refunded. Please try again."
    );
    refOwner[result] = msg.sender;
    currentUser.refCode = result;
  }

  // # Read functions

  function totalArmyAmount() public view returns (uint256) {
    return (totalArmies);
  }

  function totalSpecOpsAmount() public view returns (uint256) {
    return (totalSpecOps);
  }

  function totalSpaceForceAmount() public view returns (uint256) {
    return (totalSpaceForce);
  }

  function checkArmyAmount(address _who) public view returns (uint256) {
    return (users[_who].armies);
  }

  function checkSpecOpsAmount(address _who) public view returns (uint256) {
    return (users[_who].specOps);
  }

  function checkSpaceForceAmount(address _who) public view returns (uint256) {
    return (users[_who].spaceForce);
  }

  function checkStarsAmount(address _who) public view returns (uint256) {
    return (users[_who].stars);
  }

  function checkMerge(address _who) public view returns (bool) {
    return users[_who].merged;
  }

  function checkPlayers() public view returns (uint256) {
    return (totalPlayers);
  }

  function checkPlayerList() public view returns (address[] memory) {
    return playerList;
  }

  function checkArmyMoney(address _who) public view returns (uint256) {
    User storage currentUser = users[_who];

    uint256 _cycles = ((block.timestamp - currentUser.timestamp) /
      armyYieldTime);

    uint256 _amount = (currentUser.armies *
      armyYield +
      currentUser.specOps *
      (armyYield * 16) +
      currentUser.spaceForce *
      (armyYield * 20 * (12 + currentUser.stars))) * _cycles;

    return _amount;
  }

  function checkRefMoney(address _who) public view returns (uint256) {
    return users[_who].refMoney;
  }

  function checkTimestamp(address _who) public view returns (uint256) {
    return users[_who].timestamp;
  }

  function readRef(uint256 _ref) public view returns (address) {
    return refOwner[_ref];
  }

  function readRefCode(address _who) public view returns (uint256) {
    return users[_who].refCode;
  }

  function checkRefed(address _who) public view returns (bool) {
    return users[_who].refed;
  }

  function checkReferrer(address _who) public view returns (address) {
    return users[_who].referrer;
  }

  function readReferals(address _who) public view returns (address[] memory) {
    return users[_who].referals;
  }

  function readBuffer(address _who) public view returns(uint256) {
    return users[_who].buffer;
  }

  function readRefLevels(address _who) public view returns (address[] memory) {
    address[] memory addresses = new address[](_findIterations(_who));
    for (uint i = 0; i < 5; ) {
      _who = checkReferrer(_who);
      if (_who == address(0)) break;
      addresses[i] = _who;
      i++;
    }
    return addresses;
  }

  // # Internal functions

  function _transferClaimToRef(address _who) internal ArmiesStopper {
    User storage currentUser = users[_who];
    uint256 userBalance = checkArmyMoney(_who);
    currentUser.refMoney += userBalance;
    currentUser.timestamp +=
      ((block.timestamp - currentUser.timestamp) / armyYieldTime) *
      armyYieldTime;
  }

  function _merge(address _who) internal ArmiesStopper {
    User storage currentUser = users[_who];
    require(!currentUser.merged, "This account is already merged!");

    uint256 oldAllArmies = oldGameContract.checkArmyAmount(_who) * 10;
    uint256 oldAllSpecOps = oldGameContract.checkSpecOpsAmount(_who) * 100;
    uint256 oldAllSpaceForce = oldGameContract.checkSpaceForceAmount(_who) *
      1000;
    uint256 newArmies = (oldAllArmies + oldAllSpecOps + oldAllSpaceForce) / 100;
    currentUser.armies = newArmies;
    if (newArmies > 0) {
      totalPlayers++;
      playerList.push(_who);
    }
    currentUser.merged = true;
  }

  function _refDistribute(
    address _bottomAddr,
    uint256 _toDistribute
  ) internal ArmiesStopper {
    address[] memory list = readRefLevels(_bottomAddr);
    for (uint8 i = 0; i < list.length; ) {
      users[list[i]].refMoney += (_toDistribute * armyRefPerc[i]) / 10000;
      i++;
    }
  }

  function _findIterations(
    address _who
  ) internal view returns (uint8 iterations) {
    for (uint8 i = 0; i < 5; ) {
      _who = checkReferrer(_who);
      if (_who == address(0)) break;
      i++;
      iterations = i;
    }
  }

  // # Owner functions

  function addBlacklistMember(address _who) public OnlyOwners {
    blacklists[_who] = true;
    emit Blacklist(msg.sender, _who, true);
  }

  function transferOwner(address _who) public OnlyOwners returns (bool) {
    Owner = _who;
    emit Ownership(msg.sender, _who, true);
    return true;
  }

  function removeBlacklistMember(address _who) public OnlyOwners {
    blacklists[_who] = false;
    emit Blacklist(msg.sender, _who, false);
  }

  function checkBlacklistMember(address _who) public view returns (bool) {
    return blacklists[_who];
  }

  function changeTax(uint256 _to) public OnlyOwners {
    taxAmount = _to;
  }

  function stopArmies(bool _status) public OnlyOwners {
    armiespaused = _status;
  }

  function changeBNBprices(
    uint256 _specOps,
    uint256 _spaceForce,
    uint256 _starPrice
  ) public OnlyOwners {
    specOpsPrice = _specOps;
    spaceForcePrice = _spaceForce;
    starPrice = _starPrice;
  }

  function changeUserArmies(address _who, uint256 _amount) public OnlyOwners {
    _transferClaimToRef(_who);
    totalArmies -= users[_who].armies;
    users[_who].armies = _amount;
    totalArmies += _amount;
  }

  function changeUserSpecOps(address _who, uint256 _amount) public OnlyOwners {
    _transferClaimToRef(_who);
    totalSpecOps -= users[_who].specOps;
    users[_who].specOps = _amount;
    totalSpecOps += _amount;
  }

  function changeUserSpaceForce(
    address _who,
    uint256 _amount
  ) public OnlyOwners {
    _transferClaimToRef(_who);
    totalSpaceForce -= users[_who].spaceForce;
    users[_who].spaceForce = _amount;
    totalSpaceForce += _amount;
  }

  function withdrawToken() public OnlyOwners {
    require(tokenContract2.balanceOf(address(this)) > 0);
    tokenContract2.transfer(Owner, tokenContract2.balanceOf(address(this)));
  }

  function withdraw() public OnlyOwners {
    require(address(this).balance > 0);
    payable(Owner).transfer(address(this).balance);
  }
}