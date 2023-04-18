// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]

    maintainers:
    - [email protected]
    - [email protected]
    - [email protected]
    - [email protected]

    contributors:
    - [email protected]

**************************************/

/**************************************

    Staking interface

 **************************************/

abstract contract IStaking {

    // -----------------------------------------------------------------------
    //                              Structs
    // -----------------------------------------------------------------------
    
    /**************************************

        Compounding struct

        ------------------------------

        @param rate Q64.64 compounding index
        @param dapy current value of deflationary APY
        @param extraRate byte encoded index for staking extensions
        @param ts timestamp of last compounding
        @param freeRewards last snapshot of free rewards

     **************************************/

    struct Compounding {
        int128 rate;
        int128 dapy;
        bytes32 extraRate;
        uint128 ts;
        uint96 freeRewards;
    }

    /**************************************

        Balance struct

        ------------------------------

        @param amount deposited erc20 and is constantly increased by yield during compounding
        @param compoundingSnapshot value of compounding rate at given time
        @param extraSnapshot value of extra rewards rate at given time

     **************************************/

    struct Balance {
        uint96 amount; // @dev 2**96 > total supply of $THOL
        int128 compoundingSnapshot;
        bytes32 extraSnapshot;
    }

    // -----------------------------------------------------------------------
    //                              Events
    // -----------------------------------------------------------------------

    event Deposit(
        address indexed sender,
        uint96 amount,
        bytes extraAmount,
        uint96 rewards
    );
    event Withdrawal(
        address indexed sender,
        uint96 amount,
        bytes extraAmount,
        uint96 rewards
    );
    event Compounded(
        Compounding compounding
    );

    // -----------------------------------------------------------------------
    //                              Errors
    // -----------------------------------------------------------------------

    error UninitializedRewardPool();
    error CompoundingNotReady(uint256 required, uint128 now);
    error NoMoreRewardsLeft();
    error InsufficientRewards(uint96 compoundRewards, uint96 freeRewards);

    // -----------------------------------------------------------------------
    //                              External
    // -----------------------------------------------------------------------

    /**************************************

        Deposit sender funds

    **************************************/

    function deposit(uint96 _amount, bytes memory _extraAmount) external virtual;

    /**************************************

        Withdraw sender funds

    **************************************/

    function withdraw(uint96 _amount, bytes memory _extraAmount) external virtual;

    /**************************************

        Compound

    **************************************/

    function compound() external virtual;

    /**************************************

        View functions

    **************************************/

    // Get total available balance
    function balanceOf(address _account) external virtual view returns (uint96);

    // -----------------------------------------------------------------------
    //                              Public
    // -----------------------------------------------------------------------

    /**************************************

        View functions

    **************************************/

    // Get free rewards
    function freeRewards() public virtual view returns (uint96);

    // Get compounded base rewards
    function userBaseRewards(address _account) public virtual view returns (uint96);

    // Get compounded extra rewards
    function userExtraRewards(address _account) public virtual view returns (uint96);

    // Get total amount from rewards
    function rewardOf(address _account) public virtual view returns (uint96);

    // -----------------------------------------------------------------------
    //                              Internal
    // -----------------------------------------------------------------------

    /**************************************

        Abstract functions: core

    **************************************/

    // Deposit
    function _deposit(uint96 _amount, bytes memory _extraAmount) internal virtual;

    // Withdraw
    function _withdraw(uint96 _amount, bytes memory _extraAmount) internal virtual;

    // Check balance
    function _checkBalance(uint96 _amount, bytes memory _extraAmount) internal virtual;

    // Increase balance
    function _increaseBalance(uint96 _amount, bytes memory _extraAmount) internal virtual;

    // Decrease balance
    function _decreaseBalance(uint96 _amount, bytes memory _extraAmount) internal virtual;

    /**************************************

        Abstract functions: rewards

    **************************************/

    // Reward pool withdraw
    function _rewardPoolWithdraw(address _receiver, uint256 _amount) internal virtual;
    
    // Reward pool info
    function _rewardPoolInfo() internal virtual view returns (uint96);

    /**************************************

        Abstract functions: extra

    **************************************/

    // Get compounded extra rewards
    function _userExtraRewards(address _account) internal virtual view
    returns (uint96);

    // Get total available extra
    function _getExtraSum() internal virtual view returns (uint96);

    // Calculate extra rewards and extra ratio for sum
    function _calculateExtraRewards(uint96 _extraSum, int128 _ipy) internal virtual view
    returns (uint96, bytes32);

    // Increment rate
    function _incrementExtraRate(bytes32 _existingRate, bytes32 _incrementRate) internal virtual pure
    returns (bytes32);

}