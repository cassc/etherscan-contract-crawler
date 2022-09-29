pragma solidity >=0.6.6;

import "../interfaces/ICopycatEmergencyAllower.sol";

interface ICopycatEmergencyMaster {
  function isAllowEmergency(ICopycatEmergencyAllower allower) external view returns(bool);
  function allowEmergency(ICopycatEmergencyAllower allower, bool allowed) external;
}