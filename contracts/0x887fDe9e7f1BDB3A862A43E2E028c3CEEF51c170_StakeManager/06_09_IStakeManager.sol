pragma solidity 0.8.6;


import "IOracle.sol";


/**
* @title    StakeManager
* @notice   A lightweight Proof of Stake contract that allows
*           staking of AUTO tokens. Instead of a miner winning
*           the ability to produce a block, the algorithm selects
*           a staker for a period of 100 blocks to be the executor.
*           the executor has the exclusive right to execute requests
*           in the Registry contract. The Registry checks with StakeManager
*           who is allowed to execute requests at any given time
* @author   Quantaf1re (James Key)
*/
interface IStakeManager {

    struct Executor{
        address addr;
        uint96 forEpoch;
    }


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                          Getters                         //
    //                                                          //
    //////////////////////////////////////////////////////////////
    
    function getOracle() external view returns (IOracle);

    function getAUTOAddr() external view returns (address);

    function getTotalStaked() external view returns (uint);

    function getStake(address staker) external view returns (uint);

    /**
     * @notice  Returns the array of stakes. Every element in the array represents
     *          `STAN_STAKE` amount of AUTO tokens staked for that address. Addresses
     *          can be in the array arbitrarily many times
     */
    function getStakes() external view returns (address[] memory);

    /**
     * @notice  The length of `_stakes`, i.e. the total staked when multiplied by `STAN_STAKE`
     */
    function getStakesLength() external view returns (uint);

    /**
     * @notice  The same as getStakes except it returns only part of the array - the
     *          array might grow so large that retrieving it costs more gas than the
     *          block gas limit and therefore brick the contract. E.g. for an array of
     *          x = [4, 5, 6, 7], x[1, 2] returns [5], the same as lists in Python
     * @param startIdx  [uint] The starting index from which to start getting the slice (inclusive)
     * @param endIdx    [uint] The ending index from which to start getting the slice (exclusive)
     */
    function getStakesSlice(uint startIdx, uint endIdx) external view returns (address[] memory);

    /**
     * @notice  Returns the current epoch. Goes in increments of 100. E.g. the epoch
     *          for 420 is 400, and 42069 is 42000
     */
    function getCurEpoch() external view returns (uint96);

    /**
     * @notice  Returns the currently stored Executor - which might be old,
     *          i.e. for a previous epoch
     */
    function getExecutor() external view returns (Executor memory);

    /**
     * @notice  Returns whether `addr` is the current executor for this epoch. If the executor
     *          is outdated (i.e. for a previous epoch), it'll return false regardless of `addr`
     * @param addr  [address] The address to check
     * @return  [bool] Whether or not `addr` is the current executor for this epoch
     */
    function isCurExec(address addr) external view returns (bool);

    /**
     * @notice  Returns what the result of updating the executor would be, but doesn't actually
     *          make any changes
     * @return epoch    Returns the relevant variables for determining the new executor if the executor
     *          can be updated currently. It can only be updated currently if the stored executor
     *          is for a previous epoch, and there is some stake in the system. If the executor
     *          can't be updated currently, then everything execpt `epoch` will return 0
     */
    function getUpdatedExecRes() external view returns (uint96 epoch, uint randNum, uint idxOfExecutor, address exec);

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                          Staking                         //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice  Updates the executor. Calls `getUpdatedExecRes` to know. Makes the changes
     *          only if the executor can be updated
     * @return  Returns the relevant variables for determining the new executor if the executor
     *          can be updated currently
     */
    function updateExecutor() external returns (uint, uint, uint, address);

    /**
     * @notice  Checks if the stored executor is for the current epoch - if it is,
     *          then it returns whether `addr` is the current exec or not. If the epoch
     *          is old, then it updates the executor, then returns whether `addr` is the
     *          current executor or not. If there's no stake in the system, returns true
     * @param addr  [address] The address to check
     * @return  [bool] Returns whether or not `addr` is the current, updated executor
     */
    function isUpdatedExec(address addr) external returns (bool);

    /**
     * @notice  Stake a set amount of AUTO tokens. A set amount of tokens needs to be used
     *          so that a random number can be used to look up a specific index in the array.
     *          We want the staker to be chosen proportional to their stake, which requires
     *          knowing their stake in relation to everyone else. If you could stake any
     *          amount of AUTO tokens, then the contract would have to store that amount
     *          along with the staker and, crucially, would require iteration over the
     *          whole array. E.g. if the random number in this PoS system was 0.2, then
     *          you could calculate the amount of proportional stake that translates to.
     *          If the total stakes was 10^6, then whichever staker in the array at token
     *          position 200,000 would be the winner, but that requires going through every
     *          piece of staking info in the first part of the array in order to calculate
     *          the running cumulative and know who happens to have the slot where the
     *          cumulative stake is 200,000. This has problems when the staking array is
     *          so large that it costs more than the block gas limit to iterate over, which
     *          would brick the contract, but also just generally costs alot of gas. Having
     *          a set amount of AUTO tokens means you already know everything about every
     *          element in the array therefore don't need to iterate over it.
     *          Calling this will add the caller to the array. Calling this will first try
     *          and set the executor so that the caller can't precalculate and affect the outcome
     *          by deciding the size of `numStakes`
     * @param numStakes  [uint] The number of `STAN_STAKE` to stake and therefore how many
     *          slots in the array to add the user to
     */
    function stake(uint numStakes) external;

    /**
     * @notice  Unstake AUTO tokens. Calling this will first try and set the executor so that
     *          the caller can't precalculate and affect the outcome by deciding the size of
     *          `numStakes`
     * @dev     Instead of just deleting the array slot, this takes the last element, copies
     *          it to the slot being unstaked, and pops off the original copy of the replacement
     *          from the end of the array, so that there are no gaps left, such that 0x00...00
     *          can never be chosen as an executor
     * @param idxs  [uint[]] The indices of the user's slots, in order of which they'll be
     *              removed, which is not necessariy the current indices. E.g. if the `_staking`
     *              array is [a, b, c, b], and `idxs` = [1, 3], then i=1 will first get
     *              replaced by i=3 and look like [a, b, c], then it would try and replace i=3
     *              by the end of the array...but i=3 no longer exists, so it'll revert. In this
     *              case, `idxs` would need to be [1, 1], which would result in [a, c]. It's
     *              recommended to choose idxs in descending order so that you don't have to
     *              take account of this behaviour - that way you can just use indexes
     *              as they are already without alterations
     */
    function unstake(uint[] calldata idxs) external;
}