// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @notice Gate used by Co:Create contracts to check if the upgrades are valid and secure
 */
contract UpgradeGate is Ownable {
  event NewUpgradePathRegistered(address newImpl, address currentImpl);
  event UpgradePathUnRegistered(address newImpl, address currentImpl);

  mapping(address => mapping(address => bool)) private validUpgradePath;

  constructor(address admin) {
    _transferOwnership(admin);
  }

  function validateUpgrade(address newImpl, address currentImpl) public view {
    if (!validUpgradePath[newImpl][currentImpl]) {
      revert("UpgradeGate: UnRegistered Upgrade");
    }
  }

  function registerPath(address newImpl, address currentImpl) external onlyOwner {
    validUpgradePath[newImpl][currentImpl] = true;
    emit NewUpgradePathRegistered(newImpl, currentImpl);
  }

  function unregisterPath(address newImpl, address currentImpl) external onlyOwner {
    validUpgradePath[newImpl][currentImpl] = false;
    emit UpgradePathUnRegistered(newImpl, currentImpl);
  }
}