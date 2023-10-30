// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;

import {ERC20, ERC4626, xERC4626} from "../../lib/xERC4626.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title ssgETH - Vault token for staked sgETH. ERC20 + ERC4626
/// @author @ChimeraDefi - sharedstake.org - based on sfrxETH
/// @notice Is a vault that takes sgETH and gives you ssgETH erc20 tokens
/** @dev Exchange rate between sgETH and ssgETH floats, you can convert your ssgETH for more sgETH over time.
    Exchange rate increases as validator rewardSplitter mints new sgETH corresponding to the staking yield and drops it into this vault (ssgETH contract).
    There is a short time period, “cycles” which the exchange rate increases linearly over. This is to prevent gaming the exchange rate (MEV).
    The cycles are constant length, but calling syncRewards slightly into a would-be cycle keeps the same would-be endpoint (so cycle ends are every X seconds).
    Someone must call syncRewards, which queues any new ssgETH in the contract to be added to the redeemable amount.
    Mint vs Deposit
    mint() - deposit targeting a specific number of ssgETH out
    deposit() - deposit knowing a specific number of ssgETH in */
contract WSGETH is xERC4626, ReentrancyGuard {
  modifier andSync() {
    if (block.timestamp >= rewardsCycleEnd) {
      syncRewards();
    }
    _;
  }

  /* ========== CONSTRUCTOR ========== */
  constructor(
    ERC20 _underlying,
    uint32 _rewardsCycleLength
  ) ERC4626(_underlying, "Wrapped SharedStake Governed Ether", "wsgETH") xERC4626(_rewardsCycleLength) {} // solhint-disable-line

  /// @notice Approve and deposit() in one transaction
  function depositWithSignature(
    uint256 assets,
    address receiver,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external nonReentrant returns (uint256 shares) {
    uint256 amount = approveMax ? type(uint256).max : assets;
    asset.permit(msg.sender, address(this), amount, deadline, v, r, s);
    return (deposit(assets, receiver));
  }

  /// @notice inlines syncRewards with deposits when able
  function deposit(uint256 assets, address receiver) public override nonReentrant andSync returns (uint256 shares) {
    return super.deposit(assets, receiver);
  }

  /// @notice inlines syncRewards with mints when able
  function mint(uint256 shares, address receiver) public override nonReentrant andSync returns (uint256 assets) {
    return super.mint(shares, receiver);
  }

  /// @notice inlines syncRewards with withdrawals when able
  function withdraw(
    uint256 assets,
    address receiver,
    address owner
  ) public override nonReentrant andSync returns (uint256 shares) {
    return super.withdraw(assets, receiver, owner);
  }

  /// @notice inlines syncRewards with redemptions when able
  function redeem(uint256 shares, address receiver, address owner) public override andSync returns (uint256 assets) {
    return super.redeem(shares, receiver, owner);
  }

  /// @notice How much sgETH is 1E18 ssgETH worth. Price is in ETH, not USD
  function pricePerShare() public view returns (uint256) {
    return convertToAssets(1e18);
  }
}