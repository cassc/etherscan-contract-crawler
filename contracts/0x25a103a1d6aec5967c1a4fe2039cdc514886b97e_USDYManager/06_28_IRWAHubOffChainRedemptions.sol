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

interface IRWAHubOffChainRedemptions {
  function requestRedemptionServicedOffchain(
    uint256 amountRWATokenToRedeem,
    bytes32 offChainDestination
  ) external;

  function pauseOffChainRedemption() external;

  function unpauseOffChainRedemption() external;

  function setOffChainRedemptionMinimum(uint256 minimumAmount) external;

  /**
   * @notice Event emitted when redemption request is submitted
   *
   * @param user                The user submitting the offchain redemption request
   * @param redemptionId        The id corresponding to a given offchain redemption request
   * @param rwaTokenAmountIn    The amount of cash being burned
   * @param offChainDestination Hash of destination to which the request
   *                            should be serviced to
   */
  event RedemptionRequestedServicedOffChain(
    address indexed user,
    bytes32 indexed redemptionId,
    uint256 rwaTokenAmountIn,
    bytes32 offChainDestination
  );

  /**
   * @notice Event emitted when the off chain redemption feature is
   *         paused
   *
   * @param caller Address which initiated the pause
   */
  event OffChainRedemptionPaused(address caller);

  /**
   * @notice Event emitted when the off chain redemption feature is
   *         unpaused
   *
   * @param caller Address which initiated the unpause
   */
  event OffChainRedemptionUnpaused(address caller);

  /**
   * @notice Event emitted when the off chain redemption minimum is
   *         updated
   *
   * @param oldMinimum the old minimum redemption amount
   * @param newMinimum the new minimum redemption amount
   */
  event OffChainRedemptionMinimumSet(uint256 oldMinimum, uint256 newMinimum);
}