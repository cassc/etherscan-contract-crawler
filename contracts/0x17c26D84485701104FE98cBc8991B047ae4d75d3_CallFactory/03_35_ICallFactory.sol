// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

interface ICallFactory {
    event PoolCreated(
        address indexed erc721token,
        address oracle,
        address pool,
        address premium,
        address ntoken,
        address calltoken);
    
    function getPool(address erc721token) external view returns (address pool);
    function createPool(address erc721token, address oracle, address premium) external returns (address pool);
}