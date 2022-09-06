// SPDX-License-Identifier: MIT
// Decontracts Protocol. @2022
pragma solidity >=0.8.14;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IFundManager} from "../interfaces/fund/IFundManager.sol";
import {IFundFilter, FundFilterInitializeParams} from "../interfaces/fund/IFundFilter.sol";
import {Errors} from "../libraries/Errors.sol";

contract FundFilter is IFundFilter, Initializable, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Contract version
    uint256 public constant version = 1;

    //////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////// CONTRACT ADDRESSES /////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////

    address public override priceOracle;
    address public override swapRouter;
    address public override positionManager;
    address public override positionViewer;
    address public override protocolAdapter;

    //////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////// MANAGER SETTINGS //////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////

    // Historical allowed tokens for underlying
    EnumerableSet.AddressSet private _allowedUnderlyingTokens;

    // Historical allowed tokens for swap
    EnumerableSet.AddressSet private _allowedTokens;

    // Historical allowed protocols for execute order
    EnumerableSet.AddressSet private _allowedProtocols;

    // Min allowed management fee
    uint256 public override minManagementFee;

    // Max allowed management fee
    uint256 public override maxManagementFee;

    // Min allowed carried interest
    uint256 public override minCarriedInterest;

    // Max allowed carried interest
    uint256 public override maxCarriedInterest;

    // Dao address
    address public override daoAddress;

    // Dao profit
    uint256 public override daoProfit;

    function initialize(FundFilterInitializeParams calldata params) external initializer {
        require(
            params.minManagementFee <= maxManagementFee &&
                params.maxManagementFee <= 1e4 &&
                params.minCarriedInterest <= maxCarriedInterest &&
                params.maxCarriedInterest <= 1e4,
            Errors.InvalidInitializeParams
        );
        priceOracle = params.priceOracle;
        swapRouter = params.swapRouter;
        positionManager = params.positionManager;
        positionViewer = params.positionViewer;
        protocolAdapter = params.protocolAdapter;

        for (uint256 i = 0; i < params.allowedUnderlyingTokens.length; i++) {
            updateUnderlyingToken(params.allowedUnderlyingTokens[i], true);
        }
        for (uint256 i = 0; i < params.allowedTokens.length; i++) {
            updateToken(params.allowedTokens[i], true);
        }
        for (uint256 i = 0; i < params.allowedProtocols.length; i++) {
            updateProtocol(params.allowedProtocols[i], true);
        }

        minManagementFee = params.minManagementFee;
        maxManagementFee = params.maxManagementFee;
        minCarriedInterest = params.minCarriedInterest;
        maxCarriedInterest = params.maxCarriedInterest;
        daoAddress = params.daoAddress;
        daoProfit = params.daoProfit;
    }

    function allowedUnderlyingTokens() external view override returns (address[] memory) {
        return _allowedUnderlyingTokens.values();
    }

    function isUnderlyingTokenAllowed(address token) public view override returns (bool) {
        return _allowedUnderlyingTokens.contains(token);
    }

    function allowedTokens() external view override returns (address[] memory) {
        return _allowedTokens.values();
    }

    function isTokenAllowed(address token) public view override returns (bool) {
        return _allowedTokens.contains(token);
    }

    function allowedProtocols() external view override returns (address[] memory) {
        return _allowedProtocols.values();
    }

    function isProtocolAllowed(address protocol) public view override returns (bool) {
        return _allowedProtocols.contains(protocol);
    }

    function updateUnderlyingToken(address token, bool allow) public onlyOwner {
        if (token != address(0)) {
            if (allow) {
                _allowedUnderlyingTokens.add(token);
            } else {
                _allowedUnderlyingTokens.remove(token);
            }
            emit AllowedUnderlyingTokenUpdated(token, allow);
        }
    }

    function updateToken(address token, bool allow) public onlyOwner {
        if (token != address(0)) {
            if (allow) {
                _allowedTokens.add(token);
            } else {
                _allowedTokens.remove(token);
            }
            emit AllowedTokenUpdated(token, allow);
        }
    }

    function updateProtocol(address protocol, bool allow) public onlyOwner {
        if (protocol != address(0)) {
            if (allow) {
                _allowedProtocols.add(protocol);
            } else {
                _allowedProtocols.remove(protocol);
            }
            emit AllowedProtocolUpdated(protocol, allow);
        }
    }

    function updateManagementFee(uint256 min, uint256 max) external onlyOwner {
        require(min <= max && max <= 1e4, Errors.InvalidUpdateParams);
        minManagementFee = min;
        maxManagementFee = max;
    }

    function updateCarriedInterest(uint256 min, uint256 max) external onlyOwner {
        require(min <= max && max <= 1e4, Errors.InvalidUpdateParams);
        minCarriedInterest = min;
        maxCarriedInterest = max;
    }

    function updateDaoAddress(address dao) external onlyOwner {
        require(dao != address(0), Errors.InvalidZeroAddress);
        daoAddress = dao;
    }

    function updateDaoProfit(uint256 profit) external onlyOwner {
        require(profit <= 1e4, Errors.InvalidUpdateParams);
        daoProfit = profit;
    }

    function updatePositionViewer(address _positionViewer) external onlyOwner {
        positionViewer = _positionViewer;
    }

    function updateProtocolAdapter(address _protocolAdapter) external onlyOwner {
        protocolAdapter = _protocolAdapter;
    }
}