// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./SafeMath.sol";

contract AccessControl is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    address public constant ZERO_ADDRESS = address(0);
    address[] public admins;
    
    // fix rate swap switch 
    bool public isFRSwapOn = true;

    // dex swap switch
    bool public isSwapOn = true;

    constructor() {
        setAdmin(_msgSender());
    }

    modifier onlyAdmin() {
        bool isAdmin;

        for (uint i; i<admins.length; i++) {
            if (msg.sender == admins[i]) {
                isAdmin = true;
            }
        }
        require(isAdmin, "Invalid Admin: caller is not the admin");
        _;
    }

    modifier notZeroAddr(address addr_) {
        require(addr_ != ZERO_ADDRESS, "Zero address");
        _;
    }

    modifier onlyFRSwapOn() {
        require(isFRSwapOn, "Fix Rate Swap Is Off");
        _;
    }

    modifier onlySwapOn() {
        require(isSwapOn, "Swap Is Off");
        _;
    }

    /* ---------------------------- Writes --------------------------------- */

    function setAdmin(address newAdmin) onlyOwner public {
        for (uint i; i<admins.length; i++) {
            if (newAdmin == admins[i]) {
                revert("Already Admin");
            }
        }

        admins.push(newAdmin);

        emit SetAdmin(newAdmin);
    }

    function deleteAdmin(address oldAdmin) onlyOwner external {
        for (uint i; i<admins.length; i++) {
            if (oldAdmin == admins[i]) {
                admins[i] = admins[admins.length-1];
                admins.pop();
                break;
            }
        }

        emit DeleteAdmin(oldAdmin);
    }

    function flipSwap() onlyAdmin external {
        isSwapOn = !isSwapOn;

        emit FlipSwap(isSwapOn);
    }

    function flipFRSwap() onlyAdmin external {
        isFRSwapOn = !isFRSwapOn;

        emit FlipFRSwap(isFRSwapOn);
    }
    
    /* ---------------------------- Events --------------------------------- */

    event SetAdmin(address newAdmin);
    event DeleteAdmin(address oldAdmin);
    event FlipSwap(bool isSwapOn);
    event FlipFRSwap(bool isFRSwapOn);
}