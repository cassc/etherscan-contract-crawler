// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.9;

/// @title IMetaAlgorithm a interface to call algorithms contracts
/// @author JorgeLpzGnz & CarlosMario714
/// @dev the algorithm is responsible for calculating the prices see
interface IMetaAlgorithm {

    /// @dev See each algorithm to see how this values are calculated

    /// @notice it returns the name of the Algorithm
    function name() external pure returns( string memory );

    /// @notice it checks if the start price is valid 
    function validateStartPrice( uint _startPrice ) external pure returns( bool );

    /// @notice it checks if the multiplier is valid 
    function validateMultiplier( uint _multiplier ) external pure returns( bool );

    /// @notice Return the necessary information to sell NFTs
    /// @param _multiplier Current multiplier used to calculate the price
    /// @param _startPrice Current start price used to calculate the price
    /// @param _numItems Number of NFTs to trade
    /// @param _protocolFee Fee multiplier to calculate the protocol fee
    /// @param _poolFee Fee multiplier to calculate the pool fee
    /// @return isValid True if trade can be performed
    /// @return newStartPrice New start price used to calculate the price
    /// @return newMultiplier New multiplier used to calculate the price
    /// @return inputValue Amount to send to the pool
    /// @return protocolFee Amount to charged for the trade
    function getBuyInfo( uint128 _multiplier, uint128 _startPrice, uint _numItems, uint128 _protocolFee, uint128 _poolFee ) external pure 
        returns ( 
            bool isValid, 
            uint128 newStartPrice, 
            uint128 newMultiplier, 
            uint256 inputValue, 
            uint256 protocolFee 
        );

    /// @notice Return the necessary information to sell NFTs
    /// @param _multiplier Current multiplier used to calculate the price
    /// @param _startPrice Current start price used to calculate the price
    /// @param _numItems Number of NFTs to trade
    /// @param _protocolFee Fee multiplier to calculate the protocol fee
    /// @param _poolFee Fee multiplier to calculate the pool fee
    /// @return isValid True if trade can be performed
    /// @return newStartPrice New start price used to calculate the price
    /// @return newMultiplier New multiplier used to calculate the price
    /// @return outputValue Amount to send to the user
    /// @return protocolFee Amount to charged for the trade
    function getSellInfo( uint128 _multiplier, uint128 _startPrice, uint _numItems, uint128 _protocolFee, uint128 _poolFee ) external pure
        returns ( 
            bool isValid, 
            uint128 newStartPrice, 
            uint128 newMultiplier, 
            uint256 outputValue, 
            uint256 protocolFee 
        );

}