// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import 'hardhat/console.sol';

interface IErc20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

struct WithdrawData {
    address account;
    uint256 count;
    int256 serverBalanceChange;
}

contract Ffwar {
    mapping(address => uint256) _balances;
    IErc20 immutable _token;
    address _server;
    uint256 _totalBalances;

    event OnAddBalance(address indexed account, uint256 count, uint256 balance);
    event OnWithdraw(address indexed account, uint256 count, uint256 balance);

    constructor(address tokenAddress_) {
        _token = IErc20(tokenAddress_);
        _server = msg.sender;
    }

    modifier OnlyServer() {
        require(msg.sender == _server, 'only for server');
        _;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function totalBalances() external view returns (uint256) {
        return _totalBalances;
    }

    function rewardPool() external view returns (uint256) {
        return _token.balanceOf(address(this)) - _totalBalances;
    }

    function addBalance(uint256 count) external {
        _addBalance(msg.sender, count);
    }

    function addBalanceFrom(address account, uint256 count)
        external
        OnlyServer
    {
        _addBalance(account, count);
    }

    function _addBalance(address account, uint256 count) internal {
        uint256 lastBalance = _token.balanceOf(address(this));
        _token.transferFrom(account, address(this), count);
        uint256 balanceAdded = _token.balanceOf(address(this)) - lastBalance;
        _balances[account] += balanceAdded;
        _totalBalances += balanceAdded;
        emit OnAddBalance(account, balanceAdded, _balances[account]);
    }

    function withdraw(
        address account,
        uint256 count,
        int256 serverBalanceChange
    ) external OnlyServer {
        _withdraw(WithdrawData(account, count, serverBalanceChange));
    }

    function withdrawList(WithdrawData[] calldata data) external OnlyServer {
        // apply server negative changes (for increase reward pool)
        for (uint256 i = 0; i < data.length; ++i) {
            if (data[i].serverBalanceChange < 0) _withdraw(data[i]);
        }
        // apply server positive or zero changes (using reward pool)
        for (uint256 i = 0; i < data.length; ++i) {
            if (data[i].serverBalanceChange >= 0) _withdraw(data[i]);
        }
    }

    function _withdraw(WithdrawData memory data) internal {
        // limit if nmore than reward pool
        if (data.serverBalanceChange > int256(this.rewardPool()))
            data.serverBalanceChange = int256(this.rewardPool());

        // arrange withdraw count
        if (
            data.serverBalanceChange < 0 &&
            int256(_balances[data.account]) < -data.serverBalanceChange
        ) {
            _totalBalances -= _balances[data.account];
            _balances[data.account] = 0;
            data.count = 0;
            emit OnWithdraw(data.account, 0, 0);
        } else {
            _totalBalances = uint256(
                int256(_totalBalances) + data.serverBalanceChange
            );
            _balances[data.account] = uint256(
                int256(_balances[data.account]) + data.serverBalanceChange
            );
            if (data.count > _balances[data.account])
                data.count = _balances[data.account];

            // thansfer asset
            uint256 lastBalance = _token.balanceOf(address(this));
            _token.transfer(data.account, data.count);
            uint256 balanceRemoved = lastBalance -
                _token.balanceOf(address(this));

            //
            _totalBalances -= balanceRemoved;
            _balances[data.account] -= data.count;

            // emit event
            emit OnWithdraw(data.account, data.count, _balances[data.account]);
        }

        require(this.rewardPool() >= 0, 'control reward pool check');
    }

    function tokenAddress() external view returns (address) {
        return address(_token);
    }

    function setServer(address newServer) external OnlyServer {
        _server = newServer;
    }
}