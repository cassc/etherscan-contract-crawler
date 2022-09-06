// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./libraries/DecimalsConverter.sol";

import "./interfaces/IContractsRegistry.sol";
import "./interfaces/IClaimingRegistry.sol";
import "./interfaces/IPolicyBook.sol";
import "./interfaces/IPolicyRegistry.sol";
import "./interfaces/IPolicyBookRegistry.sol";
import "./interfaces/ILeveragePortfolio.sol";
import "./interfaces/ICapitalPool.sol";
import "./interfaces/IClaimVoting.sol";

import "./abstract/AbstractDependant.sol";
import "./Globals.sol";

contract ClaimingRegistry is IClaimingRegistry, Initializable, AbstractDependant {
    using SafeMath for uint256;
    using Math for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 internal constant ANONYMOUS_VOTING_DURATION = 1 weeks;
    uint256 internal constant EXPOSE_VOTE_DURATION = 1 weeks;

    uint256 internal constant PRIVATE_CLAIM_DURATION = 3 days;
    uint256 internal constant VIEW_VERDICT_DURATION = 10 days;
    uint256 public constant READY_TO_WITHDRAW_PERIOD = 8 days;

    IPolicyRegistry public policyRegistry;
    address public claimVotingAddress;

    mapping(address => EnumerableSet.UintSet) internal _myClaims; // claimer -> claim indexes

    mapping(address => mapping(address => uint256)) internal _allClaimsToIndex; // book -> claimer -> index

    mapping(uint256 => ClaimInfo) internal _allClaimsByIndexInfo; // index -> info

    EnumerableSet.UintSet internal _pendingClaimsIndexes;
    EnumerableSet.UintSet internal _allClaimsIndexes;

    uint256 private _claimIndex;

    address internal policyBookAdminAddress;

    ICapitalPool public capitalPool;

    // claim withdraw
    EnumerableSet.UintSet internal _withdrawClaimRequestIndexList;
    mapping(uint256 => ClaimWithdrawalInfo) public override claimWithdrawalInfo; // index -> info
    //reward withdraw
    EnumerableSet.AddressSet internal _withdrawRewardRequestVoterList;
    mapping(address => RewardWithdrawalInfo) public override rewardWithdrawalInfo; // address -> info
    IClaimVoting public claimVoting;
    IPolicyBookRegistry public policyBookRegistry;
    mapping(address => EnumerableSet.UintSet) internal _policyBookClaims; // book -> index
    ERC20 public stblToken;
    uint256 public stblDecimals;

    event AppealPending(address claimer, address policyBookAddress, uint256 claimIndex);
    event ClaimPending(address claimer, address policyBookAddress, uint256 claimIndex);
    event ClaimAccepted(
        address claimer,
        address policyBookAddress,
        uint256 claimAmount,
        uint256 claimIndex
    );
    event ClaimRejected(address claimer, address policyBookAddress, uint256 claimIndex);
    event ClaimExpired(address claimer, address policyBookAddress, uint256 claimIndex);
    event AppealRejected(address claimer, address policyBookAddress, uint256 claimIndex);
    event WithdrawalRequested(
        address _claimer,
        uint256 _claimRefundAmount,
        uint256 _readyToWithdrawDate
    );
    event ClaimWithdrawn(address _claimer, uint256 _claimRefundAmount);
    event RewardWithdrawn(address _voter, uint256 _rewardAmount);

    modifier onlyClaimVoting() {
        require(
            claimVotingAddress == msg.sender,
            "ClaimingRegistry: Caller is not a ClaimVoting contract"
        );
        _;
    }

    modifier onlyPolicyBookAdmin() {
        require(
            policyBookAdminAddress == msg.sender,
            "ClaimingRegistry: Caller is not a PolicyBookAdmin"
        );
        _;
    }

    modifier withExistingClaim(uint256 index) {
        require(claimExists(index), "ClaimingRegistry: This claim doesn't exist");
        _;
    }

    function __ClaimingRegistry_init() external initializer {
        _claimIndex = 1;
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        policyRegistry = IPolicyRegistry(_contractsRegistry.getPolicyRegistryContract());
        claimVotingAddress = _contractsRegistry.getClaimVotingContract();
        policyBookAdminAddress = _contractsRegistry.getPolicyBookAdminContract();
        capitalPool = ICapitalPool(_contractsRegistry.getCapitalPoolContract());
        policyBookRegistry = IPolicyBookRegistry(
            _contractsRegistry.getPolicyBookRegistryContract()
        );
        claimVoting = IClaimVoting(_contractsRegistry.getClaimVotingContract());
        stblToken = ERC20(_contractsRegistry.getUSDTContract());
        stblDecimals = stblToken.decimals();
    }

    function _isClaimAwaitingCalculation(uint256 index)
        internal
        view
        withExistingClaim(index)
        returns (bool)
    {
        return (_allClaimsByIndexInfo[index].status == ClaimStatus.PENDING &&
            _allClaimsByIndexInfo[index].dateSubmitted.add(votingDuration(index)) <=
            block.timestamp);
    }

    function _isClaimAppealExpired(uint256 index)
        internal
        view
        withExistingClaim(index)
        returns (bool)
    {
        return (_allClaimsByIndexInfo[index].status == ClaimStatus.REJECTED_CAN_APPEAL &&
            _allClaimsByIndexInfo[index].dateEnded.add(policyRegistry.STILL_CLAIMABLE_FOR()) <=
            block.timestamp);
    }

    function _isClaimExpired(uint256 index) internal view withExistingClaim(index) returns (bool) {
        return (_allClaimsByIndexInfo[index].status == ClaimStatus.PENDING &&
            _allClaimsByIndexInfo[index].dateSubmitted.add(validityDuration(index)) <=
            block.timestamp);
    }

    function anonymousVotingDuration(uint256 index)
        public
        view
        override
        withExistingClaim(index)
        returns (uint256)
    {
        return ANONYMOUS_VOTING_DURATION;
    }

    function votingDuration(uint256 index) public view override returns (uint256) {
        return anonymousVotingDuration(index).add(EXPOSE_VOTE_DURATION);
    }

    function validityDuration(uint256 index)
        public
        view
        override
        withExistingClaim(index)
        returns (uint256)
    {
        return votingDuration(index).add(VIEW_VERDICT_DURATION);
    }

    function anyoneCanCalculateClaimResultAfter(uint256 index)
        public
        view
        override
        returns (uint256)
    {
        return votingDuration(index).add(PRIVATE_CLAIM_DURATION);
    }

    function canCalculateClaim(uint256 index, address calculator)
        external
        view
        override
        returns (bool)
    {
        // TODO invert order condition to prevent duplicate storage hits
        return
            canClaimBeCalculatedByAnyone(index) ||
            _allClaimsByIndexInfo[index].claimer == calculator;
    }

    function canBuyNewPolicy(address buyer, address policyBookAddress) external override {
        require(msg.sender == policyBookAddress, "ClaimingRegistry: Not allowed");

        bool previousEnded = !policyRegistry.isPolicyActive(buyer, policyBookAddress);
        uint256 index = _allClaimsToIndex[policyBookAddress][buyer];

        require(
            (previousEnded &&
                (!claimExists(index) ||
                    (!_pendingClaimsIndexes.contains(index) &&
                        claimStatus(index) != ClaimStatus.REJECTED_CAN_APPEAL))) ||
                (!previousEnded && !claimExists(index)),
            "PB: Claim is pending"
        );

        if (!previousEnded) {
            IPolicyBook(policyBookAddress).endActivePolicy(buyer);
        }
    }

    function canWithdrawLockedBMI(uint256 index) public view returns (bool) {
        return
            (_allClaimsByIndexInfo[index].status == ClaimStatus.EXPIRED) ||
            (_allClaimsByIndexInfo[index].status == ClaimStatus.ACCEPTED &&
                _withdrawClaimRequestIndexList.contains(index) &&
                getClaimWithdrawalStatus(index) == WithdrawalStatus.EXPIRED &&
                !policyRegistry.isPolicyActive(
                    _allClaimsByIndexInfo[index].claimer,
                    _allClaimsByIndexInfo[index].policyBookAddress
                ));
    }

    function getClaimWithdrawalStatus(uint256 index)
        public
        view
        override
        returns (WithdrawalStatus)
    {
        if (claimWithdrawalInfo[index].readyToWithdrawDate == 0) {
            return WithdrawalStatus.NONE;
        }

        if (block.timestamp < claimWithdrawalInfo[index].readyToWithdrawDate) {
            return WithdrawalStatus.PENDING;
        }

        if (
            block.timestamp >=
            claimWithdrawalInfo[index].readyToWithdrawDate.add(READY_TO_WITHDRAW_PERIOD)
        ) {
            return WithdrawalStatus.EXPIRED;
        }

        return WithdrawalStatus.READY;
    }

    function getRewardWithdrawalStatus(address voter)
        public
        view
        override
        returns (WithdrawalStatus)
    {
        if (rewardWithdrawalInfo[voter].readyToWithdrawDate == 0) {
            return WithdrawalStatus.NONE;
        }

        if (block.timestamp < rewardWithdrawalInfo[voter].readyToWithdrawDate) {
            return WithdrawalStatus.PENDING;
        }

        if (
            block.timestamp >=
            rewardWithdrawalInfo[voter].readyToWithdrawDate.add(READY_TO_WITHDRAW_PERIOD)
        ) {
            return WithdrawalStatus.EXPIRED;
        }

        return WithdrawalStatus.READY;
    }

    function hasProcedureOngoing(address poolAddress) external view override returns (bool) {
        if (policyBookRegistry.isUserLeveragePool(poolAddress)) {
            ILeveragePortfolio userLeveragePool = ILeveragePortfolio(poolAddress);
            address[] memory _coveragePools =
                userLeveragePool.listleveragedCoveragePools(
                    0,
                    userLeveragePool.countleveragedCoveragePools()
                );

            for (uint256 i = 0; i < _coveragePools.length; i++) {
                if (
                    _hasProcedureOngoing(
                        _coveragePools[i],
                        getPolicyBookClaimsCount(_coveragePools[i])
                    )
                ) {
                    return true;
                }
            }
        } else {
            if (_hasProcedureOngoing(poolAddress, getPolicyBookClaimsCount(poolAddress))) {
                return true;
            }
        }
        return false;
    }

    function getPolicyBookClaimsCount(address policyBookAddress) internal view returns (uint256) {
        return _policyBookClaims[policyBookAddress].length();
    }

    function _hasProcedureOngoing(address policyBookAddress, uint256 limit)
        internal
        view
        returns (bool hasProcedure)
    {
        for (uint256 i = 0; i < limit; i++) {
            uint256 index = _policyBookClaims[policyBookAddress].at(i);
            ClaimStatus status = claimStatus(index);
            address claimer = _allClaimsByIndexInfo[index].claimer;
            if (
                !(status == ClaimStatus.EXPIRED || // has expired
                    status == ClaimStatus.REJECTED || // has been rejected || appeal expired
                    (status == ClaimStatus.ACCEPTED &&
                        getClaimWithdrawalStatus(index) == WithdrawalStatus.NONE) || // has been accepted and withdrawn or has withdrawn locked BMI at policy end
                    (status == ClaimStatus.ACCEPTED &&
                        getClaimWithdrawalStatus(index) == WithdrawalStatus.EXPIRED &&
                        !policyRegistry.isPolicyActive(claimer, policyBookAddress))) // has been accepted and never withdrawn but cannot request withdraw anymore
            ) {
                return true;
            }
        }
    }

    function submitClaim(
        address claimer,
        address policyBookAddress,
        string calldata evidenceURI,
        uint256 cover,
        bool appeal
    ) external override onlyClaimVoting returns (uint256 _newClaimIndex) {
        uint256 index = _allClaimsToIndex[policyBookAddress][claimer];
        ClaimStatus status =
            _myClaims[claimer].contains(index) ? claimStatus(index) : ClaimStatus.CAN_CLAIM;
        bool active = policyRegistry.isPolicyActive(claimer, policyBookAddress);

        /* (1) a new claim or a claim after rejected appeal (policy has to be active)
         * (2) a regular appeal (appeal should not be expired)
         * (3) a new claim cycle after expired appeal or a NEW policy when OLD one is accepted
         *     (PB shall not allow user to buy new policy when claim is pending or REJECTED_CAN_APPEAL)
         *     (policy has to be active)
         */
        require(
            (!appeal && active && status == ClaimStatus.CAN_CLAIM) ||
                (appeal && status == ClaimStatus.REJECTED_CAN_APPEAL) ||
                (!appeal && active && status == ClaimStatus.EXPIRED) ||
                (!appeal &&
                    active &&
                    (status == ClaimStatus.REJECTED ||
                        (policyRegistry.policyStartTime(claimer, policyBookAddress) >
                            _allClaimsByIndexInfo[index].dateSubmitted &&
                            status == ClaimStatus.ACCEPTED))) ||
                (!appeal &&
                    active &&
                    status == ClaimStatus.ACCEPTED &&
                    !_withdrawClaimRequestIndexList.contains(index)),
            "ClaimingRegistry: The claimer can't submit this claim"
        );

        if (appeal) {
            _allClaimsByIndexInfo[index].status = ClaimStatus.REJECTED;
        }

        _myClaims[claimer].add(_claimIndex);

        _allClaimsToIndex[policyBookAddress][claimer] = _claimIndex;
        _policyBookClaims[policyBookAddress].add(_claimIndex);

        _allClaimsByIndexInfo[_claimIndex] = ClaimInfo(
            claimer,
            policyBookAddress,
            evidenceURI,
            block.timestamp,
            0,
            appeal,
            ClaimStatus.PENDING,
            cover,
            0
        );

        _pendingClaimsIndexes.add(_claimIndex);
        _allClaimsIndexes.add(_claimIndex);

        _newClaimIndex = _claimIndex++;

        if (!appeal) {
            emit ClaimPending(claimer, policyBookAddress, _newClaimIndex);
        } else {
            emit AppealPending(claimer, policyBookAddress, _newClaimIndex);
        }
    }

    function claimExists(uint256 index) public view override returns (bool) {
        return _allClaimsIndexes.contains(index);
    }

    function claimSubmittedTime(uint256 index) public view override returns (uint256) {
        return _allClaimsByIndexInfo[index].dateSubmitted;
    }

    function claimEndTime(uint256 index) public view override returns (uint256) {
        return _allClaimsByIndexInfo[index].dateEnded;
    }

    function isClaimAnonymouslyVotable(uint256 index) external view override returns (bool) {
        return (_pendingClaimsIndexes.contains(index) &&
            _allClaimsByIndexInfo[index].dateSubmitted.add(anonymousVotingDuration(index)) >
            block.timestamp);
    }

    function isClaimExposablyVotable(uint256 index) external view override returns (bool) {
        if (!_pendingClaimsIndexes.contains(index)) {
            return false;
        }

        uint256 dateSubmitted = _allClaimsByIndexInfo[index].dateSubmitted;
        uint256 anonymousDuration = anonymousVotingDuration(index);

        return (dateSubmitted.add(anonymousDuration.add(EXPOSE_VOTE_DURATION)) > block.timestamp &&
            dateSubmitted.add(anonymousDuration) < block.timestamp);
    }

    function isClaimVotable(uint256 index) external view override returns (bool) {
        return (_pendingClaimsIndexes.contains(index) &&
            _allClaimsByIndexInfo[index].dateSubmitted.add(votingDuration(index)) >
            block.timestamp);
    }

    function canClaimBeCalculatedByAnyone(uint256 index) public view override returns (bool) {
        return
            _allClaimsByIndexInfo[index].status == ClaimStatus.PENDING &&
            _allClaimsByIndexInfo[index].dateSubmitted.add(
                anyoneCanCalculateClaimResultAfter(index)
            ) <=
            block.timestamp;
    }

    function isClaimPending(uint256 index) external view override returns (bool) {
        return _pendingClaimsIndexes.contains(index);
    }

    function countPolicyClaimerClaims(address claimer) external view override returns (uint256) {
        return _myClaims[claimer].length();
    }

    function countPendingClaims() external view override returns (uint256) {
        return _pendingClaimsIndexes.length();
    }

    function countClaims() external view override returns (uint256) {
        return _allClaimsIndexes.length();
    }

    /// @notice Gets the the claim index for for the users claim at an indexed position
    /// @param claimer address of of the user
    /// @param orderIndex uint256, numeric value for index
    /// @return uint256
    function claimOfOwnerIndexAt(address claimer, uint256 orderIndex)
        external
        view
        override
        returns (uint256)
    {
        return _myClaims[claimer].at(orderIndex);
    }

    function pendingClaimIndexAt(uint256 orderIndex) external view override returns (uint256) {
        return _pendingClaimsIndexes.at(orderIndex);
    }

    function claimIndexAt(uint256 orderIndex) external view override returns (uint256) {
        return _allClaimsIndexes.at(orderIndex);
    }

    function claimIndex(address claimer, address policyBookAddress)
        external
        view
        override
        returns (uint256)
    {
        return _allClaimsToIndex[policyBookAddress][claimer];
    }

    function isClaimAppeal(uint256 index) external view override returns (bool) {
        return _allClaimsByIndexInfo[index].appeal;
    }

    function policyStatus(address claimer, address policyBookAddress)
        external
        view
        override
        returns (ClaimStatus)
    {
        if (!policyRegistry.isPolicyActive(claimer, policyBookAddress)) {
            return ClaimStatus.UNCLAIMABLE;
        }

        uint256 index = _allClaimsToIndex[policyBookAddress][claimer];

        if (!_myClaims[claimer].contains(index)) {
            return ClaimStatus.CAN_CLAIM;
        }

        ClaimStatus status = claimStatus(index);
        bool newPolicyBought =
            policyRegistry.policyStartTime(claimer, policyBookAddress) >
                _allClaimsByIndexInfo[index].dateSubmitted;

        if (
            status == ClaimStatus.REJECTED ||
            status == ClaimStatus.EXPIRED ||
            (newPolicyBought && status == ClaimStatus.ACCEPTED)
        ) {
            return ClaimStatus.CAN_CLAIM;
        }

        return status;
    }

    function claimStatus(uint256 index) public view override returns (ClaimStatus) {
        if (_isClaimAppealExpired(index)) {
            return ClaimStatus.REJECTED;
        }
        if (_isClaimExpired(index)) {
            return ClaimStatus.EXPIRED;
        }
        if (_isClaimAwaitingCalculation(index)) {
            return ClaimStatus.AWAITING_CALCULATION;
        }

        return _allClaimsByIndexInfo[index].status;
    }

    function claimOwner(uint256 index) external view override returns (address) {
        return _allClaimsByIndexInfo[index].claimer;
    }

    /// @notice Gets the policybook address of a claim with a certain index
    /// @param index uint256, numeric index value
    /// @return address
    function claimPolicyBook(uint256 index) external view override returns (address) {
        return _allClaimsByIndexInfo[index].policyBookAddress;
    }

    /// @notice gets the full claim information at a particular index.
    /// @param index uint256, numeric index value
    /// @return _claimInfo ClaimInfo
    function claimInfo(uint256 index)
        external
        view
        override
        withExistingClaim(index)
        returns (ClaimInfo memory _claimInfo)
    {
        _claimInfo = ClaimInfo(
            _allClaimsByIndexInfo[index].claimer,
            _allClaimsByIndexInfo[index].policyBookAddress,
            _allClaimsByIndexInfo[index].evidenceURI,
            _allClaimsByIndexInfo[index].dateSubmitted,
            _allClaimsByIndexInfo[index].dateEnded,
            _allClaimsByIndexInfo[index].appeal,
            claimStatus(index),
            _allClaimsByIndexInfo[index].claimAmount,
            _allClaimsByIndexInfo[index].claimRefund
        );
    }

    /// @notice fetches the pending claims amounts which is before awaiting for calculation by 24 hrs
    /// @dev use it with getWithdrawClaimRequestIndexListCount
    /// @return _totalClaimsAmount uint256 collect claim amounts from pending claims
    function getAllPendingClaimsAmount(uint256 _limit)
        external
        view
        override
        returns (uint256 _totalClaimsAmount)
    {
        WithdrawalStatus _currentStatus;
        uint256 index;

        for (uint256 i = 0; i < _limit; i++) {
            index = _withdrawClaimRequestIndexList.at(i);
            _currentStatus = getClaimWithdrawalStatus(index);

            if (
                _currentStatus == WithdrawalStatus.NONE ||
                _currentStatus == WithdrawalStatus.EXPIRED
            ) {
                continue;
            }

            ///@dev exclude all ready request until before ready to withdraw date by 24 hrs
            /// + 1 hr (spare time for transaction execution time)
            if (
                block.timestamp >=
                claimWithdrawalInfo[index].readyToWithdrawDate.sub(
                    ICapitalPool(capitalPool).rebalanceDuration().add(60 * 60)
                )
            ) {
                _totalClaimsAmount = _totalClaimsAmount.add(
                    _allClaimsByIndexInfo[index].claimRefund
                );
            }
        }
    }

    /// @dev use it with getWithdrawRewardRequestVoterListCount
    function getAllPendingRewardsAmount(uint256 _limit)
        external
        view
        override
        returns (uint256 _totalRewardsAmount)
    {
        WithdrawalStatus _currentStatus;
        address voter;

        for (uint256 i = 0; i < _limit; i++) {
            voter = _withdrawRewardRequestVoterList.at(i);
            _currentStatus = getRewardWithdrawalStatus(voter);

            if (
                _currentStatus == WithdrawalStatus.NONE ||
                _currentStatus == WithdrawalStatus.EXPIRED
            ) {
                continue;
            }

            ///@dev exclude all ready request until before ready to withdraw date by 24 hrs
            /// + 1 hr (spare time for transaction execution time)
            if (
                block.timestamp >=
                rewardWithdrawalInfo[voter].readyToWithdrawDate.sub(
                    ICapitalPool(capitalPool).rebalanceDuration().add(60 * 60)
                )
            ) {
                _totalRewardsAmount = _totalRewardsAmount.add(
                    rewardWithdrawalInfo[voter].rewardAmount
                );
            }
        }
    }

    function getWithdrawClaimRequestIndexListCount() external view override returns (uint256) {
        return _withdrawClaimRequestIndexList.length();
    }

    function getWithdrawRewardRequestVoterListCount() external view override returns (uint256) {
        return _withdrawRewardRequestVoterList.length();
    }

    /// @notice gets the claiming balance from a list of claim indexes
    /// @param _claimIndexes uint256[], list of claimIndexes
    /// @return uint256
    function getClaimableAmounts(uint256[] memory _claimIndexes)
        external
        view
        override
        returns (uint256)
    {
        uint256 _acumulatedClaimAmount;
        for (uint256 i = 0; i < _claimIndexes.length; i++) {
            _acumulatedClaimAmount = _acumulatedClaimAmount.add(
                _allClaimsByIndexInfo[i].claimAmount
            );
        }
        return _acumulatedClaimAmount;
    }

    function getBMIRewardForCalculation(uint256 index) external view override returns (uint256) {
        (, uint256 lockedBMIs, ) = claimVoting.votingInfo(index);
        uint256 timeElapsed =
            claimSubmittedTime(index).add(anyoneCanCalculateClaimResultAfter(index));

        if (canClaimBeCalculatedByAnyone(index)) {
            timeElapsed = block.timestamp.sub(timeElapsed);
        } else {
            timeElapsed = timeElapsed.sub(block.timestamp);
        }

        return
            Math.min(
                lockedBMIs,
                lockedBMIs.mul(timeElapsed.mul(CALCULATION_REWARD_PER_DAY.div(1 days))).div(
                    PERCENTAGE_100
                )
            );
    }

    function _modifyClaim(uint256 index, ClaimStatus status) internal {
        address claimer = _allClaimsByIndexInfo[index].claimer;
        address policyBookAddress = _allClaimsByIndexInfo[index].policyBookAddress;
        uint256 claimAmount = _allClaimsByIndexInfo[index].claimAmount;

        if (status == ClaimStatus.ACCEPTED) {
            _allClaimsByIndexInfo[index].status = ClaimStatus.ACCEPTED;
            _requestClaimWithdrawal(claimer, index);

            emit ClaimAccepted(claimer, policyBookAddress, claimAmount, index);
        } else if (status == ClaimStatus.EXPIRED) {
            _allClaimsByIndexInfo[index].status = ClaimStatus.EXPIRED;

            emit ClaimExpired(claimer, policyBookAdminAddress, index);
        } else if (!_allClaimsByIndexInfo[index].appeal) {
            _allClaimsByIndexInfo[index].status = ClaimStatus.REJECTED_CAN_APPEAL;

            emit ClaimRejected(claimer, policyBookAddress, index);
        } else {
            _allClaimsByIndexInfo[index].status = ClaimStatus.REJECTED;
            delete _allClaimsToIndex[policyBookAddress][claimer];
            _policyBookClaims[policyBookAddress].remove(index);

            emit AppealRejected(claimer, policyBookAddress, index);
        }

        _allClaimsByIndexInfo[index].dateEnded = block.timestamp;

        _pendingClaimsIndexes.remove(index);

        IPolicyBook(_allClaimsByIndexInfo[index].policyBookAddress).commitClaim(
            claimer,
            block.timestamp,
            _allClaimsByIndexInfo[index].status // ACCEPTED, REJECTED_CAN_APPEAL, REJECTED, EXPIRED
        );
    }

    function acceptClaim(uint256 index, uint256 amount) external override onlyClaimVoting {
        require(_isClaimAwaitingCalculation(index), "ClaimingRegistry: The claim is not awaiting");
        _allClaimsByIndexInfo[index].claimRefund = amount;
        _modifyClaim(index, ClaimStatus.ACCEPTED);
    }

    function rejectClaim(uint256 index) external override onlyClaimVoting {
        require(_isClaimAwaitingCalculation(index), "ClaimingRegistry: The claim is not awaiting");

        _modifyClaim(index, ClaimStatus.REJECTED);
    }

    function expireClaim(uint256 index) external override onlyClaimVoting {
        require(_isClaimExpired(index), "ClaimingRegistry: The claim is not expired");

        _modifyClaim(index, ClaimStatus.EXPIRED);
    }

    /// @notice Update Image Uri in case it contains material that is ilegal
    ///         or offensive.
    /// @dev Only the owner of the PolicyBookAdmin can erase/update evidenceUri.
    /// @param claim_Index Claim Index that is going to be updated
    /// @param _newEvidenceURI New evidence uri. It can be blank.
    function updateImageUriOfClaim(uint256 claim_Index, string calldata _newEvidenceURI)
        external
        override
        onlyPolicyBookAdmin
    {
        _allClaimsByIndexInfo[claim_Index].evidenceURI = _newEvidenceURI;
    }

    function requestClaimWithdrawal(uint256 index) external override {
        require(
            claimStatus(index) == IClaimingRegistry.ClaimStatus.ACCEPTED,
            "ClaimingRegistry: Claim is not accepted"
        );
        address claimer = _allClaimsByIndexInfo[index].claimer;
        require(msg.sender == claimer, "ClaimingRegistry: Not allowed to request");
        address policyBookAddress = _allClaimsByIndexInfo[index].policyBookAddress;
        require(
            policyRegistry.isPolicyActive(claimer, policyBookAddress) &&
                policyRegistry.policyStartTime(claimer, policyBookAddress) <
                _allClaimsByIndexInfo[index].dateEnded,
            "ClaimingRegistry: The policy is expired"
        );
        require(
            getClaimWithdrawalStatus(index) == WithdrawalStatus.NONE ||
                getClaimWithdrawalStatus(index) == WithdrawalStatus.EXPIRED,
            "ClaimingRegistry: The claim is already requested"
        );
        _requestClaimWithdrawal(claimer, index);
    }

    function _requestClaimWithdrawal(address claimer, uint256 index) internal {
        _withdrawClaimRequestIndexList.add(index);
        uint256 _readyToWithdrawDate = block.timestamp.add(capitalPool.getWithdrawPeriod());
        bool _committed = claimWithdrawalInfo[index].committed;
        claimWithdrawalInfo[index] = ClaimWithdrawalInfo(_readyToWithdrawDate, _committed);

        emit WithdrawalRequested(
            claimer,
            _allClaimsByIndexInfo[index].claimRefund,
            _readyToWithdrawDate
        );
    }

    function requestRewardWithdrawal(address voter, uint256 rewardAmount)
        external
        override
        onlyClaimVoting
    {
        require(
            getRewardWithdrawalStatus(voter) == WithdrawalStatus.NONE ||
                getRewardWithdrawalStatus(voter) == WithdrawalStatus.EXPIRED,
            "ClaimingRegistry: The reward is already requested"
        );
        _requestRewardWithdrawal(voter, rewardAmount);
    }

    function _requestRewardWithdrawal(address voter, uint256 rewardAmount) internal {
        _withdrawRewardRequestVoterList.add(voter);
        uint256 _readyToWithdrawDate = block.timestamp.add(capitalPool.getWithdrawPeriod());
        rewardWithdrawalInfo[voter] = RewardWithdrawalInfo(rewardAmount, _readyToWithdrawDate);

        emit WithdrawalRequested(voter, rewardAmount, _readyToWithdrawDate);
    }

    function withdrawClaim(uint256 index) public virtual {
        address claimer = _allClaimsByIndexInfo[index].claimer;
        require(claimer == msg.sender, "ClaimingRegistry: Not the claimer");
        require(
            getClaimWithdrawalStatus(index) == WithdrawalStatus.READY,
            "ClaimingRegistry: Withdrawal is not ready"
        );

        address policyBookAddress = _allClaimsByIndexInfo[index].policyBookAddress;

        uint256 claimRefundConverted =
            DecimalsConverter.convertFrom18(
                _allClaimsByIndexInfo[index].claimRefund,
                stblDecimals
            );

        uint256 _actualAmount =
            capitalPool.fundClaim(claimer, claimRefundConverted, policyBookAddress);

        claimRefundConverted = claimRefundConverted.sub(_actualAmount);

        if (!claimWithdrawalInfo[index].committed) {
            IPolicyBook(policyBookAddress).commitWithdrawnClaim(msg.sender);
            claimWithdrawalInfo[index].committed = true;
        }

        if (claimRefundConverted == 0) {
            _allClaimsByIndexInfo[index].claimRefund = 0;
            _withdrawClaimRequestIndexList.remove(index);
            delete claimWithdrawalInfo[index];
        } else {
            _allClaimsByIndexInfo[index].claimRefund = DecimalsConverter.convertTo18(
                claimRefundConverted,
                stblDecimals
            );
            _requestClaimWithdrawal(claimer, index);
        }

        claimVoting.transferLockedBMI(index, claimer);

        emit ClaimWithdrawn(
            msg.sender,
            DecimalsConverter.convertTo18(_actualAmount, stblDecimals)
        );
    }

    function withdrawReward() public {
        require(
            getRewardWithdrawalStatus(msg.sender) == WithdrawalStatus.READY,
            "ClaimingRegistry: Withdrawal is not ready"
        );

        uint256 rewardAmountConverted =
            DecimalsConverter.convertFrom18(
                rewardWithdrawalInfo[msg.sender].rewardAmount,
                stblDecimals
            );

        uint256 _actualAmount = capitalPool.fundReward(msg.sender, rewardAmountConverted);

        rewardAmountConverted = rewardAmountConverted.sub(_actualAmount);

        if (rewardAmountConverted == 0) {
            rewardWithdrawalInfo[msg.sender].rewardAmount = 0;
            _withdrawRewardRequestVoterList.remove(msg.sender);
            delete rewardWithdrawalInfo[msg.sender];
        } else {
            rewardWithdrawalInfo[msg.sender].rewardAmount = DecimalsConverter.convertTo18(
                rewardAmountConverted,
                stblDecimals
            );

            _requestRewardWithdrawal(msg.sender, rewardWithdrawalInfo[msg.sender].rewardAmount);
        }

        emit RewardWithdrawn(
            msg.sender,
            DecimalsConverter.convertTo18(_actualAmount, stblDecimals)
        );
    }

    function withdrawLockedBMI(uint256 index) public virtual {
        address claimer = _allClaimsByIndexInfo[index].claimer;
        require(claimer == msg.sender, "ClaimingRegistry: Not the claimer");

        require(
            canWithdrawLockedBMI(index),
            "ClaimingRegistry: Claim is not expired or can still be withdrawn"
        );

        address policyBookAddress = _allClaimsByIndexInfo[index].policyBookAddress;
        if (claimStatus(index) == ClaimStatus.ACCEPTED) {
            IPolicyBook(policyBookAddress).commitWithdrawnClaim(claimer);
            _withdrawClaimRequestIndexList.remove(index);
            delete claimWithdrawalInfo[index];
        }

        claimVoting.transferLockedBMI(index, claimer);
    }

    /// @dev return yes and no percentage with 10**25 precision
    function getRepartition(uint256 index)
        external
        view
        returns (uint256 yesPercentage, uint256 noPercentage)
    {
        (, , yesPercentage) = claimVoting.votingInfo(index);
        noPercentage = (PERCENTAGE_100.sub(yesPercentage));
    }
}