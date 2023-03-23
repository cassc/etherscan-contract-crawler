pragma solidity 0.8.17;
// SPDX-License-Identifier: MIT

interface ISpotV1 {

    struct Swap {
        address[] path;
        uint outMin;
    }
    
    function init(
        address _wrapper,
        address _pool,
        address _router,
        address _stakingToken,
        address _rewardToken,
        uint _poolIndex,
        uint _ownerId,
        address _registry,
        address factory
    ) external;

    function deposit(
        uint amount,
        Swap memory swap0,
        Swap memory swap1,
        Swap memory swapReward0,
        Swap memory swapReward1,
        uint deadline
    ) external payable;

    function withdraw(
        uint amountToBurn,
        Swap memory swap0,
        Swap memory swap1,
        Swap memory swapReward0,
        Swap memory swapReward1,
        uint deadline
    ) external;

    function restake(
        Swap memory swapReward0,
        Swap memory swapReward1,
        uint deadline
    ) external;
    
}