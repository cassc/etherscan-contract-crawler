//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {IIndividualVesting} from "./interfaces/IIndividualVesting.sol";

contract IndividualVesting is IIndividualVesting, Initializable {
  uint256 private constant BONE = 1e18;

  /// @dev - Thursday, May 6, 2021
  uint256 public constant distributionStart = 1620293249;

  /// @dev - 270 days converted to seconds
  uint256 public constant teamCliff = 270 days;

  /// @dev - start of the team vesting allocation, Monday, January 31, 2022
  uint256 public constant vestingStartTS = distributionStart + teamCliff;

  /// @dev - 720 days converted to seconds
  uint256 public constant vestingPeriod = 720 days;

  /// @dev - 10%
  uint256 public constant initialUnlockPercent = BONE / 10;

  /// @dev - Team's multisig address
  address public constant fundingWalletAddress = address(0xeAAb5ec0F9DC67D9e2810C02117ABb33537A68d8);

  /// @dev - OIL token address
  address public constant tokenAddress = address(0x0275E1001e293C46CFe158B3702AADe0B99f88a5);

  /// @dev - Address to receive tokens
  address public receiverAddress;

  /// @dev - The total amount of tokens Granted to the team member
  uint256 public grantedAmount;

  /// @dev - How many tokens the team member already received via this contract & directly
  uint256 public withdrawnAmount;

  /// @dev marks the implementation 'initialized' (doesn't affect proxies)
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function initialize(
    address _receiverAddress,
    uint256 _grantedAmount,
    uint256 _withdrawnAmount
  ) external initializer {
    receiverAddress = _receiverAddress;
    grantedAmount = _grantedAmount;
    withdrawnAmount = _withdrawnAmount;
  }

  /// @notice How many tokens are already unlocked at current timestamp
  function unlockedAmount() public view returns (uint256) {
    // The Default Vesting scheme is as follows:
    // 10% is immediately unlocked at vestingStartTS (31 Jan) and the rest 90% is vested over the next 720 days (2 years)
    uint256 initialUnlockAmount = (grantedAmount * initialUnlockPercent) / BONE;

    // Calculate how much of the remaining 90% is already vested to date and how much is unlocked total
    uint256 vestedAmount = ((grantedAmount - initialUnlockAmount) * (block.timestamp - vestingStartTS)) / vestingPeriod;
    uint256 totalUnlockedAmount = initialUnlockAmount + vestedAmount;

    // total unlocked can't be more than granted (protection for >720 days)
    if (totalUnlockedAmount > grantedAmount) totalUnlockedAmount = grantedAmount;

    return totalUnlockedAmount;
  }

  /// @notice withdraw unlocked tokens
  /// @dev Anyone can call this - funds will be sent to receiverAddress anyways
  function withdraw() public {
    // Subtract what was already withdrawn
    uint256 withdrawableAmount = unlockedAmount() - withdrawnAmount;

    withdrawnAmount += withdrawableAmount;

    // Try to pull tokens from TeamWallet (should have approval + should have tokens)
    // If not enough tokens on TeamWallet - probably a makeInstallment() call is required to pull more tokens from Distribution
    require(
      IERC20(tokenAddress).transferFrom(fundingWalletAddress, receiverAddress, withdrawableAmount),
      "Transfer failed, try calling makeInstallment(2) at Distribution 0x5A3E535C93558bD89287Aa4ef3752FD726517673"
    );
  }
}