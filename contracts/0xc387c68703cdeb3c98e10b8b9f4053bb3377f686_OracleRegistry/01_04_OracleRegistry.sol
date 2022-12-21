// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/oracle/IOracleRegistry.sol";

contract OracleRegistry is Ownable, IOracleRegistry {
    mapping(address => mapping(uint256 => address)) public oracleRegistry;

    /// @notice Function to return the list of Oracle addresses
    function getOracleAddress(address _token, uint256 _oracleType) public view override returns (address) {
        return oracleRegistry[_token][_oracleType];
    }

    /// @notice Set Oracle Addresses
    function setOracleAddress(
        address _token,
        uint256 _oracleType,
        address _oracleAddr
    ) public onlyOwner {
        oracleRegistry[_token][_oracleType] = _oracleAddr;
        emit OracleRegistered(_token, _oracleType, _oracleAddr);
    }
}