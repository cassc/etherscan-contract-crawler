// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
    @title Bounty Contract Version 2

    @notice This contract allows for the creation, funding, and completion of blockchain intelligence
    bounties in a decentralized manner.

    @dev This contract is intended to be used with the ARKM token.

    Users can submit bounties by putting up ARKM, and other users can complete the bounties by
    staking ARKM to submit IDs that correspond to solutions.

    Submission IDs are not submitted raw, but instead hashed with the submitter's address to
    prevent front-running. The IDs are effectively secrets that only the submitters know on
    submission.

    Submissions are put in a queue for a bounty and given first-come first-served preference for
    evaluation.

    bountyIDs and submissionIDs correspond to off-chain records that detail the bounty and contain
    solutions. For v2, these records live on the Arkham platform. In the future there could be any
    number of secondary services that host these records.

    Once submissions are made, only a set of approver addresses can approve or reject them -- NOT
    the posters of the bounty. Approver addresses can be added or removed by the the contract
    owner.

    Once a bounty is funded, it cannot be closed until after its expiration. Bounties also must
    remain open until all submissions to the bounty have been approved or rejected. Once a bounty is
    closed, it cannot be reopened. If a funder closes their bounty, they receive the amount of the
    bounty back. (Bounty funders can receive a maximum of 100% of their initial funding back. If
    there is excess funding from rejected submissions, it is accrued as fees.)

    The contract owner sets the initial submission stake, maker fee, and taker fee.

    A maker fee is charged when a bounty is funded. A taker fee is charged when a submission is
    paid out. These fees are in basis points, e.g. 100 basis points = 1%. Fees are disbursed at the
    discretion of the contract owner and are withdrawn to an address set at contract creation and
    changeable by the owner.

    If a submission is approved, the submitter receives the bounty amount less a taker fee, plus
    their stake back. If a submission is rejected, the submitter does NOT receive their stake back,
    and the bounty amount increases by the amount staked. Only one submission may be active for a
    given bounty at a time. Stakes for un-evaluated submissions are paid back to the submitters
    when the bounty is closed.

    Delivery of the information corresponding to the accepted submission to the funder is handled
    off-chain.
 */
contract BountyV2 is Ownable {
    address private immutable _arkm;

    uint256 private _submissionStake;
    uint256 private _makerFee;
    uint256 private _takerFee;
    uint32  private _maxActiveSubmissions;
    bool    private _acceptingBounties;
    uint256 private _accruedFees;
    address private _feeReceiverAddress;
    uint256 private _minBounty;

    uint32 private immutable _bountyDuration;

    uint64  private constant _MAX_BPS = 10000;

    /// @dev Bounty ID --> Bounty
    mapping(uint256 => Bounty) private _bounties;

    /// @dev Bounty ID --> Submission[], contains queues of submissions to bounties
    mapping(uint256 => Submission[]) private _submissions;

    /// @dev Approver address --> is approver
    mapping(address => bool) private _approvers;

    /// @notice Struct representing a bounty
    /// @dev No submissions may be posted to the bounty after the unlock time. If there is are
    /// active submissions when the unlock time is reached, they may still be approved after the
    /// unlock time. The bounty is only considered closed when it is past the expiration AND there
    /// are no active submissions. The ID corresponds to a record kept on the Arkham platform - or
    /// in the future, on any number of secondary serivices.
    struct Bounty {
        uint256 amount;
        uint256 initialAmount;
        uint64 expiration;
        address funder;
        uint32 queueIndex;
        bool closed;
    }

    /// @notice Struct representing a submission to a bounty
    /// @dev The payload is a hash of the submission ID and the submitter's address to prevent
    /// front-running. This ID corresponds to a record on the Arkham platform - or, in the future,
    /// any secondary service that bounty-approvers can use to verify the submission.
    struct Submission {
        bytes32 payload;
        address submitter;
        uint256 stake;
    }

    /// @notice Emitted when a bounty is funded
    /// @param bountyID The ID of the funded bounty
    /// @param funder The address of the funder
    /// @param initialValue The initial value of the bounty
    /// @param expiration The unlock time of the bounty
    event FundBounty (
        uint256 indexed bountyID,
        address indexed funder,
        uint256 initialValue,
        uint64  expiration
    );

    /// @notice Emitted when a submission is made for a bounty
    /// @param bountyID The ID of the bounty for which the submission is made
    /// @param submitter The address of the submitter
    /// @param stake The stake of the submission
    /// @param payload The payload of the submission
    /// @param queueIndex The queue index of the submission
    /// @param currentQueueIndex The current queue index of the bounty the submission was made to
    event FundSubmission (
        uint256 indexed bountyID,
        address indexed submitter,
        uint256 stake,
        bytes32 payload,
        uint32 queueIndex,
        uint32 currentQueueIndex
    );

    /// @notice Emitted when a submission for a bounty is rejected
    /// @param bountyID The ID of the bounty for which the submission is rejected
    /// @param submitter The address of the submitter
    /// @param stake The stake of the rejected submission
    /// @param payload The payload of the rejected submission
    /// @param queueIndex The queue index of the submission
    /// @param queueLength The queue length of the bounty the submission was made to
    event RejectSubmission (
        uint256 indexed bountyID,
        address indexed submitter,
        uint256 stake,
        bytes32 payload,
        uint32 queueIndex,
        uint32 queueLength
    );

    /// @notice Emitted when a submission for a bounty is approved
    /// @param bountyID The ID of the bounty for which the submission is approved
    /// @param submitter The address of the submitter
    /// @param stake The stake of the approved submission
    /// @param payload The payload of the approved submission
    /// @param payoutToSubmitter The payout to the submitter
    /// @param queueIndex The queue index of the submission
    /// @param queueLength The queue length of the bounty the submission was made to
    event SubmissionApproved (
        uint256 indexed bountyID,
        address indexed submitter,
        uint256 stake,
        bytes32 payload,
        uint256 payoutToSubmitter,
        uint32 queueIndex,
        uint32 queueLength
    );

    /// @notice Emitted when a bounty is closed
    /// @param bountyID The ID of the closed bounty
    /// @param funder The address of the funder
    /// @param payoutToFunder The payout to the funder
    /// @param excessFromStaking The excess fees
    /// @param queueLength The total number of rejected submissions in the queue
    event CloseBounty (
        uint256 indexed bountyID,
        address indexed funder,
        address indexed closedBy,
        uint256 payoutToFunder,
        uint256 excessFromStaking,
        uint32 queueLength
    );

    /// @notice Emitted when an account is granted approver status
    /// @param account The account granted approver status
    event GrantApprover (
        address indexed account
    );

    /// @notice Emitted when an account has its approver status revoked
    /// @param account The account that had its approver status revoked
    event RevokeApprover (
        address indexed account
    );

    /// @notice Emitted when the maker fee is set
    /// @param newFee The new maker fee
    /// @param oldFee The old maker fee
    event SetMakerFee (
        uint256 newFee,
        uint256 oldFee
    );

    /// @notice Emitted when the taker fee is set
    /// @param newFee The new taker fee
    /// @param oldFee The old taker fee
    event SetTakerFee (
        uint256 newFee,
        uint256 oldFee
    );

    /// @notice Emitted when the submission stake is set
    /// @param newStake The new submission stake
    /// @param oldStake The old submission stake
    event SetSubmissionStake (
        uint256 newStake,
        uint256 oldStake
    );

    /// @notice Emitted when the contract stops accepting bounties
    event CloseBountySubmissions ();

    /// @notice Emitted when accrued fees are withdrawn
    /// @param amount The amount of accrued fees withdrawn
    event WithdrawFees (
        uint256 amount
    );

    /// @notice Contract constructor that sets initial values
    /// @param arkmAddress Address of the ERC20 token to be used (ARKM)
    /// @param initialSubmissionStake Initial stake required for a submission, e.g. 10 e18
    /// @param initialMakerFee Initial fee for creating a bounty, in basis points
    /// @param initialTakerFee Initial fee for completing a bounty, in basis points
    /// @param bountyDuration Duration of a bounty, in days, i.e. time until expiration
    /// @dev The burnable check makes sure the token is an ERC20. We are not currently using burn
    /// functionality. ARKM passes the burnable check, so if it fails we know we are trying to
    /// deploy with the wrong token contract address.
    constructor(address arkmAddress, uint256 initialSubmissionStake, uint256 initialMakerFee, uint256 initialTakerFee, uint32 bountyDuration, address feeReceiverAddress, uint32 initialMaxActiveSubmissions, uint256 initialMinBounty) {
        require(initialMakerFee <= _MAX_BPS, "BountyV2: maker fee must be <= 10000");
        require(initialTakerFee <= _MAX_BPS, "BountyV2: taker fee must be <= 10000");
        require(feeReceiverAddress != address(0), "BountyV2: fee receiver address cannot be 0x0");
        require(bountyDuration <= 36500, "BountyV2: bounty duration must be <= 36500 days");


        try ERC20Burnable(arkmAddress).totalSupply() returns (uint256) {
            _arkm = arkmAddress;
        } catch {
            revert("BountyV2: provided token address does not implement ERC20Burnable");
        }

        _submissionStake = initialSubmissionStake;
        _makerFee = initialMakerFee;
        _takerFee = initialTakerFee;
        _acceptingBounties = true;
        _bountyDuration = bountyDuration;
        _feeReceiverAddress = feeReceiverAddress;
        _maxActiveSubmissions = initialMaxActiveSubmissions;
        _minBounty = initialMinBounty;
    }

    /// @return The amount of ARKM accrued from fees
    function accruedFees() public view virtual returns (uint256) {
        return _accruedFees;
    }

    /// @return The address of the ERC20 token to be used
    function arkm() public view virtual returns (address) {
        return _arkm;
    }

    /// @return The fee for creating a bounty, in basis points
    function makerFee() public view virtual returns (uint256) {
        return _makerFee;
    }

    /// @return The fee for completing a bounty, in basis points
    function takerFee() public view virtual returns (uint256) {
        return _takerFee;
    }

    /// @return The stake required for a submission, in value of the ERC20 token
    function submissionStake() public view virtual returns (uint256) {
        return _submissionStake;
    }

    /// @return The minimum bounty amount
    function minBounty() public view virtual returns (uint256) {
        return _minBounty;
    }

    /// @return The max number of active submissions
    function maxActiveSubmissions() public view virtual returns (uint32) {
        return _maxActiveSubmissions;
    }

    /// @return The duration of a bounty, in days
    function bountyDurationDays() public view virtual returns (uint64) {
        return _bountyDuration;
    }

    /// @param bounty The int representation of the UUID of the bounty
    function funder(uint256 bounty) public view virtual returns (address) {
        return _bounties[bounty].funder;
    }

    /// @param bounty The ID of the bounty
    /// @return The amount of the bounty
    function amount(uint256 bounty) public view virtual returns (uint256) {
        return _bounties[bounty].amount;
    }

    /// @param bounty The ID of the bounty
    /// @return The initial amount of the bounty
    function initialAmount(uint256 bounty) public view virtual returns (uint256) {
        return _bounties[bounty].initialAmount;
    }

    /// @param bounty The ID of the bounty
    /// @return The expiration time of the bounty
    function expiration(uint256 bounty) public view virtual returns (uint64) {
        return _bounties[bounty].expiration;
    }

    /// @param bounty The ID of the bounty
    /// @return The current queue index of the bounty
    /// @dev The queue index is used to move through the list of submission made for a bounty. If
    /// the queue index is 3, the 4th submission in the list is the current one -- or, if there
    /// are only 3 submissions, there is no current submission. Anything submissions prior to th
    /// current queueIndex are rejected, any above are yet to be officially reviewed.
    function bountyQueueIndex(uint256 bounty) public view virtual returns (uint32) {
        return _bounties[bounty].queueIndex;
    }


    /// @param bounty The ID of the bounty
    /// @return The payload of the approved submission or 0 if none
    function approvedSubmission(uint256 bounty) public view virtual returns (bytes32) {
        if (!_bounties[bounty].closed) return 0;
        if (submissionsCount(bounty) <= bountyQueueIndex(bounty)) return 0;
        return _submissions[bounty][bountyQueueIndex(bounty)].payload;
    }

    /// @param bounty The ID of the bounty
    /// @return The total number of submissions received for the bounty
    function submissionsCount(uint256 bounty) public view virtual returns (uint32) {
        return uint32(_submissions[bounty].length);
    }

    /// @param bounty the ID of the bounty
    /// @return The number of active (un-rejected) submissions for the bounty
    function activeSubmissionsCount(uint256 bounty) internal view returns (uint32) {
        return submissionsCount(bounty) - bountyQueueIndex(bounty);
    }

    /// @param bounty The ID of the bounty
    /// @return Whether the bounty is closed or not
    /// @dev 'closed' is only true once a submission has been approved OR the bounty has been
    /// closed by the funder, which can only happen after the unlock time when there is no active
    /// submission.
    function closed(uint256 bounty) public view virtual returns (bool) {
        return _bounties[bounty].closed;
    }

    /// @param payload The payload to check
    /// @param bounty The ID of the bounty the submission corresponds to
    /// @return Whether the payload has been rejected or not
    function rejectedPayload(bytes32 payload, uint256 bounty) public view virtual returns (bool) {
        uint32 _queueIndex = bountyQueueIndex(bounty);
        for (uint32 i = 0; i < _queueIndex; i++) {
            if (_submissions[bounty][i].payload == payload) {
                return true;
            }
        }
        return false;
    }

    /// @param submission The ID of the submission
    /// @param bounty The ID of the bounty the submission corresponds to
    /// @return The position of the submission in the queue
    /// @dev Used to tell our off-chain record about a submission's position.
    function submissionQueuePosition(uint256 submission, uint256 bounty) public view virtual returns (uint32) {
        uint32 _numSubmissions = submissionsCount(bounty);
        for (uint32 i = 0; i < _numSubmissions; i++) {
            if (_submissions[bounty][i].payload == keccak256(abi.encodePacked(submission, _submissions[bounty][i].submitter))) {
                return i;
            }
        }

        revert("BountyV2: submission not found");
    }

    /// @param position The position in the queue
    /// @param bounty The ID of the bounty the submission corresponds to
    /// @return The submitter of the submission at the position in the queue
    function submitterAtPosition(uint32 position, uint256 bounty) public view virtual returns (address) {
        return _submissions[bounty][position].submitter;
    }

    /// @param position The position in the queue
    /// @param bounty The ID of the bounty the submission corresponds to
    /// @return The stake of the submission at the position in the queue
    function stakeAtPosition(uint32 position, uint256 bounty) public view virtual returns (uint256) {
        return _submissions[bounty][position].stake;
    }

    /// @param account The account to check
    /// @return Whether the account is an approver or not
    function approver(address account) public view virtual returns (bool) {
        return _approvers[account];
    }

    /// @return Whether the contract is accepting bounties or not
    function acceptingBounties() public view virtual returns (bool) {
        return _acceptingBounties;
    }

    /// @param value The value to calculate the fee from
    /// @param maker Whether the fee is for creating a bounty or not
    /// @return The calculated fee
    /// @dev The 10000 accounts for denomination in basis points.
    function fee(uint256 value, bool maker) public view virtual returns (uint256) {
        return value * (maker ? _makerFee : _takerFee) / 10000;
    }

    /// @notice Modifier to require that the caller is an approver
    modifier onlyApprover() {
        require(approver(_msgSender()), "BountyV2: caller is not approver");
        _;
    }

    /// @notice Funds a bounty
    /// @param bounty The ID of the bounty to fund
    /// @param _amount The amount of the ERC20 to fund the bounty with
    /// @dev Additional bounty information like name and description is stored on an off-chain
    /// platform, e.g. Arkham. In the current implementation, Bounty records are generated
    /// on the Arkham platform and the bountyID is the int representation of the UUID of those
    /// records.
    function fundBounty(uint256 bounty, uint256 _amount) external {
        require(_acceptingBounties, "BountyV2: contract no longer accepting bounties");
        require(amount(bounty) == 0, "BountyV2: bounty already funded");
        require(_amount >= _minBounty, "BountyV2: below minimum bounty");

        // Should not allow funding a bounty that is closed. However that is covered by the
        // fact that you can not fund an already funded bounty and you can not close an
        // unfunded bounty.

        uint256 _fee = fee(_amount, true);

        _accruedFees += _fee;

        uint64 _expiration = uint64(block.timestamp + _bountyDuration * 1 days);

        _bounties[bounty] = Bounty({
            amount: _amount,
            initialAmount: _amount,
            expiration: _expiration,
            funder: _msgSender(),
            closed: false,
            queueIndex: 0
        });

        SafeERC20.safeTransferFrom(IERC20(_arkm), _msgSender(), address(this), _amount + _fee);

        emit FundBounty(
            bounty,
            _msgSender(),
            _amount,
            _expiration
        );
    }

    /// @notice Closes a bounty and returns the funds to the funder
    /// @param bounty The ID of the bounty to close
    /// @dev The bounty may be closed by anyone after the unlock time when there is no active
    /// submission. Funds are returned to the funder. Approvers can close bounties before expiration.
    function closeBounty(uint256 bounty) external {
        require(amount(bounty) > 0, "BountyV2: bounty not funded");
        require(expiration(bounty) <= block.timestamp || approver(_msgSender()), "BountyV2: only approvers can close before expiration");
        require(activeSubmissionsCount(bounty) == 0, "BountyV2: has active submission");
        require(!closed(bounty), "BountyV2: bounty already closed");

        /// @dev Staked funds from rejected submissions have added to the ammount. Accrue as fees.
        uint256 excessFromStaking = _bounties[bounty].amount - _bounties[bounty].initialAmount;
        _accruedFees += excessFromStaking;

        // There are no active submissions, so there are no more stakes to be returned.

        SafeERC20.safeTransfer(IERC20(_arkm), _bounties[bounty].funder, _bounties[bounty].initialAmount);
        _bounties[bounty].closed = true;

        emit CloseBounty(
            bounty,
            _bounties[bounty].funder,
            _msgSender(),
            _bounties[bounty].initialAmount,
            excessFromStaking,
            submissionsCount(bounty)
        );
    }

    /// @notice Makes a submission for a bounty by staking the ERC20
    /// @param bounty The ID of the bounty to make a submission to
    /// @param payload The payload of the submission, used to validate the sender's address
    /// @dev The payload is a hash of the submission ID and the submitter's address to prevent
    /// front-running. All submissions must provide a stake, which is returned if the submission
    /// is approved (less fees) or forfeit (and added to the bounty) if the submission is rejected.
    /// This is to prevent spamming of submissions.
    function makeSubmission(uint256 bounty, bytes32 payload) external {
        require(!closed(bounty), "BountyV2: bounty closed");
        require(amount(bounty) > 0, "BountyV2: bounty not funded");
        require(expiration(bounty) > block.timestamp, "BountyV2: bounty expired");
        require(!rejectedPayload(payload, bounty), "BountyV2: payload rejected");
        require(!approver(_msgSender()), "BountyV2: approvers cannot submit");
        require(activeSubmissionsCount(bounty) < _maxActiveSubmissions, "BountyV2: max active submissions reached");

        _submissions[bounty].push(Submission({
            payload: payload,
            submitter: _msgSender(),
            stake: _submissionStake
        }));

        SafeERC20.safeTransferFrom(IERC20(_arkm), _msgSender(), address(this), _submissionStake);

        emit FundSubmission(
            bounty,
            _msgSender(),
            _submissionStake,
            payload,
            bountyQueueIndex(bounty),
            uint32(_submissions[bounty].length - 1)
        );
    }

    /// @notice Approves and pays out for a submission to a bounty
    /// @param bounty The ID of the bounty whose submission to approve
    /// @param index The index of the submission to approve
    /// @dev The bounty is paid out to the address that submitted the approved submission, plus
    /// their initial stake, less fees. The bounty is closed and will no longer receive
    /// submissions. Off-chain, the information corresponding to the submission ID is delivered to
    /// the funder.
    function approveSubmissionAt(uint256 bounty, uint32 index) internal {
        // Approving a submission on a closed bounty is not allowed but handled by check that makes
        // it impossible to submit to a closed bounty and the check that makes it impossible to close
        // a bounty that has an active submission.

        require(_submissions[bounty][index].submitter != _msgSender(), "BountyV2: cannot approve own submission");

        /// @dev If there have been other rejected submissions, their stake will be reflected in
        /// the bounty amount.
        uint256 _amount = amount(bounty);
        uint256 _stake = _submissions[bounty][index].stake;
        _accruedFees += fee(_amount, false);

        uint256 payout = _amount + _stake - fee(_amount, false);
        SafeERC20.safeTransfer(IERC20(_arkm), _submissions[bounty][index].submitter, payout);

        _bounties[bounty].closed = true;

        emit SubmissionApproved(
            bounty,
            _submissions[bounty][index].submitter,
            _stake,
            _submissions[bounty][index].payload,
            payout,
            index,
            submissionsCount(bounty)
        );
    }

    /// @notice Approves the Nth submission for a bounty (0-indexed)
    /// @param bounty The ID of the bounty whose submission to approve
    /// @param submission The ID of the submission to approve
    /// @dev Un-assessed submissions get their stakes returned.
    function approveSubmission(uint256 bounty, uint256 submission) external onlyApprover {

        bool _foundSubmission = false;

        for (uint32 i = _bounties[bounty].queueIndex; i < submissionsCount(bounty); i++) {
            // If we've already approved, refund stake.
            if (_foundSubmission) {
                SafeERC20.safeTransfer(IERC20(_arkm), _submissions[bounty][i].submitter, _submissions[bounty][i].stake);
            }

            // If this address hashes with the submission ID to produce this payload, it is the
            // target.
            else if (_submissions[bounty][i].payload == keccak256(abi.encodePacked(submission, _submissions[bounty][i].submitter))) {
                _foundSubmission = true;
                approveSubmissionAt(bounty, i);
            }

            //
            else {
                rejectSubmission(bounty);
            }
        }

        require(_foundSubmission, "BountyV2: submission not found");
    }

    /// @notice Rejects N submissions for a bounty
    /// @param bounty The ID of the bounty whose submissions to reject
    /// @param n The number of submissions to reject
    function rejectSubmissions(uint256 bounty, uint32 n) public onlyApprover {
        require(activeSubmissionsCount(bounty) >= n, "BountyV2: not enough active submissions");

        for (uint32 i = 0; i < n; i++) {
            rejectSubmission(bounty);
        }
    }

    /// @notice Rejects a submission for a bounty
    /// @param bounty The ID of the bounty whose submission to reject
    /// @dev The stake of the rejected submission is added to the bounty amount. The queueIndex for
    /// the bounty is incremented to move to the next submission in the queue.
    function rejectSubmission(uint256 bounty) internal {
        // If there are active submissions, we can reject one.

        uint32 _currentPosition = bountyQueueIndex(bounty);
        uint256 _stake = _submissions[bounty][_currentPosition].stake;
        bytes32 _payload = _submissions[bounty][_currentPosition].payload;

        uint256 _stakeFee = fee(_stake, true);

        _accruedFees += _stakeFee;
        _bounties[bounty].amount += _stake - _stakeFee;
        _bounties[bounty].queueIndex += 1;

        emit RejectSubmission(
            bounty,
            _submissions[bounty][_currentPosition].submitter,
            _stake,
            _payload,
            bountyQueueIndex(bounty),
            submissionsCount(bounty)
        );
    }

    /// @notice Grants approver status to an account
    /// @param account The account to grant approver status to
    /// @dev There can be any number of approvers. Only one approver is required to approve a
    /// submission.
    function grantApprover(address account) external onlyOwner {
        require(!approver(account), "BountyV2: already approver");
        _approvers[account] = true;

        emit GrantApprover(
            account
        );
    }

    /// @notice Revokes approver status from an account
    /// @param account The account to revoke approver status from
    function revokeApprover(address account) external onlyOwner {
        require(approver(account), "BountyV2: not approver");
        _approvers[account] = false;

        emit RevokeApprover(
            account
        );
    }


    /// @notice Sets a new maker fee
    /// @param newFee The new maker fee, in basis points
    function setMakerFee(uint256 newFee) external onlyOwner {
        require(newFee <= _MAX_BPS, "BountyV2: maker fee must be <= 100%");
        uint256 _oldFee = _makerFee;
        _makerFee = newFee;

        emit SetMakerFee(
            newFee,
            _oldFee
        );
    }

    /// @notice Sets a new taker fee
    /// @param newFee The new taker fee, in basis points
    function setTakerFee(uint256 newFee) external onlyOwner {
        require(newFee <= _MAX_BPS, "BountyV2: taker fee must be <= 100%");
        uint256 _oldFee = _takerFee;
        _takerFee = newFee;

        emit SetTakerFee(
            newFee,
            _oldFee
        );
    }

    /// @notice Sets a new submission stake
    /// @param newStake The new submission stake, in value of the ERC20 token e.g. 10 e18
    function setSubmissionStake(uint256 newStake) external onlyOwner {
        uint256 _oldStake = _submissionStake;
        _submissionStake = newStake;

        emit SetSubmissionStake(
            newStake,
            _oldStake
        );
    }

    /// @notice Sets a new minimum bounty
    /// @param newMinBounty The new minimum bounty
    function setMinBounty(uint256 newMinBounty) external onlyOwner {
        _minBounty = newMinBounty;
    }

    /// @notice Sets a new max active submissions
    /// @param newMaxActiveSubmissions The new max active submissions
    function setMaxActiveSubmissions(uint32 newMaxActiveSubmissions) external onlyOwner {
        _maxActiveSubmissions = newMaxActiveSubmissions;
    }

    /// @notice Sets a new fee receiver address
    /// @param feeReceiverAddress The new fee receiver address
    /// @dev This is the address that will receive fees.
    function setFeeReceiverAddress(address feeReceiverAddress) external onlyOwner {
        require(feeReceiverAddress != address(0), "BountyV2: fee receiver address cannot be 0x0");
        _feeReceiverAddress = feeReceiverAddress;
    }

    /// @notice Prevent any further bounties from being created
    /// @dev This is how we will sunset the contract when we want to move to a new version. It's
    /// important that we continue to allow submissions to existing bounties until they all expire.
    /// Once all bounties have expired and we have approved or rejected all submissions, we can
    /// disburse any remaining fees.
    function stopAcceptingBounties() external onlyOwner {
        _acceptingBounties = false;

        emit CloseBountySubmissions();
    }

    /// @notice Withdraw accrued fees
    /// @dev This can be called periodically by the owner.
    function withdrawFees() external onlyOwner {
        uint256 fees = _accruedFees;
        _accruedFees = 0;
        SafeERC20.safeTransfer(IERC20(_arkm), _feeReceiverAddress, fees);

        emit WithdrawFees(
            fees
        );
    }
}