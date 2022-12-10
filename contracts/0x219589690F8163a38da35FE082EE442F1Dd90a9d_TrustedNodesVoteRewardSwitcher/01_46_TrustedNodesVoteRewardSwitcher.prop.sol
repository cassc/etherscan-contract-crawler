// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../monetary/TrustedNodes.sol";

/**
 * Updates the vote rewarded to a trustee per vote
 */
contract TrustedNodesVoteRewardSwitcher is TrustedNodes {
    address public constant TEST_FILL_ADDRESS =
        0xDEADBEeFbAdf00dC0fFee1Ceb00dAFACEB00cEc0;

    bytes32 public constant TEST_FILL_BYTES =
        0x9f24c52e0fcd1ac696d00405c3bd5adc558c48936919ac5ab3718fcb7d70f93f;

    address[] private fill;

    // this is for setting up the storage context
    // the values are unused but must validate the super constructor
    constructor() TrustedNodes(Policy(TEST_FILL_ADDRESS), fill, 0) {}

    /**
     * Updates the voteReward in the context of the deployed TrustedNodes
     *
     * @param _voteReward the new vote reward per vote that trustees get
     */
    function setVoteReward(uint256 _voteReward) public {
        voteReward = _voteReward;
    }
}