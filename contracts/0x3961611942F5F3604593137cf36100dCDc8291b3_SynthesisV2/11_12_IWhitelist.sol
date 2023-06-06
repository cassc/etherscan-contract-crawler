// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;


interface IWhitelist {

    enum TokenState { NotSet, InOut }
    enum PoolState { NotSet, AddSwapRemove }

    struct TokenStatus {
        address token;
        uint256 min;
        uint256 max;
        uint256 bridgeFee;
        TokenState state;
    }

    struct PoolStatus {
        address pool;
        uint256 aggregationFee;
        PoolState state;
    }
    
    function tokenMin(address token) external view returns (uint256);
    function tokenMax(address token) external view returns (uint256);
    function tokenMinMax(address token) external view returns (uint256, uint256);
    function bridgeFee(address token) external view returns (uint256);
    function tokenState(address token) external view returns (uint8);
    function tokenStatus(address token) external view returns (TokenStatus memory);
    function tokens(uint256 offset, uint256 count) external view returns (TokenStatus[] memory);

    function aggregationFee(address pool) external view returns (uint256);
    function poolState(address pool) external view returns (uint8);
    function poolStatus(address pool) external view returns (PoolStatus memory);
    function pools(uint256 offset, uint256 count) external view returns (PoolStatus[] memory);

}