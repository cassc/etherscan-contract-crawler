// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/* 
 * @title IWorm1000Artwork
 * @author minimizer <[email protected]>; https://minimizer.art/ 
 * 
 * Interface for the Worm1000Artwork, to be used by the Token Contract
 */

interface IWorm1000Artwork {
    
    function tokenURI(uint mainDiscipleNumber, uint[4] memory numberOfLightsByLumenLevel, bool animationView) external view returns (string memory);
    
    function royaltyRecipient() external view returns (address);
}