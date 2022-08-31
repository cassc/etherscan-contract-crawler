// SPDX-License-Identifier: GPL-3.0-or-later

// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌

pragma solidity 0.8.9;

/// @title IKeepTokenStaking
/// @notice Interface for Keep TokenStaking contract
interface IKeepTokenStaking {
    /// @notice Seize provided token amount from every member in the misbehaved
    /// operators array. The tattletale is rewarded with 5% of the total seized
    /// amount scaled by the reward adjustment parameter and the rest 95% is burned.
    /// @param amountToSeize Token amount to seize from every misbehaved operator.
    /// @param rewardMultiplier Reward adjustment in percentage. Min 1% and 100% max.
    /// @param tattletale Address to receive the 5% reward.
    /// @param misbehavedOperators Array of addresses to seize the tokens from.
    function seize(
        uint256 amountToSeize,
        uint256 rewardMultiplier,
        address tattletale,
        address[] memory misbehavedOperators
    ) external;

    /// @notice Gets stake delegation info for the given operator.
    /// @param operator Operator address.
    /// @return amount The amount of tokens the given operator delegated.
    /// @return createdAt The time when the stake has been delegated.
    /// @return undelegatedAt The time when undelegation has been requested.
    /// If undelegation has not been requested, 0 is returned.
    function getDelegationInfo(address operator)
        external
        view
        returns (
            uint256 amount,
            uint256 createdAt,
            uint256 undelegatedAt
        );

    /// @notice Gets the stake owner for the specified operator address.
    /// @return Stake owner address.
    function ownerOf(address operator) external view returns (address);

    /// @notice Gets the beneficiary for the specified operator address.
    /// @return Beneficiary address.
    function beneficiaryOf(address operator)
        external
        view
        returns (address payable);

    /// @notice Gets the authorizer for the specified operator address.
    /// @return Authorizer address.
    function authorizerOf(address operator) external view returns (address);

    /// @notice Gets the eligible stake balance of the specified address.
    /// An eligible stake is a stake that passed the initialization period
    /// and is not currently undelegating. Also, the operator had to approve
    /// the specified operator contract.
    ///
    /// Operator with a minimum required amount of eligible stake can join the
    /// network and participate in new work selection.
    ///
    /// @param operator address of stake operator.
    /// @param operatorContract address of operator contract.
    /// @return balance an uint256 representing the eligible stake balance.
    function eligibleStake(address operator, address operatorContract)
        external
        view
        returns (uint256 balance);
}

/// @title INuCypherStakingEscrow
/// @notice Interface for NuCypher StakingEscrow contract
interface INuCypherStakingEscrow {
    /// @notice Slash the staker's stake and reward the investigator
    /// @param staker Staker's address
    /// @param penalty Penalty
    /// @param investigator Investigator
    /// @param reward Reward for the investigator
    function slashStaker(
        address staker,
        uint256 penalty,
        address investigator,
        uint256 reward
    ) external;

    /// @notice Request merge between NuCypher staking contract and T staking contract.
    ///         Returns amount of staked tokens
    function requestMerge(address staker, address stakingProvider)
        external
        returns (uint256);

    /// @notice Get all tokens belonging to the staker
    function getAllTokens(address staker) external view returns (uint256);
}