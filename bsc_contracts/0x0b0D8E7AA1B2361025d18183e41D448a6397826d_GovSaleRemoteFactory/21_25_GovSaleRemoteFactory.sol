// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

import "../utils/AdminProxyManager.sol";
import "../interfaces/IGovFactory.sol";
import "../interfaces/IGovSaleRemote.sol";

contract GovSaleRemoteFactory is
  Initializable,
  UUPSUpgradeable,
  PausableUpgradeable,
  OwnableUpgradeable,
  AdminProxyManager,
  IGovFactory
{
  // d2 = 2 decimal
  uint256 public override gasForDestinationLzReceive;
  uint128 public override operationalPercentage_d2;
  uint128 public override marketingPercentage_d2;
  uint128 public override treasuryPercentage_d2;
  uint128 public override crossFee_d2;

  address[] public override allProjects; // all projects created
  address[] public override allPayments; // all payment Token accepted

  address public override beacon;
  address public override savior; // KOM address to spend left tokens
  address public override keeper;
  address public override saleGateway; // dst sale gateway

  address public override operational; // operational address
  address public override marketing; // marketing address
  address public override treasury; // treasury address

  mapping(address => uint256) public override getPaymentIndex;
  mapping(address => bool) public override isKnown;

  function init(
    address _beacon,
    address _savior,
    address _keeper,
    address _saleGateway, // sale gateway
    address _operational,
    address _marketing,
    address _treasury,
    uint256 _gasForDestinationLzReceive
  ) external initializer proxied {
    __UUPSUpgradeable_init();
    __Ownable_init();
    __Pausable_init();
    __AdminProxyManager_init(_msgSender());

    require(
      _beacon != address(0) &&
        _savior != address(0) &&
        _keeper != address(0) &&
        _saleGateway != address(0) &&
        _operational != address(0) &&
        _marketing != address(0) &&
        _treasury != address(0) &&
        _gasForDestinationLzReceive > 0,
      "bad"
    );

    beacon = _beacon;
    savior = _savior;
    keeper = _keeper;
    saleGateway = _saleGateway;
    operational = _operational;
    marketing = _marketing;
    treasury = _treasury;

    operationalPercentage_d2 = 4000;
    marketingPercentage_d2 = 3000;
    treasuryPercentage_d2 = 3000;
    gasForDestinationLzReceive = _gasForDestinationLzReceive;
  }

  function _authorizeUpgrade(address newImplementation) internal virtual override proxied {}

  /**
   * @dev Get total number of projects created
   */
  function allProjectsLength() external view virtual override returns (uint256) {
    return allProjects.length;
  }

  /**
   * @dev Get total number of payment Toked accepted
   */
  function allPaymentsLength() external view virtual override returns (uint256) {
    return allPayments.length;
  }

  /**
   * @dev Create new project for raise fund
   * @param _start Epoch date to start round 1
   * @param _duration Duration per booster (in seconds)
   * @param _sale Amount token project to sell (based on token decimals of project)
   * @param _price Token project price in payment decimal
   * @param _fee_d2 Fee project percent in each rounds in 2 decimal
   * @param _payment Tokens to raise
   * @param _targetSale Target sale on destination chain
   */
  function createProject(
    uint128 _start,
    uint128 _duration,
    uint128 _sale,
    uint128 _price,
    uint128[4] calldata _fee_d2,
    address _payment,
    address _targetSale
  ) external virtual onlyOwner whenNotPaused returns (address project) {
    require(_payment != address(0) && _payment == allPayments[getPaymentIndex[_payment]], "bad");

    bytes memory data = abi.encodeWithSelector(
      IGovSaleRemote.init.selector,
      _start,
      _duration,
      _sale,
      _price,
      _fee_d2,
      _payment,
      _targetSale
    );

    project = address(new BeaconProxy(beacon, data));

    allProjects.push(project);
    isKnown[project] = true;

    emit ProjectCreated(project, allProjects.length - 1);
  }

  /**
   * @dev Set new token to be accepted
   * @param _token New token address
   */
  function setPayment(address _token) external virtual override onlyOwner {
    require(_token != address(0), "bad");
    if (allPayments.length > 0) require(_token != allPayments[getPaymentIndex[_token]], "existed");

    allPayments.push(_token);
    getPaymentIndex[_token] = allPayments.length - 1;
  }

  /**
   * @dev Remove token as payment
   * @param _token Token address
   */
  function removePayment(address _token) external virtual override onlyOwner {
    require(_token != address(0), "bad");
    require(_token == allPayments[getPaymentIndex[_token]], "!found");

    uint256 indexToDelete = getPaymentIndex[_token];
    address addressToMove = allPayments[allPayments.length - 1];

    allPayments[indexToDelete] = addressToMove;
    getPaymentIndex[addressToMove] = indexToDelete;

    allPayments.pop();
    delete getPaymentIndex[_token];
  }

  /**
   * @dev Set gas for destination layerZero receive
   * @param _gasForDestinationLzReceive Sale implementation address
   */
  function setGasForDestinationLzReceive(uint256 _gasForDestinationLzReceive) external virtual override onlyOwner {
    require(_gasForDestinationLzReceive > 0 && gasForDestinationLzReceive != _gasForDestinationLzReceive, "bad");

    gasForDestinationLzReceive = _gasForDestinationLzReceive;
  }

  /**
   * @dev Config Factory addresses
   * @param _saleGateway Sale gateway address
   * @param _savior Savior address
   * @param _keeper Keeper address
   * @param _operational Operational address
   * @param _marketing Marketing address
   * @param _treasury Treasury address
   */
  function config(
    address _beacon,
    address _saleGateway,
    address _savior,
    address _keeper,
    address _operational,
    address _marketing,
    address _treasury
  ) external virtual override onlyOwner {
    require(
      _beacon != address(0) &&
        _saleGateway != address(0) &&
        _savior != address(0) &&
        _keeper != address(0) &&
        _operational != address(0) &&
        _marketing != address(0) &&
        _treasury != address(0),
      "bad"
    );

    beacon = _beacon;
    saleGateway = _saleGateway;
    savior = _savior;
    keeper = _keeper;
    operational = _operational;
    marketing = _marketing;
    treasury = _treasury;
  }

  /**
   * @dev Config Factory percentage
   * @param _operationalPercentage Operational percentage in 2 decimal
   * @param _marketingPercentage Marketing percentage in 2 decimal
   * @param _treasuryPercentage Treasury percentage in 2 decimal
   */
  function setPercentage_d2(
    uint128 _crossFee,
    uint128 _operationalPercentage,
    uint128 _marketingPercentage,
    uint128 _treasuryPercentage
  ) external virtual onlyOwner {
    require(_operationalPercentage + _marketingPercentage + _treasuryPercentage == 10000, "bad");
    crossFee_d2 = _crossFee;
    operationalPercentage_d2 = _operationalPercentage;
    marketingPercentage_d2 = _marketingPercentage;
    treasuryPercentage_d2 = _treasuryPercentage;
  }

  function togglePause() external virtual onlyOwner {
    if (paused()) {
      _unpause();
    } else {
      _pause();
    }
  }
}