// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ILpLocker {
    function totalSupply() external view returns (uint256);

    function balanceOf(address _user) external view returns (uint256);

    function lock(
        address _user,
        uint256 _amount,
        uint256 _weeks
    ) external;

    function unlock(uint256 _slot) external;

    event Locked(address indexed _user, uint256 _amount, uint256 _weeks);

    event Unlocked(
        address indexed _user,
        uint256 _unlockTime,
        uint256 _amount,
        uint256 _vlQuoAmount
    );

    event RewardAdded(uint256 _reward);

    event RewardPaid(address indexed _user, uint256 _reward);
}