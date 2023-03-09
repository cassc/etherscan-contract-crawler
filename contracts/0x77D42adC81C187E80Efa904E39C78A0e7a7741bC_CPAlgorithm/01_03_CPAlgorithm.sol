// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../libraries/FixedPointMathLib.sol";
import "../interfaces/IMetaAlgorithm.sol";

/// @title CPAlgorithm Algorithm to calculate trade prices
/// @author JorgeLpzGnz & CarlosMario714
/// @notice This Algorithm a Constant product Based on ( XY = K )
contract CPAlgorithm is IMetaAlgorithm {

    /*

      In the Constant Product Market Algorithm it needs the balances
      of two tokens to calculate the trade prices, is the formula XY = K
      in this protocol, X = balance of token 1, Y = balance of token 2,
      so in this algorithm those values are: 
      
      tokenBalance = startPrice;
      nftBalance = multiplier;

    */

    /// @notice See [ FixedPointMathLib ] for more info
    using FixedPointMathLib for uint256;

    /// @return name Name of the Algorithm 
    function name() external pure override returns( string memory ) {

        return "Constant Product";

    }

    /// @notice It validates the start price
    /// @dev In CP algorithm all values are valid 
    function validateStartPrice( uint ) external pure override returns( bool ) {

        return true;

    }

    /// @notice It validates the multiplier
    /// @dev In CP algorithm all values are valid 
    function validateMultiplier( uint ) external pure override returns( bool ) {        

        return true;

    }

    /// @notice Returns the info to Buy NFTs in Constant Product market
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

        if (_numItems == 0) return ( false, 0, 0, 0, 0);

        uint tokenBalance = _startPrice;

        uint nftBalance = _multiplier;

        // multiply the number of items by 1e18 because all the calculations are done in base 1e18

        uint numItems = _numItems * 1e18;

        // num Items should be < NFT balance ( multiplier = numItems  initial Price )

        if ( numItems >= nftBalance ) return ( false, 0, 0, 0, 0);

        // input value = ( tokenBalance * numItems ) / ( nftBalance - numItems )

        uint inputValueWithoutFee = tokenBalance.fmul( numItems, FixedPointMathLib.WAD ).fdiv( nftBalance - numItems , FixedPointMathLib.WAD );

        // calculate buy fees

        uint poolFee = inputValueWithoutFee.fmul( _poolFee, FixedPointMathLib.WAD );

        protocolFee = inputValueWithoutFee.fmul( _protocolFee, FixedPointMathLib.WAD );

        // adding fees

        inputValue = inputValueWithoutFee + ( protocolFee + poolFee );

        // update start Price and multiplier

        newStartPrice = uint128( tokenBalance + inputValueWithoutFee );

        newMultiplier = uint128( nftBalance - numItems );

        isValid = true;

    }

    /// @notice Returns the info to Sell NFTs in Constant Product market
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
        ) 
    {
        
        // num Items should be > 0

        if ( _numItems == 0) return (false, 0, 0, 0, 0);

        uint tokenBalance = _startPrice;

        uint nftBalance = _multiplier;
        
        // multiply the number of items by 1e18 because all the calculations are done in base 1e18

        uint numItems = _numItems * 1e18;

        // input value = ( tokenBalance * numItems ) / ( nftBalance + numItems )

        uint outputValueWithoutFee = ( tokenBalance.fmul( numItems, FixedPointMathLib.WAD ) ).fdiv( nftBalance + numItems, FixedPointMathLib.WAD );

        // calculate sell fees

        uint poolFee = outputValueWithoutFee.fmul( _poolFee, FixedPointMathLib.WAD );

        protocolFee = outputValueWithoutFee.fmul( _protocolFee, FixedPointMathLib.WAD );

        // adding fees

        outputValue = outputValueWithoutFee - ( protocolFee + poolFee );

        // update start Price and multiplier 

        newStartPrice = uint128( tokenBalance - outputValueWithoutFee );

        newMultiplier = uint128( nftBalance + numItems );

        isValid = true;

    }
    
}