// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../policy/Policy.sol";
import "../../policy/PolicedUtils.sol";
import "../../utils/TimeUtils.sol";
import "../../currency/IECO.sol";
import "../monetary/RandomInflation.sol";

/** @title Inflation Root Hash Proposal
 * This implements a root hash proposal contract to
 * establish a merkle tree representing accounts and balances
 *
 * Merkle Tree serves as a way to fairly establish which addresses can claim the random inflation reward
 */
contract InflationRootHashProposal is PolicedUtils, TimeUtils {
    enum ChallengeStatus {
        Empty,
        Pending,
        Resolved
    }

    enum RootHashStatus {
        Pending,
        Rejected,
        Accepted
    }

    struct ChallengeResponse {
        address account;
        uint256 balance;
        uint256 sum;
    }

    struct InflationChallenge {
        bool initialized;
        uint256 challengeEnds;
        uint256 amountOfRequests;
        mapping(uint256 => ChallengeStatus) challengeStatus;
    }

    struct RootHashProposal {
        bool initialized;
        bytes32 rootHash;
        uint256 totalSum;
        uint256 amountOfAccounts;
        uint256 lastLiveChallenge;
        uint256 amountPendingChallenges;
        uint256 totalChallenges;
        uint256 stakedAmount;
        uint256 newChallengerSubmissionEnds;
        RootHashStatus status;
        mapping(address => InflationChallenge) challenges;
        mapping(uint256 => ChallengeResponse) challengeResponses;
        mapping(address => bool) claimed;
    }

    // the ECO token contract address
    IECO public immutable ecoToken;

    /** The root hash accepted for current generation, set as a final result */
    bytes32 public acceptedRootHash;

    /** The total cumulative sum of the accepted root hash proposal */
    uint256 public acceptedTotalSum;

    /** The total number of accounts in the merkle tree of the accepted root hash proposal */
    uint256 public acceptedAmountOfAccounts;

    /** proposer to proposal data structure. Stores all evaluated proposals */
    mapping(address => RootHashProposal) public rootHashProposals;

    /** Challenger charged with CHALLENGE_FEE ECO every time they challenge proposal */
    uint256 public constant CHALLENGE_FEE = 1000e18;

    /** Root hash proposer charged with PROPOSER_FEE ECO for the root hash submission */
    uint256 public constant PROPOSER_FEE = 100000e18;

    /** Initial amount of time given to challengers to submit challenges to new proposal */
    uint256 public constant CHALLENGING_TIME = 1 days;

    /** Amount of time given to challengers to contest a challenges to a proposal */
    uint256 public constant CONTESTING_TIME = 1 hours;

    /** The time period to collect fees after the root hash was accepted.
     */
    uint256 public constant FEE_COLLECTION_TIME = 180 days;

    /** The timestamp at which the fee collection phase ends and contract might be destructed.
     */
    uint256 public feeCollectionEnds;

    /** merkle tree verified against balances at block number
     */
    uint256 public blockNumber;

    /* Event to be emitted whenever a new root hash proposal submitted to the contract.
     */
    event RootHashPost(
        address indexed proposer,
        bytes32 indexed proposedRootHash,
        uint256 totalSum,
        uint256 amountOfAccounts
    );

    /* Event to be emitted whenever a new challenge to root hash submitted to the contract.
     */
    event RootHashChallengeIndexRequest(
        address indexed proposer,
        address challenger,
        uint256 indexed index
    );

    /* Event to be emitted whenever proposer successfully responded to a challenge
     */
    event ChallengeSuccessResponse(
        address indexed proposer,
        address challenger,
        address account,
        uint256 balance,
        uint256 sum,
        uint256 indexed index
    );

    /* Event to be emitted whenever a root hash proposal rejected.
     */
    event RootHashRejection(address indexed proposer);

    /* Event to be emitted whenever a missing account claim succeeded. Root hash is rejected.
     */
    event ChallengeMissingAccountSuccess(
        address indexed proposer,
        address challenger,
        address missingAccount,
        uint256 indexed index
    );

    /* Event to be emitted whenever a root hash proposal accepted.
     */
    event RootHashAcceptance(
        address indexed proposer,
        uint256 totalSum,
        uint256 amountOfAccounts
    );

    /* Event to be emitted whenever the configuration for the inflation root hash proposal contract is set
     */
    event ConfigureBlock(uint256 _blockNumber);

    modifier hashIsNotAcceptedYet() {
        require(
            acceptedRootHash == 0,
            "The root hash accepted, no more actions allowed"
        );
        _;
    }

    constructor(Policy _policy, IECO _ecoAddr) PolicedUtils(_policy) {
        require(
            address(_ecoAddr) != address(0),
            "do not set the _ecoAddr as the zero address"
        );
        ecoToken = IECO(_ecoAddr);
    }

    /** @notice Configure the inflation root hash proposal contract
     *  which is part of the random inflation mechanism
     *
     * @param _blockNumber block number to verify accounts balances against
     */
    function configure(uint256 _blockNumber) external {
        require(blockNumber == 0, "This instance has already been configured");

        blockNumber = _blockNumber;
        emit ConfigureBlock(_blockNumber);
    }

    /** @notice Allows to propose new root hash
     *  which is part of the random inflation mechanism
     *
     * @param _proposedRootHash a root hash of the merkle tree describing all the accounts
     * @param _totalSum total cumulative sum of all the balances in the merkle tree
     * @param _amountOfAccounts total amount of accounts in the tree
     */
    function proposeRootHash(
        bytes32 _proposedRootHash,
        uint256 _totalSum,
        uint256 _amountOfAccounts
    ) external hashIsNotAcceptedYet {
        require(_proposedRootHash != bytes32(0), "Root hash cannot be zero");
        require(_totalSum > 0, "Total sum cannot be zero");
        require(
            _amountOfAccounts > 0,
            "Hash must consist of at least 1 account"
        );

        RootHashProposal storage proposal = rootHashProposals[msg.sender];

        require(!proposal.initialized, "Root hash already proposed");

        proposal.initialized = true;
        proposal.rootHash = _proposedRootHash;
        proposal.totalSum = _totalSum;
        proposal.amountOfAccounts = _amountOfAccounts;
        proposal.newChallengerSubmissionEnds = getTime() + CHALLENGING_TIME;

        emit RootHashPost(
            msg.sender,
            _proposedRootHash,
            _totalSum,
            _amountOfAccounts
        );

        chargeFee(msg.sender, msg.sender, PROPOSER_FEE);
    }

    /** @notice Allows to challenge previously proposed root hash.
     *  Challenge requires proposer of the root hash submit proof of the account for requested index
     *
     *  @param _proposer  the roothash proposer address
     *  @param _index    index in the merkle tree of the account being challenged
     */
    function challengeRootHashRequestAccount(address _proposer, uint256 _index)
        external
        hashIsNotAcceptedYet
    {
        requireValidChallengeConstraints(_proposer, msg.sender, _index);
        RootHashProposal storage proposal = rootHashProposals[_proposer];

        InflationChallenge storage challenge = proposal.challenges[msg.sender];

        if (!challenge.initialized) {
            challenge.initialized = true;
            challenge.challengeEnds = getTime() + CHALLENGING_TIME;
            challenge.challengeStatus[_index] = ChallengeStatus.Pending;
        } else {
            require(
                challenge.challengeStatus[_index] == ChallengeStatus.Empty,
                "Index already challenged"
            );
            challenge.challengeStatus[_index] = ChallengeStatus.Pending;
        }
        emit RootHashChallengeIndexRequest(_proposer, msg.sender, _index);
        updateCounters(_proposer, msg.sender);

        chargeFee(msg.sender, _proposer, CHALLENGE_FEE);
    }

    /** @notice A special challenge, the challenger can claim that an account is missing
     *
     * @param _proposer         the roothash proposer address
     * @param _index        index in the merkle tree of the account being challenged
     * @param _account      address of the missing account
     */
    function claimMissingAccount(
        address _proposer,
        uint256 _index,
        address _account
    ) external hashIsNotAcceptedYet {
        requireValidChallengeConstraints(_proposer, msg.sender, _index);
        RootHashProposal storage proposal = rootHashProposals[_proposer];
        InflationChallenge storage challenge = proposal.challenges[msg.sender];

        require(
            ecoToken.getPastVotes(_account, blockNumber) > 0,
            "Missing account does not exist"
        );

        require(challenge.initialized, "Submit Index Request first");

        if (_index != 0) {
            require(
                challenge.challengeStatus[_index - 1] ==
                    ChallengeStatus.Resolved,
                "Left _index is not resolved"
            );
            require(
                proposal.challengeResponses[_index - 1].account < _account,
                "Missing account claim failed"
            );
        }
        if (_index != proposal.amountOfAccounts) {
            require(
                challenge.challengeStatus[_index] == ChallengeStatus.Resolved,
                "Right _index is not resolved"
            );
            require(
                _account < proposal.challengeResponses[_index].account,
                "Missing account claim failed"
            );
        }

        challenge.amountOfRequests += 1;

        emit ChallengeMissingAccountSuccess(
            _proposer,
            msg.sender,
            _account,
            _index
        );
        rejectRootHash(_proposer);
    }

    /** @notice Allows to proposer of the root hash respond to a challenge of specific index with proof details
     *
     *  @param _challenger       address of the submitter of the challenge
     *  @param _proof            the “other nodes” in the merkle tree.
     *  @param _account          address of an account of challenged index in the tree
     *  @param _claimedBalance   balance of an account of challenged index in the tree
     *  @param _sum              cumulative sum of an account of challenged index in the tree
     *  @param _index            index in the merkle tree being answered
     */
    function respondToChallenge(
        address _challenger,
        bytes32[] calldata _proof,
        address _account,
        uint256 _claimedBalance,
        uint256 _sum,
        uint256 _index
    ) external hashIsNotAcceptedYet {
        require(
            _claimedBalance > 0,
            "Accounts with zero balance not allowed in Merkle tree"
        );
        require(
            _account != address(0),
            "The zero address not allowed in Merkle tree"
        );

        RootHashProposal storage proposal = rootHashProposals[msg.sender];
        InflationChallenge storage challenge = proposal.challenges[_challenger];

        require(
            getTime() < challenge.challengeEnds,
            "Timeframe to respond to a challenge is over"
        );

        require(
            challenge.challengeStatus[_index] == ChallengeStatus.Pending,
            "There is no pending challenge for this index"
        );

        /* Since the merkle tree includes the index as the hash, it's impossible to give isomorphic answers,
         * so any attempt to answer with a different value than what was used before will fail the merkle check,
         * hence this doesn't care if it rewrites previous answer */
        ChallengeResponse storage indexChallenge = proposal.challengeResponses[
            _index
        ];
        indexChallenge.account = _account;
        indexChallenge.balance = _claimedBalance;
        indexChallenge.sum = _sum;

        require(
            ecoToken.getPastVotes(_account, blockNumber) == _claimedBalance,
            "Challenge response failed account balance check"
        );

        require(
            verifyMerkleProof(
                _proof,
                proposal.rootHash,
                keccak256(
                    abi.encodePacked(_account, _claimedBalance, _sum, _index)
                ),
                _index,
                proposal.amountOfAccounts
            ),
            "Challenge response failed merkle tree verification check"
        );

        // Ensure first account starts at 0 cumulative sum
        if (_index == 0) {
            require(_sum == 0, "cumulative sum does not starts from 0");
        } else {
            ChallengeResponse storage leftNeighborChallenge = proposal
                .challengeResponses[_index - 1];
            if (leftNeighborChallenge.balance != 0) {
                // Is left neighbor queried, and is it valid?
                require(
                    leftNeighborChallenge.sum + leftNeighborChallenge.balance ==
                        _sum,
                    "Left neighbor sum verification failed"
                );
                require(
                    leftNeighborChallenge.account < _account,
                    "Left neighbor order verification failed"
                );
            }
        }

        // Ensure final account matches total sum
        if (_index == proposal.amountOfAccounts - 1) {
            require(
                proposal.totalSum == _sum + _claimedBalance,
                "cumulative sum does not match total sum"
            );
        } else {
            ChallengeResponse storage rightNeighborChallenge = proposal
                .challengeResponses[_index + 1];
            // Is right neighbor queried, and is it valid?
            if (rightNeighborChallenge.balance != 0) {
                require(
                    _sum + _claimedBalance == rightNeighborChallenge.sum,
                    "Right neighbor sum verification failed"
                );
                require(
                    _account < rightNeighborChallenge.account,
                    "Right neighbor order verification failed"
                );
            }
        }

        emit ChallengeSuccessResponse(
            msg.sender,
            _challenger,
            _account,
            _claimedBalance,
            _sum,
            _index
        );

        challenge.challengeStatus[_index] = ChallengeStatus.Resolved;
        proposal.amountPendingChallenges -= 1;
        challenge.challengeEnds += CONTESTING_TIME;
    }

    /** @notice Checks root hash proposal. If time is out and there is unanswered challenges proposal is rejected. If time to submit
     *  new challenges is over and there is no unanswered challenges, root hash is accepted.
     *
     *  @param _proposer the roothash proposer address
     *
     */
    function checkRootHashStatus(address _proposer) external {
        RootHashProposal storage proposal = rootHashProposals[_proposer];

        if (
            acceptedRootHash == 0 &&
            getTime() > proposal.newChallengerSubmissionEnds &&
            getTime() > proposal.lastLiveChallenge
        ) {
            if (proposal.amountPendingChallenges == 0) {
                acceptRootHash(_proposer);
            } else {
                rejectRootHash(_proposer);
            }
        }

        if (
            acceptedRootHash != 0 && proposal.status == RootHashStatus.Pending
        ) {
            rejectRootHash(_proposer);
        }
    }

    /** @notice Verifies that the account specified is associated with the provided cumulative sum in the approved
     * Merkle tree for the current generation.
     *
     *  @param _who     address of the account attempting to claim
     *  @param _proof   the “other nodes” in the merkle tree.
     *  @param _sum     cumulative sum of a claiming account
     *  @param _index   index of the account
     */
    function verifyClaimSubmission(
        address _who,
        bytes32[] calldata _proof,
        uint256 _sum,
        uint256 _index
    ) external view returns (bool) {
        require(
            acceptedRootHash != 0,
            "Can't claim before root hash established"
        );
        uint256 balance = ecoToken.getPastVotes(_who, blockNumber);
        return
            verifyMerkleProof(
                _proof,
                acceptedRootHash,
                keccak256(abi.encodePacked(_who, balance, _sum, _index)),
                _index,
                acceptedAmountOfAccounts
            );
    }

    /** @notice Allows to claim fee paid as part of challenge or proposal submissions
     *
     *  @param _who        fee recipient
     *  @param _proposer   the roothash proposer address
     */
    function claimFeeFor(address _who, address _proposer) public {
        RootHashProposal storage proposal = rootHashProposals[_proposer];
        InflationChallenge storage challenge = proposal.challenges[_who];
        require(
            proposal.status != RootHashStatus.Pending,
            "Can't claim _fee on pending root hash proposal"
        );

        require(!proposal.claimed[_who], "fee already claimed");

        if (_who == _proposer) {
            require(
                proposal.status == RootHashStatus.Accepted ||
                    (proposal.status == RootHashStatus.Rejected &&
                        proposal.rootHash == acceptedRootHash &&
                        proposal.totalSum == acceptedTotalSum &&
                        proposal.amountOfAccounts == acceptedAmountOfAccounts),
                "proposer can't claim fee on not accepted hash"
            );
            require(
                ecoToken.transfer(_who, proposal.stakedAmount),
                "Transfer Failed"
            );
        } else {
            require(
                challenge.initialized &&
                    proposal.status == RootHashStatus.Rejected,
                "challenger may claim fee on rejected proposal only"
            );
            uint256 amount = challenge.amountOfRequests * CHALLENGE_FEE;
            amount =
                amount +
                (proposal.stakedAmount *
                    proposal.challenges[msg.sender].amountOfRequests) /
                proposal.totalChallenges;
            require(ecoToken.transfer(_who, amount), "Transfer Failed");
        }
        proposal.claimed[_who] = true;
    }

    /** @notice Allows to claim fee paid as part of challenge or proposal submissions
     *          on behalf of the caller (`msg.sender`).
     *
     *  @param _proposer   the roothash proposer address
     *
     */
    function claimFee(address _proposer) external {
        claimFeeFor(msg.sender, _proposer);
    }

    /** @notice Reclaims tokens on the inflation root hash proposal contract.
     *
     */
    function destruct() external {
        require(
            feeCollectionEnds != 0 && getTime() > feeCollectionEnds,
            "contract might be destructed after fee collection period is over"
        );
        require(
            ecoToken.transfer(
                address(policy),
                ecoToken.balanceOf(address(this))
            ),
            "Transfer Failed"
        );
    }

    /** @notice updates root hash proposal data structure to mark it rejected
     */
    function rejectRootHash(address _proposer) internal {
        rootHashProposals[_proposer].status = RootHashStatus.Rejected;
        emit RootHashRejection(_proposer);
    }

    /** @notice updates root hash proposal data structure  and contract state variables
     *  to mark root hash is accepted
     */
    function acceptRootHash(address _proposer) internal {
        RootHashProposal storage proposal = rootHashProposals[_proposer];

        proposal.status = RootHashStatus.Accepted;
        acceptedRootHash = proposal.rootHash;
        acceptedTotalSum = proposal.totalSum;
        acceptedAmountOfAccounts = proposal.amountOfAccounts;
        feeCollectionEnds = getTime() + FEE_COLLECTION_TIME;
        emit RootHashAcceptance(
            _proposer,
            proposal.totalSum,
            proposal.amountOfAccounts
        );
    }

    /**
     * @dev Returns true if a `_leaf` can be proved to be a part of a Merkle tree
     * defined by `_root`. For this, a `_proof` must be provided, containing
     * sibling hashes on the branch from the _leaf to the _root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     * (c) https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/cryptography/MerkleProof.sol
     */
    function verifyMerkleProof(
        bytes32[] memory _proof,
        bytes32 _root,
        bytes32 _leaf,
        uint256 _index,
        uint256 _numAccounts
    ) internal pure returns (bool) {
        // ensure that the proof conforms to the minimum possible tree height
        // and also that the number of accounts is small enough to fit in the claimed tree
        if (
            1 << (_proof.length - 1) >= _numAccounts ||
            1 << (_proof.length) < _numAccounts
        ) {
            return false;
        }

        bytes32 computedHash = _leaf;

        // checks for validity of proof elements and tree ordering
        for (uint256 i = 0; i < _proof.length; i++) {
            bytes32 proofElement = _proof[i];
            if ((_index >> i) & 1 == 1) {
                // Hash(current element of the _proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            } else {
                // Hash(current computed hash + current element of the _proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            }
        }

        if (computedHash != _root) {
            return false;
        }

        // xor to separate matching and non-matching elements of the bitmaps
        uint256 branchBitMap = _index ^ (_numAccounts - 1);

        // verifies that unused tree nodes are reperesnted by bytes32(0)
        for (uint256 i = _proof.length; i > 0; i--) {
            // check if this is traversing the right edge of the filled tree
            // _numAccounts indexes from 1 but _index does so from zero
            if ((branchBitMap >> (i - 1)) & 1 == 0) {
                // see if the index is in a left branch requiring a zero valued right branch
                if ((_index >> (i - 1)) & 1 == 0) {
                    if (_proof[i - 1] != bytes32(0)) {
                        return false;
                    }
                }
            } else {
                // the index is now in the middle of the tree, cannot check further
                break;
            }
        }

        // Check if the computed hash (_root) is equal to the provided _root
        return true;
    }

    /** @notice increment counter that's used to track amount of open challenges and the timelines
     */
    function updateCounters(address _proposer, address _challenger) internal {
        RootHashProposal storage proposal = rootHashProposals[_proposer];
        InflationChallenge storage challenge = proposal.challenges[_challenger];
        uint256 challengeEnds = challenge.challengeEnds;

        proposal.totalChallenges += 1;
        proposal.amountPendingChallenges += 1;
        challenge.amountOfRequests += 1;

        challenge.challengeEnds = challengeEnds + CONTESTING_TIME;
        challengeEnds += CONTESTING_TIME;

        if (proposal.lastLiveChallenge < challengeEnds) {
            proposal.lastLiveChallenge = challengeEnds;
        }
    }

    /** @notice charge sender with a fee while updating tracking stake counter
     */
    function chargeFee(
        address _submitter,
        address _proposer,
        uint256 _fee
    ) internal {
        require(
            ecoToken.transferFrom(_submitter, address(this), _fee),
            "Transfer Failed"
        );
        rootHashProposals[_proposer].stakedAmount += _fee;
    }

    function requireValidChallengeConstraints(
        address _proposer,
        address _challenger,
        uint256 _index
    ) internal view {
        RootHashProposal storage proposal = rootHashProposals[_proposer];

        require(
            _proposer != _challenger,
            "Root hash proposer can't challenge its own submission"
        );
        require(
            proposal.rootHash != bytes32(0),
            "There is no such hash proposal"
        );
        require(
            proposal.status == RootHashStatus.Pending,
            "The proposal is resolved"
        );
        require(
            proposal.amountOfAccounts > _index,
            "The index have to be within the range of claimed amount of accounts"
        );
        uint256 requestsByChallenger = proposal
            .challenges[_challenger]
            .amountOfRequests;
        if (requestsByChallenger > 2) {
            /* math explanation x - number of request, N - amount of accounts, log base 2
              condition  -- x < 2 * log( N ) + 2
                            2 ^ x < 2 ^ (2 * log( N ) + 2)
                            2 ^ (x - 2) < (2 ^ log( N )) ^ 2
                            2 ^ (x - 2) < N ^ 2
            */

            require(
                1 << (requestsByChallenger - 2) <=
                    (proposal.amountOfAccounts)**2,
                "Challenger reached maximum amount of allowed challenges"
            );
        }
        InflationChallenge storage challenge = proposal.challenges[_challenger];
        if (!challenge.initialized) {
            require(
                getTime() < proposal.newChallengerSubmissionEnds,
                "Time to submit new challenges is over"
            );
        } else {
            require(
                getTime() < challenge.challengeEnds,
                "Time to submit additional challenges is over"
            );
        }
    }
}