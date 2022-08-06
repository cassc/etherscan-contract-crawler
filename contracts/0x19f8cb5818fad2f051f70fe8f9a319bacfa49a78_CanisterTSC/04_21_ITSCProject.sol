// SPDX-License-Identifier: MIT
/**
* @N.T.P. Canisters 
* @modules Ownable, ERC721Psi, RoyaltyInfo.
*/
pragma solidity ^0.8.15;

// Inherit this interface for the TSCProject
interface ITSCProject {
    // Should only be called by CanisterTSC
    function mintProject(address to, uint256 quantity) external returns(uint256);
}