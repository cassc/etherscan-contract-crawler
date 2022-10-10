// SPDX-License-Identifier: BUSL-1.1-COPYCAT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IWETH.sol";
import "./CopycatLeader.sol";
import "./interfaces/ICopycatAdapter.sol";
import "./interfaces/ICopycatPlugin.sol";
import "./interfaces/ICopycatEmergencyAllower.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CopycatLeaderStorage is Ownable, ReentrancyGuard {
  event FeeCollected(address indexed leaderContract, address indexed from, uint256 amount);
  event NewDeposit(address indexed leaderContract, uint256 indexed level, address indexed depositer, uint256 amount);
  event NewWithdraw(address indexed leaderContract, uint256 indexed level, address indexed withdrawer, uint256 amount);

  address public leaderFactoryAddress = address(0);

  struct LeaderInfo {
    uint256 leaderId;
    uint256 totalDeposit;
    uint256 totalWithdraw;
    // bool isUnsafe;

    uint256 depositCopycatFee;
    uint256 depositPercentageFee;

    string tokenName;
    string tokenSymbol;
    string description;
    string avatar;
    uint256 level;

    string leaderType;
  }

  struct TradingRoute {
    address router;
    address[] tradingRouteBuy;
    address[] tradingRouteSell;
    bool enabled;
  }

  mapping(address => TradingRoute) public tradingRoute;
  mapping(address => address) public factory2router;
  mapping(address => bool) public tokenAllowed;

  IERC20 immutable public copycatToken;
  IWETH immutable public WETH;

  mapping(address => LeaderInfo) private leaderInfo;
  mapping(uint256 => address) public leaderIdMap;
  mapping(address => bool) public registeredPluginFactory;
  mapping(address => uint256) public excludeFromFee;
  mapping(address => bool) public contractWhitelist;
  mapping(address => bool) public copygameContract;
  mapping(address => bool) public pairManager;

  uint256 public nextLeaderId = 1;

  uint256[6] public FEE_LIST = [200 ether, 2000 ether, 100000 ether, 1 ether, 0.3 ether, 0.001 ether];

  address public feeAddress;
  address public adminAddress;

  modifier onlyAdmin {
    require(msg.sender == adminAddress, "OA");
    _;
  }

  modifier onlyPairManager {
    require(pairManager[msg.sender], "OP");
    _;
  }

  mapping(address => ICopycatPlugin[]) public plugins;
  mapping(address => ICopycatAdapter[]) public adapters;
  mapping(address => mapping(ICopycatPlugin => uint256)) public pluginsIdMap;
  mapping(address => mapping(ICopycatPlugin => bool)) public pluginsEnMap;
  mapping(address => mapping(ICopycatAdapter => IERC20)) public adaptersToken;
  mapping(address => mapping(IERC20 => ICopycatAdapter[])) public tokenAdapters;

  function getLeaderInfo(address leader) external view returns(LeaderInfo memory) {
    return leaderInfo[leader];
  }

  function getPlugins(address leader) external view returns(ICopycatPlugin[] memory) {
    return plugins[leader];
  }

  function getAdapters(address leader) external view returns(ICopycatAdapter[] memory) {
    return adapters[leader];
  }

  function getAdaptersSpecificType(address leader, string memory leaderType) external view returns(ICopycatAdapter[] memory) {
    ICopycatAdapter[] memory result = adapters[leader];
    for (uint i = 0; i < result.length; i++) {
      if (keccak256(abi.encodePacked(result[i].pluginType())) != keccak256(abi.encodePacked(leaderType))) {
        result[i] = ICopycatAdapter(address(0));
      }
    }
    return result;
  }

  function getTokenAdapters(address leader, IERC20 token) external view returns(ICopycatAdapter[] memory) {
    return tokenAdapters[leader][token];
  }

  // Add existing initialized plugin to this leader
  event AddPlugin(address adder, address indexed leader, address indexed token, address indexed plugin);
  function addPlugin(CopycatLeader leader, address token, ICopycatPlugin plugin) nonReentrant public {
    if (registeredPluginFactory[address(plugin)]) {
      require(msg.sender == owner() && token == address(0), "F");
    } else {
      require(registeredPluginFactory[msg.sender], "F");
      require(plugin.leaderContract() == leader, "WC");
      require(plugin.leaderAddress() == leader.owner(), "WL");
    }

    uint256 pluginId = plugins[address(leader)].length;
    
    plugins[address(leader)].push(plugin);

    pluginsIdMap[address(leader)][plugin] = pluginId;
    pluginsEnMap[address(leader)][plugin] = true;

    if (token != address(0)) {
      ICopycatAdapter adapter = ICopycatAdapter(address(plugin));
      adapters[address(leader)].push(adapter);
      adaptersToken[address(leader)][adapter] = IERC20(token);
      tokenAdapters[address(leader)][IERC20(token)].push(adapter);
    }

    emit AddPlugin(msg.sender, address(leader), token, address(plugin));
  }

  // !!! Don't forget to reset allowance after disabled plugin !!! (Disable, Enable Plugin)
  event ModifyPlugin(address indexed caller, uint256 indexed adpterId, bool enabled, address plugin);
  function modifyPlugin(CopycatLeader leader, uint256 pluginId, bool enabled) external nonReentrant {
    ICopycatPlugin plugin = plugins[address(leader)][pluginId];

    require(leader.factory().isAllowEmergency(ICopycatEmergencyAllower(msg.sender)) || plugin.balance() == 0, "F");

    pluginsEnMap[address(leader)][plugin] = enabled;

    emit ModifyPlugin(msg.sender, pluginId, enabled, address(plugin));
  }

  constructor(
    IERC20 _copycatToken,
    IWETH _WETH
  ) {
    copycatToken = _copycatToken;
    WETH = _WETH;
    feeAddress = msg.sender;
    adminAddress = msg.sender;
    pairManager[msg.sender] = true;
  }

  event SetPair(address indexed tradingToken, address indexed router, bool enabled);
  function setPair(
    address _router,
    address _tradingToken,
    address[] memory _tradingRouteBuy,
    address[] memory _tradingRouteSell,
    bool _enabled
  ) public onlyPairManager {
    require(
      _tradingRouteBuy[0] == IUniswapV2Router02(_router).WETH() && 
      _tradingRouteBuy[_tradingRouteBuy.length - 1] == _tradingToken && 
      _tradingRouteSell[0] == _tradingToken &&
      _tradingRouteSell[_tradingRouteSell.length - 1] == IUniswapV2Router02(_router).WETH()
    , "V");

    factory2router[IUniswapV2Router02(_router).factory()] = _router;

    tradingRoute[_tradingToken] = TradingRoute({
      router: _router,
      tradingRouteBuy: _tradingRouteBuy,
      tradingRouteSell: _tradingRouteSell,
      enabled: _enabled
    });

    tokenAllowed[_tradingToken] = _enabled;

    emit SetPair(_tradingToken, _router, _enabled);
  }

  event SetTokenAllowed(address indexed caller, address indexed token, bool allowed);
  function setTokenAllowed(address token, bool allowed) external onlyPairManager {
    tokenAllowed[token] = allowed;
    emit SetTokenAllowed(msg.sender, token, allowed);
  }

  function getTradingRouteRouter(address _tradingToken) external view returns(address) {
    return tradingRoute[_tradingToken].router;
  }

  function getTradingRouteBuy(address _tradingToken) external view returns(address[] memory) {
    return tradingRoute[_tradingToken].tradingRouteBuy;
  }

  function getTradingRouteSell(address _tradingToken) external view returns(address[] memory) {
    return tradingRoute[_tradingToken].tradingRouteSell;
  }

  function getTradingRouteEnabled(address _tradingToken) external view returns(bool) {
    return tradingRoute[_tradingToken].enabled;
  }

  function setLeaderFactoryAddress(address _address) public {
    require(leaderFactoryAddress == address(0), "F");
    leaderFactoryAddress = _address;
  }

  function COPYCAT_FEE_BASE() public view returns(uint256) {
    return FEE_LIST[3];
  }

  event SetFee(address indexed setter, uint256 index, uint256 oldFee, uint256 newFee);
  function setFee(uint256 newFee, uint256 index) public onlyOwner {
    emit SetFee(msg.sender, index, FEE_LIST[index], newFee);
    FEE_LIST[index] = newFee;
  }

  /*event SetDeployFeeEnablePercentage(address indexed setter, uint256 oldFee, uint256 newFee);
  function setDeployFeeEnablePercentage(uint256 newFee) public onlyOwner {
    // emit SetDeployFeeEnablePercentage(msg.sender, DEPLOY_FEE_ENABLE_PERCENTAGE, newFee);
    DEPLOY_FEE_ENABLE_PERCENTAGE = newFee;
  }*/

  event SetFeeAddress(address indexed setter, address oldAddress, address newAddress);
  function setFeeAddress(address newAddress) public onlyOwner {
    emit SetFeeAddress(msg.sender, feeAddress, newAddress);
    feeAddress = newAddress;
  }

  event SetAdminAddress(address indexed setter, address oldAddress, address newAddress);
  function setAdminAddress(address newAddress) public onlyOwner {
    emit SetAdminAddress(msg.sender, adminAddress, newAddress);
    adminAddress = newAddress;
  }

  event SetRegisteredPluginFactory(address indexed setter, address indexed factoryAddress, bool enabled);
  function setRegisteredPluginFactory(address factoryAddress, bool enabled) public onlyOwner {
    registeredPluginFactory[factoryAddress] = enabled;
    emit SetRegisteredPluginFactory(msg.sender, factoryAddress, enabled);
  }

  event SetContractWhitelist(address indexed setter, address indexed contractAddr, bool enabled);
  function setContractWhitelist(address contractAddr, bool enabled) public {
    require(msg.sender == owner() || registeredPluginFactory[msg.sender], "F");
    contractWhitelist[contractAddr] = enabled;
    emit SetContractWhitelist(msg.sender, contractAddr, enabled);
  }

  event SetCopygameContract(address indexed setter, address indexed contractAddr, bool enabled);
  function setCopygameContract(address contractAddr, bool enabled) public {
    require(msg.sender == owner() || registeredPluginFactory[msg.sender], "F");
    copygameContract[contractAddr] = enabled;
    emit SetCopygameContract(msg.sender, contractAddr, enabled);
  }

  event SetPairManager(address indexed setter, address indexed contractAddr, bool enabled);
  function setPairManager(address contractAddr, bool enabled) public onlyAdmin {
    pairManager[contractAddr] = enabled;
    emit SetPairManager(msg.sender, contractAddr, enabled);
  }

  event SetExcludeFromFee(address indexed setter, address indexed walletAddress, uint256 level);
  function setExcludeFromFee(address walletAddress, uint256 level) public {
    require(msg.sender == adminAddress || msg.sender == leaderFactoryAddress, "F");
    excludeFromFee[walletAddress] = level;
    emit SetExcludeFromFee(msg.sender, walletAddress, level);
  }

  function emitDeposit(address depositer, uint256 amount) public {
    require(leaderInfo[msg.sender].leaderId > 0, "NR");
    leaderInfo[msg.sender].totalDeposit += amount;
    emit NewDeposit(msg.sender, leaderInfo[msg.sender].level, depositer, amount);
  }

  function emitWithdraw(address withdrawer, uint256 amount) public {
    require(leaderInfo[msg.sender].leaderId > 0, "NR");
    leaderInfo[msg.sender].totalWithdraw += amount;
    emit NewWithdraw(msg.sender, leaderInfo[msg.sender].level, withdrawer, amount);
  }

  function collectDeployFee(address from, uint256 amount) external {
    require(msg.sender == leaderFactoryAddress, "F");
    copycatToken.transferFrom(from, feeAddress, amount);
    emit FeeCollected(address(this), from, amount);
  }

  function collectLeaderFee(address from, uint256 amount) public {
    require(leaderInfo[msg.sender].leaderId > 0, "NR");
    uint256 half = amount * 6 / 10;
    copycatToken.transferFrom(from, CopycatLeader(payable(msg.sender)).owner(), half);
    copycatToken.transferFrom(from, feeAddress, amount - half);
    emit FeeCollected(address(this), from, amount);
  }

  function initLeader(
    address leaderContract, 
    address leader,

    uint256 _depositCopycatFee,
    uint256 _depositPercentageFee,
    uint256 _level,
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _description,
    string memory _avatar,
    string memory _leaderType
  ) external {
    require(msg.sender == leaderFactoryAddress, "F");
    require(_depositPercentageFee < 1 ether, "P");

    // Register leader to factory
    leaderInfo[leaderContract] = LeaderInfo({
      leaderId: nextLeaderId,
      totalDeposit: 0,
      totalWithdraw: 0,

      depositCopycatFee: _depositCopycatFee,
      depositPercentageFee: _depositPercentageFee,

      tokenName: _tokenName,
      tokenSymbol: _tokenSymbol,
      description: _description,
      avatar: _avatar,
      level: _level,

      leaderType: _leaderType
    });

    leaderIdMap[nextLeaderId] = leaderContract;
    excludeFromFee[leader] = 0;
    nextLeaderId++;
  }

  event UpdateLeaderInfo(
    address indexed updater,
    uint256 _depositCopycatFee,
    uint256 _depositPercentageFee,
    uint256 _level
  );
  function updateLeaderInfo(
    address leaderContract,
    uint256 _depositCopycatFee,
    uint256 _depositPercentageFee,
    uint256 _level,
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _description,
    string memory _avatar
  ) external {
    require(leaderInfo[leaderContract].leaderId > 0 && (msg.sender == Ownable(leaderContract).owner() || msg.sender == adminAddress), "F");
    require(_level < 3, "L");
    require(_depositPercentageFee < 1 ether, "P");

    LeaderInfo storage info = leaderInfo[leaderContract];

    if (_level == info.level) {
      collectLeaderFee(msg.sender, FEE_LIST[0]);
    } else {
      collectLeaderFee(msg.sender, FEE_LIST[_level]);
    }

    leaderInfo[leaderContract] = LeaderInfo({
      leaderId: info.leaderId,
      totalDeposit: info.totalDeposit,
      totalWithdraw: info.totalWithdraw,

      depositCopycatFee: _depositCopycatFee,
      depositPercentageFee: _depositPercentageFee,

      tokenName: _tokenName,
      tokenSymbol: _tokenSymbol,
      description: _description,
      avatar: _avatar,
      level: _level,

      leaderType: info.leaderType
    });

    emit UpdateLeaderInfo(msg.sender, _depositCopycatFee, _depositPercentageFee, _level);
  }

  event AdminSetLevel(address indexed setter, uint256 levelBefore, uint256 level);
  function adminSetLevel(address leaderContract, uint256 _level) public {
    require(leaderInfo[leaderContract].leaderId > 0 && msg.sender == adminAddress, "F");
    emit AdminSetLevel(msg.sender, leaderInfo[leaderContract].level, _level);
    leaderInfo[leaderContract].level = _level;
  }

  function getLeaderName(address leaderContract) public view returns(string memory) {
    return leaderInfo[leaderContract].tokenName;
  }

  function getLeaderSymbol(address leaderContract) public view returns(string memory) {
    return leaderInfo[leaderContract].tokenSymbol;
  }

  function getLeaderType(address leaderContract) public view returns(string memory) {
    return leaderInfo[leaderContract].leaderType;
  }

  function getLeaderId(address leaderContract) public view returns(uint256) {
    return leaderInfo[leaderContract].leaderId;
  }

  function getLeaderDepositCopycatFee(address leaderContract) public view returns(uint256) {
    return leaderInfo[leaderContract].depositCopycatFee * COPYCAT_FEE_BASE() / 1e18;
  }

  function getLeaderDepositPercentageFee(address leaderContract) public view returns(uint256) {
    return leaderInfo[leaderContract].depositPercentageFee;
  }
 
}