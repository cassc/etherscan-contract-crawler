// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import '../utils/SafeMath.sol';
import '../utils/Math.sol';

/**
 * @title Structures, methods and data are available to manage the staker state.
 */
library Stakes {
    using SafeMath for uint256;
    using Stakes for Stakes.Staker;

    struct Staker {
        uint256 tokensStaked; // Tokens staked by the Staker
        uint256 tokensAllocated; // Tokens allocated for jobs
        uint256 tokensLocked; // Tokens locked for withdrawal
        uint256 tokensLockedUntil; // Tokens locked until time
    }

    /**
     * @dev Deposit tokens to the staker stake.
     * @param stake Staker struct
     * @param _tokens Amount of tokens to deposit
     */
    function deposit(Stakes.Staker storage stake, uint256 _tokens) internal {
        stake.tokensStaked = stake.tokensStaked.add(_tokens);
    }

    /**
     * @dev Release tokens from the staker stake.
     * @param stake Staker struct
     * @param _tokens Amount of tokens to release
     */
    function release(Stakes.Staker storage stake, uint256 _tokens) internal {
        stake.tokensStaked = stake.tokensStaked.sub(_tokens);
    }

    /**
     * @dev Add tokens from the main stack to tokensAllocated.
     * @param stake Staker struct
     * @param _tokens Amount of tokens to allocate
     */
    function allocate(Stakes.Staker storage stake, uint256 _tokens) internal {
        stake.tokensAllocated = stake.tokensAllocated.add(_tokens);
    }

    /**
     * @dev Unallocate tokens from a escrowAddress back to the main stack.
     * @param stake Staker struct
     * @param _tokens Amount of tokens to unallocate
     */
    function unallocate(Stakes.Staker storage stake, uint256 _tokens) internal {
        stake.tokensAllocated = stake.tokensAllocated.sub(_tokens);
    }

    /**
     * @dev Lock tokens until a lock period pass.
     * @param stake Staker struct
     * @param _tokens Amount of tokens to unstake
     * @param _period Period in blocks that need to pass before withdrawal
     */
    function lockTokens(
        Stakes.Staker storage stake,
        uint256 _tokens,
        uint256 _period
    ) internal {
        uint256 lockingPeriod = _period;

        if (stake.tokensLocked > 0) {
            lockingPeriod = Math.weightedAverage(
                Math.diffOrZero(stake.tokensLockedUntil, block.number), // Remaining lock period
                stake.tokensLocked,
                _period,
                _tokens
            );
        }

        stake.tokensLocked = stake.tokensLocked.add(_tokens);
        stake.tokensLockedUntil = block.number.add(lockingPeriod);
    }

    /**
     * @dev Unlock tokens.
     * @param stake Staker struct
     * @param _tokens Amount of tokens to unkock
     */
    function unlockTokens(
        Stakes.Staker storage stake,
        uint256 _tokens
    ) internal {
        stake.tokensLocked = stake.tokensLocked.sub(_tokens);
        if (stake.tokensLocked == 0) {
            stake.tokensLockedUntil = 0;
        }
    }

    /**
     * @dev Return all tokens available for withdrawal.
     * @param stake Staker struct
     * @return Amount of tokens available for withdrawal
     */
    function withdrawTokens(
        Stakes.Staker storage stake
    ) internal returns (uint256) {
        uint256 tokensToWithdraw = stake.tokensWithdrawable();

        if (tokensToWithdraw > 0) {
            stake.unlockTokens(tokensToWithdraw);
            stake.release(tokensToWithdraw);
        }

        return tokensToWithdraw;
    }

    /**
     * @dev Return all tokens available in stake.
     * @param stake Staker struct
     * @return Token amount
     */
    function tokensAvailable(
        Stakes.Staker memory stake
    ) internal pure returns (uint256) {
        return stake.tokensStaked.sub(stake.tokensUsed());
    }

    /**
     * @dev Return all tokens used in allocations and locked for withdrawal.
     * @param stake Staker struct
     * @return Token amount
     */
    function tokensUsed(
        Stakes.Staker memory stake
    ) internal pure returns (uint256) {
        return stake.tokensAllocated.add(stake.tokensLocked);
    }

    /**
     * @dev Return the amount of tokens staked which are not locked.
     * @param stake Staker struct
     * @return Token amount
     */
    function tokensSecureStake(
        Stakes.Staker memory stake
    ) internal pure returns (uint256) {
        return stake.tokensStaked.sub(stake.tokensLocked);
    }

    /**
     * @dev Tokens available for withdrawal after lock period.
     * @param stake Staker struct
     * @return Token amount
     */
    function tokensWithdrawable(
        Stakes.Staker memory stake
    ) internal view returns (uint256) {
        if (
            stake.tokensLockedUntil == 0 ||
            block.number < stake.tokensLockedUntil
        ) {
            return 0;
        }
        return stake.tokensLocked;
    }
}