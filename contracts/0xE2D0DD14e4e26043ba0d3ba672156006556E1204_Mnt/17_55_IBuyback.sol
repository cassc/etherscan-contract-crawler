// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./ILinkageLeaf.sol";

interface IBuyback is IAccessControl, ILinkageLeaf {
    event Stake(address who, uint256 amount, uint256 discounted);
    event Unstake(address who, uint256 amount);
    event NewBuyback(uint256 amount, uint256 share);
    event ParticipateBuyback(address who);
    event LeaveBuyback(address who, uint256 currentStaked);
    event BuybackWeightChanged(address who, uint256 newWeight, uint256 oldWeight, uint256 newTotalWeight);

    /**
     * @notice Gets parameters used to calculate the discount curve.
     * @return start The timestamp from which the discount starts
     * @return flatSeconds Seconds from protocol start when approximation function has minimum value
     * ~ 4.44 years of the perfect year, at this point df/dx == 0
     * @return flatRate Flat rate of the discounted MNTs after the kink point.
     * Equal to the percentage at flatSeconds time
     */
    function discountParameters()
        external
        view
        returns (
            uint256 start,
            uint256 flatSeconds,
            uint256 flatRate
        );

    /**
     * @notice Applies current discount rate to the supplied amount
     * @param amount The amount to discount
     * @return Discounted amount in range [0; amount]
     */
    function discountAmount(uint256 amount) external view returns (uint256);

    /**
     * @notice Calculates value of polynomial approximation of e^-kt, k = 0.725, t in seconds of a perfect year
     * function follows e^(-0.725*t) ~ 1 - 0.7120242*x + 0.2339357*x^2 - 0.04053335*x^3 + 0.00294642*x^4
     * up to the minimum and then continues with a flat rate
     * @param secondsElapsed Seconds elapsed from the start block
     * @return Discount rate in range [0..1] with precision mantissa 1e18
     */
    function getPolynomialFactor(uint256 secondsElapsed) external pure returns (uint256);

    /**
     * @notice Gets all info about account membership in Buyback
     */
    function getMemberInfo(address account)
        external
        view
        returns (
            bool participating,
            uint256 weight,
            uint256 lastIndex,
            uint256 rawStake,
            uint256 discountedStake
        );

    /**
     * @notice Gets if an account is participating in Buyback
     */
    function isParticipating(address account) external view returns (bool);

    /**
     * @notice Gets discounted stake of the account
     */
    function getDiscountedStake(address account) external view returns (uint256);

    /**
     * @notice Gets buyback weight of an account
     */
    function getWeight(address account) external view returns (uint256);

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
     * @notice Stakes the specified amount of MNT and transfers them to this contract.
     * Sender's weight would increase by the discounted amount of staked funds.
     * @notice This contract should be approved to transfer MNT from sender account
     * @param amount The amount of MNT to stake
     */
    function stake(uint256 amount) external;

    /**
     * @notice Unstakes the specified amount of MNT and transfers them back to sender if he participates
     *         in the Buyback system, otherwise just transfers MNT tokens to the sender.
     *         Sender's weight would decrease by discounted amount of unstaked funds, but resulting weight
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
     * @notice Make account participating in the buyback. If the sender has a staked balance, then
     * the weight will be equal to the discounted amount of staked funds.
     */
    function participate() external;

    /**
     *@notice Make accounts participate in buyback before its start.
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
     * @dev Admin function to leave on behalf.
     * Can only be called if (timestamp > participantLastVoteTimestamp + maxNonVotingPeriod).
     * @param participant Address to leave for
     * @dev RESTRICTION: Admin only
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
}