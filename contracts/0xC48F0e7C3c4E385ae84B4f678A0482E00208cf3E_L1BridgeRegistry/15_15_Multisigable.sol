// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// LightLink 2023
abstract contract Multisigable {
  address public multisig;

  /** Modifier */
  // verified
  modifier requireMultisig() {
    require(msg.sender == multisig, "Multisig required");
    _;
  }

  function modifyMultisig(address _multisig) public requireMultisig {
    require(_multisig != address(0), "Multisig address cannot be zero");
    multisig = _multisig;
  }

  function __Multisigable_init(address _multisig) internal {
    require(_multisig != address(0), "Multisig address cannot be zero");
    multisig = _multisig;
  }
}