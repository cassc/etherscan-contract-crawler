// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./ILinkageLeaf.sol";

interface IBuyback is IAccessControl, ILinkageLeaf {
    event Stake(address who, uint256 amount);
    event Unstake(address who, uint256 amount);
    event NewBuyback(uint256 amount, uint256 share);
    event ParticipateBuyback(address who);
    event LeaveBuyback(address who, uint256 currentStaked);
    event BuybackWeightChanged(address who, uint256 newWeight, uint256 oldWeight, uint256 newTotalWeight);
    event LoyaltyParametersChanged(uint256 newCoreFactor, uint32 newCoreResetPenalty);
    event LoyaltyStrataChanged();
    event LoyaltyGroupsChanged(uint256 newGroupCount);

    /**
     * @notice Gets info about account membership in Buyback
     */
    function getMemberInfo(address account)
        external
        view
        returns (
            bool participating,
            uint256 weight,
            uint256 lastIndex,
            uint256 stakeAmount
        );

    /**
     * @notice Gets info about accounts loyalty calculation
     */
    function getLoyaltyInfo(address account)
        external
        view
        returns (
            uint32 loyaltyStart,
            uint256 coreBalance,
            uint256 lastBalance
        );

    /**
     * @notice Gets if an account is participating in Buyback
     */
    function isParticipating(address account) external view returns (bool);

    /**
     * @notice Gets stake of the account
     */
    function getStakedAmount(address account) external view returns (uint256);

    /**
     * @notice Gets buyback weight of an account
     */
    function getWeight(address account) external view returns (uint256);

    /**
     * @notice Gets loyalty factor of an account with given balance.
     */
    function getLoyaltyFactorForBalance(address account, uint256 balance) external view returns (uint256);

    /**
     * @notice Gets total Buyback weight, which is the sum of weights of all accounts.
     */
    function getTotalWeight() external view returns (uint256);

    /**
     * @notice Gets current Buyback index.
     * Its the accumulated sum of MNTs shares that are given for each weight of an account.
     */
    function getBuybackIndex() external view returns (uint256);

    /**
     * @notice Gets all global loyalty parameters.
     */
    function getLoyaltyParameters()
        external
        view
        returns (
            uint256[24] memory loyaltyStrata,
            uint256[] memory groupThresholds,
            uint32[] memory groupStartStrata,
            uint256 coreFactor,
            uint32 coreResetPenalty
        );

    /**
     * @notice Stakes the specified amount of MNT and transfers them to this contract.
     * @notice This contract should be approved to transfer MNT from sender account
     * @param amount The amount of MNT to stake
     */
    function stake(uint256 amount) external;

    /**
     * @notice Unstakes the specified amount of MNT and transfers them back to sender if he participates
     *         in the Buyback system, otherwise just transfers MNT tokens to the sender.
     *         would not be greater than staked amount left. If `amount == MaxUint256` unstakes all staked tokens.
     * @param amount The amount of MNT to unstake
     */
    function unstake(uint256 amount) external;

    /**
     * @notice Claims buyback rewards, updates buyback weight and voting power.
     * Does nothing if account is not participating. Reverts if operation is paused.
     * @param account Address to update weights for
     */
    function updateBuybackAndVotingWeights(address account) external;

    /**
     * @notice Claims buyback rewards, updates buyback weight and voting power.
     * Does nothing if account is not participating or update is paused.
     * @param account Address to update weights for
     */
    function updateBuybackAndVotingWeightsRelaxed(address account) external;

    /**
     * @notice Does a buyback using the specified amount of MNT from sender's account
     * @param amount The amount of MNT to take and distribute as buyback
     * @dev RESTRICTION: Distributor only
     */
    function buyback(uint256 amount) external;

    /**
     * @notice Make account participating in the buyback.
     */
    function participate() external;

    /**
     * @notice Make accounts participate in buyback before its start.
     * @param accounts Address to make participate in buyback.
     * @dev RESTRICTION: Admin only
     */
    function participateOnBehalf(address[] memory accounts) external;

    /**
     * @notice Leave buyback participation, claim any MNTs rewarded by the buyback.
     * Leaving does not withdraw staked MNTs but reduces weight of the account to zero
     */
    function leave() external;

    /**
     * @notice Leave buyback participation on behalf, claim any MNTs rewarded by the buyback and
     * reduce the weight of account to zero. All staked MNTs remain on the buyback contract and available
     * for their owner to be claimed
     * Can only be called if (timestamp > participantLastVoteTimestamp + maxNonVotingPeriod).
     * @param participant Address to leave for
     * @dev RESTRICTION: GATEKEEPER only
     */
    function leaveOnBehalf(address participant) external;

    /**
     * @notice Leave buyback participation on behalf, claim any MNTs rewarded by the buyback and
     * reduce the weight of account to zero. All staked MNTs remain on the buyback contract and available
     * for their owner to be claimed.
     * @dev Function to leave sanctioned accounts from Buyback system
     * Can only be called if the participant is sanctioned by the AML system.
     * @param participant Address to leave for
     */
    function leaveByAmlDecision(address participant) external;

    /**
     * @notice Changes loyalty core factor and core reset penalty parameters.
     * @dev RESTRICTION: Admin only
     */
    function setLoyaltyParameters(uint256 newCoreFactor, uint32 newCoreResetPenalty) external;

    /**
     * @notice Sets new loyalty factors for all strata.
     * @dev RESTRICTION: Admin only
     */
    function setLoyaltyStrata(uint256[24] memory newLoyaltyStrata) external;

    /**
     * @notice Sets new groups and their parameters
     * @param newGroupThresholds New list of groups and their balance thresholds.
     * @param newGroupStartStrata Indexes of starting stratum of each group. First index MUST be zero.
     *        Length of array must be equal to the newGroupThresholds
     * @dev RESTRICTION: Admin only
     */
    function setLoyaltyGroups(uint256[] memory newGroupThresholds, uint32[] memory newGroupStartStrata) external;
}