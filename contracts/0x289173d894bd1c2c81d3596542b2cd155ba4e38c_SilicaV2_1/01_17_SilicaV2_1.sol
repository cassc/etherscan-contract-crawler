/**
     _    _ _    _           _             
    / \  | | | _(_)_ __ ___ (_)_   _  __ _ 
   / _ \ | | |/ / | '_ ` _ \| | | | |/ _` |
  / ___ \| |   <| | | | | | | | |_| | (_| |
 /_/   \_\_|_|\_\_|_| |_| |_|_|\__, |\__,_|
                               |___/        
 * */
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {AbstractSilicaV2_1} from "./AbstractSilicaV2_1.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/oracle/IOracle.sol";
import "./interfaces/oracle/IOracleRegistry.sol";
import "./libraries/math/RewardMath.sol";

contract SilicaV2_1 is AbstractSilicaV2_1 {

    /*///////////////////////////////////////////////////////////////
                                Constants
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant COMMODITY_TYPE = 0; // Consensus commodity type being sold

    /*///////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////*/

    constructor() ERC20("Silica", "SLC") {}

    /*///////////////////////////////////////////////////////////////
                                Getters
    //////////////////////////////////////////////////////////////*/

    function decimals() public pure override returns (uint8) {
        return 15;
    }

    /// @notice Returns the commodity type the seller is selling with this contract
    /// @return The commodity type the seller is selling with this contract
    function getCommodityType() external pure override returns (uint256) {
        return COMMODITY_TYPE;
    }

    /// @notice Returns decimals of the Silica contract
    function getDecimals() external pure override returns (uint8) {
        return decimals();
    }

    /// @notice Function to return the last day Silica was synced with Oracle
    /// @return uint32: Last day silica was synced with Oracle
    function _getLastIndexedDay() internal view override returns (uint32) {
        IOracle oracle = IOracle(IOracleRegistry(oracleRegistry).getOracleAddress(address(rewardToken), COMMODITY_TYPE));
        uint32 lastIndexedDayMem = oracle.getLastIndexedDay();
        require(lastIndexedDayMem != 0, "Invalid State");

        return lastIndexedDayMem;
    }

    /// @notice Function to return the amount of rewards due by the seller to the contract on day inputed
    /// @param _day The day to query the reward due on
    /// @return uint256: The reward due
    function _getRewardDueOnDay(uint256 _day) internal view override returns (uint256) {
        IOracle oracle = IOracle(IOracleRegistry(oracleRegistry).getOracleAddress(address(rewardToken), COMMODITY_TYPE));
        (, , uint256 networkHashrate, uint256 networkReward, , , ) = oracle.get(_day);

        return RewardMath._getMiningRewardDue(totalSupply(), networkReward, networkHashrate);
    }

    /// @notice Function to return total rewards due between _firstday (inclusive) and _lastday (inclusive)
    /// @dev    This function is to be overridden by derived Silica contracts
    /// @param _firstDay The start day to query from
    /// @param _lastDay The end day to query until 
    function _getRewardDueInRange(uint256 _firstDay, uint256 _lastDay) internal view override returns (uint256[] memory) {
        IOracle oracle = IOracle(IOracleRegistry(oracleRegistry).getOracleAddress(address(rewardToken), COMMODITY_TYPE));
        (uint256[] memory hashrateArray, uint256[] memory rewardArray) = oracle.getInRange(_firstDay, _lastDay);

        uint256[] memory rewardDueArray = new uint256[](hashrateArray.length);

        uint256 totalSupplyCopy = totalSupply();
        for (uint256 i; i < hashrateArray.length; ) {
            rewardDueArray[i] = RewardMath._getMiningRewardDue(totalSupplyCopy, rewardArray[i], hashrateArray[i]);
            unchecked {
                ++i;
            }
        }

        return rewardDueArray;
    }
}