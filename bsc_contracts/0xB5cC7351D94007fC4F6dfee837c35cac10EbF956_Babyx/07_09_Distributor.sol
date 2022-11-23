// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import './interfaces/IUniswapDex.sol';

/// @dev A contract that allows anyone to pay and distribute ethers to users as shares.
/// @notice This contract is based on erc1726 by Roger-Wu (https://github.com/Roger-Wu/erc1726-dividend-paying-token)

contract Distributor is Ownable {
    using Address for address payable;

    mapping(address => uint256) public userShares;
    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;
    mapping(address => bool) public excludedFromDividends;
    mapping(address => uint256) public lastClaimTime;
    mapping(address => uint256) public elegibleUsersIndex;
    mapping(address => bool) public isElegible;

    address[] elegibleUsers;

    IRouter public rewardRouter;
    address public rewardToken;

    uint256 internal constant magnitude = 2 ** 128;

    uint256 internal magnifiedDividendPerShare;
    uint256 public totalDividends;
    uint256 public totalDividendsWithdrawn;
    uint256 public totalShares;
    uint256 public minBalanceForRewards;
    uint256 public claimDelay;
    uint256 public currentIndex;

    event ExcludeFromDividends(address indexed account, bool value);
    event Claim(address indexed account, uint256 amount);
    event DividendWithdrawn(address indexed to, uint256 weiAmount);

    constructor(address _router, address _rewardToken) {
        rewardRouter = IRouter(_router);
        rewardToken = _rewardToken;
    }

    function excludeFromDividends(address account, bool value) external onlyOwner {
        require(excludedFromDividends[account] != value, 'Account excluded');
        excludedFromDividends[account] = value;
        if (value == true) {
            _setBalance(account, 0);
        } else {
            _setBalance(account, userShares[account]);
        }
        emit ExcludeFromDividends(account, value);
    }

    function _setRewardToken(address newToken) internal {
        rewardToken = newToken;
    }

    function getAccount(
        address account
    )
        public
        view
        returns (
            uint256 withdrawableUserDividends,
            uint256 totalUserDividends,
            uint256 lastUserClaimTime,
            uint256 withdrawnUserDividends
        )
    {
        withdrawableUserDividends = withdrawableDividendOf(account);
        totalUserDividends = accumulativeDividendOf(account);
        lastUserClaimTime = lastClaimTime[account];
        withdrawnUserDividends = withdrawnDividends[account];
    }

    function setBalance(address account, uint256 newBalance) internal {
        if (excludedFromDividends[account]) {
            return;
        }
        _setBalance(account, newBalance);
    }

    function _setMinBalanceForRewards(uint256 newMinBalance) internal {
        minBalanceForRewards = newMinBalance;
    }

    function autoDistribute(uint256 gasAvailable) public {
        uint256 size = elegibleUsers.length;
        if (size == 0) return;

        uint256 gasSpent = 0;
        uint256 gasLeft = gasleft();
        uint256 lastIndex = currentIndex;
        uint256 iterations = 0;

        while (gasSpent < gasAvailable && iterations < size) {
            if (lastIndex >= size) {
                lastIndex = 0;
            }
            address account = elegibleUsers[lastIndex];
            if (lastClaimTime[account] + claimDelay < block.timestamp) {
                _processAccount(account);
            }
            lastIndex++;
            iterations++;
            gasSpent += gasLeft - gasleft();
            gasLeft = gasleft();
        }

        currentIndex = lastIndex;
    }

    function _processAccount(address account) internal returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

        if (amount > 0) {
            lastClaimTime[account] = block.timestamp;
            emit Claim(account, amount);
            return true;
        }
        return false;
    }

    function distributeDividends() external payable {
        if (msg.value > 0) {
            _distributeDividends(msg.value);
        }
    }

    function _distributeDividends(uint256 amount) internal {
        require(totalShares > 0, 'Total shares must be > 0');
        magnifiedDividendPerShare = magnifiedDividendPerShare + ((amount * magnitude) / totalShares);
        totalDividends = totalDividends + amount;
    }

    function _withdrawDividendOfUser(address user) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] += _withdrawableDividend;
            totalDividendsWithdrawn += _withdrawableDividend;
            emit DividendWithdrawn(user, _withdrawableDividend);
            bool success = swapEthForCustomToken(user, _withdrawableDividend);
            if (!success) {
                (bool secondSuccess, ) = payable(user).call{value: _withdrawableDividend, gas: 3000}('');
                if (!secondSuccess) {
                    withdrawnDividends[user] -= _withdrawableDividend;
                    totalDividendsWithdrawn -= _withdrawableDividend;
                    return 0;
                }
            }
            return _withdrawableDividend;
        }
        return 0;
    }

    function swapEthForCustomToken(address user, uint256 amt) internal returns (bool) {
        address[] memory path = new address[](2);
        path[0] = rewardRouter.WETH();
        path[1] = rewardToken;

        try
            rewardRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amt}(0, path, user, block.timestamp)
        {
            return true;
        } catch {
            return false;
        }
    }

    function dividendOf(address _owner) public view returns (uint256) {
        return withdrawableDividendOf(_owner);
    }

    function withdrawableDividendOf(address _owner) public view returns (uint256) {
        return accumulativeDividendOf(_owner) - withdrawnDividends[_owner];
    }

    function withdrawnDividendOf(address _owner) public view returns (uint256) {
        return withdrawnDividends[_owner];
    }

    function accumulativeDividendOf(address _owner) public view returns (uint256) {
        return
            uint256(int256(magnifiedDividendPerShare * userShares[_owner]) + magnifiedDividendCorrections[_owner]) /
            magnitude;
    }

    function addShares(address account, uint256 value) internal {
        userShares[account] += value;
        totalShares += value;

        magnifiedDividendCorrections[account] =
            magnifiedDividendCorrections[account] -
            int256(magnifiedDividendPerShare * value);
    }

    function removeShares(address account, uint256 value) internal {
        userShares[account] -= value;
        totalShares -= value;

        magnifiedDividendCorrections[account] =
            magnifiedDividendCorrections[account] +
            int256(magnifiedDividendPerShare * value);
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = userShares[account];
        if (currentBalance > 0) {
            _processAccount(account);
        }
        if (newBalance < minBalanceForRewards && isElegible[account]) {
            isElegible[account] = false;
            elegibleUsers[elegibleUsersIndex[account]] = elegibleUsers[elegibleUsers.length - 1];
            elegibleUsersIndex[elegibleUsers[elegibleUsers.length - 1]] = elegibleUsersIndex[account];
            elegibleUsers.pop();
            removeShares(account, currentBalance);
        } else {
            if (userShares[account] == 0) {
                isElegible[account] = true;
                elegibleUsersIndex[account] = elegibleUsers.length;
                elegibleUsers.push(account);
            }
            if (newBalance > currentBalance) {
                uint256 mintAmount = newBalance - currentBalance;
                addShares(account, mintAmount);
            } else if (newBalance < currentBalance) {
                uint256 burnAmount = currentBalance - newBalance;
                removeShares(account, burnAmount);
            }
        }
    }
}