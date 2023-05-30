// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

/// @title Dynamic Vesting Escrow
/// @author Curve Finance, Yearn Finance, vasa (@vasa-develop)
/// @notice A vesting escsrow for dynamic teams, based on Curve vesting escrow
/// @dev A vesting escsrow for dynamic teams, based on Curve vesting escrow

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DynamicVestingEscrow is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /**
    Paused: Vesting is paused. Recipient can be Unpaused by the owner.
    UnPaused: Vesting is unpaused. The vesting resumes from the time it was paused (in case the recipient was paused).
    Terminated: Recipient is terminated, meaning vesting is stopped and claims are blocked forever. No way to go back. 
    */
    enum Status {Terminated, Paused, UnPaused}

    struct Recipient {
        uint256 startTime; // timestamp at which vesting period will start (should be in future)
        uint256 endTime; // timestamp at which vesting period will end (should be in future)
        uint256 cliffDuration; // time duration after startTime before which the recipient cannot call claim
        uint256 lastPausedAt; // latest timestamp at which vesting was paused
        uint256 vestingPerSec; // constant number of tokens that will be vested per second.
        uint256 totalVestingAmount; // total amount that can be vested over the vesting period.
        uint256 totalClaimed; // total amount of tokens that have been claimed by the recipient.
        Status recipientVestingStatus; // current vesting status
    }

    mapping(address => Recipient) public recipients; // mapping from recipient address to Recipient struct
    mapping(address => bool) public lockedTokensSeizedFor; // in case of escrow termination, a mapping to keep track of which
    address public token; // vesting token address
    // WARNING: The contract assumes that the token address is NOT malicious.

    uint256 public dust; // total amount of token that is sitting as dust in this contract (unallocatedSupply)
    uint256 public totalClaimed; // total number of tokens that have been claimed.
    uint256 public totalAllocatedSupply; // total token allocated to the recipients via addRecipients.
    uint256 public ESCROW_TERMINATED_AT; // timestamp at which escow terminated.
    address public SAFE_ADDRESS; // an address where all the funds are sent in case any recipient or vesting escrow is terminated.
    bool public ALLOW_PAST_START_TIME = false; // a flag that decides if past startTime is allowed for any recipient.
    bool public ESCROW_TERMINATED = false; // global switch to terminate the vesting escrow. See more info in terminateVestingEscrow()

    modifier escrowNotTerminated() {
        // escrow should NOT be in terminated state
        require(!ESCROW_TERMINATED, "escrowNotTerminated: escrow terminated");
        _;
    }

    modifier isNonZeroAddress(address recipient) {
        // recipient should NOT be a 0 address
        require(recipient != address(0), "isNonZeroAddress: 0 address");
        _;
    }

    modifier recipientIsUnpaused(address recipient) {
        // recipient should NOT be a 0 address
        require(recipient != address(0), "recipientIsUnpaused: 0 address");
        // recipient should be in UnPaused status
        require(
            recipients[recipient].recipientVestingStatus == Status.UnPaused,
            "recipientIsUnpaused: recipient NOT in UnPaused state"
        );
        _;
    }

    modifier recipientIsNotTerminated(address recipient) {
        // recipient should NOT be a 0 address
        require(recipient != address(0), "recipientIsNotTerminated: 0 address");
        // recipient should NOT be in Terminated status
        require(
            recipients[recipient].recipientVestingStatus != Status.Terminated,
            "recipientIsNotTerminated: recipient terminated"
        );
        _;
    }

    constructor(address _token, address _safeAddress) {
        // SAFE_ADDRESS should NOT be 0 address
        require(_safeAddress != address(0), "constructor: SAFE_ADDRESS cannot be 0 address");
        // token should NOT be 0 address
        require(_token != address(0), "constructor: token cannot be 0 address");
        SAFE_ADDRESS = _safeAddress;
        token = _token;
    }

    /// @notice Terminates the vesting escrow forever.
    /// @dev All the vesting states will be freezed, recipients can still claim their vested tokens.
    ///      Only owner of the vesting escrow can invoke this function.
    ///      Can only be invoked if the escrow is NOT terminated.
    function terminateVestingEscrow() external onlyOwner escrowNotTerminated {
        // set termination variables
        ESCROW_TERMINATED = true;
        ESCROW_TERMINATED_AT = block.timestamp;
    }

    /// @notice Updates the SAFE_ADDRESS
    /// @dev It is assumed that the SAFE_ADDRESS is NOT malicious
    ///      Only owner of the vesting escrow can invoke this function.
    ///      Can only be invoked if the escrow is NOT terminated.
    /// @param safeAddress An address where all the tokens are transferred in case of a (recipient/escrow) termination
    function updateSafeAddress(address safeAddress) external onlyOwner escrowNotTerminated {
        // Check if the safeAddress is NOT a 0 address
        require(safeAddress != address(0), "updateSafeAddress: SAFE_ADDRESS cannot be 0 address");
        SAFE_ADDRESS = safeAddress;
    }

    /// @notice Add and fund new recipients.
    /// @dev Owner of the vesting escrow needs to approve tokens to this contract
    ///      Only owner of the vesting escrow can invoke this function.
    ///      Can only be invoked if the escrow is NOT terminated.
    /// @param _recipients An array of recipient addresses
    /// @param _amounts An array of amounts to be vested by the corresponding recipient addresses
    /// @param _startTimes An array of startTimes of the vesting schedule for the corresponding recipient addresses
    /// @param _endTimes An array of endTimes of the vesting schedule for the corresponding recipient addresses
    /// @param _cliffDurations An array of cliff durations of the vesting schedule for the corresponding recipient addresses
    /// @param _totalAmount Total sum of the amounts in the _amounts array
    function addRecipients(
        address[] calldata _recipients,
        uint256[] calldata _amounts,
        uint256[] calldata _startTimes,
        uint256[] calldata _endTimes,
        uint256[] calldata _cliffDurations,
        uint256 _totalAmount
    ) external onlyOwner escrowNotTerminated {
        // Every input should be of equal length (greater than 0)
        require(
            (_recipients.length == _amounts.length) &&
                (_amounts.length == _startTimes.length) &&
                (_startTimes.length == _endTimes.length) &&
                (_endTimes.length == _cliffDurations.length) &&
                (_recipients.length != 0),
            "addRecipients: invalid params"
        );

        // _totalAmount should be greater than 0
        require(_totalAmount > 0, "addRecipients: zero totalAmount not allowed");

        // transfer funds from the msg.sender
        // Will fail if the allowance is less than _totalAmount
        IERC20(token).safeTransferFrom(msg.sender, address(this), _totalAmount);

        // register _totalAmount before allocation
        uint256 _before = _totalAmount;

        // populate recipients mapping
        for (uint256 i = 0; i < _amounts.length; i++) {
            // recipient should NOT be a 0 address
            require(_recipients[i] != address(0), "addRecipients: recipient cannot be 0 address");
            // if past startTime is NOT allowed, then the startTime should be in future
            require(ALLOW_PAST_START_TIME || (_startTimes[i] >= block.timestamp), "addRecipients: invalid startTime");
            // endTime should be greater than startTime
            require(_endTimes[i] > _startTimes[i], "addRecipients: endTime should be after startTime");
            // cliffDuration should be less than vesting duration
            require(_cliffDurations[i] < _endTimes[i].sub(_startTimes[i]), "addRecipients: cliffDuration too long");
            // amount should be greater than 0
            require(_amounts[i] > 0, "addRecipients: vesting amount cannot be 0");
            // add recipient to the recipients mapping
            recipients[_recipients[i]] = Recipient(
                _startTimes[i],
                _endTimes[i],
                _cliffDurations[i],
                0,
                // vestingPerSec = totalVestingAmount/(endTimes-(startTime+cliffDuration))
                _amounts[i].div(_endTimes[i].sub(_startTimes[i].add(_cliffDurations[i]))),
                _amounts[i],
                0,
                Status.UnPaused
            );
            // reduce _totalAmount
            // Will revert if the _totalAmount is less than sum of _amounts
            _totalAmount = _totalAmount.sub(_amounts[i]);
        }
        // add the allocated token amount to totalAllocatedSupply
        totalAllocatedSupply = totalAllocatedSupply.add(_before.sub(_totalAmount));
        // register remaining _totalAmount as dust
        dust = dust.add(_totalAmount);
    }

    /// @notice Pause recipient vesting
    /// @dev This freezes the vesting schedule for the paused recipient.
    ///      Recipient will NOT be able to claim until unpaused.
    ///      Only owner of the vesting escrow can invoke this function.
    ///      Can only be invoked if the escrow is NOT terminated.
    /// @param recipient The recipient address for which vesting will be paused.
    function pauseRecipient(address recipient) external onlyOwner escrowNotTerminated isNonZeroAddress(recipient) {
        // current recipient status should be UnPaused
        require(recipients[recipient].recipientVestingStatus == Status.UnPaused, "pauseRecipient: cannot pause");
        // set vesting status of the recipient as Paused
        recipients[recipient].recipientVestingStatus = Status.Paused;
        // set lastPausedAt timestamp
        recipients[recipient].lastPausedAt = block.timestamp;
    }

    /// @notice UnPause recipient vesting
    /// @dev This unfreezes the vesting schedule for the paused recipient. Recipient will be able to claim.
    ///      In order to keep vestingPerSec for the recipient a constant, cliffDuration and endTime for the
    ///      recipient are shifted by the pause duration so that the recipient resumes with the same state
    ///      at the time it was paused.
    ///      Only owner of the vesting escrow can invoke this function.
    ///      Can only be invoked if the escrow is NOT terminated.
    /// @param recipient The recipient address for which vesting will be unpaused.
    function unPauseRecipient(address recipient) external onlyOwner escrowNotTerminated isNonZeroAddress(recipient) {
        // current recipient status should be Paused
        require(recipients[recipient].recipientVestingStatus == Status.Paused, "unPauseRecipient: cannot unpause");
        // set vesting status of the recipient as "UnPaused"
        recipients[recipient].recipientVestingStatus = Status.UnPaused;
        // calculate the time for which the recipient was paused for
        uint256 pausedFor = block.timestamp.sub(recipients[recipient].lastPausedAt);
        // extend the cliffDuration by the pause duration
        recipients[recipient].cliffDuration = recipients[recipient].cliffDuration.add(pausedFor);
        // extend the endTime by the pause duration
        recipients[recipient].endTime = recipients[recipient].endTime.add(pausedFor);
    }

    /// @notice Terminate recipient vesting
    /// @dev This terminates the vesting schedule for the recipient forever.
    ///      Recipient will NOT be able to claim.
    ///      Only owner of the vesting escrow can invoke this function.
    ///      Can only be invoked if the escrow is NOT terminated.
    /// @param recipient The recipient address for which vesting will be terminated.
    function terminateRecipient(address recipient) external onlyOwner escrowNotTerminated isNonZeroAddress(recipient) {
        // current recipient status should NOT be Terminated
        require(recipients[recipient].recipientVestingStatus != Status.Terminated, "terminateRecipient: cannot terminate");
        // claim for the user if possible
        if (canClaim(recipient)) {
            // transfer unclaimed tokens to the recipient
            _claimFor(claimableAmountFor(recipient), recipient);
            // transfer locked tokens to the SAFE_ADDRESS
        }
        uint256 _bal = recipients[recipient].totalVestingAmount.sub(recipients[recipient].totalClaimed);
        IERC20(token).safeTransfer(SAFE_ADDRESS, _bal);
        // set vesting status of the recipient as "Terminated"
        recipients[recipient].recipientVestingStatus = Status.Terminated;
    }

    /// @notice Claim a specific amount of tokens.
    /// @dev Claim a specific amount of tokens.
    ///      Will revert if amount parameter is greater than the claimable amount
    ///      of tokens for the recipient at the time of function invocation.
    ///      Can be invoked by any non-terminated recipient.
    /// @param amount The amount of tokens recipient wants to claim.
    function claim(uint256 amount) external {
        _claimFor(amount, msg.sender);
    }

    // claim tokens for a specific recipient
    function _claimFor(uint256 _amount, address _recipient) internal {
        // get recipient
        Recipient storage recipient = recipients[_recipient];

        // recipient should be able to claim
        require(canClaim(_recipient), "_claimFor: recipient cannot claim");

        // max amount the user can claim right now
        uint256 claimableAmount = claimableAmountFor(_recipient);

        // amount parameter should be less or equal to than claimable amount
        require(_amount <= claimableAmount, "_claimFor: cannot claim passed amount");

        // increase user specific totalClaimed
        recipient.totalClaimed = recipient.totalClaimed.add(_amount);

        // user's totalClaimed should NOT be greater than user's totalVestingAmount
        require(recipient.totalClaimed <= recipient.totalVestingAmount, "_claimFor: cannot claim more than you deserve");

        // increase global totalClaimed
        totalClaimed = totalClaimed.add(_amount);

        // totalClaimed should NOT be greater than total totalAllocatedSupply
        require(totalClaimed <= totalAllocatedSupply, "_claimFor: cannot claim more than allocated to escrow");

        // transfer the amount to the _recipient
        IERC20(token).safeTransfer(_recipient, _amount);
    }

    /// @notice Get total vested tokens for multiple recipients.
    /// @dev Reverts if any of the recipients is terminated.
    /// @param _recipients An array of non-terminated recipient addresses.
    /// @return totalAmount total vested tokens for all _recipients passed.
    function batchTotalVestedOf(address[] memory _recipients) public view returns (uint256 totalAmount) {
        for (uint256 i = 0; i < _recipients.length; i++) {
            totalAmount = totalAmount.add(totalVestedOf(_recipients[i]));
        }
    }

    /// @notice Get total vested tokens of a specific recipient.
    /// @dev Reverts if the recipient is terminated.
    /// @param recipient A non-terminated recipient address.
    /// @return Total vested tokens for the recipient address.
    function totalVestedOf(address recipient) public view recipientIsNotTerminated(recipient) returns (uint256) {
        // get recipient
        Recipient memory _recipient = recipients[recipient];

        // totalVested = totalClaimed + claimableAmountFor
        return _recipient.totalClaimed.add(claimableAmountFor(recipient));
    }

    /// @notice Check if a recipient address can successfully invoke claim.
    /// @dev Reverts if the recipient is a zero address.
    /// @param recipient A zero address recipient address.
    /// @return bool representing if the recipient can successfully invoke claim.
    function canClaim(address recipient) public view isNonZeroAddress(recipient) returns (bool) {
        Recipient memory _recipient = recipients[recipient];

        // terminated recipients cannot claim
        if (_recipient.recipientVestingStatus == Status.Terminated) {
            return false;
        }

        // In case of a paused recipient
        if (_recipient.recipientVestingStatus == Status.Paused) {
            return _recipient.lastPausedAt >= _recipient.startTime.add(_recipient.cliffDuration);
        }

        // In case of a unpaused recipient, recipient can claim if the cliff duration (inclusive) has passed.
        return block.timestamp >= _recipient.startTime.add(_recipient.cliffDuration);
    }

    /// @notice Check the time after (inclusive) which recipient can successfully invoke claim.
    /// @dev Reverts if the recipient is a zero address.
    /// @param recipient A zero address recipient address.
    /// @return Returns the time after (inclusive) which recipient can successfully invoke claim.
    function claimStartTimeFor(address recipient)
        public
        view
        escrowNotTerminated
        recipientIsUnpaused(recipient)
        returns (uint256)
    {
        return recipients[recipient].startTime.add(recipients[recipient].cliffDuration);
    }

    /// @notice Get amount of tokens that can be claimed by a recipient at the current timestamp.
    /// @dev Reverts if the recipient is terminated.
    /// @param recipient A non-terminated recipient address.
    /// @return Amount of tokens that can be claimed by a recipient at the current timestamp.
    function claimableAmountFor(address recipient) public view recipientIsNotTerminated(recipient) returns (uint256) {
        // get recipient
        Recipient memory _recipient = recipients[recipient];

        // claimable = totalVestingAmount - (totalClaimed + locked)
        return _recipient.totalVestingAmount.sub(_recipient.totalClaimed.add(totalLockedOf(recipient)));
    }

    /// @notice Get total locked (non-vested) tokens for multiple non-terminated recipient addresses.
    /// @dev Reverts if any of the recipients is terminated.
    /// @param _recipients An array of non-terminated recipient addresses.
    /// @return totalAmount Total locked (non-vested) tokens for multiple non-terminated recipient addresses.
    function batchTotalLockedOf(address[] memory _recipients) public view returns (uint256 totalAmount) {
        for (uint256 i = 0; i < _recipients.length; i++) {
            totalAmount = totalAmount.add(totalLockedOf(_recipients[i]));
        }
    }

    /// @notice Get total locked tokens of a specific recipient.
    /// @dev Reverts if any of the recipients is terminated.
    /// @param recipient A non-terminated recipient address.
    /// @return Total locked tokens of a specific recipient.
    function totalLockedOf(address recipient) public view recipientIsNotTerminated(recipient) returns (uint256) {
        // get recipient
        Recipient memory _recipient = recipients[recipient];

        // We know that vestingPerSec is constant for a recipient for entirety of their vesting period
        // locked = vestingPerSec*(endTime-max(lastPausedAt, startTime+cliffDuration))
        if (_recipient.recipientVestingStatus == Status.Paused) {
            if (_recipient.lastPausedAt >= _recipient.endTime) {
                return 0;
            }
            return
                _recipient.vestingPerSec.mul(
                    _recipient.endTime.sub(
                        Math.max(_recipient.lastPausedAt, _recipient.startTime.add(_recipient.cliffDuration))
                    )
                );
        }

        // Nothing is locked if the recipient passed the endTime
        if (block.timestamp >= _recipient.endTime) {
            return 0;
        }

        // in case escrow is terminated, locked amount stays the constant
        if (ESCROW_TERMINATED) {
            return
                _recipient.vestingPerSec.mul(
                    _recipient.endTime.sub(
                        Math.max(ESCROW_TERMINATED_AT, _recipient.startTime.add(_recipient.cliffDuration))
                    )
                );
        }

        // We know that vestingPerSec is constant for a recipient for entirety of their vesting period
        // locked = vestingPerSec*(endTime-max(block.timestamp, startTime+cliffDuration))
        if (_recipient.recipientVestingStatus == Status.UnPaused) {
            return
                _recipient.vestingPerSec.mul(
                    _recipient.endTime.sub(Math.max(block.timestamp, _recipient.startTime.add(_recipient.cliffDuration)))
                );
        }
    }

    /// @notice Allows owner to transfer the ERC20 assets (other than token) to the "to" address in case of any emergency
    /// @dev It is assumed that the "to" address is NOT malicious
    ///      Only owner of the vesting escrow can invoke this function.
    ///      Reverts if the asset address is a zero address or the token address.
    ///      Reverts if the to address is a zero address.
    /// @param asset Address of the ERC20 asset to be rescued
    /// @param to Address to which all ERC20 asset amount will be transferred
    /// @return rescued Total amount of asset transferred to the SAFE_ADDRESS.
    function inCaseAssetGetStuck(address asset, address to) external onlyOwner returns (uint256 rescued) {
        // asset address should NOT be a 0 address
        require(asset != address(0), "inCaseAssetGetStuck: asset cannot be 0 address");
        // asset address should NOT be the token address
        require(asset != token, "inCaseAssetGetStuck: cannot withdraw token");
        // to address should NOT a 0 address
        require(to != address(0), "inCaseAssetGetStuck: to cannot be 0 address");
        // transfer all the balance of the asset this contract hold to the "to" address
        rescued = IERC20(asset).balanceOf(address(this));
        IERC20(asset).safeTransfer(to, rescued);
    }

    /// @notice Transfers the dust to the SAFE_ADDRESS.
    /// @dev It is assumed that the SAFE_ADDRESS is NOT malicious.
    ///      Only owner of the vesting escrow can invoke this function.
    /// @return Amount of dust to the SAFE_ADDRESS.
    function transferDust() external onlyOwner returns (uint256) {
        // precaution for reentrancy attack
        if (dust > 0) {
            uint256 _dust = dust;
            dust = 0;
            IERC20(token).safeTransfer(SAFE_ADDRESS, _dust);
            return _dust;
        }
        return 0;
    }

    /// @notice Transfers the locked (non-vested) tokens of the passed recipients to the SAFE_ADDRESS
    /// @dev It is assumed that the SAFE_ADDRESS is NOT malicious
    ///      Only owner of the vesting escrow can invoke this function.
    ///      Reverts if any of the recipients is terminated.
    ///      Can only be invoked if the escrow is terminated.
    /// @param _recipients An array of non-terminated recipient addresses.
    /// @return totalSeized Total tokens seized from the recipients.
    function seizeLockedTokens(address[] calldata _recipients) external onlyOwner returns (uint256 totalSeized) {
        // only seize if escrow is terminated
        require(ESCROW_TERMINATED, "seizeLockedTokens: escrow not terminated");
        // get the total tokens to be seized
        for (uint256 i = 0; i < _recipients.length; i++) {
            // only seize tokens from the recipients which have not been seized before
            if (!lockedTokensSeizedFor[_recipients[i]]) {
                totalSeized = totalSeized.add(totalLockedOf(_recipients[i]));
                lockedTokensSeizedFor[_recipients[i]] = true;
            }
        }
        // transfer the totalSeized amount to the SAFE_ADDRESS
        IERC20(token).safeTransfer(SAFE_ADDRESS, totalSeized);
    }
}