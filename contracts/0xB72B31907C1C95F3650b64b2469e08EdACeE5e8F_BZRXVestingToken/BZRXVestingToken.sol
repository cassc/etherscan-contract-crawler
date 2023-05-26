/**
 *Submitted for verification at Etherscan.io on 2020-07-11
*/

/**
 * Copyright 2017-2020, bZeroX, LLC <https://bzx.network/>. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract IERC20 {
    string public name;
    uint8 public decimals;
    string public symbol;
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function allowance(address _owner, address _spender) public view returns (uint256);
    function approve(address _spender, uint256 _value) public returns (bool);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "unauthorized");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * Copyright (C) 2019 Aragon One <https://aragon.one/>
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
/**
 * @title Checkpointing
 * @notice Checkpointing library for keeping track of historical values based on an arbitrary time
 *         unit (e.g. seconds or block numbers).
 * @dev Adapted from:
 *   - Checkpointing  (https://github.com/aragonone/voting-connectors/blob/master/shared/contract-utils/contracts/Checkpointing.sol)
 */
library Checkpointing {

    struct Checkpoint {
        uint256 time;
        uint256 value;
    }

    struct History {
        Checkpoint[] history;
    }

    function addCheckpoint(
        History storage _self,
        uint256 _time,
        uint256 _value)
        internal
    {
        uint256 length = _self.history.length;
        if (length == 0) {
            _self.history.push(Checkpoint(_time, _value));
        } else {
            Checkpoint storage currentCheckpoint = _self.history[length - 1];
            uint256 currentCheckpointTime = currentCheckpoint.time;

            if (_time > currentCheckpointTime) {
                _self.history.push(Checkpoint(_time, _value));
            } else if (_time == currentCheckpointTime) {
                currentCheckpoint.value = _value;
            } else { // ensure list ordering
                revert("past-checkpoint");
            }
        }
    }

    function getValueAt(
        History storage _self,
        uint256 _time)
        internal
        view
        returns (uint256)
    {
        return _getValueAt(_self, _time);
    }

    function lastUpdated(
        History storage _self)
        internal
        view
        returns (uint256)
    {
        uint256 length = _self.history.length;
        if (length != 0) {
            return _self.history[length - 1].time;
        }
    }

    function latestValue(
        History storage _self)
        internal
        view
        returns (uint256)
    {
        uint256 length = _self.history.length;
        if (length != 0) {
            return _self.history[length - 1].value;
        }
    }

    function _getValueAt(
        History storage _self,
        uint256 _time)
        private
        view
        returns (uint256)
    {
        uint256 length = _self.history.length;

        // Short circuit if there's no checkpoints yet
        // Note that this also lets us avoid using SafeMath later on, as we've established that
        // there must be at least one checkpoint
        if (length == 0) {
            return 0;
        }

        // Check last checkpoint
        uint256 lastIndex = length - 1;
        Checkpoint storage lastCheckpoint = _self.history[lastIndex];
        if (_time >= lastCheckpoint.time) {
            return lastCheckpoint.value;
        }

        // Check first checkpoint (if not already checked with the above check on last)
        if (length == 1 || _time < _self.history[0].time) {
            return 0;
        }

        // Do binary search
        // As we've already checked both ends, we don't need to check the last checkpoint again
        uint256 low = 0;
        uint256 high = lastIndex - 1;

        while (high != low) {
            uint256 mid = (high + low + 1) / 2; // average, ceil round
            Checkpoint storage checkpoint = _self.history[mid];
            uint256 midTime = checkpoint.time;

            if (_time > midTime) {
                low = mid;
            } else if (_time < midTime) {
                // Note that we don't need SafeMath here because mid must always be greater than 0
                // from the while condition
                high = mid - 1;
            } else {
                // _time == midTime
                return checkpoint.value;
            }
        }

        return _self.history[low].value;
    }
}

contract CheckpointingToken is IERC20 {
    using Checkpointing for Checkpointing.History;

    mapping (address => mapping (address => uint256)) internal allowances_;

    mapping (address => Checkpointing.History) internal balancesHistory_;

    struct Checkpoint {
        uint256 time;
        uint256 value;
    }

    struct History {
        Checkpoint[] history;
    }

    // override this function if a totalSupply should be tracked
    function totalSupply()
        public
        view
        returns (uint256)
    {
        return 0;
    }

    function balanceOf(
        address _owner)
        public
        view
        returns (uint256)
    {
        return balanceOfAt(_owner, block.number);
    }

    function balanceOfAt(
        address _owner,
        uint256 _blockNumber)
        public
        view
        returns (uint256)
    {
        return balancesHistory_[_owner].getValueAt(_blockNumber);
    }

    function allowance(
        address _owner,
        address _spender)
        public
        view
        returns (uint256)
    {
        return allowances_[_owner][_spender];
    }

    function approve(
        address _spender,
        uint256 _value)
        public
        returns (bool)
    {
        allowances_[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transfer(
        address _to,
        uint256 _value)
        public
        returns (bool)
    {
        return transferFrom(
            msg.sender,
            _to,
            _value
        );
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value)
        public
        returns (bool)
    {
        uint256 previousBalanceFrom = balanceOfAt(_from, block.number);
        require(previousBalanceFrom >= _value, "insufficient-balance");

        if (_from != msg.sender && allowances_[_from][msg.sender] != uint(-1)) {
            require(allowances_[_from][msg.sender] >= _value, "insufficient-allowance");
            allowances_[_from][msg.sender] = allowances_[_from][msg.sender] - _value; // overflow not possible
        }

        balancesHistory_[_from].addCheckpoint(
            block.number,
            previousBalanceFrom - _value // overflow not possible
        );

        balancesHistory_[_to].addCheckpoint(
            block.number,
            add(
                balanceOfAt(_to, block.number),
                _value
            )
        );

        emit Transfer(_from, _to, _value);
        return true;
    }

    function _getBlockNumber()
        internal
        view
        returns (uint256)
    {
        return block.number;
    }

    function _getTimestamp()
        internal
        view
        returns (uint256)
    {
        return block.timestamp;
    }

    function add(
        uint256 x,
        uint256 y)
        internal
        pure
        returns (uint256 c)
    {
        require((c = x + y) >= x, "addition-overflow");
    }

    function sub(
        uint256 x,
        uint256 y)
        internal
        pure
        returns (uint256 c)
    {
        require((c = x - y) <= x, "subtraction-overflow");
    }

    function mul(
        uint256 a,
        uint256 b)
        internal
        pure
        returns (uint256 c)
    {
        if (a == 0) {
            return 0;
        }
        require((c = a * b) / a == b, "multiplication-overflow");
    }

    function div(
        uint256 a,
        uint256 b)
        internal
        pure
        returns (uint256 c)
    {
        require(b != 0, "division by zero");
        c = a / b;
    }
}

contract BZRXVestingToken is CheckpointingToken, Ownable {

    event Claim(
        address indexed owner,
        uint256 value
    );

    string public constant name = "bZx Vesting Token";
    string public constant symbol = "vBZRX";
    uint8 public constant decimals = 18;

    uint256 public constant cliffDuration =                  15768000; // 86400 * 365 * 0.5
    uint256 public constant vestingDuration =               126144000; // 86400 * 365 * 4
    uint256 internal constant vestingDurationAfterCliff_ =  110376000; // 86400 * 365 * 3.5

    uint256 public constant vestingStartTimestamp =         1594648800; // start_time
    uint256 public constant vestingCliffTimestamp =         vestingStartTimestamp + cliffDuration;
    uint256 public constant vestingEndTimestamp =           vestingStartTimestamp + vestingDuration;
    uint256 public constant vestingLastClaimTimestamp =     vestingEndTimestamp + 86400 * 365;

    uint256 public totalClaimed; // total claimed since start

    IERC20 public constant BZRX = IERC20(0x56d811088235F11C8920698a204A5010a788f4b3);

    uint256 internal constant startingBalance_ = 889389933e18; // 889,389,933 BZRX

    Checkpointing.History internal totalSupplyHistory_;

    mapping (address => uint256) internal lastClaimTime_;
    mapping (address => uint256) internal userTotalClaimed_;

    bool internal isInitialized_;


    // sets up vesting and deposits BZRX
    function initialize()
        external
    {
        require(!isInitialized_, "already initialized");

        balancesHistory_[msg.sender].addCheckpoint(_getBlockNumber(), startingBalance_);
        totalSupplyHistory_.addCheckpoint(_getBlockNumber(), startingBalance_);

        emit Transfer(
            address(0),
            msg.sender,
            startingBalance_
        );

        BZRX.transferFrom(
            msg.sender,
            address(this),
            startingBalance_
        );

        isInitialized_ = true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value)
        public
        returns (bool)
    {
        _claim(_from);
        if (_from != _to) {
            _claim(_to);
        }

        return super.transferFrom(
            _from,
            _to,
            _value
        );
    }

    // user can claim vested BZRX
    function claim()
        public
    {
        _claim(msg.sender);
    }

    // user can burn remaining vBZRX tokens once fully vested; unclaimed BZRX with be withdrawn
    function burn()
        external
    {
        require(_getTimestamp() >= vestingEndTimestamp, "not fully vested");

        _claim(msg.sender);

        uint256 _blockNumber = _getBlockNumber();
        uint256 balanceBefore = balanceOfAt(msg.sender, _blockNumber);
        balancesHistory_[msg.sender].addCheckpoint(_blockNumber, 0);
        totalSupplyHistory_.addCheckpoint(_blockNumber, totalSupplyAt(_blockNumber) - balanceBefore); // overflow not possible

        emit Transfer(
            msg.sender,
            address(0),
            balanceBefore
        );
    }

    // funds unclaimed one year after vesting ends (5 years) can be rescued
    function rescue(
        address _receiver,
        uint256 _amount)
        external
        onlyOwner
    {
        require(_getTimestamp() > vestingLastClaimTimestamp, "unauthorized");

        BZRX.transfer(
            _receiver,
            _amount
        );
    }

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return totalSupplyAt(_getBlockNumber());
    }

    function totalSupplyAt(
        uint256 _blockNumber)
        public
        view
        returns (uint256)
    {
        return totalSupplyHistory_.getValueAt(_blockNumber);
    }

    // total that has vested, but has not yet been claimed by a user
    function vestedBalanceOf(
        address _owner)
        public
        view
        returns (uint256)
    {
        uint256 lastClaim = lastClaimTime_[_owner];
        if (lastClaim < _getTimestamp()) {
            return _totalVested(
                balanceOfAt(_owner, _getBlockNumber()),
                lastClaim
            );
        }
    }

    // total that has not yet vested
    function vestingBalanceOf(
        address _owner)
        public
        view
        returns (uint256 balance)
    {
        balance = balanceOfAt(_owner, _getBlockNumber());
        if (balance != 0) {
            uint256 lastClaim = lastClaimTime_[_owner];
            if (lastClaim < _getTimestamp()) {
                balance = sub(
                    balance,
                    _totalVested(
                        balance,
                        lastClaim
                    )
                );
            }
        }
    }

    // total that has been claimed by a user
    function claimedBalanceOf(
        address _owner)
        public
        view
        returns (uint256)
    {
        return userTotalClaimed_[_owner];
    }

    // total vested since start (claimed + unclaimed)
    function totalVested()
        external
        view
        returns (uint256)
    {
        return _totalVested(startingBalance_, 0);
    }

    // total unclaimed since start
    function totalUnclaimed()
        external
        view
        returns (uint256)
    {
        return sub(
            _totalVested(startingBalance_, 0),
            totalClaimed
        );
    }

    function _claim(
        address _owner)
        internal
    {
        uint256 vested = vestedBalanceOf(_owner);
        if (vested != 0) {
            userTotalClaimed_[_owner] = add(userTotalClaimed_[_owner], vested);
            totalClaimed = add(totalClaimed, vested);

            BZRX.transfer(
                _owner,
                vested
            );

            emit Claim(
                _owner,
                vested
            );
        }

        lastClaimTime_[_owner] = _getTimestamp();
    }

    function _totalVested(
        uint256 _proportionalSupply,
        uint256 _lastClaimTime)
        internal
        view
        returns (uint256)
    {
        uint256 currentTimeForVesting = _getTimestamp();

        if (currentTimeForVesting <= vestingCliffTimestamp ||
            _lastClaimTime >= vestingEndTimestamp ||
            currentTimeForVesting > vestingLastClaimTimestamp) {
            // time cannot be before vesting starts
            // OR all vested token has already been claimed
            // OR time cannot be after last claim date
            return 0;
        }
        if (_lastClaimTime < vestingCliffTimestamp) {
            // vesting starts at the cliff timestamp
            _lastClaimTime = vestingCliffTimestamp;
        }
        if (currentTimeForVesting > vestingEndTimestamp) {
            // vesting ends at the end timestamp
            currentTimeForVesting = vestingEndTimestamp;
        }

        uint256 timeSinceClaim = sub(currentTimeForVesting, _lastClaimTime);
        return mul(_proportionalSupply, timeSinceClaim) / vestingDurationAfterCliff_; // will never divide by 0
    }
}