// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../libraries/FixedPointMathLib.sol";
import "../interfaces/IMetaAlgorithm.sol";

/// @title ExponentialAlgorithm Algorithm to calculate trade prices
/// @author JorgeLpzGnz & CarlosMario714
/// @notice Algorithm to calculate the price exponentially
contract ExponentialAlgorithm is IMetaAlgorithm {

    /*

      In the Exponential Algorithm the Start Price will be multiplied 
      or Divided by the multiplier to calculate the trade price

    */

    /// @notice See [ FixedPointMathLib ] for more info
    using FixedPointMathLib for uint256;

    /// @notice the minimum start price
    uint32 public constant MIN_PRICE = 1 gwei; 

    /// @notice the minimum multiplier
    uint public constant MIN_MULTIPLIER = 1e18; 

    /// @return name Name of the Algorithm 
    function name() external pure override returns( string memory ) {

        return "Exponential";

    }

    /// @notice It validates the start price
    /// @dev The start price have to be grater than 1 gwei
    /// this to handel possible dividing errors
    function validateStartPrice( uint _startPrice ) external pure override returns( bool ) {

        return _startPrice >= MIN_PRICE;

    }

    /// @notice It validates the multiplier
    /// @dev The multiplier should be greater than 1e18 that
    function validateMultiplier( uint _multiplier ) external pure override returns( bool ) {

        return _multiplier > MIN_MULTIPLIER;

    }

    /// @notice Returns the info to Buy NFTs in a Exponential market
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
        ) 
    {
        
        // num Items should be > 0

        if( _numItems == 0 ) return (false, 0, 0, 0, 0);

        // multiplierPow = multiplier ^ number of items

        uint multiplierPow = uint( _multiplier ).fpow( _numItems, FixedPointMathLib.WAD );

        uint _newStartPrice = uint( _startPrice ).fmul( multiplierPow, FixedPointMathLib.WAD);
        
        // handle possible overflow errors

        if( _newStartPrice > type( uint128 ).max ) return ( false, 0, 0, 0, 0);

        newStartPrice = uint128( _newStartPrice );

        // buy price = startPrice * multiplier

        uint buyPrice = uint( _startPrice ).fmul( _multiplier, FixedPointMathLib.WAD );

        // inputValue = buyPrice * ( multiplierPow - 1) / ( multiplier - 1)

        inputValue = buyPrice.fmul( 
            ( multiplierPow - FixedPointMathLib.WAD ).fdiv( 
                _multiplier - FixedPointMathLib.WAD, FixedPointMathLib.WAD
            ), FixedPointMathLib.WAD);

        uint poolFee = inputValue.fmul( _poolFee, FixedPointMathLib.WAD );

        protocolFee = inputValue.fmul( _protocolFee, FixedPointMathLib.WAD );

        // adding fees

        inputValue += ( protocolFee + poolFee );

        // update start price

        newStartPrice = uint128( _newStartPrice );

        // keep multiplier the same

        newMultiplier = _multiplier;

        isValid = true;

    }

    function getSellInfo( uint128 _multiplier, uint128 _startPrice, uint _numItems, uint128 _protocolFee, uint128 _poolFee ) external pure override 
        returns ( 
            bool isValid, 
            uint128 newStartPrice, 
            uint128 newMultiplier, 
            uint256 outputValue, 
            uint256 protocolFee 
        ) 
    {
        
        // num Items should be > 0

        if( _numItems == 0 ) return (false, 0, 0, 0, 0);

        uint invMultiplier = FixedPointMathLib.WAD.fdiv( _multiplier, FixedPointMathLib.WAD );

        // invMultiplierPow = ( 1 / multiplier ) ^ number of items

        uint invMultiplierPow = invMultiplier.fpow( _numItems, FixedPointMathLib.WAD );

        // update start price

        newStartPrice = uint128(
            uint256( _startPrice ).fmul( invMultiplierPow, FixedPointMathLib.WAD )
        );

        // newStartPrice should be > 1 gwei ( 1e9 )

        if( newStartPrice < MIN_PRICE ) newStartPrice = MIN_PRICE;

        // outputValue = spotPrice * ( 1 - invMultiplierPow ) / ( 1 - invMultiplier )

        outputValue = uint256( _startPrice ).fmul(
            ( FixedPointMathLib.WAD - invMultiplierPow ).fdiv(
                FixedPointMathLib.WAD - invMultiplier,
                FixedPointMathLib.WAD
            ),
            FixedPointMathLib.WAD
        );

        uint poolFee = outputValue.fmul( _poolFee, FixedPointMathLib.WAD );

        protocolFee = outputValue.fmul( _protocolFee, FixedPointMathLib.WAD );

        // adding fees

        outputValue -= ( protocolFee + poolFee );

        // keeps multiplier the same

        newMultiplier = _multiplier;

        isValid = true;
        
    }
    
}