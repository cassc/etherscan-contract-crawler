// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.7.0;

import './MUSDMock.sol';
import '../utils/StableMath.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@nomiclabs/buidler/console.sol';

contract SavingsContractMock {
  using SafeMath for uint256;
  using StableMath for uint256;

  // Amount of underlying savings in the contract
  uint256 public totalSavings;
  // Total number of savings credits issued
  uint256 public totalCredits;

  uint256 public exchangeRate = 1e18;

  MUSDMock reserve;

  mapping(address => uint256) public creditBalances;

  constructor(address _reserve) public {
    reserve = MUSDMock(_reserve);
  }

  function depositInterest(uint256 amount) external {
    require(reserve.transferFrom(msg.sender, address(this), amount), 'Must receive tokens');
    totalSavings = totalSavings.add(amount);

    if (totalCredits > 0) {
      // new exchange rate is relationship between totalCredits & totalSavings
      // totalCredits * exchangeRate = totalSavings
      // exchangeRate = totalSavings/totalCredits
      // e.g. (100e18 * 1e18) / 100e18 = 1e18
      // e.g. (101e20 * 1e18) / 100e20 = 1.01e18
      exchangeRate = totalSavings.divPrecisely(totalCredits);
    }
  }

  function depositSavings(uint256 amount) external returns (uint256 creditsIssued) {
    require(amount > 0, 'Must deposit something');

    require(reserve.transferFrom(msg.sender, address(this), amount), 'Must receive tokens');
    totalSavings = totalSavings.add(amount);

    creditsIssued = _massetToCredit(amount);
    totalCredits = totalCredits.add(creditsIssued);

    // add credits to balances
    creditBalances[msg.sender] = creditBalances[msg.sender].add(creditsIssued);
  }

  function redeem(uint256 credits) external returns (uint256 massetReturned) {
    require(credits > 0, 'Must withdraw something');

    uint256 saverCredits = creditBalances[msg.sender];
    require(saverCredits >= credits, 'Saver has no credits');

    creditBalances[msg.sender] = saverCredits.sub(credits);
    totalCredits = totalCredits.sub(credits);

    // Calc payout based on currentRatio
    massetReturned = _creditToMasset(credits);
    totalSavings = totalSavings.sub(massetReturned);

    require(reserve.transfer(msg.sender, massetReturned), 'Must send asset');
  }

  function _massetToCredit(uint256 _amount) internal view returns (uint256 credits) {
    // e.g. (1e20 * 1e18) / 1e18 = 1e20
    // e.g. (1e20 * 1e18) / 14e17 = 7.1429e19
    credits = _amount.divPrecisely(exchangeRate);
  }

  function _creditToMasset(uint256 _credits) internal view returns (uint256 massetAmount) {
    // e.g. (1e20 * 1e18) / 1e18 = 1e20
    // e.g. (1e20 * 14e17) / 1e18 = 1.4e20
    massetAmount = _credits.mulTruncate(exchangeRate);
  }
}