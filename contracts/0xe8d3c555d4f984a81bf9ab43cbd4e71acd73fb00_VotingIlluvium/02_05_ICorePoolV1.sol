// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

struct V1Stake {
    // @dev token amount staked
    uint256 tokenAmount;
    // @dev stake weight
    uint256 weight;
    // @dev locking period - from
    uint64 lockedFrom;
    // @dev locking period - until
    uint64 lockedUntil;
    // @dev indicates if the stake was created as a yield reward
    bool isYield;
}

struct V1User {
    // @dev Total staked amount
    uint256 tokenAmount;
    // @dev Total weight
    uint256 totalWeight;
    // @dev Auxiliary variable for yield calculation
    uint256 subYieldRewards;
    // @dev Auxiliary variable for vault rewards calculation
    uint256 subVaultRewards;
    // @dev An array of holder's deposits
    V1Stake[] deposits;
}

interface ICorePoolV1 {
    function users(address _who) external view returns (V1User memory);

    function balanceOf(address _user) external view returns (uint256);

    function getDeposit(address _from, uint256 _stakeId)
        external
        view
        returns (V1Stake memory);

    function poolToken() external view returns (address);

    function usersLockingWeight() external view returns (uint256);

    function poolTokenReserve() external view returns (uint256);
}