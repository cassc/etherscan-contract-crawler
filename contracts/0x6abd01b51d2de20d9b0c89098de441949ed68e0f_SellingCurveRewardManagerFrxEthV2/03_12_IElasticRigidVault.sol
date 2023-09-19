//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IElasticRigidVault {
    function lockedNominalRigid() external view returns (uint256);
}