// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

/**
 * @title Upgradeable
 * @dev This contract provides special helper functions when using the upgradeability proxy.
 */
abstract contract Upgradeable {
  uint256 internal _version;

  /**
   * @dev Storage slot with the admin of the contract.
   * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1.
   */
  bytes32 internal constant ADMIN_SLOT =
    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  modifier onlyProxyAdmin() {
    address proxyAdmin;
    bytes32 slot = ADMIN_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      proxyAdmin := sload(slot)
    }
    require(msg.sender == proxyAdmin, "Upgradeable/MustBeProxyAdmin");
    _;
  }
}