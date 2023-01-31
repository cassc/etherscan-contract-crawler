// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract KrunRaffle is Ownable {
  bool public paused;
  address private krunAddress;
  uint256 public raffleIndex;
  uint256 public KrunTicketMax;
  uint256 public EthTicketMax;

  constructor() {
    krunAddress = 0x14a47885db4AEE4b83d13e281b2013A18AA75ff4;
    paused = false;
    raffleIndex = 1;
    KrunTicketMax = 1000000000000000000000;
    EthTicketMax = 100;
  }

  // userAddress => raffleIndex => token amount //
  mapping(address => mapping(uint256 => uint256)) userKrunBalance;
  mapping(address => mapping(uint256 => uint256)) userEthBalance;

  // Events //
  event etherDepositComplete(address sender, uint256 value);
  event KrunDepositComplete(address sender, uint256 amount);
  event etherwithdrawComplete(address sender, uint256 amount);
  event KrunWithdrawalComplete(address sender, uint256 amount);

  // Views //
  function getEthBalance() public view returns (uint) {
    return address(this).balance;
  }

  function getKrunBalance() public view returns (uint) {
    return IERC20(krunAddress).balanceOf(address(this));
  }

  function getUserKrunBalance(address user) public view returns (uint) {
    return userKrunBalance[user][raffleIndex];
  }

  function getUserEthBalance(address user) public view returns (uint) {
    return userEthBalance[user][raffleIndex];
  }

  // Functions //
  function setPaused(bool _paused) external onlyOwner {
    paused = _paused;
  }

  function setRaffleIndex(uint256 _raffleIndex) external onlyOwner {
    raffleIndex = _raffleIndex;
  }

  function setKrunTicketMax(uint256 _TicketMax) external onlyOwner {
    KrunTicketMax = _TicketMax;
  }

  function setEthTicketMax(uint256 _TicketMax) external onlyOwner {
    EthTicketMax = _TicketMax;
  }

  function depositEther() public payable {
    require(paused == false, "Contract Paused");
    require(
      msg.sender.balance > msg.value,
      "Your Eth balance is less than deposit amount"
    );
    require(
      userEthBalance[msg.sender][raffleIndex] + msg.value <= EthTicketMax,
      "You have already hit ticket limit"
    );
    userEthBalance[msg.sender][raffleIndex] += msg.value;
    emit etherDepositComplete(msg.sender, msg.value);
  }

  function depositKrun(uint256 amount) public {
    require(paused == false, "Contract Paused");
    require(
      IERC20(krunAddress).balanceOf(msg.sender) >= amount,
      "Your token balance is less than deposit amount"
    );
    require(
      userKrunBalance[msg.sender][raffleIndex] + amount <= KrunTicketMax,
      "You have already hit ticket limit"
    );
    require(
      IERC20(krunAddress).transferFrom(msg.sender, address(this), amount)
    );
    userKrunBalance[msg.sender][raffleIndex] += amount;
    emit KrunDepositComplete(msg.sender, amount);
  }

  function withdrawEther() external onlyOwner {
    require(address(this).balance > 0, "Contract value is zero");
    address payable to = payable(msg.sender);
    uint256 amount = getEthBalance();
    to.transfer(getEthBalance());
    emit etherwithdrawComplete(msg.sender, amount);
  }

  function withdrawKrun() external onlyOwner {
    require(
      IERC20(krunAddress).balanceOf(address(this)) > 0,
      "Contract value is zero"
    );
    uint256 amount = getKrunBalance();
    require(
      IERC20(krunAddress).transfer(msg.sender, amount),
      "Withdraw all has failed"
    );
    emit KrunWithdrawalComplete(msg.sender, amount);
  }

  function tokenRescue(
    IERC20 token,
    address recipient,
    uint256 amount
  ) external onlyOwner {
    token.transfer(recipient, amount);
  }
}