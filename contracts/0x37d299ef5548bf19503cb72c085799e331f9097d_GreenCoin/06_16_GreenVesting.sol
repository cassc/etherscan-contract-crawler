//SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GreenVesting is ReentrancyGuard, Ownable {
  using SafeERC20 for IERC20;
  using SafeMath for uint;

  uint256 public constant COMPANY_SHARE = 40;
  uint256 public constant COMMUNITY_SHARE = 60;
  uint256 public constant COMMUNITY_VESTING = 8;
  uint256 public constant SECONDS_IN_YEAR = 365.255 * 24 * 60 * 60;
  
  bool private _releasedFirst;
  uint256 public communityAmount;
  uint256 public communityAmountPerYear;
  uint256 public currentCommunityAmount;
  uint256 public companyAmount;
  uint256 public vestingStartTime;
  uint256 public lastReleaseDate;
  uint256 public releasedYearsCount;

  address public token;

  event Released(address communityAddress, uint256 amount);
  event SentToCompany(address company, uint256 amount);

  constructor(address _tokenAddress, uint256 _amount, address owner) {
    token = _tokenAddress;
    communityAmount = _amount.mul(COMMUNITY_SHARE).div(100);
    communityAmountPerYear = communityAmount.div(COMMUNITY_VESTING);
    companyAmount = _amount.mul(COMPANY_SHARE).div(100);
    
    vestingStartTime = block.timestamp;
    lastReleaseDate = vestingStartTime.sub(vestingStartTime.mod(SECONDS_IN_YEAR));
    transferOwnership(owner);
  }

  function _getCurrentYear() private view returns (uint256 currentYear) {
    currentYear = block.timestamp.sub(block.timestamp.mod(SECONDS_IN_YEAR));
  }

  function _getYearsPassed() private view returns (uint256 yearsPassed) {
    uint256 yearsPassedTotal = _getCurrentYear().sub(lastReleaseDate.sub(vestingStartTime.mod(SECONDS_IN_YEAR))).div(SECONDS_IN_YEAR);
    yearsPassed = Math.max(Math.min(yearsPassedTotal, COMMUNITY_VESTING), 1);
  }

  function getReleasableAmount() public view returns (uint256 _amount) {
    uint256 currentDate = _getCurrentYear();
    uint256 yearsPassed = _getYearsPassed();
    _amount = currentCommunityAmount;

    if((lastReleaseDate.add(SECONDS_IN_YEAR) <= currentDate && releasedYearsCount < COMMUNITY_VESTING) || lastReleaseDate < vestingStartTime) {
      _amount = _amount.add(
        communityAmountPerYear.mul(
          yearsPassed
        )
      );
    }
  }

  function release(address communityAddress, uint256 _amount) public onlyOwner nonReentrant {
    uint256 currentDate = _getCurrentYear();
    uint256 yearsPassed = _getYearsPassed();
    
    if(releasedYearsCount < COMMUNITY_VESTING) {
      if(lastReleaseDate.add(SECONDS_IN_YEAR) <= currentDate || !_releasedFirst) {
        lastReleaseDate = currentDate;

        currentCommunityAmount = currentCommunityAmount.add(
          communityAmountPerYear.mul(
            yearsPassed
          )
        );
        communityAmount = communityAmount.sub(
          communityAmountPerYear.mul(
            yearsPassed
          )
        );

        releasedYearsCount = releasedYearsCount.add(yearsPassed);
        _releasedFirst = true;
      }
    }
    require(_amount <= currentCommunityAmount, "Not enough tokens allocated");
    currentCommunityAmount = currentCommunityAmount.sub(_amount);
    IERC20(token).safeTransfer(communityAddress, _amount);
    emit Released(communityAddress, _amount);
  }

  function sendToCompany(address _company, uint256 _amount) public onlyOwner nonReentrant {
    require(companyAmount >= _amount, "Not enough tokens.");

    companyAmount = companyAmount.sub(_amount);
    bool success = IERC20(token).transfer(_company, _amount);
    require(success, "Transfer failed.");
    emit SentToCompany(_company, _amount);
  }
}