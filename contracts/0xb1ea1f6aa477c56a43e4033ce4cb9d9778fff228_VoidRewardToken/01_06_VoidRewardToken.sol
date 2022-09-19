// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**

    website: https://void.cash/
    twitter: https://twitter.com/voidcasherc
    telegram: https://t.me/voidcashportal
    medium: https://medium.com/@voidcash
    
    prepare to enter the
    ██╗   ██╗ ██████╗ ██╗██████╗ 
    ██║   ██║██╔═══██╗██║██╔══██╗
    ██║   ██║██║   ██║██║██║  ██║
    ╚██╗ ██╔╝██║   ██║██║██║  ██║
     ╚████╔╝ ╚██████╔╝██║██████╔╝
      ╚═══╝   ╚═════╝ ╚═╝╚═════╝ 

 */

import "openzeppelin/access/Ownable.sol";
import "openzeppelin/token/ERC20/ERC20.sol";

contract VoidRewardToken is ERC20, Ownable {

    /* -------------------------------------------------------------------------- */
    /*                                   errors                                   */
    /* -------------------------------------------------------------------------- */
    error NotAllowed();

    /* -------------------------------------------------------------------------- */
    /*                                   events                                   */
    /* -------------------------------------------------------------------------- */
    event AddedToAllowedList(address _address);
    event RemovedFromAllowedList(address _address);

    /* -------------------------------------------------------------------------- */
    /*                                   states                                   */
    /* -------------------------------------------------------------------------- */
    mapping(address => bool) public allowedList;

    /* -------------------------------------------------------------------------- */
    /*                                 constructor                                */
    /* -------------------------------------------------------------------------- */
    constructor() ERC20("VoidRewardToken", "VRT") {}

    /* -------------------------------------------------------------------------- */
    /*                                  external                                  */
    /* -------------------------------------------------------------------------- */
    function mint(address to, uint256 amount) external {

        // check is allowed to mint
        if (!allowedList[msg.sender]) { revert NotAllowed(); }

        // mint
        _mint(to, amount);
    }

    function burn(uint256 amount) external {

        // check is allowed to burn
        if (!allowedList[msg.sender]) { revert NotAllowed(); }

        // burn
        _burn(msg.sender, amount);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   owners                                   */
    /* -------------------------------------------------------------------------- */
    function addToAllowedList(address _address) external onlyOwner {
        allowedList[_address] = true;
        emit AddedToAllowedList(_address);
    }

    function removeFromAllowedList(address _address) external onlyOwner {
        delete allowedList[_address];
        emit RemovedFromAllowedList(_address);
    }
}