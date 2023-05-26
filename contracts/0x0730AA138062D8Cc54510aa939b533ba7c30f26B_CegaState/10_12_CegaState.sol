// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

import { IFCNProduct } from "./interfaces/IFCNProduct.sol";

contract CegaState is AccessControl {
    // Create a new role identifier for the admin roles
    bytes32 public constant OPERATOR_ADMIN_ROLE = keccak256("OPERATOR_ADMIN_ROLE");
    bytes32 public constant TRADER_ADMIN_ROLE = keccak256("TRADER_ADMIN_ROLE");
    bytes32 public constant SERVICE_ADMIN_ROLE = keccak256("SERVICE_ADMIN_ROLE");

    event FCNProductViewerUpdated(address indexed fcnProductViewerAddress);
    event OracleAdded(string indexed oracleName, address indexed oracleAddress);
    event OracleRemoved(string indexed oracleName);
    event ProductAdded(string indexed productName, address indexed productAddress);
    event ProductRemoved(string indexed productName);
    event MarketMakerPermissionUpdated(address indexed marketMaker, bool indexed allow);
    event FeeRecipientUpdated(address indexed feeRecipient);
    event AssetsMovedToProduct(string indexed productName, address indexed vaultAddress, uint256 amount);

    mapping(address => bool) public marketMakerAllowList;
    mapping(string => address) public products;
    mapping(string => address) public oracleAddresses;

    string[] public oracleNames;
    string[] public productNames;
    address public feeRecipient;

    // Store this address for lookup on SDK side
    address public fcnProductViewerAddress;

    /**
     * @notice CegaState contructor that sets up the admin roles
     * @param _operatorAdmin is the address of the operator admin
     * @param _traderAdmin is the address of the trader admin
     * @param _serviceAdmin is the address of the service admin
     */
    constructor(address _operatorAdmin, address _traderAdmin, address _serviceAdmin) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ADMIN_ROLE, _operatorAdmin);
        _setupRole(TRADER_ADMIN_ROLE, _traderAdmin);
        _setupRole(SERVICE_ADMIN_ROLE, _serviceAdmin);
    }

    /**
     * @notice Only operator admin can set the viewer address. SDK uses this to lookup viewer address
     * @param _fcnProductViewerAddress is the address of the viewer contract
     */
    function setFCNProductViewerAddress(address _fcnProductViewerAddress) public onlyRole(OPERATOR_ADMIN_ROLE) {
        fcnProductViewerAddress = _fcnProductViewerAddress;
        emit FCNProductViewerUpdated(_fcnProductViewerAddress);
    }

    /**
     * @notice Asserts whether the sender has the DEFAULT_ADMIN_ROLE
     * @param sender is the address to be checked
     */
    function isDefaultAdmin(address sender) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, sender);
    }

    /**
     * @notice Asserts whether the sender has the TRADER_ADMIN_ROLE
     * @param sender is the address to be checked
     */
    function isTraderAdmin(address sender) public view returns (bool) {
        return hasRole(TRADER_ADMIN_ROLE, sender);
    }

    /**
     * @notice Asserts whether the sender has the OPERATOR_ADMIN_ROLE
     * @param sender is the address to be checked
     */
    function isOperatorAdmin(address sender) public view returns (bool) {
        return hasRole(OPERATOR_ADMIN_ROLE, sender);
    }

    /**
     * @notice Asserts whether the sender has the SERVICE_ADMIN_ROLE
     * @param sender is the address of callee
     */
    function isServiceAdmin(address sender) public view returns (bool) {
        return hasRole(SERVICE_ADMIN_ROLE, sender);
    }

    /**
     * @notice Returns all oracle names (ex: "BTC/USD,PYTH")
     */
    function getOracleNames() public view returns (string[] memory) {
        return oracleNames;
    }

    /**
     * @notice Operator admin has ability to add a new oracle
     * @param oracleName is the name of the new oracle (ex: "BTC/USD,PYTH")
     * @param oracleAddress is the address of the oracle
     */
    function addOracle(string memory oracleName, address oracleAddress) public onlyRole(OPERATOR_ADMIN_ROLE) {
        require(oracleAddress != address(0), "400:IA");
        if (oracleAddresses[oracleName] == address(0)) {
            oracleNames.push(oracleName);
        }
        oracleAddresses[oracleName] = oracleAddress;
        emit OracleAdded(oracleName, oracleAddress);
    }

    /**
     * @notice Operator admin has ability to remove oracle
     * @param oracleName is the name of the oracle to be removed
     */
    function removeOracle(string memory oracleName) public onlyRole(OPERATOR_ADMIN_ROLE) {
        bool found = false;
        uint256 index = 0;
        for (uint256 i = 0; i < oracleNames.length; i++) {
            if (keccak256(abi.encodePacked(oracleNames[i])) == keccak256(abi.encodePacked(oracleName))) {
                index = i;
                found = true;
                break;
            }
        }
        if (found) {
            // Swap last element with element at index, then pop to delete oracle
            oracleNames[index] = oracleNames[oracleNames.length - 1];
            oracleNames.pop();
            delete oracleAddresses[oracleName];
            emit OracleRemoved(oracleName);
        }
    }

    /**
     * @notice Returns all product names
     */
    function getProductNames() public view returns (string[] memory) {
        return productNames;
    }

    /**
     * @notice Operator admin has the ability to create a new product
     * @param productName is the name of the new product
     * @param product is the address of the product
     */
    function addProduct(string memory productName, address product) public onlyRole(OPERATOR_ADMIN_ROLE) {
        require(product != address(0), "400:IA");
        if (products[productName] == address(0)) {
            productNames.push(productName);
        }
        products[productName] = product;
        emit ProductAdded(productName, product);
    }

    /**
     * @notice Operator admin has the ability to remove products
     * @param productName is the name of the product to be removed
     */
    function removeProduct(string memory productName) public onlyRole(OPERATOR_ADMIN_ROLE) {
        bool found = false;
        uint256 index = 0;
        for (uint256 i = 0; i < productNames.length; i++) {
            if (keccak256(abi.encodePacked(productNames[i])) == keccak256(abi.encodePacked(productName))) {
                index = i;
                found = true;
            }
        }
        if (found) {
            // Swap last element with element at index, then pop to delete product
            productNames[index] = productNames[productNames.length - 1];
            productNames.pop();
            delete products[productName];
            emit ProductRemoved(productName);
        }
    }

    /**
     * @notice Operator admin can toggle whether trade with market maker
     * @param marketMaker is the address of the market maker
     * @param allow is whether funds can be sent to that market maker
     */
    function updateMarketMakerPermission(address marketMaker, bool allow) public onlyRole(OPERATOR_ADMIN_ROLE) {
        require(marketMaker != address(0), "400:IA");
        marketMakerAllowList[marketMaker] = allow;
        emit MarketMakerPermissionUpdated(marketMaker, allow);
    }

    /**
     * @notice Only default admin can set the fee recipient
     * @param _feeRecipient is the address of the fee recipient
     */
    function setFeeRecipient(address _feeRecipient) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_feeRecipient != address(0), "400:IA");
        feeRecipient = _feeRecipient;
        emit FeeRecipientUpdated(_feeRecipient);
    }

    /**
     * @notice Moves assets to corresponding product and vault account
     * @param productName is the name of the product
     * @param vaultAddress is the address of the vault
     */
    function moveAssetsToProduct(
        string memory productName,
        address vaultAddress,
        uint256 amount
    ) public onlyRole(TRADER_ADMIN_ROLE) {
        address productAddress = products[productName];
        require(productAddress != address(0), "400:PN");

        IFCNProduct fcnProduct = IFCNProduct(productAddress);
        IERC20(fcnProduct.asset()).approve(productAddress, amount);
        fcnProduct.receiveAssetsFromCegaState(vaultAddress, amount);
        emit AssetsMovedToProduct(productName, vaultAddress, amount);
    }
}