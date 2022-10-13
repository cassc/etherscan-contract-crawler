// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "./interfaces/CBKLandInterface.sol";

contract Village is Initializable, AccessControlUpgradeable, IERC721ReceiverUpgradeable {

  bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

  CBKLandInterface public cbkLand;

  mapping(address => uint256) public stakedLand;
  mapping(address => uint256) public stakedFrom;
  mapping(address => uint256) public stakedTo;
  mapping(uint256 => mapping(Building => uint256)) public buildings; // land to building to level
  mapping(uint256 => BuildingUpgrade) public currentlyUpgrading;
  mapping(Building => uint256) public buildingMaxLevel;
  mapping(Building => BuildingRequirement) public buildingRequirement;

  enum Building{NONE, TOWN_HALL, HEADQUARTERS, BARRACKS, CLAY_PIT, FOREST_CAMP, STONE_MINE, STOREHOUSE, SMITHY, FARM, HIDDEN_STASH, WALL, MARKET}

  struct BuildingUpgrade {
    Building building;
    uint256 finishTimestamp;
  }

  struct BuildingRequirement {
    Building building;
    uint256 level;
  }

  event Staked(address indexed user, uint256 indexed id);
  event Unstaked(address indexed user, uint256 indexed id);
  event BuildingUpgraded(uint256 indexed id, Building indexed building, uint256 level);

  function initialize(address cbkLandAddress) public initializer {
    __AccessControl_init_unchained();
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(GAME_ADMIN, msg.sender);

    cbkLand = CBKLandInterface(cbkLandAddress);
  }

  modifier restricted() {
    _restricted();
    _;
  }

  function _restricted() internal view {
    require(hasRole(GAME_ADMIN, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "NA");
  }

  modifier assertOwnsLand(address user, uint id) {
    _assertOwnsLand(user, id);
    _;
  }

  function _assertOwnsLand(address user, uint id) internal view {
    require(cbkLand.ownerOf(id) == user, 'Not land owner');
  }

  modifier assertStakesLand(address user) {
    _assertStakesLand(user);
    _;
  }

  function _assertStakesLand(address user) internal view {
    require(stakedLand[user] != 0, 'You do not stake land');
  }

  function onERC721Received(address, address, uint256, bytes calldata) pure external override returns (bytes4) {
    return IERC721ReceiverUpgradeable.onERC721Received.selector;
  }

  function stake(uint id) public assertOwnsLand(tx.origin, id) {
    require(stakedTo[msg.sender] == 0, 'You have already staked land');
    require(stakedLand[msg.sender] == 0, 'You already have a land staked');
    stakedLand[msg.sender] = id;
    stakedFrom[msg.sender] = block.timestamp;
    cbkLand.safeTransferFrom(msg.sender, address(this), id);
    emit Staked(msg.sender, id);
  }

  function unstake() public assertStakesLand(tx.origin) {
    uint landId = stakedLand[tx.origin];
    stakedLand[msg.sender] = 0;
    stakedTo[msg.sender] = block.timestamp;
    cbkLand.safeTransferFrom(address(this), tx.origin, landId);
    emit Unstaked(msg.sender, landId);
  }

  function setCurrentlyUpgrading(uint id, Building building, uint finishTimestamp) external restricted assertStakesLand(tx.origin) {
    BuildingUpgrade memory buildingUpgrade = currentlyUpgrading[id];
    if (buildingUpgrade.building != Building.NONE) {
      finishBuildingUpgrade(id);
    }
    if (building != Building.NONE) {
      require(getBuildingLevel(id, building) < buildingMaxLevel[building], 'Building is already at max level');
      BuildingRequirement memory requirement = buildingRequirement[building];
      require(getBuildingLevel(id, requirement.building) >= requirement.level, 'Required building is not at required level');
    }
    currentlyUpgrading[id] = BuildingUpgrade(building, finishTimestamp);
  }

  function finishBuildingUpgrade(uint id) public {
    BuildingUpgrade memory buildingUpgrade = currentlyUpgrading[id];
    require(buildingUpgrade.building != Building.NONE, 'No upgrade in progress');
    require(buildingUpgrade.finishTimestamp < block.timestamp, 'Upgrade not yet finished');
    buildings[id][buildingUpgrade.building] += 1;
    emit BuildingUpgraded(id, buildingUpgrade.building, buildings[id][buildingUpgrade.building]);
    currentlyUpgrading[id] = BuildingUpgrade(Building.NONE, 0);
  }

  // SETTERS

  function setBuildingMaxLevel(Building building, uint level) external restricted {
    buildingMaxLevel[building] = level;
  }

  function setBuildingRequirement(Building building, Building requirement, uint level) external restricted {
    buildingRequirement[building] = BuildingRequirement(requirement, level);
  }

  // VIEWS

  function getBuildingLevel(uint id, Building building) public view returns (uint256) {
    BuildingUpgrade memory buildingUpgrade = currentlyUpgrading[id];
    if (buildingUpgrade.building == building && buildingUpgrade.finishTimestamp < block.timestamp) {
      return buildings[id][Building(building)] + 1;
    }
    return buildings[id][Building(building)];
  }

  function canUpgradeBuilding(uint id, Building building) public view returns (bool) {
    BuildingRequirement memory requirement = buildingRequirement[building];
    return getBuildingLevel(id, building) < buildingMaxLevel[building] && getBuildingLevel(id, requirement.building) >= requirement.level;
  }

}