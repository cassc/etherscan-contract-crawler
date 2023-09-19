// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../policy/PolicedUtils.sol";
import "../../currency/ECOx.sol";
import "../TimedPolicies.sol";
import "../IGeneration.sol";
import "../../utils/TimeUtils.sol";

/** @title TrustedNodes
 *
 * A registry of trusted nodes. Trusted nodes are able to vote during
 * inflation/deflation votes, and can only be added or removed using policy
 * proposals.
 *
 */
contract TrustedNodes is PolicedUtils, TimeUtils {
    uint256 public constant GENERATIONS_PER_YEAR = 26;

    uint256 public yearEnd;

    uint256 public yearStartGen;

    address public hoard;

    /** Tracks the current trustee cohort
     * each trustee election cycle corresponds to a new trustee cohort.
     */

    struct Cohort {
        /** The list of trusted nodes in the cohort*/
        address[] trustedNodes;
        /** @dev address of trusted node to index in trustedNodes */
        mapping(address => uint256) trusteeNumbers;
    }

    /** cohort number */
    uint256 public cohort;

    /** cohort number to cohort */
    mapping(uint256 => Cohort) internal cohorts;

    /** Represents the number of votes for which the trustee can claim rewards.
    Increments each time the trustee votes, set to zero upon redemption */
    mapping(address => uint256) public votingRecord;

    // last year's voting record
    mapping(address => uint256) public lastYearVotingRecord;

    // completely vested
    mapping(address => uint256) public fullyVestedRewards;

    /** reward earned per completed and revealed vote */
    uint256 public voteReward;

    // unallocated rewards to be sent to hoard upon the end of the year term
    uint256 public unallocatedRewardsCount;

    /** Event emitted when a node added to a list of trusted nodes.
     */
    event TrustedNodeAddition(address indexed node, uint256 cohort);

    /** Event emitted when a node removed from a list of trusted nodes
     */
    event TrustedNodeRemoval(address indexed node, uint256 cohort);

    /** Event emitted when voting rewards are redeemed */
    event VotingRewardRedemption(address indexed recipient, uint256 amount);

    // Event emitted on annualUpdate and newCohort to request funding to the contract
    event FundingRequest(uint256 amount);

    // information for the new trustee rewards term
    event RewardsTrackingUpdate(
        uint256 nextUpdateTimestamp,
        uint256 newRewardsCount
    );

    /** Creates a new trusted node registry, populated with some initial nodes.
     */
    constructor(
        Policy _policy,
        address[] memory _initialTrustedNodes,
        uint256 _voteReward
    ) PolicedUtils(_policy) {
        voteReward = _voteReward;
        uint256 trusteeCount = _initialTrustedNodes.length;
        hoard = address(_policy);

        for (uint256 i = 0; i < trusteeCount; ++i) {
            address node = _initialTrustedNodes[i];
            _trust(node);
        }
    }

    /** Initialize the storage context using parameters copied from the
     * original contract (provided as _self).
     *
     * Can only be called once, during proxy initialization.
     *
     * @param _self The original contract address.
     */
    function initialize(address _self) public override onlyConstruction {
        super.initialize(_self);
        // vote reward is left as mutable for easier governance
        voteReward = TrustedNodes(_self).voteReward();
        hoard = TrustedNodes(_self).hoard();
        yearStartGen = GENERATION_START + 1;
        yearEnd = getTime() + GENERATIONS_PER_YEAR * MIN_GENERATION_DURATION;

        uint256 _numTrustees = TrustedNodes(_self).numTrustees();

        unallocatedRewardsCount = _numTrustees * GENERATIONS_PER_YEAR;
        uint256 _cohort = TrustedNodes(_self).cohort();
        address[] memory trustees = TrustedNodes(_self)
            .getTrustedNodesFromCohort(_cohort);

        for (uint256 i = 0; i < _numTrustees; ++i) {
            _trust(trustees[i]);
        }
    }

    function getTrustedNodesFromCohort(uint256 _cohort)
        public
        view
        returns (address[] memory)
    {
        return cohorts[_cohort].trustedNodes;
    }

    /** Grant trust to a node.
     *
     * The node is pushed to trustedNodes array.
     *
     * @param _node The node to start trusting.
     */
    function trust(address _node) external onlyPolicy {
        _trust(_node);
    }

    /** Stop trusting a node.
     *
     * Node to distrust swaped to be a last element in the trustedNodes, then deleted
     *
     * @param _node The node to stop trusting.
     */
    function distrust(address _node) external onlyPolicy {
        Cohort storage currentCohort = cohorts[cohort];
        uint256 trusteeNumber = currentCohort.trusteeNumbers[_node];
        require(trusteeNumber > 0, "Node already not trusted");

        uint256 lastIndex = currentCohort.trustedNodes.length - 1;

        delete currentCohort.trusteeNumbers[_node];

        uint256 trusteeIndex = trusteeNumber - 1;
        if (trusteeIndex != lastIndex) {
            address lastNode = currentCohort.trustedNodes[lastIndex];

            currentCohort.trustedNodes[trusteeIndex] = lastNode;
            currentCohort.trusteeNumbers[lastNode] = trusteeNumber;
        }

        currentCohort.trustedNodes.pop();
        emit TrustedNodeRemoval(_node, cohort);
    }

    /** Incements the counter when the trustee reveals their vote
     * only callable by the CurrencyGovernance contract
     */
    function recordVote(address _who) external {
        require(
            msg.sender == policyFor(ID_CURRENCY_GOVERNANCE),
            "Must be the monetary policy contract to call"
        );

        votingRecord[_who]++;

        if (unallocatedRewardsCount > 0) {
            unallocatedRewardsCount--;
        }
    }

    /** The calling trustee can redeem any rewards from the previous generation
     *  that they have earned for participating in that generation's voting.
     */
    function redeemVoteRewards() external {
        // rewards from last year
        uint256 yearGenerationCount = IGeneration(policyFor(ID_TIMED_POLICIES))
            .generation() - yearStartGen;

        uint256 record = lastYearVotingRecord[msg.sender];
        uint256 vested = fullyVestedRewards[msg.sender];
        require(record + vested > 0, "No vested rewards to redeem");
        uint256 rewardsToRedeem = (
            record > yearGenerationCount ? yearGenerationCount : record
        );
        lastYearVotingRecord[msg.sender] = record - rewardsToRedeem;

        // fully vested rewards if they exist
        if (vested > 0) {
            rewardsToRedeem += vested;
            fullyVestedRewards[msg.sender] = 0;
        }

        uint256 reward = rewardsToRedeem * voteReward;

        require(
            ECOx(policyFor(ID_ECOX)).transfer(msg.sender, reward),
            "Transfer Failed"
        );

        emit VotingRewardRedemption(msg.sender, reward);
    }

    /** Return the number of entries in trustedNodes array.
     */
    function numTrustees() external view returns (uint256) {
        return cohorts[cohort].trustedNodes.length;
    }

    /** Helper function for adding a node to the trusted set.
     *
     * @param _node The node to add to the trusted set.
     */
    function _trust(address _node) private {
        uint256 _cohort = cohort;
        Cohort storage currentCohort = cohorts[_cohort];
        require(
            currentCohort.trusteeNumbers[_node] == 0,
            "Node is already trusted"
        );
        // trustee number of new node is len(trustedNodes) + 1, since we dont want an actual trustee with trusteeNumber = 0
        currentCohort.trusteeNumbers[_node] =
            currentCohort.trustedNodes.length +
            1;
        currentCohort.trustedNodes.push(_node);
        emit TrustedNodeAddition(_node, _cohort);
    }

    /** Checks if a node address is trusted in the current cohort
     */
    function isTrusted(address _node) public view returns (bool) {
        return cohorts[cohort].trusteeNumbers[_node] > 0;
    }

    /** Function for adding a new cohort of trustees
     * used for implementing the results of a trustee election
     */
    function newCohort(address[] memory _newCohort) external onlyPolicy {
        uint256 trustees = cohorts[cohort].trustedNodes.length;
        if (_newCohort.length > trustees) {
            emit FundingRequest(
                voteReward *
                    GENERATIONS_PER_YEAR *
                    (_newCohort.length - trustees)
            );
        }

        cohort++;

        for (uint256 i = 0; i < _newCohort.length; ++i) {
            _trust(_newCohort[i]);
        }
    }

    /** Updates the trustee rewards that they have earned for the year
     * and then sends the unallocated reward to the hoard.
     */
    function annualUpdate() external {
        require(
            getTime() > yearEnd,
            "cannot call this until the current year term has ended"
        );
        address[] memory trustees = cohorts[cohort].trustedNodes;
        for (uint256 i = 0; i < trustees.length; ++i) {
            address trustee = trustees[i];
            fullyVestedRewards[trustee] += lastYearVotingRecord[trustee];
            lastYearVotingRecord[trustee] = votingRecord[trustee];
            votingRecord[trustee] = 0;
        }

        uint256 reward = unallocatedRewardsCount * voteReward;
        unallocatedRewardsCount =
            cohorts[cohort].trustedNodes.length *
            GENERATIONS_PER_YEAR;
        yearEnd = getTime() + GENERATIONS_PER_YEAR * MIN_GENERATION_DURATION;
        yearStartGen = IGeneration(policyFor(ID_TIMED_POLICIES)).generation();

        ECOx ecoX = ECOx(policyFor(ID_ECOX));

        require(ecoX.transfer(hoard, reward), "Transfer Failed");

        emit FundingRequest(unallocatedRewardsCount * voteReward);
        emit VotingRewardRedemption(hoard, reward);
        emit RewardsTrackingUpdate(yearEnd, unallocatedRewardsCount);
    }
}