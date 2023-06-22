//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/*
This contract allows XRUNE holders and LPs to lock some of their tokens up for
vXRUNE, the Thorstarter DAO's voting token. It's an ERC20 but without the
transfer methods.
It supports snapshoting and delegation of voting power.
*/

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IVoters.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IERC677Receiver.sol";

contract Voters is IVoters, IERC677Receiver, AccessControl { 
    using SafeERC20 for IERC20;
    
    struct UserInfo {
        uint lastFeeGrowth;
        uint lockedToken;
        uint lockedSsLpValue;
        uint lockedSsLpAmount;
        uint lockedTcLpValue;
        uint lockedTcLpAmount;
        address delegate;
    }
    struct Snapshots {
        uint[] ids;
        uint[] values;
    }

    event Transfer(address indexed from, address indexed to, uint value);
    event Snapshot(uint id);
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    string public constant name = "Thorstarter Voting Token";
    string public constant symbol = "vXRUNE";
    uint8 public constant decimals = 18;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER");
    bytes32 public constant SNAPSHOTTER_ROLE = keccak256("SNAPSHOTTER");
    IERC20 public token;
    IERC20 public sushiLpToken;
    uint public lastFeeGrowth;
    uint public totalSupply;
    mapping(address => UserInfo) private _userInfos;
    uint public currentSnapshotId;
    Snapshots private _totalSupplySnapshots;
    mapping(address => Snapshots) private _balancesSnapshots;
    mapping(address => uint) private _votes;
    mapping(address => Snapshots) private _votesSnapshots;
    mapping(address => bool) public historicalTcLps;
    address[] private _historicalTcLpsList;
    mapping(address => uint) public lastLockBlock;

    constructor(address _owner, address _token, address _sushiLpToken) {
        _setRoleAdmin(KEEPER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(SNAPSHOTTER_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, _owner);
        _setupRole(KEEPER_ROLE, _owner);
        _setupRole(SNAPSHOTTER_ROLE, _owner);
        token = IERC20(_token);
        sushiLpToken = IERC20(_sushiLpToken);
        currentSnapshotId = 1;
    }

    function userInfo(address user) external view returns (uint, uint, uint, uint, uint, uint, address) {
      UserInfo storage userInfo = _userInfos[user];
      return (
        userInfo.lastFeeGrowth,
        userInfo.lockedToken,
        userInfo.lockedSsLpValue,
        userInfo.lockedSsLpAmount,
        userInfo.lockedTcLpValue,
        userInfo.lockedTcLpAmount,
        userInfo.delegate
      );
    }

    function balanceOf(address user) override public view returns (uint) {
        UserInfo storage userInfo = _userInfos[user];
        return _userInfoTotal(userInfo);
    }

    function balanceOfAt(address user, uint snapshotId) override external view returns (uint) {
        (bool snapshotted, uint value) = _valueAt(_balancesSnapshots[user], snapshotId);
        return snapshotted ? value : balanceOf(user);
    }

    function votes(address user) public view returns (uint) {
        return _votes[user];
    }

    function votesAt(address user, uint snapshotId) override external view returns (uint) {
        (bool snapshotted, uint value) = _valueAt(_votesSnapshots[user], snapshotId);
        return snapshotted ? value : votes(user);
    }

    function totalSupplyAt(uint snapshotId) override external view returns (uint) {
        (bool snapshotted, uint value) = _valueAt(_totalSupplySnapshots, snapshotId);
        return snapshotted ? value : totalSupply;
    }

    function approve(address spender, uint amount) external returns (bool) {
        revert("not implemented");
    }

    function transfer(address to, uint amount) external returns (bool) {
        revert("not implemented");
    }

    function transferFrom(address from, address to, uint amount) external returns (bool) {
        revert("not implemented");
    }

    function snapshot() override external onlyRole(SNAPSHOTTER_ROLE) returns (uint) {
        currentSnapshotId += 1;
        emit Snapshot(currentSnapshotId);
        return currentSnapshotId;
    }

    function _valueAt(Snapshots storage snapshots, uint snapshotId) private view returns (bool, uint) {
        if (snapshots.ids.length == 0) {
            return (false, 0);
        }
        uint lower = 0;
        uint upper = snapshots.ids.length;
        while (lower < upper) {
            uint mid = (lower & upper) + (lower ^ upper) / 2;
            if (snapshots.ids[mid] > snapshotId) {
                upper = mid;
            } else {
                lower = mid + 1;
            }
        }

        uint index = lower;
        if (lower > 0 && snapshots.ids[lower - 1] == snapshotId) {
          index = lower -1;
        }

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateSnapshot(Snapshots storage snapshots, uint value) private {
        uint currentId = currentSnapshotId;
        uint lastSnapshotId = 0;
        if (snapshots.ids.length > 0) {
            lastSnapshotId = snapshots.ids[snapshots.ids.length - 1];
        }
        if (lastSnapshotId < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(value);
        }
    }

    function delegate(address delegatee) external {
        require(delegatee != address(0), "zero address provided");
        UserInfo storage userInfo = _userInfos[msg.sender];
        address currentDelegate = userInfo.delegate;
        userInfo.delegate = delegatee;

        _updateSnapshot(_votesSnapshots[currentDelegate], votes(currentDelegate));
        _updateSnapshot(_votesSnapshots[delegatee], votes(delegatee));
        uint amount = balanceOf(msg.sender);
        _votes[currentDelegate] -= amount;
        _votes[delegatee] += amount;

        emit DelegateChanged(msg.sender, currentDelegate, delegatee);
    }

    function _lock(address user, uint amount) private {
        require(amount > 0, "!zero");
        UserInfo storage userInfo = _userInfo(user);

        // track last time a user called the lock method to prevent flash loan attacks
        lastLockBlock[user] = block.number;

        _updateSnapshot(_totalSupplySnapshots, totalSupply);
        _updateSnapshot(_balancesSnapshots[user], balanceOf(user));
        _updateSnapshot(_votesSnapshots[userInfo.delegate], votes(userInfo.delegate));

        totalSupply += amount;
        userInfo.lockedToken += amount;
        _votes[userInfo.delegate] += amount;
        emit Transfer(address(0), user, amount);
    }

    function lock(uint amount) external {
        _transferFrom(token, msg.sender, amount);
        _lock(msg.sender, amount);
    }

    function onTokenTransfer(address user, uint amount, bytes calldata _data) external override {
        require(msg.sender == address(token), "onTokenTransfer: not xrune");
        _lock(user, amount);
    }

    function unlock(uint amount) external {
        require(block.number > lastLockBlock[msg.sender], "no lock-unlock in same tx");

        UserInfo storage userInfo = _userInfo(msg.sender);
        require(amount <= userInfo.lockedToken, "locked balance too low");

        _updateSnapshot(_totalSupplySnapshots, totalSupply);
        _updateSnapshot(_balancesSnapshots[msg.sender], balanceOf(msg.sender));
        _updateSnapshot(_votesSnapshots[userInfo.delegate], votes(userInfo.delegate));

        totalSupply -= amount;
        userInfo.lockedToken -= amount;
        _votes[userInfo.delegate] -= amount;
        emit Transfer(msg.sender, address(0), amount);

        if (amount > 0) {
            token.safeTransfer(msg.sender, amount);
        }
    }

    function lockSslp(uint lpAmount) external {
        UserInfo storage userInfo = _userInfo(msg.sender);
        require(lpAmount > 0, "!zero");
        _transferFrom(sushiLpToken, msg.sender, lpAmount);

        _updateSnapshot(_totalSupplySnapshots, totalSupply);
        _updateSnapshot(_balancesSnapshots[msg.sender], balanceOf(msg.sender));
        _updateSnapshot(_votesSnapshots[userInfo.delegate], votes(userInfo.delegate));

        // Subtract current LP value
        uint previousValue = userInfo.lockedSsLpValue;
        totalSupply -= userInfo.lockedSsLpValue;
        _votes[userInfo.delegate] -= userInfo.lockedSsLpValue;

        // Increment LP amount
        userInfo.lockedSsLpAmount += lpAmount;

        // Calculated updated *full* LP amount value and set (not increment)
        // We do it like this and not based on just amount added so that unlock
        // knows that the lockedSsLpValue is based on one rate and not multiple adds
        uint lpTokenSupply = sushiLpToken.totalSupply();
        uint lpTokenReserve = token.balanceOf(address(sushiLpToken));
        require(lpTokenSupply > 0, "lp token supply can not be zero");
        uint amount = (2 * userInfo.lockedSsLpAmount * lpTokenReserve) / lpTokenSupply;
        totalSupply += amount; // Increment as we decremented
        _votes[userInfo.delegate] += amount; // Increment as we decremented
        userInfo.lockedSsLpValue = amount; // Set a we didn't ajust and amount is full value
        if (previousValue < userInfo.lockedSsLpValue) {
            emit Transfer(address(0), msg.sender, userInfo.lockedSsLpValue - previousValue);
        } else if (previousValue > userInfo.lockedSsLpValue) {
            emit Transfer(msg.sender, address(0), previousValue - userInfo.lockedSsLpValue);
        }
    }

    function unlockSslp(uint lpAmount) external {
        UserInfo storage userInfo = _userInfo(msg.sender);
        require(lpAmount > 0, "amount can't be 0");
        require(lpAmount <= userInfo.lockedSsLpAmount, "locked balance too low");

        _updateSnapshot(_totalSupplySnapshots, totalSupply);
        _updateSnapshot(_balancesSnapshots[msg.sender], balanceOf(msg.sender));
        _updateSnapshot(_votesSnapshots[userInfo.delegate], votes(userInfo.delegate));

        // Proportionally decrement lockedSsLpValue & supply & delegated votes
        uint amount = lpAmount * userInfo.lockedSsLpValue / userInfo.lockedSsLpAmount;
        totalSupply -= amount;
        userInfo.lockedSsLpValue -= amount;
        userInfo.lockedSsLpAmount -= lpAmount;
        _votes[userInfo.delegate] -= amount;
        emit Transfer(msg.sender, address(0), amount);

        sushiLpToken.safeTransfer(msg.sender, lpAmount);
    }

    function updateTclp(address[] calldata users, uint[] calldata amounts, uint[] calldata values) external onlyRole(KEEPER_ROLE) {
        require(users.length == amounts.length && users.length == values.length, "length");
        for (uint i = 0; i < users.length; i++) {
            address user = users[i];
            UserInfo storage userInfo = _userInfo(user);
            _updateSnapshot(_totalSupplySnapshots, totalSupply);
            _updateSnapshot(_balancesSnapshots[user], balanceOf(user));
            _updateSnapshot(_votesSnapshots[userInfo.delegate], votes(userInfo.delegate));

            uint previousValue = userInfo.lockedTcLpValue;
            totalSupply = totalSupply - previousValue + values[i];
            _votes[userInfo.delegate] = _votes[userInfo.delegate] - previousValue + values[i];
            userInfo.lockedTcLpValue = values[i];
            userInfo.lockedTcLpAmount = amounts[i];
            if (previousValue < values[i]) {
                emit Transfer(address(0), user, values[i] - previousValue);
            } else if (previousValue > values[i]) {
                emit Transfer(user, address(0), previousValue - values[i]);
            }

            // Add to historicalTcLpsList for keepers to use
            if (!historicalTcLps[user]) {
              historicalTcLps[user] = true;
              _historicalTcLpsList.push(user);
            }
        }
    }

    function historicalTcLpsList(uint page, uint pageSize) external view returns (address[] memory) {
      address[] memory list = new address[](pageSize);
      for (uint i = page * pageSize; i < (page + 1) * pageSize && i < _historicalTcLpsList.length; i++) {
        list[i-(page*pageSize)] = _historicalTcLpsList[i];
      }
      return list;
    }

    function donate(uint amount) override external {
        _transferFrom(token, msg.sender, amount);
        lastFeeGrowth += (amount * 1e12) / totalSupply;
    }

    function _userInfo(address user) private returns (UserInfo storage) {
        require(user != address(0), "zero address provided");
        UserInfo storage userInfo = _userInfos[user];
        if (userInfo.delegate == address(0)) {
            userInfo.delegate = user;
        }
        if (userInfo.lastFeeGrowth == 0 && lastFeeGrowth != 0) {
            userInfo.lastFeeGrowth = lastFeeGrowth;
        } else {
            uint fees = (_userInfoTotal(userInfo) * (lastFeeGrowth - userInfo.lastFeeGrowth)) / 1e12;
            if (fees > 0) {
                _updateSnapshot(_totalSupplySnapshots, totalSupply);
                _updateSnapshot(_balancesSnapshots[user], balanceOf(user));
                _updateSnapshot(_votesSnapshots[userInfo.delegate], votes(userInfo.delegate));

                totalSupply += fees;
                userInfo.lockedToken += fees;
                userInfo.lastFeeGrowth = lastFeeGrowth;
                _votes[userInfo.delegate] += fees;
                emit Transfer(address(0), user, fees);
            }
        }
        return userInfo;
    }

    function _userInfoTotal(UserInfo storage userInfo) private view returns (uint) {
        return userInfo.lockedToken + userInfo.lockedSsLpValue + userInfo.lockedTcLpValue;
    }

    function _transferFrom(IERC20 token, address from, uint amount) private {
        uint balanceBefore = token.balanceOf(address(this));
        token.safeTransferFrom(from, address(this), amount);
        uint balanceAfter = token.balanceOf(address(this));
        require(balanceAfter - balanceBefore == amount, "_transferFrom: balance change does not match amount");
    }
}