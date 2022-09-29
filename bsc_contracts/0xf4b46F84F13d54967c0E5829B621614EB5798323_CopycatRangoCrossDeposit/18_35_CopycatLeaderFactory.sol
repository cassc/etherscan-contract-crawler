// SPDX-License-Identifier: BUSL-1.1-COPYCAT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CopycatLeader.sol";
import "./CopycatLeaderStorage.sol";
import "./lib/CopycatEmergencyMaster.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

interface CopygameLeaderInitialize {
  function initializeGame(
    address _leaderAddr, 
    address _staker, 
    IERC20 _baseToken, 
    uint256 _depositLimit
  ) external;
}

interface CopygameStakerInitialize {
  function initialize(address payable _shareToken) external;
}

contract CopycatLeaderFactory is CopycatEmergencyMaster, ReentrancyGuard {
  event NewCopycatLeaderContract(address indexed copycatLeader, address indexed leader, uint256 indexed leaderId);

  CopycatLeaderStorage public immutable S;
  IERC20 public immutable WETH;
  address public immutable copycatLeader;
  address public immutable copygameLeader;
  address public immutable copygameLeaderMirror;
  address public immutable copygameStaker;
  address public immutable dummyLeaderToken;

  constructor(CopycatLeaderStorage _S, address _copycatLeader, address _copygameLeader, address _copygameLeaderMirror, address _copygameStaker, address _dummyLeaderToken) {
    S = _S;
    WETH = S.WETH();
    copycatLeader = _copycatLeader;
    copygameLeader = _copygameLeader;
    copygameLeaderMirror = _copygameLeaderMirror;
    copygameStaker = _copygameStaker;
    dummyLeaderToken = _dummyLeaderToken;
  }

  function deployLeader(
    uint256 _depositCopycatFee,
    uint256 _depositPercentageFee,
    uint256 _level,
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _description,
    string memory _avatar
    // address payable _migrateFrom
  ) external nonReentrant payable returns(address payable copycatLeaderAddress) {
    require(_level < 3, "L");
    require(msg.value == 0.0001 ether, "IL");

    uint256 nextLeaderId = S.nextLeaderId();

    if (_level >= S.excludeFromFee(msg.sender)) {
      S.collectDeployFee(msg.sender, S.FEE_LIST(_level));
    }

    copycatLeaderAddress = payable(Clones.clone(copycatLeader));

    // if (_migrateFrom != address(0)) {
    //   CopycatLeader(_migrateFrom).migrateTo(CopycatLeader(copycatLeaderAddress));
    // }

    CopycatLeader(copycatLeaderAddress).initialize(
      msg.sender
    );

    S.initLeader(
      copycatLeaderAddress, 
      msg.sender,
      _depositCopycatFee,
      _depositPercentageFee,
      _level,
      _tokenName,
      _tokenSymbol,
      _description,
      _avatar,
      "trade"
    );

    // Burn and force initial leader share
    S.WETH().deposit{value: msg.value}();
    S.WETH().transfer(copycatLeaderAddress, 0.0001 ether);
    // S.WETH().approve(copycatLeaderAddress, msg.value);
    // CopycatLeader(copycatLeaderAddress).depositTo{value: 0}(msg.sender, msg.value * 10000, S.WETH(), msg.value);

    emit NewCopycatLeaderContract(copycatLeaderAddress, msg.sender, nextLeaderId);
  }

  function deployLeaderGame(
    uint256 _depositCopycatFee,
    uint256 _depositPercentageFee,
    uint256 _level,
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _description,
    string memory _avatar,
    IERC20 baseToken,
    uint256 depositLimit
  ) external nonReentrant payable returns(address payable copycatLeaderAddress) {
    require(_level < 3, "L");

    uint256 nextLeaderId = S.nextLeaderId();

    if (_level >= S.excludeFromFee(msg.sender) && address(baseToken) != dummyLeaderToken) {
      S.collectDeployFee(msg.sender, S.FEE_LIST(_level));
    }

    copycatLeaderAddress = payable(Clones.clone(copygameLeader));
    address copygameStakerAddress = payable(Clones.clone(copygameStaker));

    // if (_migrateFrom != address(0)) {
    //   CopycatLeader(_migrateFrom).migrateTo(CopycatLeader(copycatLeaderAddress));
    // }

    CopygameStakerInitialize(copygameStakerAddress).initialize(copycatLeaderAddress);

    CopygameLeaderInitialize(copycatLeaderAddress).initializeGame(
      msg.sender,
      copygameStakerAddress,
      baseToken,
      depositLimit
    );

    S.initLeader(
      copycatLeaderAddress, 
      msg.sender,
      _depositCopycatFee,
      _depositPercentageFee,
      _level,
      _tokenName,
      _tokenSymbol,
      _description,
      _avatar,
      "game"
    );

    // Burn and force initial leader share
    if (msg.value > 0 && baseToken == WETH) {
      S.WETH().deposit{value: msg.value}();
      S.WETH().transfer(copycatLeaderAddress, 0.0001 ether);
    } else {
      baseToken.transferFrom(msg.sender, copycatLeaderAddress, 0.0001 ether);
    }

    emit NewCopycatLeaderContract(copycatLeaderAddress, msg.sender, nextLeaderId);
  }

  function deployLeaderGameMirror(
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _description,
    string memory _avatar
  ) external nonReentrant payable returns(address payable copycatLeaderAddress) {
    uint256 nextLeaderId = S.nextLeaderId();

    copycatLeaderAddress = payable(Clones.clone(copygameLeaderMirror));
    address copygameStakerAddress = payable(Clones.clone(copygameStaker));

    // if (_migrateFrom != address(0)) {
    //   CopycatLeader(_migrateFrom).migrateTo(CopycatLeader(copycatLeaderAddress));
    // }

    CopygameStakerInitialize(copygameStakerAddress).initialize(copycatLeaderAddress);

    CopygameLeaderInitialize(copycatLeaderAddress).initializeGame(
      msg.sender,
      copygameStakerAddress,
      IERC20(dummyLeaderToken),
      0
    );

    S.initLeader(
      copycatLeaderAddress, 
      msg.sender,
      0,
      0,
      0,
      _tokenName,
      _tokenSymbol,
      _description,
      _avatar,
      "game_mirror"
    );

    // Burn and force initial leader share
    IERC20(dummyLeaderToken).transferFrom(msg.sender, copycatLeaderAddress, 0.0001 ether);

    emit NewCopycatLeaderContract(copycatLeaderAddress, msg.sender, nextLeaderId);
  }
}