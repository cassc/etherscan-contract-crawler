// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./PausableByOwner.sol";
import "./interfaces/IStakingService.sol";
import "./interfaces/IBoostingService.sol";
import "./RecoverableByOwner.sol";

contract LaunchPoolMigrator is Context, PausableByOwner, RecoverableByOwner {

  event Migrate(
    address owner,
    uint256 unstakedAmount,
    uint256 amount0,
    uint256 amount1,
    uint256 stakedAmount,
    uint256 amount0Pooled,
    uint256 amount1Pooled
  );

  event AddressAllowed(address allowedAddress);
  event AddressRemoved(address removedAddress);

  struct MigratePayload {
    address migrationAddress;
    uint128 unstakeSignedAmount;
    uint256 deadline;
    uint8 unstakeV;
    bytes32 unstakeR;
    bytes32 unstakeS;
  }

  IStakingService constant _launchPoolStakingService = IStakingService(0xDbF1B10FE3e05397Cd454163F6F1eD0c1181C3B3);
  IERC20 constant _nmxToken = IERC20(0xd32d01A43c869EdcD1117C640fBDcfCFD97d9d65);

  mapping (address => bool) public isAllowedDestination;

  function addAllowedAddresses(address[] calldata allowedAddresses) external onlyOwner {
    for (uint256 i = 0; i < allowedAddresses.length; i++) {
      SafeERC20.safeApprove(_nmxToken, address(allowedAddresses[i]), 2**256 - 1);
      isAllowedDestination[address(allowedAddresses[i])] = true;
      emit AddressAllowed(allowedAddresses[i]);
    }
  }

  function removeAllowedAddresses(address[] calldata allowedAddresses) external onlyOwner  {
    for (uint256 i = 0; i < allowedAddresses.length; i++) {
      SafeERC20.safeApprove(_nmxToken, address(allowedAddresses[i]), 0);
      isAllowedDestination[address(allowedAddresses[i])] = false;
      emit AddressRemoved(allowedAddresses[i]);
    }
  }

  function migrate(MigratePayload calldata payload) external whenNotPaused {
    require(isAllowedDestination[payload.migrationAddress], "LaunchPoolMigrator: INVALID_MIGRATION_ADDRESS");

    _launchPoolStakingService.unstakeWithAuthorization(
      _msgSender(),
      payload.unstakeSignedAmount,
      payload.unstakeSignedAmount,
      payload.deadline,
      payload.unstakeV,
      payload.unstakeR,
      payload.unstakeS
    );

    uint128 staked = IBoostingService(address(payload.migrationAddress)).stakeFor(_msgSender(), payload.unstakeSignedAmount);

    emit Migrate(_msgSender(), payload.unstakeSignedAmount, 0, 0, staked, 0, 0);
  }

}