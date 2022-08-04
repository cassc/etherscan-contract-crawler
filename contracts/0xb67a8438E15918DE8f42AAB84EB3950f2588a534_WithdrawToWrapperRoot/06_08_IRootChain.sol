//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

interface IRootChain {
    struct HeaderBlock {
        bytes32 root;
        uint256 start;
        uint256 end;
        uint256 createdAt;
        address proposer;
    }

    /**
     * @notice mapping of checkpoint header numbers to block details
     * @dev These checkpoints are submited by plasma contracts
     */
    function headerBlocks(uint256 number)
        external
        view
        returns (HeaderBlock calldata);
}