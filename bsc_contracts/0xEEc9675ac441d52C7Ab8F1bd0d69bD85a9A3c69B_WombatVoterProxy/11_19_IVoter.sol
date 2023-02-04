// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IVoter {
    function veWom() external view returns (address);

    function lpTokens(uint256) external view returns (address);

    function infos(address)
        external
        view
        returns (
            uint104 supplyBaseIndex, // 19.12 fixed point. distributed reward per alloc point
            uint104 supplyVoteIndex, // 19.12 fixed point. distributed reward per vote weight
            uint40 nextEpochStartTime,
            uint128 claimable, // 20.18 fixed point. Rewards pending distribution in the next epoch
            bool whitelist,
            address gaugeManager,
            address bribe // address of bribe
        );

    function lpTokenLength() external view returns (uint256);

    function getUserVotes(address _user, address _lpToken)
        external
        view
        returns (uint256);

    function vote(address[] calldata _lpVote, int256[] calldata _deltas)
        external
        returns (uint256[][] memory bribeRewards);

    function pendingBribes(address[] calldata _lpTokens, address _user)
        external
        view
        returns (uint256[][] memory bribeRewards);

    function distribute(address _lpToken) external;
}