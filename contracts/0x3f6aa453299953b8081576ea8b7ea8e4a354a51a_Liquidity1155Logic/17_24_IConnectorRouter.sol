// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {DataTypes} from "../libraries/DataTypes.sol";

/**
 * @title IConnectorRouter
 * @author Souq.Finance
 * @notice Defines the interface of the connector router
 * @notice License: https://souq-nft-amm-v1.s3.amazonaws.com/LICENSE.md
 */
interface IConnectorRouter {
    event YieldDistributorSet(address indexed vaultAddress, address indexed yieldDistributorAddress);
    event YieldDistributorUpdated(address indexed vaultAddress, address indexed yieldDistributorAddress);
    event YieldDistributorDeleted(address indexed vaultAddress);

    event StakingContractSet(address indexed tokenAddress, address indexed stakingContractAddress);
    event StakingContractUpdated(address indexed tokenAddress, address indexed stakingContractAddress);
    event StakingContractDeleted(address indexed stakingContractAddress);

    event SwapContractSet(address indexed tokenAddress, address indexed swapContractAddress);
    event SwapContractUpdated(address indexed tokenAddress, address indexed swapContractAddress);
    event SwapContractDeleted(address indexed swapContractAddress);

    event OracleConnectorSet(address indexed tokenAddress, address indexed oracleConnectorAddress);
    event OracleConnectorUpdated(address indexed tokenAddress, address indexed oracleConnectorAddress);
    event OracleConnectorDeleted(address indexed oracleConnectorAddress);

    event CollectionConnectorSet(address indexed liquidityPool, address indexed collectionConnectorAddress, uint indexed tokenID);
    event CollectionConnectorUpdated(address indexed liquidityPool, address indexed collectionConnectorAddress, uint indexed tokenID);
    event CollectionConnectorDeleted(address indexed collectionConnectorAddress);

    event StablecoinYieldConnectorSet(address indexed tokenAddress, address indexed stablecoinYieldConnectorAddress);
    event StablecoinYieldConnectorUpdated(address indexed tokenAddress, address indexed stablecoinYieldConnectorAddress);
    event StablecoinYieldConnectorDeleted(address indexed stablecoinYieldConnectorAddress);

    /**
     * @dev Sets the initial owner and timelock address of the contract.
     * @param timelock address
     */
    function initialize(address timelock) external;

    /**
     * @dev Returns the address of the yield distributor contract for a given vault.
     * @param vaultAddress address
     * @return address of the yield distributor contract
     */
    function getYieldDistributor(address vaultAddress) external view returns (address);

    function setYieldDistributor(address vaultAddress, address yieldDistributorAddress) external;

    function updateYieldDistributor(address vaultAddress, address yieldDistributorAddress) external;

    function deleteYieldDistributor(address vaultAddress) external;

    function getStakingContract(address tokenAddress) external view returns (address);

    function setStakingContract(address tokenAddress, address stakingContractAddress) external;

    function updateStakingContract(address tokenAddress, address stakingContractAddress) external;

    function deleteStakingContract(address tokenAddress) external;

    function getSwapContract(address tokenAddress) external view returns (address);

    function setSwapContract(address tokenAddress, address swapContractAddress) external;

    function updateSwapContract(address tokenAddress, address swapContractAddress) external;

    function deleteSwapContract(address tokenAddress) external;

    function getOracleConnectorContract(address tokenAddress) external view returns (address);

    function setOracleConnectorContract(address tokenAddress, address oracleConnectorAddress) external;

    function updateOracleConnectorContract(address tokenAddress, address oracleConnectorAddress) external;

    function deleteOracleConnectorContract(address tokenAddress) external;

    function getCollectionConnectorContract(address liquidityPool) external view returns (DataTypes.ERC1155Collection memory);

    function setCollectionConnectorContract(address liquidityPool, address collectionConnectorAddress, uint tokenID) external;

    function updateCollectionConnectorContract(address liquidityPool, address collectionConnectorAddress, uint tokenID) external;

    function deleteCollectionConnectorContract(address liquidityPool) external;

    function getStablecoinYieldConnectorContract(address tokenAddress) external view returns (address);

    function setStablecoinYieldConnectorContract(address tokenAddress, address stablecoinYieldConnectorAddress) external;

    function updateStablecoinYieldConnectorContract(address tokenAddress, address stablecoinYieldConnectorAddress) external;

    function deleteStablecoinYieldConnectorContract(address tokenAddress) external;
}