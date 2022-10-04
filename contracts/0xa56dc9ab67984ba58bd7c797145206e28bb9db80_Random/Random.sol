/**
 *Submitted for verification at Etherscan.io on 2022-10-03
*/

pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

contract Random {
    /**
     * @notice RandomNumberEvent event is emitted when user generates a random number.
     */
    event RandomNumberEvent(
        string title,
        uint256 number,
        address indexed requestedBy
    );

    /**
     * @notice This method generates random number between 1 to `maxNumber` inclusive and broadcasts event with given title and the result.
     */
    function newRandomEvent(uint256 maxNumber, string calldata title) public {
        uint256 number = randomNumber(maxNumber);
        emit RandomNumberEvent(title, number, msg.sender);
    }

    /**
     * @dev randomNumber function returns a number between 1 and `maxNumber` inclusive based on block difficulty, block timestamp and sender address.
     */
    function randomNumber(uint256 maxNumber) public view returns (uint256) {
        uint256 number = (uint256(
            keccak256(abi.encode(block.difficulty, block.timestamp, msg.sender))
        ) % maxNumber) + 1;
        return number;
    }
}