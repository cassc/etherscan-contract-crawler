/**
 *Submitted for verification at BscScan.com on 2023-01-04
*/

/*
 *
 *
 *          .      .                                                 .                  
 *               .                                                                      
 *            .;;..         .':::::::::::::;,..    .'::;..   . .':::;'. .               
 *           'xKXk;.      . .oXXXXXXXXXXXXXXKOl'.  .oXXKc.    .l0XX0o.                  
 *          .dXXXXk, .      .;dddddddddddddkKXXk,  .oXXKc.  .:kXXKx,.  .                
 *       . .oKXXXXXx'              .  .    .oKXXo. .oXXKc..'dKXXOc. .    .              
 *     .. .lKXXkxKXXx. .                   .lKXXo. .oXXKd;lOXXKo'.      .               
 *       .cKXXk'.oKXKd.      .cloollllllolox0XXO;. .oXXXXXXXXKl. .                      
 *   .  .c0XXk,  .dXXKo. .  .lXXXXXXXXXXXXXXX0d,.. .oXXXOxkKXKk:.                       
 *     .:0XXO;.   'xXXKl.   .oXXKxcccccco0XXKc.  . .oXXKc..cOXXKd,.                     
 *     ;OXX0:.     ,kXX0c.  .oXXKc      .:0XXO,    .oXXKc. .'o0XX0l.                    
 *    ,kXX0c.       ,OXX0:. .oXXKc.  ..  .c0XXk,   .oXXKc. . .;xKXKk;.                  
 *   .cxxxc.        .;xxko. .:kkx;.       .:xxxl.  .:xxx;. .   .cxxxd;. .               
 *   ......          ...... ......       . ......   .....       .......                 
 *               .             .             ..                                         
 *
 *
 * 
 * ARK LIQUIDTY LOCKER
 *
 * SPDX-License-Identifier: None
 */

pragma solidity 0.8.16;

interface ARK_LIQ {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount ) external returns (bool);
}

contract ARK_LIQ_LOCK {
    ARK_LIQ public immutable LP;
    address public immutable CEO;
    uint256 public lockedUntil;

    modifier onlyCEO() {
        require(msg.sender == CEO, "Only the CEO can do that");
        _;
    }

    constructor(address lpAddress, address lockOwner, uint256 initialLockDays) {
        LP = ARK_LIQ(lpAddress);
        CEO = lockOwner;
        lockedUntil = block.timestamp + initialLockDays * 1 days;
    }

    function lock(uint256 howMuch, uint256 forHowLong) external onlyCEO {
        LP.transferFrom(msg.sender, address(this), howMuch);
        if(block.timestamp + forHowLong * 1 days > lockedUntil) lockedUntil = block.timestamp + forHowLong * 1 days;
    }

    function lockAll(uint256 forHowLong) external onlyCEO {
        LP.transferFrom(msg.sender, address(this), LP.balanceOf(msg.sender));
        if(block.timestamp + forHowLong * 1 days > lockedUntil) lockedUntil = block.timestamp + forHowLong * 1 days;
    }

    function extendLock(uint256 forHowLong) external onlyCEO {
        lockedUntil += forHowLong * 1 days;
    }

    function withdraw(uint256 howMuch) external onlyCEO {
        require(block.timestamp > lockedUntil, "LP is still locked");
        LP.transfer(msg.sender, howMuch);
    }
    
    function withdrawAll() external onlyCEO {
        require(block.timestamp > lockedUntil, "LP is still locked");
        LP.transfer(msg.sender, LP.balanceOf(address(this)));
    }
}

contract ARK_LIQ_LOCK_FACTORY {
    mapping(address => bool) private hasAdminRights;
    address[] public lpLockers; 

    modifier onlyCEO() {if(!hasAdminRights[msg.sender]) return; _;} 
 
    event NewLockCreated(address lpAddress, address lockOwner, uint256 initialLockDays);

    constructor() { 
        hasAdminRights[msg.sender] = true;
    }

    function createNewLpLocker(address lpAddress, address lockOwner, uint256 initialLockDays) external onlyCEO {
        lpLockers.push(address(new ARK_LIQ_LOCK(lpAddress, lockOwner, initialLockDays))); 
    }

    function setAdminAddress(address adminWallet, bool status) external onlyCEO {
        hasAdminRights[adminWallet] = status;
    }
}