// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../policy/Policy.sol";
import "../../policy/PolicedUtils.sol";
import "../../currency/ECO.sol";
import "../../utils/TimeUtils.sol";
import "../../VDF/VDFVerifier.sol";
import "./InflationRootHashProposal.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/** @title RandomInflation
 *
 * This contract oversees the currency random inflation process and is spawned
 * on demand by the CurrencyTimer.
 */
contract RandomInflation is PolicedUtils, TimeUtils {
    /** The time period over which inflation reward is spread to prevent
     *  flooding by spreading out the new tokens.
     */
    uint256 public constant CLAIM_PERIOD = 28 days;

    /** The bound on how much more than the uint256 previous blockhash can a submitted prime be
     */
    uint256 public constant PRIME_BOUND = 1000;

    /** The number of checks to determine the prime seed to start the VDF
     */
    uint256 public constant MILLER_RABIN_ROUNDS = 25;

    /** The per-participant reward amount in basic unit of 10^{-18} ECO (weico) selected by the voting process.
     */
    uint256 public reward;

    /** The computed number of reward recipients (inflation/reward) in basic unit of 10^{-18} ECO (weico).
     */
    uint256 public numRecipients;

    /** The block number to use as the reference point when checking if an account holds currency.
     */
    uint256 public blockNumber;

    /** The initial value used for VDF to compute random seed. This is set by a
     * call to `commitEntropyVDFSeed()` after the vote results are computed.
     */
    uint256 public entropyVDFSeed;

    /** The random seed used to determine the inflation reward recipients.
     */
    bytes32 public seed;

    /** Difficulty of VDF for random process. This is left mutable for easier governance */
    uint256 public randomVDFDifficulty;

    /** Timestamp to start claim period from */
    uint256 public claimPeriodStarts;

    /** A mapping recording which claim numbers have been claimed.
     */
    mapping(uint256 => uint256) public claimed;

    // the max bits that can be stored in a uint256 number
    uint256 public constant BITMAP_MAXIMUM = 256;

    // A counter of outstanding unclaimed rewards
    uint256 public unclaimedRewards;

    /** The base VDFVerifier implementation */
    /** The VDF is used to set the random seed for inflation */
    VDFVerifier public vdfVerifier;

    /** The base InflationRootHashProposal implementation */
    /** The inflation root hash proposal that's used to verify inflation claims */
    InflationRootHashProposal public inflationRootHashProposal;

    // the ECO token address
    ECO public immutable ecoToken;

    /** A mapping of primals asssociated to the block they were commited in
     */
    mapping(uint256 => uint256) public primals;

    /** Emitted when inflation starts.
     */
    event InflationStart(
        VDFVerifier indexed vdfVerifier,
        InflationRootHashProposal indexed inflationRootHashProposal,
        uint256 claimPeriodStarts
    );

    /** Fired when a user claims their reward */
    event Claim(address indexed who, uint256 sequence);

    /** Emitted when the VDF seed used to provide entropy has been committed to the contract.
     */
    event EntropyVDFSeedCommit(uint256 seed);

    /** Emitted when the entropy seed is revealed by provable VDF computation.
     */
    event EntropySeedReveal(bytes32 seed);

    constructor(
        Policy _policy,
        VDFVerifier _vdfVerifierImpl,
        uint256 _randomDifficulty,
        InflationRootHashProposal _inflationRootHashProposalImpl,
        ECO _ecoAddr
    ) PolicedUtils(_policy) {
        require(
            address(_vdfVerifierImpl) != address(0),
            "do not set the _vdfVerifierImpl as the zero address"
        );
        require(
            _randomDifficulty > 0,
            "do not set the _randomDifficulty to zero"
        );
        require(
            address(_inflationRootHashProposalImpl) != address(0),
            "do not set the _inflationRootHashProposalImpl as the zero address"
        );
        require(
            address(_ecoAddr) != address(0),
            "do not set the _ecoAddr as the zero address"
        );
        vdfVerifier = _vdfVerifierImpl;
        randomVDFDifficulty = _randomDifficulty;
        inflationRootHashProposal = _inflationRootHashProposalImpl;
        ecoToken = _ecoAddr;
    }

    /** Clean up the inflation contract.
     *
     * Can only be called after all rewards
     * have been claimed.
     */
    function destruct() external {
        require(
            seed != 0 || getTime() > claimPeriodStarts + CLAIM_PERIOD,
            "Entropy not set, wait until end of full claim period to abort"
        );

        // consider putting a long scale timeout to allow for late stage aborts
        // unclaimedRewards is guaranteed to be set before the seed
        require(
            seed == 0 || unclaimedRewards == 0,
            "All rewards must be claimed prior to destruct"
        );

        require(
            ecoToken.transfer(
                address(policy),
                ecoToken.balanceOf(address(this))
            ),
            "Transfer Failed"
        );
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
        blockNumber = block.number - 1;

        vdfVerifier = VDFVerifier(RandomInflation(_self).vdfVerifier().clone());
        randomVDFDifficulty = RandomInflation(_self).randomVDFDifficulty();

        inflationRootHashProposal = InflationRootHashProposal(
            RandomInflation(_self).inflationRootHashProposal().clone()
        );
        inflationRootHashProposal.configure(blockNumber);
    }

    /** Commit to a VDF seed for inflation distribution entropy.
     *
     * Can only be called after results are computed and the registration
     * period has ended. The VDF seed can only be set once, and must be computed and
     * set in the previous block.
     *
     * @param _primal the primal to use, must have been committed to in a previous block
     */
    function commitEntropyVDFSeed(uint256 _primal) external {
        require(entropyVDFSeed == 0, "The VDF seed has already been set");
        uint256 _primalCommitBlock = primals[_primal];
        require(
            _primalCommitBlock > 0 && _primalCommitBlock < block.number,
            "primal block invalid"
        );
        require(
            vdfVerifier.isProbablePrime(_primal, MILLER_RABIN_ROUNDS),
            "input failed primality test"
        );

        entropyVDFSeed = _primal;

        emit EntropyVDFSeedCommit(entropyVDFSeed);
    }

    /** Sets a primal in storage associated to the commiting block
     * A user first adds a primal to the contract, then they can test
     * its primality in a subsequent block
     *
     * @param _primal uint256 the prime number to commit for the block
     */
    function setPrimal(uint256 _primal) external {
        uint256 _bhash = uint256(blockhash(block.number - 1));
        require(
            _primal > _bhash && _primal - _bhash < PRIME_BOUND,
            "suggested prime is out of bounds"
        );

        primals[_primal] = block.number;
    }

    /** Starts the inflation payout period. Validates that the contract is sufficiently
     * capitalized with Eco to meet the inflation demand. Can only be called once, ie by CurrencyTimer
     *
     * @param _numRecipients the number of recipients that will get rewards
     * @param _reward the amount of ECO to be given as reward to each recipient
     */
    function startInflation(uint256 _numRecipients, uint256 _reward) external {
        require(
            _numRecipients > 0 && _reward > 0,
            "Contract must have rewards"
        );
        require(
            ecoToken.balanceOf(address(this)) >= _numRecipients * _reward,
            "The contract must have a token balance at least the total rewards"
        );
        require(numRecipients == 0, "The sale can only be started once");

        /* This sets the amount of recipients we will iterate through later, it is important
        this number stay reasonable from gas consumption standpoint */
        numRecipients = _numRecipients;
        unclaimedRewards = _numRecipients;
        reward = _reward;
        claimPeriodStarts = getTime();
        emit InflationStart(
            vdfVerifier,
            inflationRootHashProposal,
            claimPeriodStarts
        );
    }

    /** Submit a solution for VDF for randomness.
     *
     * @param _y The computed VDF output. Must be proven with the VDF
     *           verification contract.
     */
    function submitEntropyVDF(bytes calldata _y) external {
        require(entropyVDFSeed != 0, "Initial seed must be set");
        require(seed == bytes32(0), "Can only submit once");

        require(
            vdfVerifier.isVerified(entropyVDFSeed, randomVDFDifficulty, _y),
            "The VDF output value must be verified by the VDF verification contract"
        );

        seed = keccak256(_y);

        emit EntropySeedReveal(seed);
    }

    /** Claim an inflation reward on behalf of some address.
     *
     * The reward is sent directly to the address that has claim to the reward, but the
     * gas cost is paid by the caller.
     *
     * For example, an exchange might stake using funds deposited into its
     * contract.
     *
     * @param _who The address to claim a reward on behalf of.
     * @param _sequence The reward sequence number to determine if the address
     *                  gets paid.
     * @param _proof the “other nodes” in the Merkle tree
     * @param _sum cumulative sum of all account ECO votes before this node
     * @param _index the index of the `who` address in the Merkle tree
     */
    function claimFor(
        address _who,
        uint256 _sequence,
        bytes32[] memory _proof,
        uint256 _sum,
        uint256 _index
    ) public {
        require(seed != bytes32(0), "Must prove VDF before claims can be paid");
        require(
            _sequence < numRecipients,
            "The provided sequence number must be within the set of recipients"
        );
        require(
            getTime() >
                claimPeriodStarts + (_sequence * CLAIM_PERIOD) / numRecipients,
            "A claim can only be made after enough time has passed"
        );
        require(
            claimed[_sequence / BITMAP_MAXIMUM] &
                (1 << (_sequence % BITMAP_MAXIMUM)) ==
                0,
            "A claim can only be made if it has not already been made"
        );

        require(
            inflationRootHashProposal.acceptedRootHash() != 0,
            "A claim can only be made after root hash for this generation was accepted"
        );

        require(
            inflationRootHashProposal.verifyClaimSubmission(
                _who,
                _proof,
                _sum,
                _index
            ),
            "A claim submission failed root hash verification"
        );

        claimed[_sequence / BITMAP_MAXIMUM] +=
            1 <<
            (_sequence % BITMAP_MAXIMUM);
        unclaimedRewards--;

        uint256 claimable = uint256(
            keccak256(abi.encodePacked(seed, _sequence))
        ) % inflationRootHashProposal.acceptedTotalSum();

        require(
            claimable < ecoToken.getPastVotes(_who, blockNumber) + _sum,
            "The provided address cannot claim this reward"
        );
        require(
            claimable >= _sum,
            "The provided address cannot claim this reward"
        );

        require(ecoToken.transfer(_who, reward), "Transfer Failed");

        emit Claim(_who, _sequence);
    }

    /** Claim an inflation reward for yourself.
     *
     * You need to know your claim number's place in the order.
     *
     * @param _sequence Your claim number's place in the order.
     */
    function claim(
        uint256 _sequence,
        bytes32[] calldata _proof,
        uint256 _sum,
        uint256 _index
    ) external {
        claimFor(msg.sender, _sequence, _proof, _sum, _index);
    }
}