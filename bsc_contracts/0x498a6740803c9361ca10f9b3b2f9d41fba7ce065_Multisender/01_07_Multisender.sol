// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

import "./libraries/TransferHelper.sol";

contract Multisender is OwnableUpgradeable {
  using SafeMathUpgradeable for uint256;

  uint256 public constant MATCH_POOL_BPS = 6000;
  uint256 public constant LOTTERY_POOL_BPS = 500;
  uint256 public constant MARKETING_BPS = 2500;
  uint256 public constant REFERRAL_BPS = 1000;

  address public matchPoolAddress;
  address public lotteryPoolAddress;
  address public marketingAddress;
  address public referralAddress;

  function initialize(
    address _matchPoolAddress,
    address _lotteryPoolAddress,
    address _marketingAddress,
    address _referralAddress
  ) external initializer {
    OwnableUpgradeable.__Ownable_init();

    matchPoolAddress = _matchPoolAddress;
    lotteryPoolAddress = _lotteryPoolAddress;
    marketingAddress = _marketingAddress;
    referralAddress = _referralAddress;
  }

  receive() external payable {
    TransferHelper.safeTransferETH(matchPoolAddress, msg.value.mul(MATCH_POOL_BPS).div(10_000));
    TransferHelper.safeTransferETH(lotteryPoolAddress, msg.value.mul(LOTTERY_POOL_BPS).div(10_000));
    TransferHelper.safeTransferETH(marketingAddress, msg.value.mul(MARKETING_BPS).div(10_000));
    TransferHelper.safeTransferETH(referralAddress, msg.value.mul(REFERRAL_BPS).div(10_000));
  }

  function updateMatchPoolAddress(address _matchPoolAddress) external onlyOwner {
    matchPoolAddress = _matchPoolAddress;
  }

  function updateLotteryPoolAddress(address _lotteryPoolAddress) external onlyOwner {
    lotteryPoolAddress = _lotteryPoolAddress;
  }

  function updateMarketingAddress(address _marketingAddress) external onlyOwner {
    marketingAddress = _marketingAddress;
  }

  function updateReferralAddress(address _referralAddress) external onlyOwner {
    referralAddress = _referralAddress;
  }
}