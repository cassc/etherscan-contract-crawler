// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

import './Controller.sol';
import './Lottery.sol';
import './Token.sol';


contract LotteryICO is Ownable, ReentrancyGuard, Pausable {
  using Address for address payable;
  using EnumerableMap for EnumerableMap.AddressToUintMap;

  LotteryToken public immutable token;
  Lottery public immutable lottery;
  LotteryController public immutable controller;

  // Absolute shares of the raised funds to distribute to each developer address.
  EnumerableMap.AddressToUintMap private _developerShares;

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
      uint256 initialPrice)
  {
    token = _token;
    lottery = _lottery;
    controller = _controller;
    price = initialPrice;
  }

  function tokensForSale() public view returns (uint256) {
    return token.allowance(owner(), address(this));
  }

  function getDevelopers() public view returns (address[] memory) {
    uint length = _developerShares.length();
    address[] memory developers = new address[](length);
    for (uint i = 0; i < length; i++) {
      (developers[i], ) = _developerShares.at(i);
    }
    return developers;
  }

  function getDeveloperShare(address developer) public view returns (uint) {
    return _developerShares.get(developer);
  }

  function setDeveloperShare(address developer, uint share) public onlyOwner returns (bool) {
    return _developerShares.set(developer, share);
  }

  function removeDeveloper(address developer) public onlyOwner returns (bool) {
    return _developerShares.remove(developer);
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

  function buy() public payable whenNotPaused nonReentrant {
    uint256 tokens = convertEtherToToken(msg.value);
    require(tokens <= token.allowance(owner(), address(this)), 'insufficient ELOT balance');
    balance[msg.sender] += tokens;
    token.transferFrom(owner(), address(this), tokens);
  }

  function close() public onlyOwner nonReentrant {
    require(_open, 'invalid state');
    _open = false;
    uint numDevelopers = _developerShares.length();
    uint totalShares = 0;
    for (uint i = 0; i < numDevelopers; i++) {
      (, uint share) = _developerShares.at(i);
      totalShares += share;
    }
    if (totalShares > 0) {
      uint256 funds = address(this).balance;
      for (uint i = 0; i < numDevelopers; i++) {
        (address developer, uint share) = _developerShares.at(i);
        payable(developer).sendValue(funds * developerShare * share / (10000 * totalShares));
      }
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