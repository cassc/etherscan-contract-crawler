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

import "contracts/interfaces/IBlocklist.sol";

/**
 * @title IBlocklistClient
 * @author Ondo Finance
 * @notice The client interface for the Blocklist contract.
 */
interface IBlocklistClient {
  /// @notice Returns reference to the blocklist that this client queries
  function blocklist() external view returns (IBlocklist);

  /// @notice Sets the blocklist reference
  function setBlocklist(address registry) external;

  /// @notice Error for when caller attempts to set the blocklist reference
  ///         to the zero address
  error BlocklistZeroAddress();

  /// @notice Error for when caller attempts to perform action on a blocked
  ///         account
  error BlockedAccount();

  /**
   * @dev Event for when the blocklist reference is set
   *
   * @param oldBlocklist The old blocklist
   * @param newBlocklist The new blocklist
   */
  event BlocklistSet(address oldBlocklist, address newBlocklist);
}