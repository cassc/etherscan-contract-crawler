// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

interface IReverseRegistrar {
  /**
   * @dev Transfers ownership of the reverse ENS record associated with the
   *      calling account.
   * @param owner The address to set as the owner of the reverse record in ENS.
   * @return The ENS node hash of the reverse record.
   */
  function claim(address owner) external returns (bytes32);

  /**
   * @dev Sets the `name()` record for the reverse ENS record associated with
   * the calling account. First updates the resolver to the default reverse
   * resolver if necessary.
   * @param name The name to set for this address.
   * @return The ENS node hash of the reverse record.
   */
  function setName(string memory name) external returns (bytes32);
}