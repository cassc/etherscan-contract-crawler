// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract MonwuMarketingVesting is Ownable {

  ERC20 public monwuToken;

  address public constant marketingAddress = 0xBC24fD879A441Cb5eC0c900aB704437F1cA5a4D6;

  uint256 public allocation;
  uint256 public tokensReleased;

  uint256 public start;
  uint256 public vestingEnd;
  uint256 public constant releaseDuration = 52 weeks;
  uint256 public constant numberOfUnlocks = 2;

  event MarketingReleaseTokens(uint256 indexed amount);

  constructor(address monwuTokenAddress) {
    start = block.timestamp;
    vestingEnd = start + releaseDuration;

    monwuToken = ERC20(monwuTokenAddress);
    allocation = 50_000_000 * (10 ** monwuToken.decimals());

    transferOwnership(marketingAddress);
  }


  // ____________________________________________________________________________________
  //                               OWNER INTERFACE
  // ====================================================================================

  function releaseTokens(uint256 amount) external onlyOwner {

    uint256 releasableAmount = computeReleasableAmount();

    require (releasableAmount >= amount, "Can't withdraw more than is released");
    require((tokensReleased + amount) <= allocation, "Can't withdraw more than allocation");

    tokensReleased += amount;

    monwuToken.transfer(marketingAddress, amount);

    emit MarketingReleaseTokens(amount);
  }



  // ____________________________________________________________________________________
  //                                     HELPERS
  // ====================================================================================

  function computeReleasableAmount() internal view returns(uint256) {

    uint256 releasableAmount;
    uint256 totalReleasableTokens;

    if(block.timestamp < vestingEnd) {
      totalReleasableTokens = allocation / numberOfUnlocks;
    } else {
      totalReleasableTokens = allocation;
    }

    releasableAmount = totalReleasableTokens - tokensReleased;

    return releasableAmount;
  }
}