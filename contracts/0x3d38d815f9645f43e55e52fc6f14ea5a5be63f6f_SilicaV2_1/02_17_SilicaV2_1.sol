// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {AbstractSilicaV2_1} from "./AbstractSilicaV2_1.sol";

import "./interfaces/oracle/IOracle.sol";
import "./interfaces/oracle/IOracleRegistry.sol";
import "./libraries/math/RewardMath.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SilicaV2_1 is AbstractSilicaV2_1 {
    uint8 internal constant COMMODITY_TYPE = 0;

    function decimals() public pure override returns (uint8) {
        return 15;
    }

    constructor() ERC20("Silica", "SLC") {}

    /// @notice Function to return the last day silica is synced with Oracle
    function getLastIndexedDay() internal view override returns (uint32) {
        IOracle oracle = IOracle(IOracleRegistry(oracleRegistry).getOracleAddress(address(rewardToken), COMMODITY_TYPE));
        uint32 lastIndexedDayMem = oracle.getLastIndexedDay();
        require(lastIndexedDayMem != 0, "Invalid State");

        return lastIndexedDayMem;
    }

    /// @notice Function to return the amount of rewards due by the seller to the contract on day inputed
    function getRewardDueOnDay(uint256 _day) internal view override returns (uint256) {
        IOracle oracle = IOracle(IOracleRegistry(oracleRegistry).getOracleAddress(address(rewardToken), COMMODITY_TYPE));
        (, , uint256 networkHashrate, uint256 networkReward, , , ) = oracle.get(_day);

        return RewardMath.getMiningRewardDue(totalSupply(), networkReward, networkHashrate);
    }

    /// @notice Function to return an array with the amount of rewards due by the seller to the contract on days in range inputed
    function getRewardDueInRange(uint256 _firstDay, uint256 _lastDay) internal view override returns (uint256[] memory) {
        IOracle oracle = IOracle(IOracleRegistry(oracleRegistry).getOracleAddress(address(rewardToken), COMMODITY_TYPE));
        (uint256[] memory hashrateArray, uint256[] memory rewardArray) = oracle.getInRange(_firstDay, _lastDay);

        uint256[] memory rewardDueArray = new uint256[](hashrateArray.length);

        uint256 totalSupplyCopy = totalSupply();
        for (uint256 i = 0; i < hashrateArray.length; i++) {
            rewardDueArray[i] = RewardMath.getMiningRewardDue(totalSupplyCopy, rewardArray[i], hashrateArray[i]);
        }

        return rewardDueArray;
    }

    /// @notice Returns the commodity type the seller is selling with this contract
    /// @return The commodity type the seller is selling with this contract
    function getCommodityType() external pure override returns (uint8) {
        return COMMODITY_TYPE;
    }

    /// @notice Returns decimals of the contract
    function getDecimals() external pure override returns (uint8) {
        return decimals();
    }
}