// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.11;

/**
    @title Interface for Bridge contract.
    @author ChainSafe Systems.
 */
interface IBridge {
    /**
        @notice Exposing getter for {_domainID} instead of forcing the use of call.
        @return uint8 The {_domainID} that is currently set for the Bridge contract.
     */
    function _domainID() external returns (uint8);
    /**
        @notice Exposing getter for Fee values by concrete token, chain Id
        @param tokenAddress The address of bridged concrete token
        @param chainId The Id of bridged concrete chain
        @return fee values on concrete token and chain
     */
    function getFee(address tokenAddress, uint8 chainId) external view returns(uint256, uint256, uint256);
    /**
        @notice Exposing getter for fee max percent value
        @return fee max percent value
     */
    function getFeeMaxValue() external view returns(uint128);
    /**
        @notice Exposing getter for fee percent value
        @return fee percent value
     */
    function getFeePercent() external view returns(uint64);
}