// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
 * @title Alkimiya Oracle Addresses
 * @author Alkimiya Team
 * */
interface IOracleRegistry {
    event OracleRegistered(address token, uint256 oracleType, address oracleAddr);

    function getOracleAddress(address _token, uint256 _oracleType) external view returns (address);
}