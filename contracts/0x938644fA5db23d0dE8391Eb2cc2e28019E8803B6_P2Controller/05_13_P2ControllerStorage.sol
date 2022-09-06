// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./interface/IXToken.sol";
import "./interface/IXNFT.sol";
import "./interface/IOracle.sol";
import "./interface/ILiquidityMining.sol";

contract P2ControllerStorage{

    address public admin;
    address public pendingAdmin;

    bool internal _notEntered;

    struct PoolState{
        bool isListed;
        uint256 borrowCap;
        uint256 supplyCap;
    }
    // xToken => poolState
    mapping(address => PoolState) public poolStates;

    struct CollateralState{
        bool isListed;
        uint256 collateralFactor;
        uint256 liquidateFactor;
        bool isSupportAllPools;
        mapping(address => bool) supportPools;
        // the speical NFT could or not borrow
        // mapping(uint256 => bool) blackList;
    }
    //nft address => state
    mapping(address => CollateralState) public collateralStates;

    // orderId => xToken
    mapping(uint256 => address) public orderDebtStates;

    IXNFT public xNFT;
    IOracle public oracle;
    ILiquidityMining public liquidityMining;

    uint256 internal constant COLLATERAL_FACTOR_MAX = 1e18;
    uint256 internal constant LIQUIDATE_FACTOR_MAX = 1e18;

    mapping(address => mapping(uint256 => bool)) public xTokenPausedMap;
}