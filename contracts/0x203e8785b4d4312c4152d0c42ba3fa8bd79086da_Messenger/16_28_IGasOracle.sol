// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IGasOracle {
    function chainData(uint chainId) external view returns (uint128 price, uint128 gasPrice);

    function chainId() external view returns (uint);

    function crossRate(uint otherChainId) external view returns (uint);

    function getTransactionGasCostInNativeToken(uint otherChainId, uint256 gasAmount) external view returns (uint);

    function getTransactionGasCostInUSD(uint otherChainId, uint256 gasAmount) external view returns (uint);

    function price(uint chainId) external view returns (uint);

    function setChainData(uint chainId, uint128 price, uint128 gasPrice) external;

    function setGasPrice(uint chainId, uint128 gasPrice) external;

    function setPrice(uint chainId, uint128 price) external;
}