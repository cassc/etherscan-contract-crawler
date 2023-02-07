// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./PoolGetters.sol";
import "./PoolState.sol";

contract PoolSetters is PoolState, PoolGetters {
    using SafeMath for uint256;

    /**
     * Global
     */

    function pause(uint256 poolID) internal {
        _state[poolID].paused = true;
    }

    function resume(uint256 poolID) internal {
        _state[poolID].paused = false;
    }

    /**
     * Account
     */

    function incrementBalanceOfReward(
        uint256 amount,
        uint256 poolID
    ) internal {
        _state[poolID].balance.reward = _state[poolID].balance.reward.add(
            amount
        );
    }   

    function decrementBalanceOfReward(
        uint256 amount,
        uint256 poolID,
        string memory reason
    ) internal {
        _state[poolID].balance.reward = _state[poolID].balance.reward.sub(
            amount,
            reason
        );
    }  

    function incrementBalanceOfBonded(
        address account,
        uint256 amount,
        uint256 poolID
    ) internal {
        _state[poolID].accounts[account].bonded = _state[poolID]
            .accounts[account]
            .bonded
            .add(amount);
        _state[poolID].balance.bonded = _state[poolID].balance.bonded.add(
            amount
        );
    }

    function decrementBalanceOfBonded(
        address account,
        uint256 amount,
        string memory reason,
        uint256 poolID
    ) internal {
        _state[poolID].accounts[account].bonded = _state[poolID]
            .accounts[account]
            .bonded
            .sub(amount, reason);
        _state[poolID].balance.bonded = _state[poolID].balance.bonded.sub(
            amount,
            reason
        );
    }

    function incrementBalanceOfStaged(
        address account,
        uint256 amount,
        uint256 poolID
    ) internal {
        _state[poolID].accounts[account].staged = _state[poolID]
            .accounts[account]
            .staged
            .add(amount);
        _state[poolID].balance.staged = _state[poolID].balance.staged.add(
            amount
        );
    }

    function decrementBalanceOfStaged(
        address account,
        uint256 amount,
        string memory reason,
        uint256 poolID
    ) internal {
        _state[poolID].accounts[account].staged = _state[poolID]
            .accounts[account]
            .staged
            .sub(amount, reason);
        _state[poolID].balance.staged = _state[poolID].balance.staged.sub(
            amount,
            reason
        );
    }

    function incrementBalanceOfClaimable(
        address account,
        uint256 amount,
        uint256 poolID
    ) internal {
        _state[poolID].accounts[account].claimable = _state[poolID]
            .accounts[account]
            .claimable
            .add(amount);
        _state[poolID].balance.claimable = _state[poolID].balance.claimable.add(
            amount
        );
    }

    function decrementBalanceOfClaimable(
        address account,
        uint256 amount,
        string memory reason,
        uint256 poolID
    ) internal {
        _state[poolID].accounts[account].claimable = _state[poolID]
            .accounts[account]
            .claimable
            .sub(amount, reason);
        _state[poolID].balance.claimable = _state[poolID].balance.claimable.sub(
            amount,
            reason
        );
        _state[poolID].balance.reward = _state[poolID].balance.reward.sub(
            amount,
            reason
        );
    }

    function incrementBalanceOfPhantom(
        address account,
        uint256 amount,
        uint256 poolID
    ) internal {
        _state[poolID].accounts[account].phantom = _state[poolID]
            .accounts[account]
            .phantom
            .add(amount);
        _state[poolID].balance.phantom = _state[poolID].balance.phantom.add(
            amount
        );
    }

    function decrementBalanceOfPhantom(
        address account,
        uint256 amount,
        string memory reason,
        uint256 poolID
    ) internal {
        _state[poolID].accounts[account].phantom = _state[poolID]
            .accounts[account]
            .phantom
            .sub(amount, reason);
        _state[poolID].balance.phantom = _state[poolID].balance.phantom.sub(
            amount,
            reason
        );
    }

    function unfreeze(address account, uint256 poolID) internal {
        _state[poolID].accounts[account].fluidUntil = epoch().add(
            Constants.getPoolExitLockupEpochs()
        );
    }
}