// SPDX-License-Identifier: MIT
//
// ...............   ...............   ...............  .....   ...............  
// :==============.  ===============  :==============:  -====  .==============-  
// :==============.  ===============  :==============:  -====  .==============-  
// :==============.  ===============  :==============:  -====  .==============-  
// :==============.  ===============  :==============:  -====  .==============-  
// .::::-====-::::.  ===============  :====-:::::::::.  -====  .====-::::-====-  
//      :====.       ===============  :====:            -====  .====:    .====-  
//      :====.       ===============  :====:            -====  .====:    .====-  
//
// Learn more at https://topia.gg or Twitter @topiagg

pragma solidity 0.8.18;

import "../Ownable/Ownable.sol";
import "./UpgradeableStorage.sol";

contract Upgradeable is Ownable {
  function setUpgrade(bytes4 _sig, address _target) external onlyOwner {
    UpgradeableStorage.layout().upgrades[_sig] = _target;
  }

  function hasUpgrade(bytes4 _sig) private view returns (bool) {
    return UpgradeableStorage.layout().upgrades[_sig] != address(0);
  }

  function executeUpgrade(bytes4 _sig) private returns (bool) {
    address target = UpgradeableStorage.layout().upgrades[_sig];

    assembly {
      calldatacopy(0, 0, calldatasize())
      let result := delegatecall(gas(), target, 0, calldatasize(), 0, 0)
      returndatacopy(0, 0, returndatasize())
      switch result
        case 0 {revert(0, returndatasize())}
        default {return (0, returndatasize())}
    }
  }

  modifier checkForUpgrade() {
    if (hasUpgrade(msg.sig)) {
      executeUpgrade(msg.sig);
    } else {
      _;
    }
  }

  fallback() external payable {
    require(hasUpgrade(msg.sig));
    executeUpgrade(msg.sig);
  }

  receive() external payable {}
}