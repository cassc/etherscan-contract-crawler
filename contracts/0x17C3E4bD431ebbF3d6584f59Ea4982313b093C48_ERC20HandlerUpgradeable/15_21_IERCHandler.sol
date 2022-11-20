// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/// @title Interface to be used with handlers that support ERC20s and ERC721s.
/// @author Router Protocol.
interface IERCHandler {
    function withdrawFees(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) external;

    function getBridgeFee(uint8 destinationChainID, address feeTokenAddress) external view returns (uint256, uint256);

    function setBridgeFee(
        uint8 destinationChainID,
        address feeTokenAddress,
        uint256 transferFee,
        uint256 exchangeFee,
        bool accepted
    ) external;

    function toggleFeeStatus(bool status) external;

    function getFeeStatus() external view returns (bool);

    function _ETH() external view returns (address);

    function _WETH() external view returns (address);

    function resourceIDToTokenContractAddress(bytes32 resourceID) external view returns (address);

    /// @notice Correlates {resourceID} with {contractAddress}.
    /// @param resourceID ResourceID to be used when making deposits.
    /// @param contractAddress Address of contract to be called when a deposit is made and a deposited is executed.
    function setResource(bytes32 resourceID, address contractAddress) external;

    // function setTokenDecimals(
    //     address[] calldata tokenAddress,
    //     uint8[] calldata destinationChainID,
    //     uint8[] calldata decimals
    // ) external;

    /// @notice Sets oneSplitAddress for the handler
    /// @param contractAddress Address of oneSplit contract
    function setOneSplitAddress(address contractAddress) external;

    /// @notice Correlates {resourceID} with {contractAddress}.
    /// @param contractAddress Address of contract for qhich liquidity pool needs to be created.
    function setLiquidityPool(address contractAddress, address lpAddress) external;

    // function setLiquidityPool(
    //     string memory name,
    //     string memory symbol,
    //     uint8 decimals,
    //     address contractAddress,
    //     address lpAddress
    // ) external;

    /// @notice Sets liquidity pool owner for an existing LP.
    /// @dev Can only be set by the bridge
    /// @param oldOwner Address of the old owner of LP
    /// @param newOwner Address of the new owner for LP
    /// @param tokenAddress Address of ERC20 token
    /// @param lpAddress Address of LP
    function setLiquidityPoolOwner(
        address oldOwner,
        address newOwner,
        address tokenAddress,
        address lpAddress
    ) external;

    /// @notice Marks {contractAddress} as mintable/burnable.
    /// @param contractAddress Address of contract to be used when making or executing deposits.
    /// @param status Boolean flag for burnanble status.
    function setBurnable(address contractAddress, bool status) external;

    /// @notice Used to manually release funds from ERC safes.
    /// @param tokenAddress Address of token contract to release.
    /// @param recipient Address to release tokens to.
    /// @param amountOrTokenID Either the amount of ERC20 tokens or the ERC721 token ID to release.
    function withdraw(
        address tokenAddress,
        address recipient,
        uint256 amountOrTokenID
    ) external;
}