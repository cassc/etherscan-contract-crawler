// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IGeminonInfrastructure {
    function arbitrageur() external view returns(address);
    function setArbitrageur(address arbitrageur_) external;
    function applyOracleChange() external;
    function cancelChangeRequests() external;
}