// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../pools/MSPoolBasic.sol";
import "../pools/PoolTypes.sol";
import "./IMetaAlgorithm.sol";

/// @title IMetaFactory a interface to call pool factory
/// @author JorgeLpzGnz & CarlosMario714
/// @dev this factory creates pair based on the minimal proxy standard IEP-1167
interface IMetaFactory {

    /// @notice Creates a new pool
    /// @param _nft NFT collection to trade
    /// @param _nftIds the NFTs to trade ( empty in pools type Buy )
    /// @param _multiplier the multiplier to calculate the trade price
    /// @param _startPrice the start Price to calculate the trade price
    /// start Price is just a name see de algorithm to see how this will be take it
    /// @param _recipient recipient of the input assets
    /// @param _fee fee multiplier to calculate the pool fee ( available on trade pool )
    /// @param _Algorithm Algorithm used to calculate the price
    /// @param _poolType the type of the pool ( sell, buy, trade )
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

    /// @notice Get current pool info
    /// @return MAX_FEE_PERCENTAGE The maximum percentage fee multiplier
    /// @return PROTOCOL_FEE Current protocol fee multiplier
    /// @return PROTOCOL_FEE_RECIPIENT The recipient of the fees
    function getFactoryInfo() external view returns( uint128, uint128, address );

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