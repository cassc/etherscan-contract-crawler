/**
     _    _ _    _           _             
    / \  | | | _(_)_ __ ___ (_)_   _  __ _ 
   / _ \ | | |/ / | '_ ` _ \| | | | |/ _` |
  / ___ \| |  <|  | | | | | | | |_| | (_| |
 /_/   \_\_|_|\_\_|_| |_| |_|_|\__, |\__,_|
                               |___/        
**/
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title  Alkimiya Oracle
 * @author Alkimiya Team
 * @notice Main interface for Reward Token Oracle contracts
 */
interface IOracle {
    
    event OracleUpdate(
        address indexed caller,
        uint256 indexed referenceDay,
        uint256 indexed referenceBlock,
        uint256 hashrate,
        uint256 reward,
        uint256 fees,
        uint256 difficulty,
        uint256 timestamp
    );

    /**
     * @notice Function to return the AlkimiyaIndex on a given day
     * @dev Timestamp must be non-zero indicating that there is an entry to read 
     * @param _referenceDay The day whose index is to be returned 
     * */
    function get(uint256 _referenceDay)
        external
        view
        returns (
            uint256 date,
            uint256 referenceBlock,
            uint256 hashrate,
            uint256 reward,
            uint256 fees,
            uint256 difficulty,
            uint256 timestamp
        );

    /**
     * @notice Function to return array of oracle data between firstday and lastday (inclusive)
     * @dev The days passed in are inclusive values
     * @param _firstDay The starting day whose index is to be returned 
     * @param _lastDay The final day whose index is to be returned 
     * */
    function getInRange(uint256 _firstDay, uint256 _lastDay)
        external
        view
        returns (uint256[] memory hashrateArray, uint256[] memory rewardArray);

    /**
     * @notice Function to check if Oracle has been updated on a given day
     * @dev Days for which function calls return true have an AlkimiyaIndex entry
     * @param _referenceDay The day to check that the Oracle has an entry for
     */
    function isDayIndexed(uint256 _referenceDay) external view returns (bool);

    /**
     * @notice Return the last day on which the Oracle was updated
     */
    function getLastIndexedDay() external view returns (uint32);

    /**
     * @notice Function to update Oracle Index
     * @dev Creates new instance of AlkimiyaIndex corresponding to _referenceDay in index mapping
     * @param _referenceDay The day to create AlkimiyaIndex entry for
     * @param _referenceBlock The block to be referenced
     * @param _hashrate The hashrate of the given day
     * @param _reward The staking reward on the given day
     * @param _fees The fees on given day
     * @param _difficulty The block difficulty on the given day
     * @param signature The signature of the Oracle calculator
     * */
    function updateIndex(
        uint256 _referenceDay,
        uint256 _referenceBlock,
        uint256 _hashrate,
        uint256 _reward,
        uint256 _fees,
        uint256 _difficulty,
        bytes memory signature
    ) external returns (bool success);
}