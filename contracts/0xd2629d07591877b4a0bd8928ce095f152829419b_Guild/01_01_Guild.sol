// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12;

/**
 * @title Guild Contract
 * @author CRYSTAL-LABS
 * @notice In this contract users can bind inviters
 */
contract Guild {
    mapping(address => address) public userInviter;

    event BindInviter(address indexed user, address inviter);

    constructor() {}

    /**
     * @dev Bind Inviter
     */
    function bindInviter(address inviter) external {
        require(inviter != address(0), "The inviter cannot be empty");
        require(
            userInviter[msg.sender] == address(0),
            "You have already bound the inviter"
        );
        require(inviter != msg.sender, "You cannot bind yourself");
        require(
            userInviter[inviter] != msg.sender,
            "Your inviter's inviter cannot be yourself"
        );

        userInviter[msg.sender] = inviter;

        emit BindInviter(msg.sender, inviter);
    }
}