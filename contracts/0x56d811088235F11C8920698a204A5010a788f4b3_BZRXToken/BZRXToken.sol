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

contract BZRXToken is CheckpointingToken {

    string public constant name = "bZx Protocol Token";
    string public constant symbol = "BZRX";
    uint8 public constant decimals = 18;

    uint256 internal constant totalSupply_ = 1030000000e18; // 1,030,000,000 BZRX

    constructor(
        address _to)
        public
    {
        balancesHistory_[_to].addCheckpoint(_getBlockNumber(), totalSupply_);
        emit Transfer(address(0), _to, totalSupply_);
    }

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return totalSupply_;
    }
}