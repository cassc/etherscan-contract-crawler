/**SPDX-License-Identifier: BUSL-1.1

      ▄▄█████████▄
   ╓██▀└ ,╓▄▄▄, '▀██▄
  ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,
 ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,
██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌
██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██
╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀
 ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`
  ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬
   ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀
      ╙▀▀██████R⌐

 */

pragma solidity 0.8.16;

import "contracts/RWAHub.sol";
import "contracts/interfaces/IRWAHubOffChainRedemptions.sol";

abstract contract RWAHubOffChainRedemptions is
  RWAHub,
  IRWAHubOffChainRedemptions
{
  // To enable and disable off chain redemptions
  bool public offChainRedemptionPaused;

  // Minimum off chain redemption amount
  uint256 public minimumOffChainRedemptionAmount;

  constructor(
    address _collateral,
    address _rwa,
    address managerAdmin,
    address pauser,
    address _assetSender,
    address _feeRecipient,
    uint256 _minimumDepositAmount,
    uint256 _minimumRedemptionAmount
  )
    RWAHub(
      _collateral,
      _rwa,
      managerAdmin,
      pauser,
      _assetSender,
      _feeRecipient,
      _minimumDepositAmount,
      _minimumRedemptionAmount
    )
  {
    // Default to the same minimum redemption amount as for On-Chain
    // redemptions.
    minimumOffChainRedemptionAmount = _minimumRedemptionAmount;
  }

  /**
   * @notice Request a redemption to be serviced off chain.
   *
   * @param amountRWATokenToRedeem The requested redemption amount
   * @param offChainDestination    A hash of the destination to which
   *                               the request should be serviced to.
   */
  function requestRedemptionServicedOffchain(
    uint256 amountRWATokenToRedeem,
    bytes32 offChainDestination
  ) external nonReentrant ifNotPaused(offChainRedemptionPaused) {
    if (amountRWATokenToRedeem < minimumOffChainRedemptionAmount) {
      revert RedemptionTooSmall();
    }

    bytes32 redemptionId = bytes32(redemptionRequestCounter++);

    rwa.burnFrom(msg.sender, amountRWATokenToRedeem);

    emit RedemptionRequestedServicedOffChain(
      msg.sender,
      redemptionId,
      amountRWATokenToRedeem,
      offChainDestination
    );
  }

  /**
   * @notice Function to pause off chain redemptoins
   */
  function pauseOffChainRedemption() external onlyRole(PAUSER_ADMIN) {
    offChainRedemptionPaused = true;
    emit OffChainRedemptionPaused(msg.sender);
  }

  /**
   * @notice Function to unpause off chain redemptoins
   */
  function unpauseOffChainRedemption() external onlyRole(MANAGER_ADMIN) {
    offChainRedemptionPaused = false;
    emit OffChainRedemptionUnpaused(msg.sender);
  }

  /**
   * @notice Admin Function to set the minimum off chain redemption amount
   *
   * @param _minimumOffChainRedemptionAmount The new minimum off chain
   *                                         redemption amount
   */
  function setOffChainRedemptionMinimum(
    uint256 _minimumOffChainRedemptionAmount
  ) external onlyRole(MANAGER_ADMIN) {
    uint256 oldMinimum = minimumOffChainRedemptionAmount;
    minimumOffChainRedemptionAmount = _minimumOffChainRedemptionAmount;
    emit OffChainRedemptionMinimumSet(
      oldMinimum,
      _minimumOffChainRedemptionAmount
    );
  }
}