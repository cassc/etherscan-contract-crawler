// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

interface IGovernable {
  function setGovernance(address _governance) external;

  function governance() external view returns (address);

  /*//////////////////////////////////////////////////////////////
                            Errors
    //////////////////////////////////////////////////////////////*/

  error NotGovernance();

  /*//////////////////////////////////////////////////////////////
                            Events
    //////////////////////////////////////////////////////////////*/

  event GovernanceTransferred(
    address indexed oldGovernance,
    address indexed newGovernance
  );
}