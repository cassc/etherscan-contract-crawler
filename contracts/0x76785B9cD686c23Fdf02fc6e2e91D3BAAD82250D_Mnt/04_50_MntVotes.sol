// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Votes.sol)

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./IERC20Votes.sol";
import "./MntErrorCodes.sol";
import "./MntGovernor.sol";

/**
 * @dev Extension of MNT token based on OpenZeppelin ERC20Votes Compound-like voting v4.2 with reduced features.
 * This extension keeps a history (checkpoints) of each account's vote power. Vote power can be delegated either
 * by calling the {delegate} function directly, or by providing a signature to be used with {delegateBySig}. Voting
 * power can be queried through the public accessors {getVotes} and {getPastVotes}.
 *
 * Token balance does not account for voting power, instead Buyback contract is responsible for updating the
 * voting power during the stake and unstake actions performed by the account. This extension requires accounts to
 * delegate to themselves in order to activate checkpoints and have their voting power tracked.
 */
abstract contract MntVotes is IERC20Votes, ERC20Permit, AccessControl {
    bytes32 private constant _DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping(address => address) private _delegates;
    mapping(address => Checkpoint[]) private _checkpoints;
    Checkpoint[] internal _totalSupplyCheckpoints;

    /// @dev Will be used instead of token balances for the accounts
    mapping(address => uint224) private _votingBalance;

    /// @dev Buyback will push this value after each account weight update, so we don't have to pull it
    /// when new proposal acquired and total supply checkpoint should be added to the list
    /// this will cost some gas every call but allows to keep total votes logic in the buyback
    uint224 private _totalVotesCurrent;

    address private buyback;

    MntGovernor public governor;

    uint256 public constant SECS_PER_YEAR = 365 * 24 * 60 * 60;

    /// @notice If the account has not voted within this time, admin can call the method `leaveOnBehalf()` for him from
    /// Minterest buyback system
    uint256 public maxNonVotingPeriod = SECS_PER_YEAR;

    /// @notice timestamp of last vote for accounts
    mapping(address => uint256) public lastVotingTimestamp;

    /// @notice timestamp of the last delegation of votes for the account
    mapping(address => uint256) public lastDelegatingTimestamp;

    /// @notice Emitted when buyback is set
    event NewBuyback(address oldBuyback, address newBuyback);

    /// @notice Emitted when governor is set
    event NewGovernor(MntGovernor oldGovernor, MntGovernor newGovernor);

    event MaxNonVotingPeriodChanged(uint256 oldValue, uint256 newValue);

    /// @notice Emitted when total votes updated
    event TotalVotesUpdated(uint224 oldTotalVotes, uint224 newTotalVotes);

    /// @notice Emitted when account votes updated
    event VotesUpdated(address account, uint224 oldVotingPower, uint224 newVotingPower);

    /**
     * @dev Get the `pos`-th checkpoint for `account`.
     */
    function checkpoints(address account, uint32 pos) public view virtual returns (Checkpoint memory) {
        return _checkpoints[account][pos];
    }

    /**
     * @dev Get number of checkpoints for `account`.
     */
    function numCheckpoints(address account) public view virtual returns (uint32) {
        return SafeCast.toUint32(_checkpoints[account].length);
    }

    /**
     * @dev Get the address `account` is currently delegating to.
     */
    function delegates(address account) public view virtual returns (address) {
        return _delegates[account];
    }

    /**
     * @dev Gets the current votes balance for `account`
     */
    function getVotes(address account) public view returns (uint256) {
        uint256 pos = _checkpoints[account].length;
        return pos == 0 ? 0 : _checkpoints[account][pos - 1].votes;
    }

    /**
     * @dev Retrieve the number of votes for `account` at the end of `blockNumber`.
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastVotes(address account, uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, MntErrorCodes.MV_BLOCK_NOT_YET_MINED);
        return _checkpointsLookup(_checkpoints[account], blockNumber);
    }

    /**
     * @dev Retrieve the `totalSupply` at the end of `blockNumber`. Note, this value is the sum of all discounted MNTs
     * staked to buyback contract in order to get Buyback rewards and to participate in the voting process.
     * Requirements:
     * - `blockNumber` must have been already mined
     */
    function getPastTotalSupply(uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, MntErrorCodes.MV_BLOCK_NOT_YET_MINED);
        return _checkpointsLookup(_totalSupplyCheckpoints, blockNumber);
    }

    /**
     * @dev Lookup a value in a list of (sorted) checkpoints.
     */
    function _checkpointsLookup(Checkpoint[] storage ckpts, uint256 blockNumber) private view returns (uint256) {
        // We run a binary search to look for the earliest checkpoint taken after `blockNumber`.
        //
        // During the loop, the index of the wanted checkpoint remains in the range [low-1, high).
        // Each iteration, either `low` or `high` is moved towards the middle of the range to maintain the invariant.
        // - If the middle checkpoint is after `blockNumber`, we look in [low, mid)
        // - If the middle checkpoint is before or equal to `blockNumber`, we look in [mid+1, high)
        // Once we reach a single value (when low == high), we've found the right checkpoint at the index high-1, if not
        // out of bounds (in which case we're looking too far in the past and the result is 0).
        // Note that if the latest checkpoint available is exactly for `blockNumber`, we end up with an index that is
        // past the end of the array, so we technically don't find a checkpoint after `blockNumber`, but it works out
        // the same.
        uint256 high = ckpts.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (ckpts[mid].fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return high == 0 ? 0 : ckpts[high - 1].votes;
    }

    /**
     * @dev Delegate votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) public virtual {
        _delegate(_msgSender(), delegatee);
    }

    /**
     * @dev Delegates votes from signer to `delegatee`
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        //solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= expiry, MntErrorCodes.MV_SIGNATURE_EXPIRED);
        address signer = ECDSA.recover(
            _hashTypedDataV4(keccak256(abi.encode(_DELEGATION_TYPEHASH, delegatee, nonce, expiry))),
            v,
            r,
            s
        );
        require(nonce == _useNonce(signer), MntErrorCodes.MV_INVALID_NONCE);
        _delegate(signer, delegatee);
    }

    /**
     * @dev Mint does not change voting power.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        super._mint(account, amount);
    }

    /**
     * @dev We don't move voting power when tokens are transferred.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount);
    }

    /**
     * @dev Change delegation for `delegator` to `delegatee`.
     *
     * Emits events {DelegateChanged} and {DelegateVotesChanged}.
     */
    function _delegate(address delegator, address delegatee) internal virtual {
        address currentDelegate = delegates(delegator);
        uint256 delegatorBalance = _votingBalance[delegator];
        _delegates[delegator] = delegatee;

        if (lastVotingTimestamp[currentDelegate] > lastDelegatingTimestamp[delegator])
            lastVotingTimestamp[delegator] = lastVotingTimestamp[currentDelegate];
        lastDelegatingTimestamp[delegator] = block.timestamp;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveVotingPower(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveVotingPower(
        address src,
        address dst,
        uint256 amount
    ) private {
        if (src != dst && amount > 0) {
            if (src != address(0)) {
                uint256 oldWeight;
                uint256 newWeight;
                (oldWeight, newWeight) = _writeCheckpoint(_checkpoints[src], _subtract, amount);
                emit DelegateVotesChanged(src, oldWeight, newWeight);
            }

            if (dst != address(0)) {
                uint256 oldWeight;
                uint256 newWeight;
                (oldWeight, newWeight) = _writeCheckpoint(_checkpoints[dst], _add, amount);
                emit DelegateVotesChanged(dst, oldWeight, newWeight);
            }
        }
    }

    function _writeCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) private returns (uint256 oldWeight, uint256 newWeight) {
        uint256 pos = ckpts.length;
        oldWeight = pos == 0 ? 0 : ckpts[pos - 1].votes;
        newWeight = op(oldWeight, delta);

        // Don't create new checkpoint if votes change in the same block
        // slither-disable-next-line incorrect-equality
        if (pos > 0 && ckpts[pos - 1].fromBlock == block.number) {
            ckpts[pos - 1].votes = SafeCast.toUint224(newWeight);
        } else {
            ckpts.push(Checkpoint({fromBlock: SafeCast.toUint32(block.number), votes: SafeCast.toUint224(newWeight)}));
        }
    }

    // slither-disable-next-line dead-code
    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    // slither-disable-next-line dead-code
    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }

    // end of OpenZeppelin implementation; MNT-specific code listed below

    /// @dev Throws if called by any account other than the buyback.
    modifier buybackOnly() {
        require(buyback != address(0) && buyback == msg.sender, MntErrorCodes.UNAUTHORIZED);
        _;
    }

    /// @dev Throws if called by any account other than the governor.
    modifier governorOnly() {
        require(governor != MntGovernor(payable(0)) && address(governor) == msg.sender, MntErrorCodes.UNAUTHORIZED);
        _;
    }

    /// @notice Set buyback implementation that is responsible for voting power calculations
    function setBuyback(address newBuyback) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newBuyback != address(0), MntErrorCodes.ZERO_ADDRESS);
        address oldBuyback = buyback;
        buyback = newBuyback;
        emit NewBuyback(oldBuyback, newBuyback);
    }

    /// @notice Set governor implementation that is responsible for voting
    function setGovernor(MntGovernor newGovernor_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(newGovernor_) != address(0), MntErrorCodes.ZERO_ADDRESS);
        MntGovernor oldGovernor = governor;
        require(oldGovernor == MntGovernor(payable(0)), MntErrorCodes.SECOND_INITIALIZATION);
        governor = newGovernor_;
        emit NewGovernor(oldGovernor, newGovernor_);
    }

    /// @notice Update votes for account and total voting volume on the current block
    function updateVotesForAccount(
        address account,
        uint224 balance,
        uint224 volume
    ) external buybackOnly {
        require(account != address(0), MntErrorCodes.TARGET_ADDRESS_CANNOT_BE_ZERO);

        // update total votes volume
        _totalVotesCurrent = volume;

        // update voting power
        uint224 oldBalance = _votingBalance[account];
        if (oldBalance == balance) {
            // don't create new point and return immediately
            return;
        }

        if (oldBalance < balance) {
            // increase voting balance of account and voting power of its delegatee
            uint224 delta = balance - oldBalance;
            _votingBalance[account] = balance;
            // "mint" some voting power
            _moveVotingPower(address(0), delegates(account), delta);
        } else {
            // decrease voting balance of account and voting power of its delegatee
            uint224 delta = oldBalance - balance;
            _votingBalance[account] = balance;
            // "burn" some voting power
            _moveVotingPower(delegates(account), address(0), delta);
        }

        emit VotesUpdated(account, oldBalance, _votingBalance[account]);
    }

    /// @notice Create checkpoint by voting volume on the current block
    function updateTotalVotes() external governorOnly {
        if (_totalSupplyCheckpoints.length > 0) {
            uint224 oldVotes = _totalSupplyCheckpoints[_totalSupplyCheckpoints.length - 1].votes;
            if (oldVotes > _totalVotesCurrent) {
                _writeCheckpoint(_totalSupplyCheckpoints, _subtract, oldVotes - _totalVotesCurrent);
            } else {
                _writeCheckpoint(_totalSupplyCheckpoints, _add, _totalVotesCurrent - oldVotes);
            }

            emit TotalVotesUpdated(oldVotes, _totalSupplyCheckpoints[_totalSupplyCheckpoints.length - 1].votes);
        } else {
            _writeCheckpoint(_totalSupplyCheckpoints, _add, _totalVotesCurrent);

            emit TotalVotesUpdated(0, _totalSupplyCheckpoints[_totalSupplyCheckpoints.length - 1].votes);
        }
    }

    /// @notice Checks user activity for the last `maxNonVotingPeriod` blocks
    /// @param account_ The address of the account
    /// @return returns true if the user voted or his delegatee voted for the last maxNonVotingPeriod blocks,
    /// otherwise returns false
    function isParticipantActive(address account_) public view virtual returns (bool) {
        return lastActivityTimestamp(account_) > block.timestamp - maxNonVotingPeriod;
    }

    /// @notice Gets the latest voting timestamp for account.
    /// @dev If the user delegated his votes, then it also checks the timestamp of the last vote of the delegatee
    /// @param account_ The address of the account
    /// @return latest voting timestamp for account
    function lastActivityTimestamp(address account_) public view virtual returns (uint256) {
        address delegatee = _delegates[account_];
        uint256 lastVoteAccount = lastVotingTimestamp[account_];

        // if the votes are not delegated to anyone, then we return the timestamp of the last vote of the account
        if (delegatee == address(0)) return lastVoteAccount;
        uint256 lastVoteDelegatee = lastVotingTimestamp[delegatee];

        // if delegatee voted after delegation, then returns the timestamp for the delegatee
        if (lastVoteDelegatee > lastDelegatingTimestamp[account_]) {
            return lastVoteDelegatee;
        }

        return lastVoteAccount;
    }

    /**
     * @notice Sets the maxNonVotingPeriod
     * @dev Admin function to set maxNonVotingPeriod
     * @param newPeriod_ The new maxNonVotingPeriod (in sec). Must be greater than 90 days and lower than 2 years.
     */
    function setMaxNonVotingPeriod(uint256 newPeriod_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newPeriod_ >= 90 days && newPeriod_ <= 2 * SECS_PER_YEAR, MntErrorCodes.MNT_INVALID_NONVOTING_PERIOD);

        uint256 oldPeriod = maxNonVotingPeriod;
        require(newPeriod_ != oldPeriod, MntErrorCodes.IDENTICAL_VALUE);

        emit MaxNonVotingPeriodChanged(oldPeriod, newPeriod_);
        maxNonVotingPeriod = newPeriod_;
    }

    /**
     * @notice function to change lastVotingTimestamp
     * @param account_ The address of the account
     * @param timestamp_ New timestamp of account user last voting
     */
    function setLastVotingTimestamp(address account_, uint256 timestamp_) external governorOnly {
        lastVotingTimestamp[account_] = timestamp_;
    }
}