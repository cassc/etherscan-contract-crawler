// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./LibDiamond.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./ISwapRouter.sol";
import "./ISwapRouterV2.sol";
import "./IDividendPayingToken.sol";
import "./IVestingSchedule.sol";

contract WithReward is
    WithStorage,
    AccessControlUpgradeable,
    IDividendPayingToken
{
    // ==================== Errors ==================== //

    error InvalidClaimTime();
    error NoSupply();
    error NullAddress();

    // ==================== Events ==================== //

    event UpdateRewardToken(address token);
    event RewardProcessed(
        address indexed owner,
        uint256 value,
        address indexed token
    );

    event ProcessAccount(address indexed owner, bool indexed isHami, address indexed token);

    function __WithReward_init() internal onlyInitializing {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        // configure excluded from fee role
        _grantRole(LibDiamond.EXCLUDED_FROM_FEE_ROLE, _msgSender());
        _grantRole(LibDiamond.EXCLUDED_FROM_FEE_ROLE, address(this));
        _grantRole(LibDiamond.EXCLUDED_FROM_FEE_ROLE, _ds().liquidityWallet); // protocol added liquidity

        // configure excluded from antiwhale role
        _grantRole(LibDiamond.EXCLUDED_FROM_MAX_WALLET_ROLE, _msgSender());
        _grantRole(LibDiamond.EXCLUDED_FROM_MAX_WALLET_ROLE, address(this));
        _grantRole(LibDiamond.EXCLUDED_FROM_MAX_WALLET_ROLE, address(0));
        _grantRole(
            LibDiamond.EXCLUDED_FROM_MAX_WALLET_ROLE,
            LibDiamond.BURN_ADDRESS
        );
        _grantRole(
            LibDiamond.EXCLUDED_FROM_MAX_WALLET_ROLE,
            _ds().liquidityWallet
        );

        _grantRole(LibDiamond.EXCLUDED_FROM_REWARD_ROLE, _msgSender());
        _grantRole(LibDiamond.EXCLUDED_FROM_REWARD_ROLE, address(this));
        _grantRole(LibDiamond.EXCLUDED_FROM_REWARD_ROLE, address(0));
        _grantRole(
            LibDiamond.EXCLUDED_FROM_REWARD_ROLE,
            LibDiamond.BURN_ADDRESS
        );
    }

    // ==================== DividendPayingToken ==================== //

    // @return dividends The amount of reward in wei that `_owner` can withdraw.
    function dividendOf(
        address _owner
    ) public view returns (uint256 dividends) {
        return withdrawableDividendOf(_owner);
    }

    // @return dividends The amount of rewards that `_owner` has withdrawn
    function withdrawnDividendOf(
        address _owner
    ) public view returns (uint256 dividends) {
        return _rs().withdrawnReward[_owner];
    }

    /// The total accumulated rewards for a address
    function accumulativeDividendOf(
        address _owner
    ) public view returns (uint256 accumulated) {
        return
            SafeCast.toUint256(
                SafeCast.toInt256(
                    _rs().magnifiedRewardPerShare * rewardBalanceOf(_owner)
                ) + _rs().magnifiedReward[_owner]
            ) / LibDiamond.MAGNITUDE;
    }

    /// The total withdrawable rewards for a address
    function withdrawableDividendOf(
        address _owner
    ) public view returns (uint256 withdrawable) {
        return accumulativeDividendOf(_owner) - _rs().withdrawnReward[_owner];
    }

    // ==================== Views ==================== //

    function getRewardPerShare() public view returns (uint256) {
        return _rs().magnifiedRewardPerShare;
    }

    function getGoHam()
        external
        view
        returns (address token, address router, bool isV3)
    {
        LibDiamond.RewardToken memory goHam = _rs().goHam;
        return (goHam.token, goHam.router, _rs().useV3);
    }

    function getRewardToken()
        external
        view
        returns (address token, address router, bool isV3)
    {
        LibDiamond.RewardToken memory rewardToken = _rs().rewardToken;
        return (rewardToken.token, rewardToken.router, _rs().useV3);
    }

    function rewardBalanceOf(address account) public view returns (uint256) {
        return _rs().rewardBalances[account];
    }

    function totalRewardSupply() public view returns (uint256) {
        return _rs().totalRewardSupply;
    }

    function isExcludedFromRewards(address account) public view returns (bool) {
        return hasRole(LibDiamond.EXCLUDED_FROM_REWARD_ROLE, account);
    }

    /// Gets the index of the last processed wallet
    // @return index The index of the last wallet that was paid rewards
    function getLastProcessedIndex() external view returns (uint256 index) {
        return _rs().lastProcessedIndex;
    }

    // @return numHolders The number of reward tracking token holders
    function getRewardHolders() external view returns (uint256 numHolders) {
        return _rs().rewardHolders.keys.length;
    }

    // gets reward account information by address
    function getRewardAccount(
        address _account
    )
        public
        view
        returns (
            address account,
            int256 index,
            int256 numInQueue,
            uint256 rewardBalance,
            uint256 withdrawableRewards,
            uint256 totalRewards,
            bool manualClaim
        )
    {
        account = _account;
        index = getIndexOfKey(account);
        if (index < 0) {
            return (account, -1, 0, 0, 0, 0, false);
        }

        uint256 lastProcessedIndex = _rs().lastProcessedIndex;

        numInQueue = 0;
        if (uint256(index) > lastProcessedIndex) {
            numInQueue = index - int256(lastProcessedIndex);
        } else {
            uint256 holders = _rs().rewardHolders.keys.length;
            uint256 processesUntilEndOfArray = holders > lastProcessedIndex
                ? holders - lastProcessedIndex
                : 0;
            numInQueue = index + int256(processesUntilEndOfArray);
        }
        rewardBalance = rewardBalanceOf(account);
        withdrawableRewards = withdrawableDividendOf(account);
        totalRewards = accumulativeDividendOf(account);
        manualClaim = _rs().manualClaim[account];
    }

    function getRewardAccountAtIndex(
        uint256 _index
    )
        external
        view
        returns (
            address account,
            int256 index,
            int256 numInQueue,
            uint256 rewardBalance,
            uint256 withdrawableRewards,
            uint256 totalRewards,
            bool manualClaim
        )
    {
        if (_index >= _rs().rewardHolders.keys.length) {
            return (account, -1, 0, 0, 0, 0, false);
        }
        return getRewardAccount(_rs().rewardHolders.keys[_index]);
    }

    // function getAccountAtIndex(uint256 _index)
    //     external
    //     view
    //     returns (
    //         address account,
    //         int256 index,
    //         int256 numInQueue,
    //         uint256 withdrawableRewards,
    //         uint256 totalRewards,
    //         uint256 lastClaimTime,
    //         uint256 nextClaimTime,
    //         uint256 timeTillAutoClaim,
    //         bool manualClaim
    //     )
    // {
    //     return getRewardAccount(_rs().rewardHolders.keys[_index]);
    // }

    // ==================== Management ==================== //

    function setRewardPerShare(
        uint256 _newPerShare
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _rs().magnifiedRewardPerShare = _newPerShare;
    }

    // ==================== Management ==================== //

    function claimRewards(bool goHami, uint256 expectedOutput) external {
        _processAccount(_msgSender(), goHami, expectedOutput);
    }

    // @notice Adds incoming funds to the rewards per share
    function accrueReward(uint256 amount) internal {
        uint256 rewardSupply = totalRewardSupply();
        if (rewardSupply <= 0) revert NoSupply();

        if (amount > 0) {
            _rs().magnifiedRewardPerShare +=
                (amount * LibDiamond.MAGNITUDE) /
                rewardSupply;
            _rs().totalAccruedReward += amount;
        }
    }

    // Vesting contract can update reward balance of account
    function updateRewardBalance(
        address account,
        uint256 balance
    ) public onlyRole(LibDiamond.VESTING_ROLE) {
        _setRewardBalance(account, balance);
    }

    function setGoHam(
        address token,
        address router,
        address[] calldata path,
        bool _useV3,
        bytes calldata pathV3
    ) external {
        if (token == address(0)) revert NullAddress();
        LibDiamond.RewardToken storage goHam = _rs().goHam;

        goHam.token = token;
        goHam.router = router;
        goHam.path = path;

        _rs().useV3 = _useV3;
        _rs().pathV3 = pathV3;
    }

    // @param token The token address of the reward
    function setRewardToken(
        address token,
        address router,
        address[] calldata path,
        bool _useV3,
        bytes calldata pathV3
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // token == address(0) means reward by ETH
        LibDiamond.RewardToken storage rewardToken = _rs().rewardToken;

        rewardToken.token = token;
        rewardToken.router = router;
        rewardToken.path = path;

        _rs().useV3 = _useV3;
        _rs().pathV3 = pathV3;

        _ds().swapRouters[router] = true;
        emit UpdateRewardToken(token);
    }

    function excludeFromReward(
        address _account
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(LibDiamond.EXCLUDED_FROM_REWARD_ROLE, _account);
        _setBalance(_account, 0);
        _remove(_account);
    }

    function setMinBalanceForReward(
        uint256 newValue
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _rs().minRewardBalance = newValue;
    }

    function setManualClaim(bool _manual) external {
        _rs().manualClaim[msg.sender] = _manual;
    }

    function overrideWithdrawnRewards(
        address _owner,
        uint256 newValue
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _rs().withdrawnReward[_owner] = newValue;
    }

    // @param _new The new time (in seconds) needed between claims
    // @dev Must be between 3600 and 86400 seconds
    function updateClaimTimeout(
        uint32 _new
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_new < 3600 || _new > 86400) revert InvalidClaimTime();
        _rs().claimTimeout = _new;
    }

    // ==================== Internal ==================== //

    // This function uses a set amount of gas to process rewards for as many wallets as it can
    function _processRewards() internal {
        uint256 gas = _ds().processingGas;
        if (gas <= 0) {
            return;
        }

        uint256 numHolders = _rs().rewardHolders.keys.length;
        uint256 _lastProcessedIndex = _rs().lastProcessedIndex;
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;

        while (gasUsed < gas && iterations < numHolders) {
            ++iterations;
            if (++_lastProcessedIndex >= _rs().rewardHolders.keys.length) {
                _lastProcessedIndex = 0;
            }
            address account = _rs().rewardHolders.keys[_lastProcessedIndex];

            if (_rs().manualClaim[account]) continue;

            if (!_canAutoClaim(_rs().claimTimes[account])) continue;
            _processAccount(account, false, 0);

            uint256 newGasLeft = gasleft();
            if (gasLeft > newGasLeft) {
                gasUsed += gasLeft - newGasLeft;
            }
            gasLeft = newGasLeft;
        }
        _rs().lastProcessedIndex = _lastProcessedIndex;
    }

    // @param newBalance The new balance to set for the account.
    function _setRewardBalance(address account, uint256 newBalance) internal {
        if (isExcludedFromRewards(account)) return;

        // (, , , , , , uint256 amountTotal, uint256 released) = IVestingSchedule(
        //     _ds().vestingContract
        // ).getVestingSchedule(account);
        // if (amountTotal > 0) {
        //     newBalance += amountTotal - released;
        // }

        if (newBalance >= _rs().minRewardBalance) {
            _setBalance(account, newBalance);
            _set(account, newBalance);
        } else {
            _setBalance(account, 0);
            _remove(account);
            _processAccount(account, false, 0);
        }
    }

    function _canAutoClaim(uint256 lastClaimTime) internal view returns (bool) {
        return
            lastClaimTime > block.timestamp
                ? false
                : block.timestamp - lastClaimTime >= _rs().claimTimeout;
    }

    function _set(address key, uint256 val) internal {
        LibDiamond.Map storage rewardHolders = _rs().rewardHolders;
        if (rewardHolders.inserted[key]) {
            rewardHolders.values[key] = val;
        } else {
            rewardHolders.inserted[key] = true;
            rewardHolders.values[key] = val;
            rewardHolders.indexOf[key] = rewardHolders.keys.length;
            rewardHolders.keys.push(key);
        }
    }

    function _remove(address key) internal {
        LibDiamond.Map storage rewardHolders = _rs().rewardHolders;
        if (!rewardHolders.inserted[key]) {
            return;
        }

        delete rewardHolders.inserted[key];
        delete rewardHolders.values[key];

        uint256 index = rewardHolders.indexOf[key];
        uint256 lastIndex = rewardHolders.keys.length - 1;
        address lastKey = rewardHolders.keys[lastIndex];

        rewardHolders.indexOf[lastKey] = index;
        delete rewardHolders.indexOf[key];

        rewardHolders.keys[index] = lastKey;
        rewardHolders.keys.pop();
    }

    function getIndexOfKey(address key) internal view returns (int256 index) {
        return
            !_rs().rewardHolders.inserted[key]
                ? -1
                : int256(_rs().rewardHolders.indexOf[key]);
    }

    function _processAccount(
        address _owner,
        bool _goHami,
        uint256 _expectedOutput
    ) internal {
        uint256 _withdrawableReward = withdrawableDividendOf(_owner);
        if (_withdrawableReward <= 0) {
            return;
        }
        _rs().withdrawnReward[_owner] += _withdrawableReward;
        _rs().claimTimes[_owner] = block.timestamp;

        LibDiamond.RewardToken memory rewardToken = _goHami
            ? _rs().goHam
            : _rs().rewardToken;

        if (_rs().useV3 && !_goHami) {
            _swapUsingV3(
                rewardToken,
                _withdrawableReward,
                _owner,
                _expectedOutput
            );
        } else {
            _swapUsingV2(
                rewardToken,
                _withdrawableReward,
                _owner,
                _expectedOutput
            );
        }

        emit ProcessAccount(_owner, _goHami, rewardToken.token);
    }

    function _setBalance(address _owner, uint256 _newBalance) internal {
        uint256 currentBalance = rewardBalanceOf(_owner);
        _rs().totalRewardSupply =
            _rs().totalRewardSupply +
            _newBalance -
            currentBalance;
        if (_newBalance > currentBalance) {
            _add(_owner, _newBalance - currentBalance);
        } else if (_newBalance < currentBalance) {
            _subtract(_owner, currentBalance - _newBalance);
        }
    }

    function _add(address _owner, uint256 value) internal {
        _rs().magnifiedReward[_owner] -= SafeCast.toInt256(
            _rs().magnifiedRewardPerShare * value
        );
        _rs().rewardBalances[_owner] += value;
    }

    function _subtract(address _owner, uint256 value) internal {
        _rs().magnifiedReward[_owner] += SafeCast.toInt256(
            _rs().magnifiedRewardPerShare * value
        );
        _rs().rewardBalances[_owner] -= value;
    }

    function _swapUsingV2(
        LibDiamond.RewardToken memory rewardToken,
        uint256 _value,
        address _owner,
        uint256 _expectedOutput
    ) internal {
        if (rewardToken.token == address(0)) {
            (bool success, ) = payable(_owner).call{value: _value}("");
        } else {
            try
                ISwapRouterV2(rewardToken.router).swapExactETHForTokensSupportingFeeOnTransferTokens{value: _value}(_expectedOutput, rewardToken.path, _owner, block.timestamp)
            {
                emit RewardProcessed(_owner, _value, rewardToken.token);
            } catch {
                _rs().withdrawnReward[_owner] -= _value;
            }
        }
    }

    function _swapUsingV3(
        LibDiamond.RewardToken memory rewardToken,
        uint256 _value,
        address _owner,
        uint256 _expectedOutput
    ) internal {
        if (rewardToken.token == address(0)) {
            (bool success, ) = payable(_owner).call{value: _value}("");
        } else {
            ISwapRouter.ExactInputParams memory params = ISwapRouter
                .ExactInputParams({
                    path: _rs().pathV3,
                    recipient: address(_owner),
                    deadline: block.timestamp,
                    amountIn: _value,
                    amountOutMinimum: _expectedOutput
                });

            try ISwapRouter(rewardToken.router).exactInput{value: _value}(params) {
                emit RewardProcessed(_owner, _value, rewardToken.token);
            } catch {
                _rs().withdrawnReward[_owner] -= _value;
            }
        }
    }
}