// SPDX-License-Identifier: BUSL-1.1-COPYCAT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ICopycatEmergencyMaster.sol";
import "../interfaces/ICopycatEmergencyAllower.sol";

contract CopycatEmergencyMaster is Ownable, ICopycatEmergencyMaster {
  mapping(ICopycatEmergencyAllower => bool) public override isAllowEmergency;

  event AllowEmergency(address indexed caller, ICopycatEmergencyAllower indexed allower, bool indexed allowed);
  function allowEmergency(ICopycatEmergencyAllower allower, bool allowed) external override onlyOwner {
    isAllowEmergency[allower] = allowed;
    emit AllowEmergency(msg.sender, allower, allowed);
  }
}