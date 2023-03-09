// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../pools/PoolTypes.sol";
import "./IMetaAlgorithm.sol";

/// @title IMSPool a interface to call pool functions
/// @author JorgeLpzGnz & CarlosMario714
/// @dev Pools are a IEP-1167 implementation ( minimal proxies - clones )
interface IMSPool {

    /// @notice Returns the current Buy info
    /// @param _numNFTs Number of NFTs to buy
    /// @return isValid True if trade is operable
    /// @return newStartPrice New Start price that will be set 
    /// @return newMultiplier New multiplier that will be set 
    /// @return inputValue Amount of tokens to send to the pool 
    /// @return protocolFee Amount charged for the trade
    function getPoolBuyInfo( uint _numNFTs) external view returns( bool isValid, uint128 newStartPrice, uint128 newMultiplier, uint inputValue, uint protocolFee );

    /// @notice Returns the current Sell info
    /// @param _numNFTs Number of NFTs to buy
    /// @return isValid True if trade is operable
    /// @return newStartPrice New Start price that will be set 
    /// @return newMultiplier New multiplier that will be set 
    /// @return outputValue Amount to be sent to the user
    /// @return protocolFee Amount charged for the trade
    function getPoolSellInfo( uint _numNFTs) external view returns( bool isValid, uint128 newStartPrice, uint128 newMultiplier, uint outputValue, uint protocolFee );
    
    /// @notice Returns the NFT IDs of the pool
    /// @dev In the buy pools this will be empty because the NFTs are push
    /// on the recipient indicated for the user
    function getNFTIds() external view returns ( uint[] memory nftIds);

    /// @return _recipient Recipient of the input assets
    function getAssetsRecipient() external view returns ( address _recipient );

    /// @notice Returns the current algorithm info
    /// @return algorithm Name of the algorithm used to calculate trade prices
    /// @return name Name of the algorithm used to calculate trade prices
    function getAlgorithmInfo() external view returns( IMetaAlgorithm algorithm, string memory name );

    /// @notice Returns the pool info
    /// @return poolMultiplier Current multiplier
    /// @return poolStartPrice Current start price 
    /// @return poolTradeFee Trade fee multiplier 
    /// @return poolNft NFT trade collection
    /// @return poolNFTs NFTs of the pool
    /// @return poolAlgorithm Address of the algorithm
    /// @return poolAlgorithmName Name of the algorithm
    /// @return poolPoolType The type of the pool
    /// @return assetsRecipient Recipient of the trade assets
    function getPoolInfo() external view returns( 
        uint128 poolMultiplier,
        uint128 poolStartPrice,
        uint128 poolTradeFee,
        address poolNft,
        uint[] memory poolNFTs,
        IMetaAlgorithm poolAlgorithm,
        string memory poolAlgorithmName,
        PoolTypes.PoolType poolPoolType,
        address assetsRecipient);

    /// @notice It sets all the pool params
    /// @param _multiplier Multiplier to calculate the price
    /// @param _startPrice Start price to calculate the price 
    /// @param _recipient Recipient of the input assets ( not available on trade pools )
    /// @param _owner Owner of the pool 
    /// @param _NFT NFT trade collection
    /// @param _fee Fee multiplier to calculate pool fees ( available on trade pool )
    /// @param _Algorithm Address of the algorithm to calculate trade prices
    /// @param _poolType Type of the pool
    function init(
        uint128 _multiplier, 
        uint128 _startPrice, 
        address _recipient, 
        address _owner, 
        address _NFT, 
        uint128 _fee, 
        IMetaAlgorithm _Algorithm, 
        PoolTypes.PoolType _poolType 
        ) external payable;

    /// @notice Sell NFTs and get Tokens
    /// @param _tokenIDs NFTs to sell
    /// @param _minExpected Minimum expected to return to the user
    /// @param _user Address to send the tokens
    /// @return outputAmount amount of output from the pool
    function swapNFTsForToken( uint[] memory _tokenIDs, uint _minExpected, address _user ) external returns( uint256 outputAmount );

    /// @notice Buy NFTs by depositing tokens
    /// @param _tokenIDs NFTs to buy
    /// @param _maxExpectedIn Maximum expected cost to buy the NFTs
    /// @param _user Address to send the NFTs
    /// @return inputAmount amount of input to the pool
    function swapTokenForNFT( uint[] memory _tokenIDs, uint _maxExpectedIn, address _user ) external payable returns( uint256 inputAmount );

    /// @notice Buy NFTs by depositing tokens (used when the NFTs to be sent to the user do not matter)
    /// @param _numNFTs Number of NFTs to buy
    /// @param _maxExpectedIn maximum expected cost to buy the NFTs
    /// @param _user Address to send the NFTs
    /// @return inputAmount amount of input to the pool
    function swapTokenForAnyNFT( uint _numNFTs, uint _maxExpectedIn, address _user ) external payable returns( uint256 inputAmount );

}