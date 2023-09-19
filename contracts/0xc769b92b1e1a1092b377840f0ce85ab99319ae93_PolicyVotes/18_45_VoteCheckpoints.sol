// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Pausable.sol";
import "./DelegatePermit.sol";

/**
 * @dev Extension of ERC20 to support Compound-like voting and delegation. This version is more generic than Compound's,
 * and supports token supply up to 2^224^ - 1, while COMP is limited to 2^96^ - 1.
 *
 * This extension keeps a history (checkpoints) of each account's vote power. Vote power can be delegated either
 * by calling the {delegate} function directly, or by providing a signature to be used with {delegateBySig}. Voting
 * power can be queried through the public accessors {getVotingGons} and {getPastVotingGons}.
 *
 * By default, token balance does not account for voting power. This makes transfers cheaper. The downside is that it
 * requires users to delegate to themselves in order to activate checkpoints and have their voting power tracked.
 * Enabling self-delegation can easily be done by overriding the {delegates} function. Keep in mind however that this
 * will significantly increase the base gas cost of transfers.
 *
 * _Available since v4.2._
 */
abstract contract VoteCheckpoints is ERC20Pausable, DelegatePermit {
    // structure for saving past voting balances, accounting for delegation
    struct Checkpoint {
        uint32 fromBlock;
        uint224 value;
    }

    // the mapping from an address to each address that it delegates to, then mapped to the amount delegated
    mapping(address => mapping(address => uint256)) internal _delegates;

    // a mapping that aggregates the total delegated amounts in the mapping above
    mapping(address => uint256) internal _delegatedTotals;

    /** a mapping that tracks the primaryDelegates of each user
     *
     * Primary delegates can only be chosen using delegate() which sends the full balance
     * The exist to maintain the functionality that recieving tokens gives those votes to the delegate
     */
    mapping(address => address) internal _primaryDelegates;

    // mapping that tracks if an address is willing to be delegated to
    mapping(address => bool) public delegationToAddressEnabled;

    // mapping that tracks if an address is unable to delegate
    mapping(address => bool) public delegationFromAddressDisabled;

    // mapping to the ordered arrays of voting checkpoints for each address
    mapping(address => Checkpoint[]) public checkpoints;

    // the checkpoints to track the token total supply
    Checkpoint[] private _totalSupplyCheckpoints;

    /**
     * @dev Emitted when a delegatee is delegated new votes.
     */
    event DelegatedVotes(
        address indexed delegator,
        address indexed delegatee,
        uint256 amount
    );

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to an account's voting power.
     */
    event UpdatedVotes(address indexed voter, uint256 newVotes);

    /**
     * @dev Emitted when an account denotes a primary delegate.
     */
    event NewPrimaryDelegate(
        address indexed delegator,
        address indexed primaryDelegate
    );

    constructor(
        string memory _name,
        string memory _symbol,
        address admin,
        address _initialPauser
    ) ERC20Pausable(_name, _symbol, admin, _initialPauser) {
        // call to super constructor
    }

    /** Returns the total (inflation corrected) token supply at a specified block number
     */
    function totalSupplyAt(uint256 _blockNumber)
        public
        view
        virtual
        returns (uint256)
    {
        return getPastTotalSupply(_blockNumber);
    }

    /** Return historical voting balance (includes delegation) at given block number.
     *
     * If the latest block number for the account is before the requested
     * block then the most recent known balance is returned. Otherwise the
     * exact block number requested is returned.
     *
     * @param _owner The account to check the balance of.
     * @param _blockNumber The block number to check the balance at the start
     *                        of. Must be less than or equal to the present
     *                        block number.
     */
    function getPastVotes(address _owner, uint256 _blockNumber)
        public
        view
        virtual
        returns (uint256)
    {
        return getPastVotingGons(_owner, _blockNumber);
    }

    /**
     * @dev Get number of checkpoints for `account`.
     */
    function numCheckpoints(address account)
        public
        view
        virtual
        returns (uint32)
    {
        uint256 _numCheckpoints = checkpoints[account].length;
        require(
            _numCheckpoints <= type(uint32).max,
            "number of checkpoints cannot be casted safely"
        );
        return uint32(_numCheckpoints);
    }

    /**
     * @dev Set yourself as willing to recieve delegates.
     */
    function enableDelegationTo() public {
        require(
            isOwnDelegate(msg.sender),
            "Cannot enable delegation if you have outstanding delegation"
        );

        delegationToAddressEnabled[msg.sender] = true;
        delegationFromAddressDisabled[msg.sender] = true;
    }

    /**
     * @dev Set yourself as no longer recieving delegates.
     */
    function disableDelegationTo() public {
        delegationToAddressEnabled[msg.sender] = false;
    }

    /**
     * @dev Set yourself as being able to delegate again.
     * also disables delegating to you
     * NOTE: the condition for this is not easy and cannot be unilaterally achieved
     */
    function reenableDelegating() public {
        delegationToAddressEnabled[msg.sender] = false;

        require(
            _balances[msg.sender] == getVotingGons(msg.sender) &&
                isOwnDelegate(msg.sender),
            "Cannot re-enable delegating if you have outstanding delegations to you"
        );

        delegationFromAddressDisabled[msg.sender] = false;
    }

    /**
     * @dev Returns true if the user has no amount of their balance delegated, otherwise false.
     */
    function isOwnDelegate(address account) public view returns (bool) {
        return _delegatedTotals[account] == 0;
    }

    /**
     * @dev Get the primary address `account` is currently delegating to. Defaults to the account address itself if none specified.
     * The primary delegate is the one that is delegated any new funds the address recieves.
     */
    function getPrimaryDelegate(address account)
        public
        view
        virtual
        returns (address)
    {
        address _voter = _primaryDelegates[account];
        return _voter == address(0) ? account : _voter;
    }

    /**
     * sets the primaryDelegate and emits an event to track it
     */
    function _setPrimaryDelegate(address delegator, address delegatee)
        internal
    {
        _primaryDelegates[delegator] = delegatee;

        emit NewPrimaryDelegate(
            delegator,
            delegatee == address(0) ? delegator : delegatee
        );
    }

    /**
     * @dev Gets the current votes balance in gons for `account`
     */
    function getVotingGons(address account) public view returns (uint256) {
        Checkpoint[] memory accountCheckpoints = checkpoints[account];
        uint256 pos = accountCheckpoints.length;
        return pos == 0 ? 0 : accountCheckpoints[pos - 1].value;
    }

    /**
     * @dev Retrieve the number of votes in gons for `account` at the end of `blockNumber`.
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastVotingGons(address account, uint256 blockNumber)
        public
        view
        returns (uint256)
    {
        require(
            blockNumber <= block.number,
            "VoteCheckpoints: block not yet mined"
        );
        return _checkpointsLookup(checkpoints[account], blockNumber);
    }

    /**
     * @dev Retrieve the `totalSupply` at the end of `blockNumber`. Note, this value is the sum of all balances.
     * It is NOT the sum of all the delegated votes!
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastTotalSupply(uint256 blockNumber)
        public
        view
        returns (uint256)
    {
        require(
            blockNumber <= block.number,
            "VoteCheckpoints: block not yet mined"
        );
        return _checkpointsLookup(_totalSupplyCheckpoints, blockNumber);
    }

    /**
     * @dev Lookup a value in a list of (sorted) checkpoints.
     */
    function _checkpointsLookup(Checkpoint[] storage ckpts, uint256 blockNumber)
        internal
        view
        returns (uint256)
    {
        // We run a binary search to look for the last checkpoint taken before `blockNumber`.
        //
        // During the loop, the index of the wanted checkpoint remains in the range [low-1, high).
        // With each iteration, either `low` or `high` is moved towards the middle of the range to maintain the invariant.
        // - If the middle checkpoint is after `blockNumber`, we look in [low, mid)
        // - If the middle checkpoint is before or equal to `blockNumber`, we look in [mid+1, high)
        // Once we reach a single value (when low == high), we've found the right checkpoint at the index high-1, if not
        // out of bounds (in which case we're looking too far in the past and the result is 0).
        // Note that if the latest checkpoint available is exactly for `blockNumber`, we end up with an index that is
        // past the end of the array, so we technically don't find a checkpoint after `blockNumber`, but it works out
        // the same.

        uint256 ckptsLength = ckpts.length;
        if (ckptsLength == 0) return 0;
        Checkpoint memory lastCkpt = ckpts[ckptsLength - 1];
        if (blockNumber >= lastCkpt.fromBlock) return lastCkpt.value;

        uint256 high = ckptsLength;
        uint256 low = 0;

        while (low < high) {
            uint256 mid = low + ((high - low) >> 1);
            if (ckpts[mid].fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return high == 0 ? 0 : ckpts[high - 1].value;
    }

    /**
     * @dev Delegate all votes from the sender to `delegatee`.
     * NOTE: This function assumes that you do not have partial delegations
     * It will revert with "Must have an undelegated amount available to cover delegation" if you do
     */
    function delegate(address delegatee) public {
        require(
            delegatee != msg.sender,
            "Use undelegate instead of delegating to yourself"
        );

        require(
            delegationToAddressEnabled[delegatee],
            "Primary delegates must enable delegation"
        );

        if (!isOwnDelegate(msg.sender)) {
            undelegateFromAddress(getPrimaryDelegate(msg.sender));
        }

        uint256 _amount = _balances[msg.sender];
        _delegate(msg.sender, delegatee, _amount);
        _setPrimaryDelegate(msg.sender, delegatee);
    }

    /**
     * @dev Delegate all votes from the sender to `delegatee`.
     * NOTE: This function assumes that you do not have partial delegations
     * It will revert with "Must have an undelegated amount available to cover delegation" if you do
     */
    function delegateBySig(
        address delegator,
        address delegatee,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(delegator != delegatee, "Do not delegate to yourself");
        require(
            delegationToAddressEnabled[delegatee],
            "Primary delegates must enable delegation"
        );

        if (!isOwnDelegate(delegator)) {
            _undelegateFromAddress(delegator, getPrimaryDelegate(delegator));
        }

        _verifyDelegatePermit(delegator, delegatee, deadline, v, r, s);

        uint256 _amount = _balances[delegator];
        _delegate(delegator, delegatee, _amount);
        _setPrimaryDelegate(delegator, delegatee);
    }

    /**
     * @dev Delegate an `amount` of votes from the sender to `delegatee`.
     */
    function delegateAmount(address delegatee, uint256 amount) public {
        require(delegatee != msg.sender, "Do not delegate to yourself");

        _delegate(msg.sender, delegatee, amount);
    }

    /**
     * @dev Change delegation for `delegator` to `delegatee`.
     *
     * Emits events {NewDelegatedAmount} and {UpdatedVotes}.
     */
    function _delegate(
        address delegator,
        address delegatee,
        uint256 amount
    ) internal virtual {
        require(
            amount <= _balances[delegator] - _delegatedTotals[delegator],
            "Must have an undelegated amount available to cover delegation"
        );

        require(
            !delegationFromAddressDisabled[delegator],
            "Cannot delegate if you have enabled primary delegation to yourself and/or have outstanding delegates"
        );

        emit DelegatedVotes(delegator, delegatee, amount);

        _delegates[delegator][delegatee] += amount;
        _delegatedTotals[delegator] += amount;

        _moveVotingPower(delegator, delegatee, amount);
    }

    /**
     * @dev Undelegate all votes from the sender's primary delegate.
     */
    function undelegate() public {
        address _primaryDelegate = getPrimaryDelegate(msg.sender);
        require(
            _primaryDelegate != msg.sender,
            "Must specifiy address without a Primary Delegate"
        );
        undelegateFromAddress(_primaryDelegate);
    }

    /**
     * @dev Undelegate votes from the `delegatee` back to the sender.
     */
    function undelegateFromAddress(address delegatee) public {
        _undelegateFromAddress(msg.sender, delegatee);
    }

    /**
     * @dev Undelegate votes from the `delegatee` back to the delegator.
     */
    function _undelegateFromAddress(address delegator, address delegatee)
        internal
    {
        uint256 _amount = _delegates[delegator][delegatee];
        _undelegate(delegator, delegatee, _amount);
        if (delegatee == getPrimaryDelegate(delegator)) {
            _setPrimaryDelegate(delegator, address(0));
        }
    }

    /**
     * @dev Undelegate a specific amount of votes from the `delegatee` back to the sender.
     */
    function undelegateAmountFromAddress(address delegatee, uint256 amount)
        public
    {
        require(
            _delegates[msg.sender][delegatee] >= amount,
            "amount not available to undelegate"
        );
        require(
            msg.sender == getPrimaryDelegate(msg.sender),
            "undelegating amounts is only available for partial delegators"
        );
        _undelegate(msg.sender, delegatee, amount);
    }

    function _undelegate(
        address delegator,
        address delegatee,
        uint256 amount
    ) internal virtual {
        _delegatedTotals[delegator] -= amount;
        _delegates[delegator][delegatee] -= amount;

        _moveVotingPower(delegatee, delegator, amount);
    }

    /**
     * @dev Maximum token supply. Defaults to `type(uint224).max` (2^224^ - 1).
     */
    function _maxSupply() internal view virtual returns (uint224) {
        return type(uint224).max;
    }

    /**
     * @dev Snapshots the totalSupply after it has been increased.
     */
    function _mint(address account, uint256 amount)
        internal
        virtual
        override
        returns (uint256)
    {
        amount = super._mint(account, amount);
        require(
            totalSupply() <= _maxSupply(),
            "VoteCheckpoints: total supply risks overflowing votes"
        );

        _writeCheckpoint(_totalSupplyCheckpoints, _add, amount);
        return amount;
    }

    /**
     * @dev Snapshots the totalSupply after it has been decreased.
     */
    function _burn(address account, uint256 amount)
        internal
        virtual
        override
        returns (uint256)
    {
        amount = super._burn(account, amount);

        _writeCheckpoint(_totalSupplyCheckpoints, _subtract, amount);
        return amount;
    }

    /**
     * @dev Move voting power when tokens are transferred.
     *
     * Emits a {UpdatedVotes} event.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // if the address has delegated, they might be transfering tokens allotted to someone else
        if (!isOwnDelegate(from)) {
            uint256 _undelegatedAmount = _balances[from] +
                amount -
                _delegatedTotals[from];

            // check to see if tokens must be undelegated to transefer
            if (_undelegatedAmount < amount) {
                address _sourcePrimaryDelegate = getPrimaryDelegate(from);
                uint256 _sourcePrimaryDelegatement = _delegates[from][
                    _sourcePrimaryDelegate
                ];

                require(
                    amount <= _undelegatedAmount + _sourcePrimaryDelegatement,
                    "Delegation too complicated to transfer. Undelegate and simplify before trying again"
                );

                _undelegate(
                    from,
                    _sourcePrimaryDelegate,
                    amount - _undelegatedAmount
                );
            }
        }

        address _destPrimaryDelegate = _primaryDelegates[to];
        // saving gas by manually doing isOwnDelegate since we already need to read the data for this conditional
        if (_destPrimaryDelegate != address(0)) {
            _delegates[to][_destPrimaryDelegate] += amount;
            _delegatedTotals[to] += amount;
            _moveVotingPower(from, _destPrimaryDelegate, amount);
        } else {
            _moveVotingPower(from, to, amount);
        }
    }

    function _moveVotingPower(
        address src,
        address dst,
        uint256 amount
    ) private {
        if (src != dst && amount > 0) {
            if (src != address(0)) {
                uint256 newWeight = _writeCheckpoint(
                    checkpoints[src],
                    _subtract,
                    amount
                );
                emit UpdatedVotes(src, newWeight);
            }

            if (dst != address(0)) {
                uint256 newWeight = _writeCheckpoint(
                    checkpoints[dst],
                    _add,
                    amount
                );
                emit UpdatedVotes(dst, newWeight);
            }
        }
    }

    // returns the newly written value in the checkpoint
    function _writeCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) internal returns (uint256) {
        require(
            delta <= type(uint224).max,
            "newWeight cannot be casted safely"
        );
        require(
            block.number <= type(uint32).max,
            "block number cannot be casted safely"
        );

        uint256 pos = ckpts.length;

        /* if there are no checkpoints, just write the value
         * This part assumes that an account would never exist with a balance but without checkpoints.
         * This function cannot be called directly, so there's no malicious way to exploit this. If this
         * is somehow called with op = _subtract, it will revert as that action is nonsensical.
         */
        if (pos == 0) {
            ckpts.push(
                Checkpoint({
                    fromBlock: uint32(block.number),
                    value: uint224(op(0, delta))
                })
            );
            return delta;
        }

        // else, we iterate on the existing checkpoints as per usual
        Checkpoint storage newestCkpt = ckpts[pos - 1];

        uint256 oldWeight = newestCkpt.value;
        uint256 newWeight = op(oldWeight, delta);

        require(
            newWeight <= type(uint224).max,
            "newWeight cannot be casted safely"
        );

        if (newestCkpt.fromBlock == block.number) {
            newestCkpt.value = uint224(newWeight);
        } else {
            ckpts.push(
                Checkpoint({
                    fromBlock: uint32(block.number),
                    value: uint224(newWeight)
                })
            );
        }
        return newWeight;
    }

    function _add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function _replace(uint256, uint256 b) internal pure returns (uint256) {
        return b;
    }
}