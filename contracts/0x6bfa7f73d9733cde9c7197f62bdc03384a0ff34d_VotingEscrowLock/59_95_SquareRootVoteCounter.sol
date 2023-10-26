//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
import "../../../core/governance/libraries/VoteCounter.sol";
import "../../../utils/Sqrt.sol";

contract SquareRootVoteCounter is VoteCounter {
    using Sqrt for uint256;

    function getVotes(uint256 veLockId, uint256 timestamp)
        public
        view
        override
        returns (uint256)
    {
        uint256 votes = super.getVotes(veLockId, timestamp);
        return votes.sqrt();
    }

    function getTotalVotes() public view virtual override returns (uint256) {
        return IVotingEscrowToken(veToken()).totalSupply().sqrt();
    }
}