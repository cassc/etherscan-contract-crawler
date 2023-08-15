//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ActiveAfterBlock is Ownable {
    // Starting block
    uint256 public startingBlock;

    /**
     * @dev Set starting block number
     */
    function setStartingBlock(uint256 blockNumber) external onlyOwner {
        startingBlock = blockNumber;
    }

    /**
     * @dev Check if we're active
     */
    modifier isActive() {
        require(block.number >= startingBlock, "Contract not active yet");
        _;
    }
}