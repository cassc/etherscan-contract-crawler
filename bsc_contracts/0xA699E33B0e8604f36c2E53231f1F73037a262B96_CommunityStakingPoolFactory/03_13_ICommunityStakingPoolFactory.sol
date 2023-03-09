// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IStructs.sol";

interface ICommunityStakingPoolFactory {
    
    
    struct InstanceInfo {
        address tokenErc20;
        uint64 duration;
        bool exists;
        uint64 bonusTokenFraction;
        address popularToken;
        uint64 rewardsRateFraction;
        uint64 numerator;
        uint64 denominator;
    }

    event InstanceCreated(address indexed erc20, address instance, uint instancesCount);

    function initialize(address impl) external;
    function getInstance(address tokenErc20, uint256 lockupIntervalCount) external view returns (address instance);
    function instancesByIndex(uint index) external view returns (address instance);
    function instances() external view returns (address[] memory instances);
    function instancesCount() external view returns (uint);
    function produce(address tokenErc20, uint64 duration, uint64 bonusTokenFraction, address popularToken, IStructs.StructAddrUint256[] memory donations, uint64 rewardsRateFraction, uint64 numerator, uint64 denominator) external returns (address instance);
    function getInstanceInfoByPoolAddress(address addr) external view returns(InstanceInfo memory);

}