// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../pools/MSPoolBasic.sol";
import "../pools/PoolTypes.sol";
import "./IMetaAlgorithm.sol";

/// @title IMetaFactory a interface to call pool factory
/// @author JorgeLpzGnz & CarlosMario714
/// @dev This factory creates pair based on the minimal proxy standard IEP-1167
interface IMetaFactory {

    /// @notice Creates a new pool
    /// @param _nft NFT collection to trade
    /// @param _nftIds The NFTs to trade ( empty in pools type Buy )
    /// @param _multiplier The multiplier to calculate the trade price
    /// @param _startPrice The start Price to calculate the trade price
    /// start Price is just a name see de algorithm to see how this will be take it
    /// @param _recipient Recipient of the input assets
    /// @param _fee Fee multiplier to calculate the pool fee ( available on trade pool )
    /// @param _Algorithm Algorithm used to calculate the price
    /// @param _poolType The type of the pool ( sell, buy, trade )
    /// @return pool Address of the new pool created
    function createPool( 
        address _nft, 
        uint[] memory _nftIds,
        uint128 _multiplier,
        uint128 _startPrice,
        address _recipient,
        uint128 _fee,
        IMetaAlgorithm _Algorithm, 
        PoolTypes.PoolType _poolType
        ) external payable  returns(
            MSPoolBasic pool
        );

    /// @notice Get current Factory info
    /// @return MAX_FEE_PERCENTAGE The maximum percentage fee multiplier
    /// @return PROTOCOL_FEE Current protocol fee multiplier
    /// @return PROTOCOL_FEE_RECIPIENT The recipient of the fees
    function getFactoryInfo() external view returns( uint128, uint128, address );

    /// @notice Obtain information if the router is approved
    /// @param _router router to ask
    /// @return isAllowed True if is approved
    function isRouterAllowed( address _router ) external view returns ( bool isAllowed );

    /// @notice Obtain information if the Algorithm is approved
    /// @param _algorithm Algorithm to ask
    /// @return isAllowed True if is approved
    function isAlgorithmAllowed( address _algorithm ) external view returns ( bool isAllowed );

    /// @notice Maximum multiplier fee
    /// @return MAX_FEE_PERCENTAGE The maximum percentage fee multiplier
    function MAX_FEE_PERCENTAGE() external view returns( uint128 );

    /// @notice Protocol multiplier fee, used to calculate the fee charged per trade
    /// @return PROTOCOL_FEE Current protocol fee multiplier
    function PROTOCOL_FEE() external view returns( uint128 );

    /// @notice The recipient of the fees charged per swap
    /// @return PROTOCOL_FEE_RECIPIENT The recipient of the fees
    function PROTOCOL_FEE_RECIPIENT() external view returns( address );
    
}