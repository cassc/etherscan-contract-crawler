// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IBribeFull {

    function _deposit(uint amount, uint tokenId) external;
    function _withdraw(uint amount, uint tokenId) external;
    function getRewardForOwner(uint tokenId, address[] memory tokens) external;
    function notifyRewardAmount(address token, uint amount) external;
    function left(address token) external view returns (uint);
    function rewardsListLength() external view returns (uint);
    function supplyNumCheckpoints() external view returns (uint);
    function getEpochStart(uint timestamp) external pure returns (uint);
    function getPriorSupplyIndex(uint timestamp) external view returns (uint);
    function rewards(uint index) external view returns (address);
    function tokenRewardsPerEpoch(address token,uint ts) external view returns (uint);
    function supplyCheckpoints(uint _index) external view returns(uint timestamp, uint supplyd);
    function earned(address token, uint tokenId) external view returns (uint);

}