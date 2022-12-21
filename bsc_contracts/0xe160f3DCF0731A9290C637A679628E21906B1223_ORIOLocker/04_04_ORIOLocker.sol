// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * Used to lock tokens forever for the migration.
 * What it does mean by `forever`, it doesn't allow the operator to transfer tokens deposited from holders to any tradable accounts
 * or it can disallow withdrawal action at all
 */
contract ORIOLocker is Ownable {
    address public immutable DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    event Deposited(address indexed account, uint256 amount);
    event Burned(address indexed account, uint256 amount);

    address public immutable lockToken;

    mapping(address => uint256) public locked;

    constructor(address _token) {
        lockToken = _token;
    }

    function deposit(uint256 amount) external {
        IERC20(lockToken).transferFrom(msg.sender, address(this), amount);
        locked[msg.sender] = locked[msg.sender] + amount;
        emit Deposited(msg.sender, amount);
    }

    function burn() external onlyOwner {
        uint256 totalLocked = IERC20(lockToken).balanceOf(address(this));
        IERC20(lockToken).transfer(DEAD_ADDRESS, totalLocked);
        emit Burned(DEAD_ADDRESS, totalLocked);
    }
}