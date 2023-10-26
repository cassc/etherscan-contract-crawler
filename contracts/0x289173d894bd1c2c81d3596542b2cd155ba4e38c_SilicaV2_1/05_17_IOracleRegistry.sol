/**
     _    _ _    _           _             
    / \  | | | _(_)_ __ ___ (_)_   _  __ _ 
   / _ \ | | |/ / | '_ ` _ \| | | | |/ _` |
  / ___ \| |   <| | | | | | | | |_| | (_| |
 /_/   \_\_|_|\_\_|_| |_| |_|_|\__, |\__,_|
                               |___/        
**/
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title  Oracle Registry Interface
 * @author Alkimiya Team
 * @notice Alkimiya Oracle addresses
 * */
interface IOracleRegistry {

    event OracleRegistered(address token, uint256 oracleType, address oracleAddr);

    function getOracleAddress(address _token, uint256 _oracleType) external view returns (address);

    function setOracleAddress(
        address _token,
        uint256 _oracleType,
        address _oracleAddr
    ) external;
}