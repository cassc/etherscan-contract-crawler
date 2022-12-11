// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Address.sol';

import './Controller.sol';
import './Lottery.sol';
import './Token.sol';


contract LotteryICO is Ownable, ReentrancyGuard, Pausable {
  using Address for address payable;

  LotteryToken public immutable token;
  Lottery public immutable lottery;
  LotteryController public immutable controller;
  address[] public developers;

  // Price of 1 ELOT in wei.
  uint256 public price;

  // How much of the raised funds will be transferred to the developer addresses at closure (the
  // rest will be transferred to the lottery). This number is a percentage with 2 decimal places
  // represented as an integer without the decimal point; or, equivalently, a fraction between 0 and
  // 1 multiplied by 10000 and rounded. For example, 4000 is 40%, 1234 is 12.34%, and 10000 is 100%.
  uint16 public developerShare = 0;

  // Whether the ELOT sale is open.
  bool private _open = false;

  // ELOT balance for every buyer.
  mapping (address => uint256) public balance;

  constructor(
      LotteryToken _token,
      Lottery _lottery,
      LotteryController _controller,
      address[] memory _developers,
      uint256 initialPrice)
  {
    token = _token;
    lottery = _lottery;
    controller = _controller;
    developers = _developers;
    require(developers.length > 0, 'there must be at least 1 developer address');
    price = initialPrice;
  }

  function open(uint256 newPrice, uint16 newDeveloperShare) public onlyOwner {
    price = newPrice;
    developerShare = newDeveloperShare;
    _open = true;
  }

  function isOpen() public view returns (bool) {
    return _open;
  }

  function convertEtherToToken(uint256 etherAmount) public view returns (uint256) {
    require(_open, 'invalid state');
    return etherAmount * 1e18 / price;
  }

  function buy() public payable whenNotPaused {
    uint256 tokens = convertEtherToToken(msg.value);
    require(tokens <= token.allowance(owner(), address(this)), 'insufficient ELOT balance');
    token.transferFrom(owner(), address(this), tokens);
    balance[msg.sender] += tokens;
  }

  function close() public onlyOwner nonReentrant {
    require(_open, 'invalid state');
    _open = false;
    uint256 funds = address(this).balance;
    for (uint i = 0; i < developers.length; i++) {
      payable(developers[i]).sendValue(funds * developerShare / (developers.length * 10000));
    }
    payable(lottery).sendValue(address(this).balance);
  }

  function claim() public nonReentrant whenNotPaused {
    require(!_open, 'the ICO is still open');
    uint256 tokens = balance[msg.sender];
    require(tokens > 0, 'no ELOT to claim');
    balance[msg.sender] = 0;
    token.transfer(msg.sender, tokens);
  }

  function sendRevenueBackToLottery() public onlyOwner nonReentrant {
    uint256 revenue = controller.getUnclaimedRevenue(address(this));
    if (revenue > 0) {
      controller.withdraw(payable(address(this)));
      payable(lottery).sendValue(revenue);
    }
  }
}