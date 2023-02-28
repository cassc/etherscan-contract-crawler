// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IUniswap.sol";
import "./IAggregator.sol";

abstract contract Secure {
  // PACKED {
  bool public LOCKED;
  bool public INTEREST_MODE;
  uint16 public HUNDRED_PERCENT = 1000;
  uint16 public REF_REWARD_PERCENT = 50;
  uint48 public FEE;
  address public ADMIN;
  // }

  // PACKED {
  uint32 public MONTHLY_PERCENT = 1200;
  uint32 public MONTHLY_TIME = 30 days;
  uint32 public MONTHLY_HOURS = MONTHLY_TIME / 1 hours;
  address public OWNER;
  // }

  uint8[4] public PERCENT_STEPS = [25, 30, 35, 40];

  uint64[4] public INVEST_STEPS = [
    20_00000000,
    2500_00000000,
    5000_00000000,
    10000_00000000
  ];

  // PACKED {
  bool public TOKEN_MODE;
  uint88 public TOKEN_MODE_FEE = 0.5 ether;
  address public TOKEN_ADDRESS = 0x5b08969db7f8d6e3b353E2BdA9E8E41E76fE3dbB;
  // }

  IUniswap public TOKEN_PAIR = IUniswap(0x066B6bA67f512F808Ea15aF32E14CF95260d7058);

  bytes4 private constant BALANCE = bytes4(keccak256("balanceOf(address)"));

  bytes4 private constant TRANSFER = bytes4(keccak256("transfer(address,uint256)"));

  bytes4 private constant TRANSFER_FROM =
    bytes4(keccak256("transferFrom(address,address,uint256)"));

  IAggregator constant BNB_USD = IAggregator(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);

  constructor(address admin) {
    OWNER = _msgSender();
    ADMIN = admin;
  }

  modifier onlyOwner() {
    require(_msgSender() == OWNER, "OWN");
    _;
  }

  modifier onlyOwnerOrAdmin() {
    require(_msgSender() == OWNER || _msgSender() == ADMIN, "OWN");
    _;
  }

  modifier secured() {
    require(!LOCKED, "LOK");
    LOCKED = true;
    _;
    LOCKED = false;
  }

  modifier notInterestMode() {
    require(!INTEREST_MODE, "INT");
    _;
  }

  // External functions
  function changeToken(address newToken) external onlyOwner {
    TOKEN_ADDRESS = newToken;
  }

  function changeTokenPair(address newTokenPair) external onlyOwner {
    TOKEN_PAIR = IUniswap(newTokenPair);
  }

  function lock() external onlyOwner {
    LOCKED = true;
  }

  function unlock() external onlyOwner {
    LOCKED = false;
  }

  function changeInterestMode(bool interestMode) external onlyOwner {
    INTEREST_MODE = interestMode;
  }

  function changeFee(uint48 fee) external onlyOwner {
    FEE = fee;
  }

  function changeHundredPercent(uint16 percent) external onlyOwner {
    HUNDRED_PERCENT = percent;
  }

  function changeRefRewardPercent(uint16 percent) external onlyOwner {
    REF_REWARD_PERCENT = percent;
  }

  function changeMonthlyPercent(uint32 percent) external onlyOwner {
    MONTHLY_PERCENT = percent;
  }

  function changeMonthlyTimes(uint32 time) external onlyOwner {
    MONTHLY_TIME = time;
    MONTHLY_HOURS = time / 1 hours;
  }

  function changeTokenModeFee(uint88 fee) external onlyOwner {
    TOKEN_MODE_FEE = fee;
  }

  function changeTokenMode(bool tokenMode) external onlyOwner {
    TOKEN_MODE = tokenMode;
  }

  function changeUpgrades(
    uint8 index,
    uint64 amount,
    uint8 percent
  ) external onlyOwner {
    INVEST_STEPS[index] = amount;
    PERCENT_STEPS[index] = percent;
  }

  function changeOwner(address newOwner) external onlyOwner {
    OWNER = newOwner;
  }

  function changeAdmin(address newAdmin) external onlyOwner {
    ADMIN = newAdmin;
  }

  function withdrawBNB(uint256 value) external onlyOwner {
    payable(OWNER).transfer(value);
  }

  function withdrawBNBAdmin(uint256 value) external onlyOwnerOrAdmin {
    payable(ADMIN).transfer(value);
  }

  function withdrawToken(uint256 value) external onlyOwner {
    _safeTransferToken(OWNER, value);
  }

  // Internal functions
  function _msgSender() internal view returns (address) {
    return msg.sender;
  }

  function _TokenBalance(address user) internal view returns (uint256) {
    (, bytes memory data) = TOKEN_ADDRESS.staticcall(
      abi.encodeWithSelector(BALANCE, user)
    );

    return abi.decode(data, (uint256));
  }

  function _safeDepositToken(address from, uint256 value) internal {
    (bool success, bytes memory data) = TOKEN_ADDRESS.call(
      abi.encodeWithSelector(TRANSFER_FROM, from, address(this), value)
    );

    require(success && (data.length == 0 || abi.decode(data, (bool))), "ERC");
  }

  function _safeTransferToken(address to, uint256 value) internal {
    (bool success, bytes memory data) = TOKEN_ADDRESS.call(
      abi.encodeWithSelector(TRANSFER, to, value)
    );

    require(success && (data.length == 0 || abi.decode(data, (bool))), "ERC");
  }

  function _safeTransferBNB(address to, uint256 value) internal {
    (bool success, ) = to.call{gas: 23000, value: value}("");

    require(success, "ETH");
  }
}