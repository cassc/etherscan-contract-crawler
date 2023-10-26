// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { Owned } from "solmate/src/auth/Owned.sol";

/**
 * @title TokenReceiver
 * @author CyberConnect
 * @notice A contract that receive native token and record the amount.
 * The deposit only record the cumulative amount and withdraw won't affect
 * the deposit value.
 */
contract TokenReceiver is Owned {
    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public deposits;

    /*//////////////////////////////////////////////////////////////
                                 EVENT
    //////////////////////////////////////////////////////////////*/

    event Deposit(address from, address to, uint256 amount);
    event Withdraw(address to, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address owner) Owned(owner) {}

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    function depositTo(address to) external payable {
        deposits[to] += msg.value;
        emit Deposit(msg.sender, to, msg.value);
    }

    function withdraw(address to, uint256 amount) external onlyOwner {
        payable(to).transfer(amount);
        emit Withdraw(to, amount);
    }
}