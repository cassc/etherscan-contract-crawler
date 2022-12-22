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

/**
 * @title IMulticall
 * @author Ondo Finance
 * @notice This interface dictates the required external functions for Ondo's
 *         multicall contract.
 */
interface IMulticall {
  /// @dev External call data structure
  struct ExCallData {
    // The contract we intend to call
    address target;
    // The encoded function data for the call
    bytes data;
    // The ether value to be sent in the call
    uint256 value;
  }

  /**
   * @notice Batches multiple function calls to different target contracts
   *         and returns the resulting data provided all calls were successful
   *
   * @dev The `msg.sender` is always the contract from which this function
   *      is being called
   *
   * @param exdata The ExCallData struct array containing the information
   *               regarding which contract to call, what data to call with,
   *               and what ether value to send along with the call
   *
   * @return results The resulting data returned from each call made
   */
  function multiexcall(
    ExCallData[] calldata exdata
  ) external payable returns (bytes[] memory results);
}