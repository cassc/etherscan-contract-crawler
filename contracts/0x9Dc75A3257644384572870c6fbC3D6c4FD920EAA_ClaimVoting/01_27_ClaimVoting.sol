// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./libraries/DecimalsConverter.sol";

import "./interfaces/IContractsRegistry.sol";
import "./interfaces/helpers/IPriceFeed.sol";
import "./interfaces/IClaimVoting.sol";
import "./interfaces/IPolicyBookRegistry.sol";
import "./interfaces/IReputationSystem.sol";
import "./interfaces/IReinsurancePool.sol";
import "./interfaces/IPolicyBook.sol";
import "./interfaces/IStkBMIStaking.sol";

import "./interfaces/tokens/IVBMI.sol";

import "./abstract/AbstractDependant.sol";

import "./Globals.sol";

contract ClaimVoting is IClaimVoting, Initializable, AbstractDependant {
    using SafeMath for uint256;
    using Math for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    IPriceFeed public priceFeed;

    IERC20 public bmiToken;
    IReinsurancePool public reinsurancePool;
    IVBMI public vBMI;
    IClaimingRegistry public claimingRegistry;
    IPolicyBookRegistry public policyBookRegistry;
    IReputationSystem public reputationSystem;

    uint256 public stblDecimals;

    // claim index -> info
    mapping(uint256 => VotingResult) internal _votings;

    // voter -> claim indexes
    mapping(address => EnumerableSet.UintSet) internal _myNotReceivedVotes;

    // voter -> voting indexes
    mapping(address => EnumerableSet.UintSet) internal _myVotes;

    // voter -> claim index -> vote index
    mapping(address => mapping(uint256 => uint256)) internal _allVotesToIndex;

    // vote index -> voting instance
    mapping(uint256 => VotingInst) internal _allVotesByIndexInst;

    EnumerableSet.UintSet internal _allVotesIndexes;

    uint256 private _voteIndex;

    IStkBMIStaking public stkBMIStaking;

    // vote index -> results of calculation
    mapping(uint256 => VotesUpdatesInfo) public override voteResults;

    event AnonymouslyVoted(uint256 claimIndex);
    event VoteExposed(uint256 claimIndex, address voter, uint256 suggestedClaimAmount);
    event RewardsForClaimCalculationSent(address calculator, uint256 bmiAmount);
    event ClaimCalculated(uint256 claimIndex, address calculator);

    modifier onlyPolicyBook() {
        require(policyBookRegistry.isPolicyBook(msg.sender), "CV: Not a PolicyBook");
        _;
    }

    modifier onlyClaimingRegistry() {
        require(msg.sender == address(claimingRegistry), "CV: Not ClaimingRegistry");
        _;
    }

    function _isVoteAwaitingReception(uint256 index) internal view returns (bool) {
        uint256 claimIndex = _allVotesByIndexInst[index].claimIndex;

        return
            _allVotesByIndexInst[index].status == VoteStatus.EXPOSED_PENDING &&
            !claimingRegistry.isClaimPending(claimIndex);
    }

    function _isVoteAwaitingExposure(uint256 index) internal view returns (bool) {
        uint256 claimIndex = _allVotesByIndexInst[index].claimIndex;

        return (_allVotesByIndexInst[index].status == VoteStatus.ANONYMOUS_PENDING &&
            claimingRegistry.isClaimExposablyVotable(claimIndex));
    }

    function _isVoteExpired(uint256 index) internal view returns (bool) {
        uint256 claimIndex = _allVotesByIndexInst[index].claimIndex;

        return (_allVotesByIndexInst[index].status == VoteStatus.ANONYMOUS_PENDING &&
            !claimingRegistry.isClaimVotable(claimIndex));
    }

    function isToReceive(uint256 claimIndex, address user) external view override returns (bool) {
        return
            _myNotReceivedVotes[user].contains(claimIndex) &&
            !claimingRegistry.isClaimPending(claimIndex);
    }

    function __ClaimVoting_init() external initializer {
        _voteIndex = 1;
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        priceFeed = IPriceFeed(_contractsRegistry.getPriceFeedContract());
        claimingRegistry = IClaimingRegistry(_contractsRegistry.getClaimingRegistryContract());
        policyBookRegistry = IPolicyBookRegistry(
            _contractsRegistry.getPolicyBookRegistryContract()
        );
        reputationSystem = IReputationSystem(_contractsRegistry.getReputationSystemContract());
        bmiToken = IERC20(_contractsRegistry.getBMIContract());
        stkBMIStaking = IStkBMIStaking(_contractsRegistry.getStkBMIStakingContract());

        stblDecimals = ERC20(_contractsRegistry.getUSDTContract()).decimals();
    }

    /// @notice this function needs user's BMI approval of this address (check policybook)
    function initializeVoting(
        address claimer,
        string calldata evidenceURI,
        uint256 coverTokens,
        bool appeal
    ) external override onlyPolicyBook {
        require(coverTokens > 0, "CV: Claimer has no coverage");

        // this checks claim duplicate && appeal logic
        uint256 claimIndex =
            claimingRegistry.submitClaim(claimer, msg.sender, evidenceURI, coverTokens, appeal);

        uint256 onePercentInBMIToLock =
            priceFeed.howManyBMIsInUSDT(
                DecimalsConverter.convertFrom18(coverTokens.div(100), stblDecimals)
            );

        bmiToken.transferFrom(claimer, address(this), onePercentInBMIToLock); // needed approval

        IPolicyBook.PolicyHolder memory policyHolder = IPolicyBook(msg.sender).userStats(claimer);
        uint256 reinsuranceTokensAmount = policyHolder.reinsurancePrice;
        reinsuranceTokensAmount = Math.min(reinsuranceTokensAmount, coverTokens.div(100));

        _votings[claimIndex].withdrawalAmount = coverTokens;
        _votings[claimIndex].lockedBMIAmount = onePercentInBMIToLock;
        _votings[claimIndex].reinsuranceTokensAmount = reinsuranceTokensAmount;
    }

    /// @dev check in StkBMIStaking when withdrawing, if true -> can withdraw
    /// @dev Voters can unstake stkBMI only when there are no voted Claims
    function canUnstake(address user) external view override returns (bool) {
        return _myNotReceivedVotes[user].length() == 0;
    }

    /// @dev check if no vote or vote pending reception, if true -> can vote
    /// @dev Voters can vote on other Claims only when they updated their reputation and received outcomes for all Resolved Claims.
    /// @dev _myNotReceivedVotes represent list of vote pending reception
    function canVote(address user) public view override returns (bool) {
        for (uint256 i = 0; i < _myNotReceivedVotes[user].length(); i++) {
            uint256 voteIndex = _allVotesToIndex[user][_myNotReceivedVotes[user].at(i)];
            if (_isVoteAwaitingReception(voteIndex) || _isVoteExpired(voteIndex)) {
                return false;
            }
        }
        return true;
    }

    function votingInfo(uint256 claimIndex)
        external
        view
        override
        returns (
            uint256 countVoteOnClaim,
            uint256 lockedBMIAmount,
            uint256 votedYesPercentage
        )
    {
        countVoteOnClaim = _votings[claimIndex].voteIndexes.length();
        lockedBMIAmount = _votings[claimIndex].lockedBMIAmount;
        votedYesPercentage = _votings[claimIndex].votedYesPercentage;
    }

    function countVotes(address user) external view override returns (uint256) {
        return _myVotes[user].length();
    }

    function countNotReceivedVotes(address user) external view override returns (uint256) {
        return _myNotReceivedVotes[user].length();
    }

    function voteIndex(uint256 claimIndex, address user) external view returns (uint256) {
        return _allVotesToIndex[user][claimIndex];
    }

    function getVotingPower(uint256 index) external view returns (uint256) {
        return
            _allVotesByIndexInst[index].voterReputation.mul(
                _allVotesByIndexInst[index].stakedStkBMIAmount
            );
    }

    function voteStatus(uint256 index) public view override returns (VoteStatus) {
        require(_allVotesIndexes.contains(index), "CV: Vote doesn't exist");

        if (_isVoteAwaitingReception(index)) {
            return VoteStatus.AWAITING_RECEPTION;
        } else if (_isVoteAwaitingExposure(index)) {
            return VoteStatus.AWAITING_EXPOSURE;
        } else if (_isVoteExpired(index)) {
            return VoteStatus.EXPIRED;
        }

        return _allVotesByIndexInst[index].status;
    }

    /// @dev use with claimingRegistry.countPendingClaims()
    function whatCanIVoteFor(uint256 offset, uint256 limit)
        external
        view
        override
        returns (uint256 _claimsCount, PublicClaimInfo[] memory _votablesInfo)
    {
        uint256 to = (offset.add(limit)).min(claimingRegistry.countPendingClaims()).max(offset);
        bool trustedVoter = reputationSystem.isTrustedVoter(msg.sender);

        _claimsCount = 0;

        _votablesInfo = new PublicClaimInfo[](to - offset);

        for (uint256 i = offset; i < to; i++) {
            uint256 index = claimingRegistry.pendingClaimIndexAt(i);

            if (
                _allVotesToIndex[msg.sender][index] == 0 &&
                claimingRegistry.claimOwner(index) != msg.sender &&
                claimingRegistry.isClaimAnonymouslyVotable(index) &&
                (!claimingRegistry.isClaimAppeal(index) || trustedVoter)
            ) {
                IClaimingRegistry.ClaimInfo memory claimInfo = claimingRegistry.claimInfo(index);

                _votablesInfo[_claimsCount].claimIndex = index;
                _votablesInfo[_claimsCount].claimer = claimInfo.claimer;
                _votablesInfo[_claimsCount].policyBookAddress = claimInfo.policyBookAddress;
                _votablesInfo[_claimsCount].evidenceURI = claimInfo.evidenceURI;
                _votablesInfo[_claimsCount].appeal = claimInfo.appeal;
                _votablesInfo[_claimsCount].claimAmount = claimInfo.claimAmount;
                _votablesInfo[_claimsCount].time = claimInfo.dateSubmitted;

                _votablesInfo[_claimsCount].time = _votablesInfo[_claimsCount]
                    .time
                    .add(claimingRegistry.anonymousVotingDuration(index))
                    .sub(block.timestamp);

                _claimsCount++;
            }
        }
    }

    /// @dev use with claimingRegistry.countClaims() if listOption == ALL
    /// @dev use with claimingRegistry.countPolicyClaimerClaims() if listOption == MINE
    function listClaims(
        uint256 offset,
        uint256 limit,
        ListOption listOption
    ) external view override returns (AllClaimInfo[] memory _claimsInfo) {
        uint256 count;
        if (listOption == ListOption.ALL) {
            count = claimingRegistry.countClaims();
        } else if (listOption == ListOption.MINE) {
            count = claimingRegistry.countPolicyClaimerClaims(msg.sender);
        }

        uint256 to = (offset.add(limit)).min(count).max(offset);

        _claimsInfo = new AllClaimInfo[](to - offset);

        for (uint256 i = offset; i < to; i++) {
            uint256 index;
            if (listOption == ListOption.ALL) {
                index = claimingRegistry.claimIndexAt(i);
            } else if (listOption == ListOption.MINE) {
                index = claimingRegistry.claimOfOwnerIndexAt(msg.sender, i);
            }

            IClaimingRegistry.ClaimInfo memory claimInfo = claimingRegistry.claimInfo(index);

            _claimsInfo[i - offset].publicClaimInfo.claimIndex = index;
            _claimsInfo[i - offset].publicClaimInfo.claimer = claimInfo.claimer;
            _claimsInfo[i - offset].publicClaimInfo.policyBookAddress = claimInfo
                .policyBookAddress;
            _claimsInfo[i - offset].publicClaimInfo.evidenceURI = claimInfo.evidenceURI;
            _claimsInfo[i - offset].publicClaimInfo.appeal = claimInfo.appeal;
            _claimsInfo[i - offset].publicClaimInfo.claimAmount = claimInfo.claimAmount;
            _claimsInfo[i - offset].publicClaimInfo.time = claimInfo.dateSubmitted;

            _claimsInfo[i - offset].finalVerdict = claimInfo.status;

            if (_claimsInfo[i - offset].finalVerdict == IClaimingRegistry.ClaimStatus.ACCEPTED) {
                _claimsInfo[i - offset].finalClaimAmount = _votings[index]
                    .votedAverageWithdrawalAmount;
            }

            if (claimingRegistry.canClaimBeCalculatedByAnyone(index)) {
                _claimsInfo[i - offset].bmiCalculationReward = claimingRegistry
                    .getBMIRewardForCalculation(index);
            }
        }
    }

    /// @dev use with countNotReceivedVotes()
    function myVotes(uint256 offset, uint256 limit)
        external
        view
        override
        returns (MyVoteInfo[] memory _myVotesInfo)
    {
        uint256 to = (offset.add(limit)).min(_myVotes[msg.sender].length()).max(offset);

        _myVotesInfo = new MyVoteInfo[](to - offset);

        for (uint256 i = offset; i < to; i++) {
            uint256 claimIndex = _myNotReceivedVotes[msg.sender].at(i);
            uint256 voteIndex = _allVotesToIndex[msg.sender][claimIndex];

            IClaimingRegistry.ClaimInfo memory claimInfo = claimingRegistry.claimInfo(claimIndex);

            _myVotesInfo[i - offset].allClaimInfo.publicClaimInfo.claimIndex = claimIndex;
            _myVotesInfo[i - offset].allClaimInfo.publicClaimInfo.claimer = claimInfo.claimer;
            _myVotesInfo[i - offset].allClaimInfo.publicClaimInfo.policyBookAddress = claimInfo
                .policyBookAddress;
            _myVotesInfo[i - offset].allClaimInfo.publicClaimInfo.evidenceURI = claimInfo
                .evidenceURI;
            _myVotesInfo[i - offset].allClaimInfo.publicClaimInfo.appeal = claimInfo.appeal;
            _myVotesInfo[i - offset].allClaimInfo.publicClaimInfo.claimAmount = claimInfo
                .claimAmount;
            _myVotesInfo[i - offset].allClaimInfo.publicClaimInfo.time = claimInfo.dateSubmitted;

            _myVotesInfo[i - offset].allClaimInfo.finalVerdict = claimInfo.status;

            if (
                _myVotesInfo[i - offset].allClaimInfo.finalVerdict ==
                IClaimingRegistry.ClaimStatus.ACCEPTED
            ) {
                _myVotesInfo[i - offset].allClaimInfo.finalClaimAmount = _votings[claimIndex]
                    .votedAverageWithdrawalAmount;
            }

            _myVotesInfo[i - offset].suggestedAmount = _allVotesByIndexInst[voteIndex]
                .suggestedAmount;
            _myVotesInfo[i - offset].status = voteStatus(voteIndex);

            if (_myVotesInfo[i - offset].status == VoteStatus.ANONYMOUS_PENDING) {
                _myVotesInfo[i - offset].time = claimInfo
                    .dateSubmitted
                    .add(claimingRegistry.anonymousVotingDuration(claimIndex))
                    .sub(block.timestamp);
            } else if (_myVotesInfo[i - offset].status == VoteStatus.AWAITING_EXPOSURE) {
                _myVotesInfo[i - offset].encryptedVote = _allVotesByIndexInst[voteIndex]
                    .encryptedVote;
                _myVotesInfo[i - offset].time = claimInfo
                    .dateSubmitted
                    .add(claimingRegistry.votingDuration(claimIndex))
                    .sub(block.timestamp);
            }
        }
    }

    // filter on display is made on FE
    // if the claim is calculated and the vote is received or if the claim is EXPIRED, it will not display reward
    // as reward is calculated on lockedBMIAmount and actual reputation it will not be accurate
    function myVoteUpdate(uint256 claimIndex)
        external
        view
        override
        returns (VotesUpdatesInfo memory _myVotesUpdatesInfo)
    {
        uint256 voteIndex = _allVotesToIndex[msg.sender][claimIndex];
        uint256 oldReputation = reputationSystem.reputation(msg.sender);

        uint256 stblAmount;
        uint256 bmiAmount;
        uint256 newReputation;
        uint256 bmiPenaltyAmount;

        if (_isVoteExpired(voteIndex)) {
            _myVotesUpdatesInfo.stakeChange = int256(
                _allVotesByIndexInst[voteIndex].stakedStkBMIAmount
            );
        } else if (_isVoteAwaitingReception(voteIndex)) {
            if (
                _votings[claimIndex].votedYesPercentage >= PERCENTAGE_50 &&
                _allVotesByIndexInst[_allVotesToIndex[msg.sender][claimIndex]].suggestedAmount > 0
            ) {
                (stblAmount, bmiAmount, newReputation) = _calculateMajorityYesVote(
                    claimIndex,
                    msg.sender,
                    oldReputation
                );

                _myVotesUpdatesInfo.reputationChange += int256(newReputation.sub(oldReputation));
            } else if (
                _votings[claimIndex].votedYesPercentage < PERCENTAGE_50 &&
                _allVotesByIndexInst[_allVotesToIndex[msg.sender][claimIndex]].suggestedAmount == 0
            ) {
                (bmiAmount, newReputation) = _calculateMajorityNoVote(
                    claimIndex,
                    msg.sender,
                    oldReputation
                );

                _myVotesUpdatesInfo.reputationChange += int256(newReputation.sub(oldReputation));
            } else {
                (bmiPenaltyAmount, newReputation) = _calculateMinorityVote(
                    claimIndex,
                    msg.sender,
                    oldReputation
                );

                _myVotesUpdatesInfo.reputationChange -= int256(oldReputation.sub(newReputation));
            }
            _myVotesUpdatesInfo.stblReward = stblAmount;
            _myVotesUpdatesInfo.bmiReward = bmiAmount;
            _myVotesUpdatesInfo.stakeChange = int256(bmiPenaltyAmount);
        }
    }

    function _calculateAverages(
        uint256 claimIndex,
        uint256 stakedStkBMI,
        uint256 suggestedClaimAmount,
        uint256 reputationWithPrecision,
        bool votedFor
    ) internal {
        VotingResult storage info = _votings[claimIndex];

        if (votedFor) {
            uint256 votedPower = info.votedYesStakedStkBMIAmountWithReputation;
            uint256 voterPower = stakedStkBMI.mul(reputationWithPrecision);
            uint256 totalPower = votedPower.add(voterPower);

            uint256 votedSuggestedPrice = info.votedAverageWithdrawalAmount.mul(votedPower);
            uint256 voterSuggestedPrice = suggestedClaimAmount.mul(voterPower);

            info.votedAverageWithdrawalAmount = votedSuggestedPrice.add(voterSuggestedPrice).div(
                totalPower
            );

            info.votedYesStakedStkBMIAmountWithReputation = totalPower;
        } else {
            info.votedNoStakedStkBMIAmountWithReputation = info
                .votedNoStakedStkBMIAmountWithReputation
                .add(stakedStkBMI.mul(reputationWithPrecision));
        }

        info.allVotedStakedStkBMIAmount = info.allVotedStakedStkBMIAmount.add(stakedStkBMI);
    }

    function _modifyExposedVote(
        address voter,
        uint256 claimIndex,
        uint256 suggestedClaimAmount,
        bool accept,
        bool isConfirmed
    ) internal {
        uint256 index = _allVotesToIndex[voter][claimIndex];

        _allVotesByIndexInst[index].finalHash = 0;
        delete _allVotesByIndexInst[index].encryptedVote;

        if (isConfirmed) {
            _allVotesByIndexInst[index].suggestedAmount = suggestedClaimAmount;
            _allVotesByIndexInst[index].accept = accept;

            _allVotesByIndexInst[index].status = VoteStatus.EXPOSED_PENDING;
        } else {
            _votings[claimIndex].voteIndexes.remove(index);
            _myNotReceivedVotes[voter].remove(claimIndex);
            _allVotesByIndexInst[index].status = VoteStatus.REJECTED;
        }
    }

    function _addAnonymousVote(
        address voter,
        uint256 claimIndex,
        bytes32 finalHash,
        string memory encryptedVote,
        uint256 stakedStkBMI
    ) internal {
        _myVotes[voter].add(_voteIndex);
        _myNotReceivedVotes[voter].add(claimIndex);

        _allVotesByIndexInst[_voteIndex].claimIndex = claimIndex;
        _allVotesByIndexInst[_voteIndex].finalHash = finalHash;
        _allVotesByIndexInst[_voteIndex].encryptedVote = encryptedVote;
        _allVotesByIndexInst[_voteIndex].voter = voter;
        _allVotesByIndexInst[_voteIndex].voterReputation = reputationSystem.reputation(voter);
        _allVotesByIndexInst[_voteIndex].stakedStkBMIAmount = stakedStkBMI;
        // No need to set default ANONYMOUS_PENDING status

        _allVotesToIndex[voter][claimIndex] = _voteIndex;
        _allVotesIndexes.add(_voteIndex);

        _votings[claimIndex].voteIndexes.add(_voteIndex);

        _voteIndex++;
    }

    function anonymouslyVoteBatch(
        uint256[] calldata claimIndexes,
        bytes32[] calldata finalHashes,
        string[] calldata encryptedVotes
    ) external override {
        require(canVote(msg.sender), "CV: Awaiting votes");
        require(
            claimIndexes.length == finalHashes.length &&
                claimIndexes.length == encryptedVotes.length,
            "CV: Length mismatches"
        );

        uint256 stakedStkBMI = stkBMIStaking.stakedStkBMI(msg.sender);
        require(stakedStkBMI > 0, "CV: 0 staked StkBMI");

        for (uint256 i = 0; i < claimIndexes.length; i++) {
            uint256 claimIndex = claimIndexes[i];

            require(
                claimingRegistry.isClaimAnonymouslyVotable(claimIndex),
                "CV: Anonymous voting is over"
            );
            require(
                claimingRegistry.claimOwner(claimIndex) != msg.sender,
                "CV: Voter is the claimer"
            );
            require(
                !claimingRegistry.isClaimAppeal(claimIndex) ||
                    reputationSystem.isTrustedVoter(msg.sender),
                "CV: Not a trusted voter"
            );
            require(
                _allVotesToIndex[msg.sender][claimIndex] == 0,
                "CV: Already voted for this claim"
            );

            _addAnonymousVote(
                msg.sender,
                claimIndex,
                finalHashes[i],
                encryptedVotes[i],
                stakedStkBMI
            );

            emit AnonymouslyVoted(claimIndex);
        }
    }

    function exposeVoteBatch(
        uint256[] calldata claimIndexes,
        uint256[] calldata suggestedClaimAmounts,
        bytes32[] calldata hashedSignaturesOfClaims,
        bool[] calldata isConfirmed
    ) external override {
        require(
            claimIndexes.length == suggestedClaimAmounts.length &&
                claimIndexes.length == hashedSignaturesOfClaims.length &&
                claimIndexes.length == isConfirmed.length,
            "CV: Length mismatches"
        );

        for (uint256 i = 0; i < claimIndexes.length; i++) {
            uint256 claimIndex = claimIndexes[i];
            uint256 voteIndex = _allVotesToIndex[msg.sender][claimIndex];

            require(_allVotesIndexes.contains(voteIndex), "CV: Vote doesn't exist");
            require(_isVoteAwaitingExposure(voteIndex), "CV: Vote is not awaiting");

            bytes32 finalHash =
                keccak256(
                    abi.encodePacked(
                        hashedSignaturesOfClaims[i],
                        _allVotesByIndexInst[voteIndex].encryptedVote,
                        suggestedClaimAmounts[i]
                    )
                );

            require(_allVotesByIndexInst[voteIndex].finalHash == finalHash, "CV: Data mismatches");
            require(
                _votings[claimIndex].withdrawalAmount >= suggestedClaimAmounts[i],
                "CV: Amount exceeds coverage"
            );

            bool voteFor = (suggestedClaimAmounts[i] > 0);

            if (isConfirmed[i]) {
                _calculateAverages(
                    claimIndex,
                    _allVotesByIndexInst[voteIndex].stakedStkBMIAmount,
                    suggestedClaimAmounts[i],
                    _allVotesByIndexInst[voteIndex].voterReputation,
                    voteFor
                );
            }

            _modifyExposedVote(
                msg.sender,
                claimIndex,
                suggestedClaimAmounts[i],
                voteFor,
                isConfirmed[i]
            );

            emit VoteExposed(claimIndex, msg.sender, suggestedClaimAmounts[i]);
        }
    }

    function _getRewardRatio(
        uint256 claimIndex,
        address voter,
        uint256 votedStakedStkBMIAmountWithReputation
    ) internal view returns (uint256) {
        uint256 voteIndex = _allVotesToIndex[voter][claimIndex];

        uint256 voterBMI = _allVotesByIndexInst[voteIndex].stakedStkBMIAmount;
        uint256 voterReputation = _allVotesByIndexInst[voteIndex].voterReputation;

        return
            voterBMI.mul(voterReputation).mul(PERCENTAGE_100).div(
                votedStakedStkBMIAmountWithReputation
            );
    }

    function _calculateMajorityYesVote(
        uint256 claimIndex,
        address voter,
        uint256 oldReputation
    )
        internal
        view
        returns (
            uint256 _stblAmount,
            uint256 _bmiAmount,
            uint256 _newReputation
        )
    {
        VotingResult storage info = _votings[claimIndex];

        uint256 voterRatio =
            _getRewardRatio(claimIndex, voter, info.votedYesStakedStkBMIAmountWithReputation);

        if (claimingRegistry.claimStatus(claimIndex) == IClaimingRegistry.ClaimStatus.ACCEPTED) {
            // calculate STBL reward tokens sent to the voter (from reinsurance)
            _stblAmount = info.reinsuranceTokensAmount.mul(voterRatio).div(PERCENTAGE_100);
        } else {
            // calculate BMI reward tokens sent to the voter (from 1% locked)
            _bmiAmount = info.lockedBMIAmount.mul(voterRatio).div(PERCENTAGE_100);
        }

        _newReputation = reputationSystem.getNewReputation(oldReputation, info.votedYesPercentage);
    }

    function _calculateMajorityNoVote(
        uint256 claimIndex,
        address voter,
        uint256 oldReputation
    ) internal view returns (uint256 _bmiAmount, uint256 _newReputation) {
        VotingResult storage info = _votings[claimIndex];

        uint256 voterRatio =
            _getRewardRatio(claimIndex, voter, info.votedNoStakedStkBMIAmountWithReputation);

        // calculate BMI reward tokens sent to the voter (from 1% locked)
        _bmiAmount = info.lockedBMIAmount.mul(voterRatio).div(PERCENTAGE_100);

        _newReputation = reputationSystem.getNewReputation(
            oldReputation,
            PERCENTAGE_100.sub(info.votedYesPercentage)
        );
    }

    function _calculateMinorityVote(
        uint256 claimIndex,
        address voter,
        uint256 oldReputation
    ) internal view returns (uint256 _bmiPenalty, uint256 _newReputation) {
        uint256 voteIndex = _allVotesToIndex[voter][claimIndex];
        VotingResult storage info = _votings[claimIndex];

        uint256 minorityPercentageWithPrecision =
            Math.min(info.votedYesPercentage, PERCENTAGE_100.sub(info.votedYesPercentage));

        if (minorityPercentageWithPrecision < PENALTY_THRESHOLD) {
            // calculate confiscated staked stkBMI tokens sent to reinsurance pool
            _bmiPenalty = Math.min(
                stkBMIStaking.stakedStkBMI(voter),
                _allVotesByIndexInst[voteIndex]
                    .stakedStkBMIAmount
                    .mul(PENALTY_THRESHOLD.sub(minorityPercentageWithPrecision))
                    .div(PERCENTAGE_100)
            );
        }

        _newReputation = reputationSystem.getNewReputation(
            oldReputation,
            minorityPercentageWithPrecision
        );
    }

    function receiveVoteResultBatch(uint256[] calldata claimIndexes) external override {
        (uint256 rewardAmount, ) = claimingRegistry.rewardWithdrawalInfo(msg.sender);

        uint256 stblAmount = rewardAmount;
        uint256 bmiAmount;
        uint256 bmiPenaltyAmount;
        uint256 reputation = reputationSystem.reputation(msg.sender);

        for (uint256 i = 0; i < claimIndexes.length; i++) {
            uint256 claimIndex = claimIndexes[i];
            require(claimingRegistry.claimExists(claimIndex), "CV: Claim doesn't exist");
            uint256 voteIndex = _allVotesToIndex[msg.sender][claimIndex];
            require(voteIndex != 0, "CV: No vote on this claim");

            if (
                claimingRegistry.claimStatus(claimIndex) == IClaimingRegistry.ClaimStatus.EXPIRED
            ) {
                _myNotReceivedVotes[msg.sender].remove(claimIndex);
            } else if (_isVoteExpired(voteIndex)) {
                uint256 _bmiPenaltyAmount = _allVotesByIndexInst[voteIndex].stakedStkBMIAmount;
                bmiPenaltyAmount = bmiPenaltyAmount.add(_bmiPenaltyAmount);

                _allVotesByIndexInst[voteIndex].status = VoteStatus.EXPIRED;

                _myNotReceivedVotes[msg.sender].remove(claimIndex);
            } else if (_isVoteAwaitingReception(voteIndex)) {
                if (
                    _votings[claimIndex].votedYesPercentage >= PERCENTAGE_50 &&
                    _allVotesByIndexInst[voteIndex].suggestedAmount > 0
                ) {
                    (uint256 _stblAmount, uint256 _bmiAmount, uint256 newReputation) =
                        _calculateMajorityYesVote(claimIndex, msg.sender, reputation);

                    stblAmount = stblAmount.add(_stblAmount);
                    bmiAmount = bmiAmount.add(_bmiAmount);
                    reputation = newReputation;

                    _allVotesByIndexInst[voteIndex].status = VoteStatus.MAJORITY;
                } else if (
                    _votings[claimIndex].votedYesPercentage < PERCENTAGE_50 &&
                    _allVotesByIndexInst[voteIndex].suggestedAmount == 0
                ) {
                    (uint256 _bmiAmount, uint256 newReputation) =
                        _calculateMajorityNoVote(claimIndex, msg.sender, reputation);

                    bmiAmount = bmiAmount.add(_bmiAmount);
                    reputation = newReputation;

                    _allVotesByIndexInst[voteIndex].status = VoteStatus.MAJORITY;
                } else {
                    (uint256 _bmiPenaltyAmount, uint256 newReputation) =
                        _calculateMinorityVote(claimIndex, msg.sender, reputation);

                    bmiPenaltyAmount = bmiPenaltyAmount.add(_bmiPenaltyAmount);
                    reputation = newReputation;

                    _allVotesByIndexInst[voteIndex].status = VoteStatus.MINORITY;
                }
                _myNotReceivedVotes[msg.sender].remove(claimIndex);
            }
        }
        if (stblAmount > 0) {
            claimingRegistry.requestRewardWithdrawal(msg.sender, stblAmount);
        }
        if (bmiAmount > 0) {
            bmiToken.transfer(msg.sender, bmiAmount);
        }
        if (bmiPenaltyAmount > 0) {
            stkBMIStaking.slashUserTokens(msg.sender, uint256(bmiPenaltyAmount));
        }
        reputationSystem.setNewReputation(msg.sender, reputation);
    }

    function _sendRewardsForCalculationTo(uint256 claimIndex, address calculator) internal {
        uint256 reward = claimingRegistry.getBMIRewardForCalculation(claimIndex);

        _votings[claimIndex].lockedBMIAmount = _votings[claimIndex].lockedBMIAmount.sub(reward);

        bmiToken.transfer(calculator, reward);

        emit RewardsForClaimCalculationSent(calculator, reward);
    }

    function calculateResult(uint256 claimIndex) external override {
        // SEND REWARD FOR CALCULATION
        require(
            claimingRegistry.canCalculateClaim(claimIndex, msg.sender),
            "CV: Not allowed to calculate"
        );
        _sendRewardsForCalculationTo(claimIndex, msg.sender);

        // PROCEED CALCULATION
        if (claimingRegistry.claimStatus(claimIndex) == IClaimingRegistry.ClaimStatus.EXPIRED) {
            claimingRegistry.expireClaim(claimIndex);
        } else {
            // claim existence is checked in claimStatus function
            require(
                claimingRegistry.claimStatus(claimIndex) ==
                    IClaimingRegistry.ClaimStatus.AWAITING_CALCULATION,
                "CV: Claim is not awaiting"
            );

            _resolveClaim(claimIndex);
        }
    }

    function _resolveClaim(uint256 claimIndex) internal {
        uint256 totalStakedStkBMI = stkBMIStaking.totalStakedStkBMI();
        uint256 allVotedStakedStkBMI = _votings[claimIndex].allVotedStakedStkBMIAmount;

        // if no votes or not an appeal and voted < 10% supply of staked StkBMI
        if (
            allVotedStakedStkBMI == 0 ||
            ((totalStakedStkBMI == 0 ||
                totalStakedStkBMI.mul(QUORUM).div(PERCENTAGE_100) > allVotedStakedStkBMI) &&
                !claimingRegistry.isClaimAppeal(claimIndex))
        ) {
            // reject & use locked BMI for rewards
            claimingRegistry.rejectClaim(claimIndex);
        } else {
            uint256 votedYesPower = _votings[claimIndex].votedYesStakedStkBMIAmountWithReputation;
            uint256 votedNoPower = _votings[claimIndex].votedNoStakedStkBMIAmountWithReputation;
            uint256 totalPower = votedYesPower.add(votedNoPower);

            _votings[claimIndex].votedYesPercentage = votedYesPower.mul(PERCENTAGE_100).div(
                totalPower
            );

            if (_votings[claimIndex].votedYesPercentage >= APPROVAL_PERCENTAGE) {
                // approve + send STBL & return locked BMI to the claimer
                claimingRegistry.acceptClaim(
                    claimIndex,
                    _votings[claimIndex].votedAverageWithdrawalAmount
                );
            } else {
                // reject & use locked BMI for rewards
                claimingRegistry.rejectClaim(claimIndex);
            }
        }
        emit ClaimCalculated(claimIndex, msg.sender);
    }

    function transferLockedBMI(uint256 claimIndex, address claimer)
        external
        override
        onlyClaimingRegistry
    {
        uint256 lockedAmount = _votings[claimIndex].lockedBMIAmount;
        require(lockedAmount > 0, "CV: Already withdrawn");
        _votings[claimIndex].lockedBMIAmount = 0;
        bmiToken.transfer(claimer, lockedAmount);
    }
}