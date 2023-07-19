// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity 0.8.19;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";

// ADOT + VUCA + LightLink + Pellar 2023

contract ContractProxy is Proxy, ERC1967Upgrade {
  function initialize(address _logic, bytes memory _data) public payable {
    require(_implementation() == address(0));
    _upgradeToAndCall(_logic, _data, false);
  }

  function _implementation() internal view virtual override returns (address impl) {
    return ERC1967Upgrade._getImplementation();
  }
}