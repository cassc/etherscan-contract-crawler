// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITheVault {
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
  event Harvested(
    address indexed token,
    uint256 amount,
    uint256 indexed blockNumber,
    uint256 timestamp
  );
  event PauseDeposits(address indexed pausedBy);
  event Paused(address account);
  event SetGuardian(address indexed newGuardian);
  event SetGuestList(address indexed newGuestList);
  event SetManagementFee(uint256 newManagementFee);
  event SetMaxManagementFee(uint256 newMaxManagementFee);
  event SetMaxPerformanceFee(uint256 newMaxPerformanceFee);
  event SetMaxWithdrawalFee(uint256 newMaxWithdrawalFee);
  event SetPerformanceFeeGovernance(uint256 newPerformanceFeeGovernance);
  event SetPerformanceFeeStrategist(uint256 newPerformanceFeeStrategist);
  event SetStrategy(address indexed newStrategy);
  event SetToEarnBps(uint256 newEarnToBps);
  event SetTreasury(address indexed newTreasury);
  event SetWithdrawalFee(uint256 newWithdrawalFee);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event TreeDistribution(
    address indexed token,
    uint256 amount,
    uint256 indexed blockNumber,
    uint256 timestamp
  );
  event UnpauseDeposits(address indexed pausedBy);
  event Unpaused(address account);

  function MANAGEMENT_FEE_HARD_CAP() external view returns (uint256);

  function MAX_BPS() external view returns (uint256);

  function PERFORMANCE_FEE_HARD_CAP() external view returns (uint256);

  function SECS_PER_YEAR() external view returns (uint256);

  function WITHDRAWAL_FEE_HARD_CAP() external view returns (uint256);

  function additionalTokensEarned(address) external view returns (uint256);

  function allowance(address owner, address spender)
  external
  view
  returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function assetsAtLastHarvest() external view returns (uint256);

  function available() external view returns (uint256);

  function badgerTree() external view returns (address);

  function balance() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function decimals() external view returns (uint8);

  function decreaseAllowance(address spender, uint256 subtractedValue)
  external
  returns (bool);

  function deposit(uint256 _amount, bytes32[] memory proof) external;

  function deposit(uint256 _amount) external;

  function depositAll(bytes32[] memory proof) external;

  function depositAll() external;

  function depositFor(address _recipient, uint256 _amount) external;

  function depositFor(
    address _recipient,
    uint256 _amount,
    bytes32[] memory proof
  ) external;

  function earn() external;

  function emitNonProtectedToken(address _token) external;

  function getPricePerFullShare() external view returns (uint256);

  function governance() external view returns (address);

  function guardian() external view returns (address);

  function guestList() external view returns (address);

  function increaseAllowance(address spender, uint256 addedValue)
  external
  returns (bool);

  function initialize(
    address _token,
    address _governance,
    address _keeper,
    address _guardian,
    address _treasury,
    address _strategist,
    address _badgerTree,
    string memory _name,
    string memory _symbol,
    uint256[4] memory _feeConfig
  ) external;

  function keeper() external view returns (address);

  function lastAdditionalTokenAmount(address) external view returns (uint256);

  function lastHarvestAmount() external view returns (uint256);

  function lastHarvestedAt() external view returns (uint256);

  function lifeTimeEarned() external view returns (uint256);

  function managementFee() external view returns (uint256);

  function maxManagementFee() external view returns (uint256);

  function maxPerformanceFee() external view returns (uint256);

  function maxWithdrawalFee() external view returns (uint256);

  function name() external view returns (string memory);

  function pause() external;

  function pauseDeposits() external;

  function paused() external view returns (bool);

  function pausedDeposit() external view returns (bool);

  function performanceFeeGovernance() external view returns (uint256);

  function performanceFeeStrategist() external view returns (uint256);

  function reportAdditionalToken(address _token) external;

  function reportHarvest(uint256 _harvestedAmount) external;

  function setGovernance(address _governance) external;

  function setGuardian(address _guardian) external;

  function setGuestList(address _guestList) external;

  function setKeeper(address _keeper) external;

  function setManagementFee(uint256 _fees) external;

  function setMaxManagementFee(uint256 _fees) external;

  function setMaxPerformanceFee(uint256 _fees) external;

  function setMaxWithdrawalFee(uint256 _fees) external;

  function setPerformanceFeeGovernance(uint256 _performanceFeeGovernance)
  external;

  function setPerformanceFeeStrategist(uint256 _performanceFeeStrategist)
  external;

  function setStrategist(address _strategist) external;

  function setStrategy(address _strategy) external;

  function setToEarnBps(uint256 _newToEarnBps) external;

  function setTreasury(address _treasury) external;

  function setWithdrawalFee(uint256 _withdrawalFee) external;

  function strategist() external view returns (address);

  function strategy() external view returns (address);

  function sweepExtraToken(address _token) external;

  function symbol() external view returns (string memory);

  function toEarnBps() external view returns (uint256);

  function token() external view returns (address);

  function totalSupply() external view returns (uint256);

  function transfer(address recipient, uint256 amount)
  external
  returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  function treasury() external view returns (address);

  function unpause() external;

  function unpauseDeposits() external;

  function version() external pure returns (string memory);

  function withdraw(uint256 _shares) external;

  function withdrawAll() external;

  function withdrawToVault() external;

  function withdrawalFee() external view returns (uint256);
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"spender","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"token","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"},{"indexed":true,"internalType":"uint256","name":"blockNumber","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"timestamp","type":"uint256"}],"name":"Harvested","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"pausedBy","type":"address"}],"name":"PauseDeposits","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"account","type":"address"}],"name":"Paused","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"newGuardian","type":"address"}],"name":"SetGuardian","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"newGuestList","type":"address"}],"name":"SetGuestList","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"newManagementFee","type":"uint256"}],"name":"SetManagementFee","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"newMaxManagementFee","type":"uint256"}],"name":"SetMaxManagementFee","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"newMaxPerformanceFee","type":"uint256"}],"name":"SetMaxPerformanceFee","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"newMaxWithdrawalFee","type":"uint256"}],"name":"SetMaxWithdrawalFee","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"newPerformanceFeeGovernance","type":"uint256"}],"name":"SetPerformanceFeeGovernance","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"newPerformanceFeeStrategist","type":"uint256"}],"name":"SetPerformanceFeeStrategist","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"newStrategy","type":"address"}],"name":"SetStrategy","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"newEarnToBps","type":"uint256"}],"name":"SetToEarnBps","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"newTreasury","type":"address"}],"name":"SetTreasury","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"newWithdrawalFee","type":"uint256"}],"name":"SetWithdrawalFee","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"token","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"},{"indexed":true,"internalType":"uint256","name":"blockNumber","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"timestamp","type":"uint256"}],"name":"TreeDistribution","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"pausedBy","type":"address"}],"name":"UnpauseDeposits","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"account","type":"address"}],"name":"Unpaused","type":"event"},{"inputs":[],"name":"MANAGEMENT_FEE_HARD_CAP","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"MAX_BPS","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"PERFORMANCE_FEE_HARD_CAP","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"SECS_PER_YEAR","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"WITHDRAWAL_FEE_HARD_CAP","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"additionalTokensEarned","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"assetsAtLastHarvest","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"available","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"badgerTree","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"balance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"subtractedValue","type":"uint256"}],"name":"decreaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_amount","type":"uint256"},{"internalType":"bytes32[]","name":"proof","type":"bytes32[]"}],"name":"deposit","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"deposit","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32[]","name":"proof","type":"bytes32[]"}],"name":"depositAll","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"depositAll","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_recipient","type":"address"},{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"depositFor","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_recipient","type":"address"},{"internalType":"uint256","name":"_amount","type":"uint256"},{"internalType":"bytes32[]","name":"proof","type":"bytes32[]"}],"name":"depositFor","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"earn","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_token","type":"address"}],"name":"emitNonProtectedToken","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"getPricePerFullShare","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"governance","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"guardian","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"guestList","outputs":[{"internalType":"contract BadgerGuestListAPI","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"addedValue","type":"uint256"}],"name":"increaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_token","type":"address"},{"internalType":"address","name":"_governance","type":"address"},{"internalType":"address","name":"_keeper","type":"address"},{"internalType":"address","name":"_guardian","type":"address"},{"internalType":"address","name":"_treasury","type":"address"},{"internalType":"address","name":"_strategist","type":"address"},{"internalType":"address","name":"_badgerTree","type":"address"},{"internalType":"string","name":"_name","type":"string"},{"internalType":"string","name":"_symbol","type":"string"},{"internalType":"uint256[4]","name":"_feeConfig","type":"uint256[4]"}],"name":"initialize","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"keeper","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"lastAdditionalTokenAmount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"lastHarvestAmount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"lastHarvestedAt","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"lifeTimeEarned","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"managementFee","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"maxManagementFee","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"maxPerformanceFee","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"maxWithdrawalFee","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"pause","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"pauseDeposits","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"paused","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"pausedDeposit","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"performanceFeeGovernance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"performanceFeeStrategist","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_token","type":"address"}],"name":"reportAdditionalToken","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_harvestedAmount","type":"uint256"}],"name":"reportHarvest","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_governance","type":"address"}],"name":"setGovernance","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_guardian","type":"address"}],"name":"setGuardian","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_guestList","type":"address"}],"name":"setGuestList","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_keeper","type":"address"}],"name":"setKeeper","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_fees","type":"uint256"}],"name":"setManagementFee","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_fees","type":"uint256"}],"name":"setMaxManagementFee","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_fees","type":"uint256"}],"name":"setMaxPerformanceFee","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_fees","type":"uint256"}],"name":"setMaxWithdrawalFee","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_performanceFeeGovernance","type":"uint256"}],"name":"setPerformanceFeeGovernance","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_performanceFeeStrategist","type":"uint256"}],"name":"setPerformanceFeeStrategist","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_strategist","type":"address"}],"name":"setStrategist","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_strategy","type":"address"}],"name":"setStrategy","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_newToEarnBps","type":"uint256"}],"name":"setToEarnBps","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_treasury","type":"address"}],"name":"setTreasury","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_withdrawalFee","type":"uint256"}],"name":"setWithdrawalFee","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"strategist","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"strategy","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_token","type":"address"}],"name":"sweepExtraToken","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"toEarnBps","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"token","outputs":[{"internalType":"contract IERC20Upgradeable","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transfer","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"sender","type":"address"},{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transferFrom","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"treasury","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"unpause","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"unpauseDeposits","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"version","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_shares","type":"uint256"}],"name":"withdraw","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"withdrawAll","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"withdrawToVault","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"withdrawalFee","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"}]
*/