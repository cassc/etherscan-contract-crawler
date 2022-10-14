// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IStructs.sol";

interface ICommunityStakingPoolFactory {
    
    
    struct InstanceInfo {
        address reserveToken;
        uint64 duration;
        uint64 bonusTokenFraction;
        address tradedToken;
        uint64 lpFraction;
        address lpFractionBeneficiary;
        uint64 rewardsRateFraction;
        uint64 numerator;
        uint64 denominator;
        bool exists;
        uint8 instanceType;
        address tokenErc20;
    }

    event InstanceCreated(address indexed tokenA, address indexed tokenB, address instance, uint instancesCount, address indexed erc20);

    function initialize(address impl, address implErc20) external;
    function getInstance(address reserveToken, address tradedToken, uint256 lockupIntervalCount) external view returns (address instance);
    function getInstanceErc20(address tokenErc20, uint256 lockupIntervalCount) external view returns (address instance);
    function instancesByIndex(uint index) external view returns (address instance);
    function instances() external view returns (address[] memory instances);
    function instancesCount() external view returns (uint);
    function produce(address reserveToken, address tradedToken, uint64 duration, uint64 bonusTokenFraction, IStructs.StructAddrUint256[] memory donations, uint64 lpFraction, address lpFractionBeneficiary, uint64 rewardsRateFraction, uint64 numerator, uint64 denominator) external returns (address instance);
    function produceErc20(address tokenErc20, uint64 duration, uint64 bonusTokenFraction, IStructs.StructAddrUint256[] memory donations, uint64 lpFraction, address lpFractionBeneficiary, uint64 rewardsRateFraction, uint64 numerator, uint64 denominator) external returns (address instance);
    function getInstanceInfoByPoolAddress(address addr) external view returns(InstanceInfo memory);
    function amountAfterSwapLP(address[] memory instancesToRedeem, uint256[] memory valuesToRedeem, address[][] memory swapPaths) external view returns(address, uint256);
}