// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IIncentivesStash {
    function addReward(
        address _gauge,
        address _token,
        uint256 _amount,
        uint256 _pricePerToken
    ) external returns (bool);
}