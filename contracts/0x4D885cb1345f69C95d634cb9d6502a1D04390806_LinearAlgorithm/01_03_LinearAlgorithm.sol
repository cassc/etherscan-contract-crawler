// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../libraries/FixedPointMathLib.sol";
import "../interfaces/IMetaAlgorithm.sol";

/// @title LinearAlgorithm Algorithm to calculate trade prices
/// @author JorgeLpzGnz & CarlosMario714
/// @notice Algorithm to calculate the price adding the multiplier
contract LinearAlgorithm is IMetaAlgorithm {

    /*

      In the Linear Algorithm the price will increase adding or subtracting
      the multiplier

      buy price = start Price + multiplier

      sell price = star Price - multiplier

    */

    /// @notice See [ FixedPointMathLib ] for more info
    using FixedPointMathLib for uint256;

    /// @return name Name of the Algorithm 
    function name() external pure override returns( string memory ) {

        return "Linear";

    }

    /// @notice It validates the start price
    /// @dev In Linear algorithm all values are valid 
    function validateStartPrice( uint ) external pure override returns( bool ) {

        return true;

    }

    /// @notice It validates the multiplier
    /// @dev In Linear algorithm all values are valid 
    function validateMultiplier( uint ) external pure override returns( bool ) {

        return true;

    }

    /// @notice Returns the info to Buy NFTs in Linear market
    /// @param _multiplier Pool multiplier
    /// @param _startPrice Pool Start price
    /// @param _numItems Number of Items to buy
    /// @param _protocolFee Protocol fee multiplier 
    /// @param _poolFee Pool fee multiplier  
    /// @return isValid True if the trade can be done
    /// @return newStartPrice New Pool Start Price
    /// @return newMultiplier New Pool Multiplier
    /// @return inputValue Amount to send to the pool 
    /// @return protocolFee Fee charged for the trade 
    function getBuyInfo( uint128 _multiplier, uint128 _startPrice, uint _numItems, uint128 _protocolFee, uint128 _poolFee ) external pure override 
        returns ( 
            bool isValid, 
            uint128 newStartPrice, 
            uint128 newMultiplier, 
            uint256 inputValue, 
            uint256 protocolFee 
        ) {

        // num Items should be > 0

        if ( _numItems == 0 ) return (false, 0, 0, 0, 0);

        // set new Start Price

        uint _newStartPrice = _startPrice + ( _multiplier * _numItems );
        
        // handle possible overflow errors

        if( _newStartPrice > type( uint128 ).max ) return ( false, 0, 0, 0, 0);

        uint256 buyPrice = _startPrice + _multiplier;

        inputValue = 
            _numItems * buyPrice + ( _numItems * ( _numItems - 1 ) * _multiplier ) / 2;

        // calculate buy fees

        uint poolFee = inputValue.fmul( _poolFee, FixedPointMathLib.WAD);

        protocolFee = inputValue.fmul( _protocolFee, FixedPointMathLib.WAD);
        
        // adding fees

        inputValue += ( protocolFee + poolFee );

        newStartPrice = uint128(_newStartPrice);

        // keeps the multiplier the same

        newMultiplier = _multiplier;

        isValid = true;

    }

    /// @notice Returns the info to Sell NFTs in Linear market
    /// @param _multiplier Pool multiplier
    /// @param _startPrice Pool Start price
    /// @param _numItems Number of Items to buy
    /// @param _protocolFee Protocol fee multiplier 
    /// @param _poolFee Pool fee multiplier  
    /// @return isValid True if the trade can be done
    /// @return newStartPrice New Pool Start Price
    /// @return newMultiplier New Pool Multiplier
    /// @return outputValue Amount to send to the user
    /// @return protocolFee Fee charged for the trade 
    function getSellInfo( uint128 _multiplier, uint128 _startPrice, uint _numItems, uint128 _protocolFee, uint128 _poolFee ) external pure override
        returns ( 
            bool isValid, 
            uint128 newStartPrice, 
            uint128 newMultiplier, 
            uint256 outputValue, 
            uint256 protocolFee 
        ) {
            
        // num Items should be > 0

        if ( _numItems == 0 ) return (false, 0, 0, 0, 0);

        uint decrease = _multiplier * _numItems;

        // if the decrease is greater than the start price
        // it calculates the number than can be sold until
        // the price reaches zero

        if( _startPrice < decrease ){

            newStartPrice = 0;

            _numItems = _startPrice / _multiplier + 1;

        }

        else newStartPrice = _startPrice - uint128( decrease );

        outputValue = _numItems * _startPrice - ( _numItems * ( _numItems - 1 ) * _multiplier ) / 2;

        // calculate sell fees

        uint poolFee = outputValue.fmul( _poolFee, FixedPointMathLib.WAD);

        protocolFee = outputValue.fmul( _protocolFee, FixedPointMathLib.WAD);
        
        // adding fees

        outputValue -= ( protocolFee + poolFee );

        // keeps multiplier the same

        newMultiplier = _multiplier;

        isValid = true;

    }
    
}