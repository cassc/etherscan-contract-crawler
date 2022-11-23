// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./PausableByOwner.sol";
import "./interfaces/IBoostingService.sol";
import "./RecoverableByOwner.sol";

contract BoostingMigrator is Context, PausableByOwner, RecoverableByOwner {

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
    address fromAddress;
    address toAddress;
    uint128 unstakeSignedShares;
    uint256 deadline;
    uint8 unstakeV;
    bytes32 unstakeR;
    bytes32 unstakeS;
  }

  IERC20 constant nmxToken = IERC20(0xd32d01A43c869EdcD1117C640fBDcfCFD97d9d65);
  mapping (address => bool) public isAllowedDestination;

  function addAllowedAddresses(address[] calldata allowedAddresses) external onlyOwner {
    for (uint256 i = 0; i < allowedAddresses.length; i++) {
      SafeERC20.safeApprove(nmxToken, address(allowedAddresses[i]), 2**256 - 1);
      isAllowedDestination[address(allowedAddresses[i])] = true;
      emit AddressAllowed(allowedAddresses[i]);
    }
  }

  function removeAllowedAddresses(address[] calldata allowedAddresses) external onlyOwner  {
    for (uint256 i = 0; i < allowedAddresses.length; i++) {
      SafeERC20.safeApprove(nmxToken, address(allowedAddresses[i]), 0);
      isAllowedDestination[address(allowedAddresses[i])] = false;
      emit AddressRemoved(allowedAddresses[i]);
    }
  }

  function migrate(MigratePayload calldata payload) external whenNotPaused {
    require(isAllowedDestination[payload.toAddress], "BoostingMigrator: INVALID_MIGRATION_ADDRESS");

    uint128 unstaked = IBoostingService(payload.fromAddress).unstakeSharesWithAuthorization(
      _msgSender(),
      payload.unstakeSignedShares,
      payload.unstakeSignedShares,
      payload.deadline,
      payload.unstakeV,
      payload.unstakeR,
      payload.unstakeS
    );

    uint128 staked = IBoostingService(payload.toAddress).stakeFor(_msgSender(), unstaked);

    emit Migrate(_msgSender(), unstaked, 0, 0, staked, 0, 0);
  }

}