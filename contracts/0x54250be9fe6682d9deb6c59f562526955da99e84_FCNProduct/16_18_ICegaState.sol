// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ICegaState {
    function marketMakerAllowList(address marketMaker) external view returns (bool);

    function products(string memory productName) external view returns (address);

    function oracleAddresses(string memory oracleName) external view returns (address);

    function oracleNames() external view returns (string[] memory);

    function productNames() external view returns (string[] memory);

    function feeRecipient() external view returns (address);

    function isDefaultAdmin(address sender) external view returns (bool);

    function isTraderAdmin(address sender) external view returns (bool);

    function isOperatorAdmin(address sender) external view returns (bool);

    function isServiceAdmin(address sender) external view returns (bool);

    function getOracleNames() external view returns (string[] memory);

    function addOracle(string memory oracleName, address oracleAddress) external;

    function removeOracle(string memory oracleName) external;

    function getProductNames() external view returns (string[] memory);

    function addProduct(string memory productName, address product) external;

    function removeProduct(string memory productName) external;

    function updateMarketMakerPermission(address marketMaker, bool allow) external;

    function setFeeRecipient(address _feeRecipient) external;

    function moveAssetsToProduct(string memory productName, address vaultAddress, uint256 amount) external;
}