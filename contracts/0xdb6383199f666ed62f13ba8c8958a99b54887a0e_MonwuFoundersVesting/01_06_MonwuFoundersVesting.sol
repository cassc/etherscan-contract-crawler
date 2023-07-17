// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MonwuFoundersVesting is Ownable {

  ERC20 public monwuToken;
  
  address public constant founders = 0x76bAf177d89B124Fd331764d48faf5bc6849A442;

  uint256 public foundersAllocation;
  uint256 public foundersTokensReleased; 

  uint256 public constant cliffDuration = 52 weeks;
  uint256 public constant vestingDuration = 52 weeks;
  uint256 public constant releaseDuration = 91 days;
  uint8 public constant numberOfUnlocks = 5;

  uint256 public start;
  uint256 public cliffEnd;
  uint256 public vestingEnd;

  event FoundersReleaseTokens(uint256 indexed amount);

  constructor(address monwuTokenAddress) {
    start = block.timestamp;
    cliffEnd = start + cliffDuration;
    vestingEnd = cliffEnd + vestingDuration;

    monwuToken = ERC20(monwuTokenAddress);
    foundersAllocation = 100_000_000 * (10 ** monwuToken.decimals());

    transferOwnership(founders);
  }


  // ====================================================================================
  //                                FOUNDERS INTERFACE
  // ====================================================================================

  function foundersRelease(uint256 amount) external onlyOwner {

    uint256 releasableAmount = computeReleasableAmount();
    require(releasableAmount >= amount, "Can't withdraw more than is released");

    foundersTokensReleased += amount;
    monwuToken.transfer(founders, amount);

    emit FoundersReleaseTokens(amount);
  }
  // ====================================================================================




  // ====================================================================================
  //                                     HELPERS
  // ====================================================================================

  function computeReleasableAmount() internal view returns(uint256) {

    uint256 releasableAmount;
    uint256 totalReleasedTokens;

    // if cliff duration didn't end yet, releasable amount is zero.
    if(block.timestamp < cliffEnd) return 0;

    // if cliff and vesting ended, rest tokens are claimable
    if(block.timestamp >= vestingEnd) return foundersAllocation - foundersTokensReleased;

    totalReleasedTokens = (((block.timestamp - cliffEnd) / releaseDuration) + 1) * (foundersAllocation / numberOfUnlocks);
    releasableAmount = totalReleasedTokens - foundersTokensReleased;

    return releasableAmount;
  }
}