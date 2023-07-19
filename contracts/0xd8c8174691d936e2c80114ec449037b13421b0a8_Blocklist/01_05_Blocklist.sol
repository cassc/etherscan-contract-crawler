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
import "contracts/external/openzeppelin/contracts/access/Ownable2Step.sol";
import "contracts/interfaces/IBlocklist.sol";

/**
 * @title Blocklist
 * @author Ondo Finance
 * @notice This contract manages the blocklist status for accounts.
 */
contract Blocklist is Ownable2Step, IBlocklist {
  constructor() {}

  // {<address> => is account blocked}
  mapping(address => bool) private blockedAddresses;

  /**
   * @notice Returns name of contract
   */
  function name() external pure returns (string memory) {
    return "Ondo Finance Blocklist Oracle";
  }

  /**
   * @notice Function to add a list of accounts to the blocklist
   *
   * @param accounts Array of addresses to block
   */
  function addToBlocklist(address[] calldata accounts) external onlyOwner {
    for (uint256 i; i < accounts.length; ++i) {
      blockedAddresses[accounts[i]] = true;
    }
    emit BlockedAddressesAdded(accounts);
  }

  /**
   * @notice Function to remove a list of accounts from the blocklist
   *
   * @param accounts Array of addresses to unblock
   */
  function removeFromBlocklist(address[] calldata accounts) external onlyOwner {
    for (uint256 i; i < accounts.length; ++i) {
      blockedAddresses[accounts[i]] = false;
    }
    emit BlockedAddressesRemoved(accounts);
  }

  /**
   * @notice Function to check if an account is blocked
   *
   * @param addr Address to check
   *
   * @return True if account is blocked, false otherwise
   */
  function isBlocked(address addr) external view returns (bool) {
    return blockedAddresses[addr];
  }
}