// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ITRYPToken {
    function updateReward(address _from, address _to, uint256 _tokenId) external;
    function claimReward(address _to) external;
    function burn(address _from, uint256 _amount) external;
}