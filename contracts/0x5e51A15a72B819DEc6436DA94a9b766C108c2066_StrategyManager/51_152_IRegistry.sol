// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

//  libraries
import { DataTypes } from "../../libraries/types/DataTypes.sol";

/**
 * @title Interface for Registry Contract
 * @author Opty.fi
 * @notice Interface of the opty.fi's protocol reegistry to store all the mappings, governance
 * operator, minter, strategist and all optyFi's protocol contract addresses
 */
interface IRegistry {
    /**
     * @notice Set the treasury's address for optyfi's earn protocol
     * @param _treasury Treasury's address
     */
    function setTreasury(address _treasury) external;

    /**
     * @notice Set the StrategyProvider contract address
     * @param _strategyProvider Address of StrategyProvider Contract
     */
    function setStrategyProvider(address _strategyProvider) external;

    /**
     * @notice Set the RiskManager's contract address
     * @param _riskManager Address of RiskManager Contract
     */
    function setRiskManager(address _riskManager) external;

    /**
     * @notice Set the HarvestCodeProvider contract address
     * @param _harvestCodeProvider Address of HarvestCodeProvider Contract
     */
    function setHarvestCodeProvider(address _harvestCodeProvider) external;

    /**
     * @notice Set the $OPTY token's contract address
     * @param _opty Address of Opty Contract
     */
    function setOPTY(address _opty) external;

    /**
     * @notice Set the ODEFIVaultBooster contract address
     * @dev Can only be called by the current governance
     * @param _odefiVaultBooster address of the ODEFIVaultBooster Contract
     */
    function setODEFIVaultBooster(address _odefiVaultBooster) external;

    /**
     * @dev Sets multiple `_token` from the {tokens} mapping.
     * @notice Approves multiple tokens in one transaction
     * @param _tokens List of tokens to approve
     */
    function approveToken(address[] memory _tokens) external;

    /**
     * @notice Approves the token provided
     * @param _token token to approve
     */
    function approveToken(address _token) external;

    /**
     * @notice Disable multiple tokens in one transaction
     * @param _tokens List of tokens to revoke
     */
    function revokeToken(address[] memory _tokens) external;

    /**
     * @notice Disable the token
     * @param _token token to revoke
     */
    function revokeToken(address _token) external;

    /**
     * @notice Approves multiple liquidity pools in one transaction
     * @param _pools list of liquidity/credit pools to approve
     */
    function approveLiquidityPool(address[] memory _pools) external;

    /**
     * @notice For approving single liquidity pool
     * @param _pool liquidity/credit pool to approve
     */
    function approveLiquidityPool(address _pool) external;

    /**
     * @notice Revokes multiple liquidity pools in one transaction
     * @param _pools list of liquidity/credit pools to revoke
     */
    function revokeLiquidityPool(address[] memory _pools) external;

    /**
     * @notice Revokes the liquidity pool
     * @param _pool liquidity/credit pool to revoke
     */
    function revokeLiquidityPool(address _pool) external;

    /**
     * @notice Sets multiple pool rates and liquidity pools provided
     * @param _poolRates List of pool rates ([_pool, _rate]) to set
     */
    function rateLiquidityPool(DataTypes.PoolRate[] memory _poolRates) external;

    /**
     * @notice Sets the pool rate for the liquidity pool provided
     * @param _pool liquidityPool to map with its rating
     * @param _rate rate for the liquidityPool provided
     */
    function rateLiquidityPool(address _pool, uint8 _rate) external;

    /**
     * @notice Approve and map the multiple pools to their adapter
     * @param _poolAdapters List of [pool, adapter] pairs to set
     */
    function approveLiquidityPoolAndMapToAdapter(DataTypes.PoolAdapter[] memory _poolAdapters) external;

    /**
     * @notice Approve and map the pool to the adapter
     * @param _pool the address of liquidity pool
     * @param _adapter the address of adapter
     */
    function approveLiquidityPoolAndMapToAdapter(address _pool, address _adapter) external;

    /**
     * @notice Maps multiple liquidity pools to their protocol adapters
     * @param _poolAdapters List of [pool, adapter] pairs to set
     */
    function setLiquidityPoolToAdapter(DataTypes.PoolAdapter[] memory _poolAdapters) external;

    /**
     * @notice Maps liquidity pool to its protocol adapter
     * @param _pool liquidityPool to map with its adapter
     * @param _adapter adapter for the liquidityPool provided
     */
    function setLiquidityPoolToAdapter(address _pool, address _adapter) external;

    /**
     * @notice Approves multiple swap pools in one transaction
     * @param _pools List of pools for approval to be considered as swapPool
     */
    function approveSwapPool(address[] memory _pools) external;

    /**
     * @notice Approves the swap pool
     * @param _pool swap pool address to be approved
     */
    function approveSwapPool(address _pool) external;

    /**
     * @notice Revokes multiple swap pools in one transaction
     * @param _pools List of pools for revoking from being used as swapPool
     */
    function revokeSwapPool(address[] memory _pools) external;

    /**
     * @notice Revokes the swap pool
     * @param _pool pool for revoking from being used as swapPool
     */
    function revokeSwapPool(address _pool) external;

    /**
     * @notice Sets the multiple pool rates and swap pools provided
     * @param _poolRates List of pool rates ([_pool, _rate]) to set for swapPool
     */
    function rateSwapPool(DataTypes.PoolRate[] memory _poolRates) external;

    /**
     * @notice Sets the pool rate for the swap pool provided
     * @param _pool swapPool to map with its rating
     * @param _rate rate for the swapPool provided
     */
    function rateSwapPool(address _pool, uint8 _rate) external;

    /**
     * @notice Maps multiple swap pools to their protocol adapters
     * @param _poolAdapters List of [pool, adapter] pairs to set
     */
    function setSwapPoolToAdapter(DataTypes.PoolAdapter[] memory _poolAdapters) external;

    /**
     * @notice Maps swap pool to its protocol adapter
     * @param _pool swapPool to map with its adapter
     * @param _adapter adapter for the swapPool provided
     */
    function setSwapPoolToAdapter(address _pool, address _adapter) external;

    /**
     * @notice Approve and map the multiple swap pools to their adapter
     * @param _poolAdapters List of [pool, adapter] pairs to set
     */
    function approveSwapPoolAndMapToAdapter(DataTypes.PoolAdapter[] memory _poolAdapters) external;

    /**
     * @notice Approve and map the swap pool to the adapter
     * @param _pool the address of liquidity pool
     * @param _adapter the address of adapter
     */
    function approveSwapPoolAndMapToAdapter(address _pool, address _adapter) external;

    /**
     * @notice Maps multiple token pairs to their keccak256 hash
     * @param _tokensHashesDetails List of mulitple tokens' hashes details
     */
    function setTokensHashToTokens(DataTypes.TokensHashDetail[] memory _tokensHashesDetails) external;

    /**
     * @notice Sets token pair to its keccak256 hash
     * @param _tokensHash Hash of tokens
     * @param _tokens List of tokens
     */
    function setTokensHashToTokens(bytes32 _tokensHash, address[] memory _tokens) external;

    /**
     * @notice Approve tokens and map tokens hash
     * @param _tokensHash Hash of tokens
     * @param _tokens List of tokens
     */
    function approveTokenAndMapToTokensHash(bytes32 _tokensHash, address[] memory _tokens) external;

    /**
     * @notice Approve tokens and map multiple tokens'hashes
     * @param _tokensHashesDetails List of mulitple tokens' hashes details
     */
    function approveTokenAndMapToTokensHash(DataTypes.TokensHashDetail[] memory _tokensHashesDetails) external;

    /**
     * @notice Adds the risk profile in Registry contract Storage
     * @param _riskProfileCode code of riskProfile
     * @param _name name of riskProfile
     * @param _symbol symbol of riskProfile
     * @param _poolRatingRange pool rating range ([lowerLimit, upperLimit]) supported by given risk profile
     */
    function addRiskProfile(
        uint256 _riskProfileCode,
        string memory _name,
        string memory _symbol,
        DataTypes.PoolRatingsRange memory _poolRatingRange
    ) external;

    /**
     * @notice Adds list of the risk profiles in Registry contract Storage in one transaction
     * @dev All parameters must be in the same order.
     * @param _riskProfileCodes codes of riskProfiles
     * @param _names names of riskProfiles
     * @param _symbols symbols of riskProfiles
     * @param _poolRatingRanges List of pool rating range supported by given list of risk profiles
     */
    function addRiskProfile(
        uint256[] memory _riskProfileCodes,
        string[] memory _names,
        string[] memory _symbols,
        DataTypes.PoolRatingsRange[] memory _poolRatingRanges
    ) external;

    /**
     * @notice Update the pool ratings for existing risk profile
     * @param _riskProfileCode Risk profile code (Eg: 1,2, and so on where 0 is reserved for 'no strategy')
     * to update with pool rating range
     * @param _poolRatingRange pool rating range ([lowerLimit, upperLimit]) to update for given risk profile
     */
    function updateRPPoolRatings(uint256 _riskProfileCode, DataTypes.PoolRatingsRange memory _poolRatingRange) external;

    /**
     * @notice Remove the existing risk profile in Registry contract Storage
     * @param _index Index of risk profile to be removed
     */
    function removeRiskProfile(uint256 _index) external;

    /**
     * @notice Get the list of tokensHash
     * @return Returns the list of tokensHash.
     */
    function getTokenHashes() external view returns (bytes32[] memory);

    /**
     * @notice Get list of token given the tokensHash
     * @return Returns the list of tokens corresponding to tokensHash
     */
    function getTokensHashToTokenList(bytes32 _tokensHash) external view returns (address[] memory);

    /**
     * @notice Get the list of all the riskProfiles
     * @return Returns the list of all riskProfiles stored in Registry Storage
     */
    function getRiskProfileList() external view returns (uint256[] memory);

    /**
     * @notice Retrieve the StrategyProvider contract address
     * @return Returns the StrategyProvider contract address
     */
    function getStrategyProvider() external view returns (address);

    /**
     * @notice Retrieve the RiskManager contract address
     * @return Returns the RiskManager contract address
     */
    function getRiskManager() external view returns (address);

    /**
     * @notice Retrieve the OPTYDistributor contract address
     * @return Returns the OPTYDistributor contract address
     */
    function getOPTYDistributor() external view returns (address);

    /**
     * @notice Retrieve the ODEFIVaultBooster contract address
     * @return Returns the ODEFIVaultBooster contract address
     */
    function getODEFIVaultBooster() external view returns (address);

    /**
     * @notice Retrieve the Governance address
     * @return Returns the Governance address
     */
    function getGovernance() external view returns (address);

    /**
     * @notice Retrieve the FinanceOperator address
     * @return Returns the FinanceOperator address
     */
    function getFinanceOperator() external view returns (address);

    /**
     * @notice Retrieve the RiskOperator address
     * @return Returns the RiskOperator address
     */
    function getRiskOperator() external view returns (address);

    /**
     * @notice Retrieve the StrategyOperator address
     * @return Returns the StrategyOperator address
     */
    function getStrategyOperator() external view returns (address);

    /**
     * @notice Retrieve the Operator address
     * @return Returns the Operator address
     */
    function getOperator() external view returns (address);

    /**
     * @notice Retrieve the HarvestCodeProvider contract address
     * @return Returns the HarvestCodeProvider contract address
     */
    function getHarvestCodeProvider() external view returns (address);

    /**
     * @notice Get the properties corresponding to riskProfile code provided
     * @return _riskProfile Returns the properties corresponding to riskProfile provided
     */
    function getRiskProfile(uint256) external view returns (DataTypes.RiskProfile memory _riskProfile);

    /**
     * @notice Get the index corresponding to tokensHash provided
     * @param _tokensHash Hash of token address/addresses
     * @return _index Returns the index corresponding to tokensHash provided
     */
    function getTokensHashIndexByHash(bytes32 _tokensHash) external view returns (uint256 _index);

    /**
     * @notice Get the tokensHash available at the index provided
     * @param _index Index at which you want to get the tokensHash
     * @return _tokensHash Returns the tokensHash available at the index provided
     */
    function getTokensHashByIndex(uint256 _index) external view returns (bytes32 _tokensHash);

    /**
     * @notice Get the rating and Is pool a liquidity pool for the _pool provided
     * @param _pool Liquidity Pool (like cDAI etc.) address
     * @return _liquidityPool Returns the rating and Is pool a liquidity pool for the _pool provided
     */
    function getLiquidityPool(address _pool) external view returns (DataTypes.LiquidityPool memory _liquidityPool);

    /**
     * @notice Get the adapter address mapped to the swap _pool provided
     * @param _pool Swap Pool (like USDC-ETH etc.) address
     * @return _adapter Returns the adapter address mapped to the swap _pool provided
     */
    function getSwapPoolToAdapter(address _pool) external view returns (address _adapter);

    /**
     * @notice Get the rating and Is pool a swap pool for the _pool provided
     * @param _pool Swap Pool (like USDC-ETH etc.) address
     * @return _swapPool Returns the rating and Is pool a swap pool for the _pool provided
     */
    function getSwapPool(address _pool) external view returns (DataTypes.LiquidityPool memory _swapPool);

    /**
     * @notice Get the adapter address mapped to the _pool provided
     * @param _pool Liquidity Pool (like cDAI etc.) address
     * @return _adapter Returns the adapter address mapped to the _pool provided
     */
    function getLiquidityPoolToAdapter(address _pool) external view returns (address _adapter);

    /**
     * @notice Check if the token is approved or not
     * @param _token Token address for which to check if it is approved or not
     * @return _isTokenApproved Returns a boolean for token approved or not
     */
    function isApprovedToken(address _token) external view returns (bool _isTokenApproved);
}