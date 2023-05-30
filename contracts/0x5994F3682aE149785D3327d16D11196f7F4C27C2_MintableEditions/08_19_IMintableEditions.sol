// SPDX-License-Identifier: MIT

/**
 * ░█▄█░▄▀▄▒█▀▒▄▀▄░░░▒░░░▒██▀░█▀▄░█░▀█▀░█░▄▀▄░█▄░█░▄▀▀░░░█▄░█▒█▀░▀█▀
 * ▒█▒█░▀▄▀░█▀░█▀█▒░░▀▀▒░░█▄▄▒█▄▀░█░▒█▒░█░▀▄▀░█▒▀█▒▄██▒░░█▒▀█░█▀░▒█▒
 * 
 * Made with 🧡 by Kreation.tech
 */
pragma solidity ^0.8.6;

interface IMintableEditions {
    /**
     * Mints one token for the msg.sender. 
     */
    function mint() external returns (uint256);
    
    /**
     * Mints multiple tokens, one for each of the given addresses.
     * 
     * @param to list of addresses to send the newly minted tokens to
     */
    function mintAndTransfer(address[] memory to) external returns (uint256);

    /** 
     * Returns the number of tokens still available for minting
     */
    function mintable() external view returns (uint256);

    /**
     * Returns the owner of the editions contract.
     */
    function owner() external view returns (address);
}