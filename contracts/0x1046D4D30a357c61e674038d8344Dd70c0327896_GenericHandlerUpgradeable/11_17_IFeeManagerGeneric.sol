// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

interface iFeeManagerGeneric {

    function withdrawFee(address tokenAddress, address recipient, uint256 amount) external;

    function setFee(
        uint8 destinationChainID,
        address feeTokenAddress,
        uint256 feeFactor,
        uint256 bridgeFee,
        bool accepted
    ) external;

    function getFee(uint8 destinationChainID, address feeTokenAddress) external view returns (uint256 , uint256);
}