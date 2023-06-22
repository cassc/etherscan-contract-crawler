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

import "contracts/external/chainalysis/ISanctionsList.sol";

/**
 * @title ISanctionsListClient
 * @author Ondo Finance
 * @notice The client interface for sanctions contract.
 */
interface ISanctionsListClient {
  /// @notice Returns reference to the sanctions list that this client queries
  function sanctionsList() external view returns (ISanctionsList);

  /// @notice Sets the sanctions list reference
  function setSanctionsList(address sanctionsList) external;

  /// @notice Error for when caller attempts to set the `sanctionsList`
  ///         reference to the zero address
  error SanctionsListZeroAddress();

  /// @notice Error for when caller attempts to perform an action on a
  ///         sanctioned account
  error SanctionedAccount();

  /**
   * @dev Event for when the sanctions list reference is set
   *
   * @param oldSanctionsList The old list
   * @param newSanctionsList The new list
   */
  event SanctionsListSet(address oldSanctionsList, address newSanctionsList);
}