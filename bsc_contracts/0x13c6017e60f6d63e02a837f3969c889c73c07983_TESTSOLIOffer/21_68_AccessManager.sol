/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev AccessManager limits access to owner allowed addresses.
 * @notice AccessManager mantem uma lista de endereços com acesso permitido e negado. 
 * Exemplo de utilização é o LiqiBrlToken, que só deixa endereços com permissão emitir tokens.
**/
contract AccessManager is Ownable {
    // Address-permission access map
    mapping(address => bool) private accessMap;

    /**
     * @dev Only allow access from specified contracts
     */
    modifier onlyAllowedAddress() {
        require(accessMap[_msgSender()], "Access: sender not allowed");
        _;
    }

    /**
     * @dev Gets if the specified address has access
     * @notice Retorna se o endereço especificado tem acesso
     * @param _address Address to check access
     */
    function getAccess(address _address) public view returns (bool) {
        return accessMap[_address];
    }

    /**
     * @dev Enables access to the specified address
     * @notice Dá permissões de acesso para o endereço especificado
     * @param _address Address to enable access
     */
    function enableAccess(address _address) external onlyOwner {
        // check if the address is empty
        require(_address != address(0), "Address is empty");
        // check if the user already has access
        require(!accessMap[_address], "User already has access");

        // allow the address to access
        accessMap[_address] = true;
    }

    /**
     * @dev Disables access to the specified address
     * @notice Remove permissões de acesso para o endereço especificado
     * @param _address Address to disable access
     */
    function disableAccess(address _address) external onlyOwner {
        // check if the address is empty
        require(_address != address(0), "Address is empty");
        // check if the user already has no access
        require(accessMap[_address], "User already has no access");

        // disallow the address        
        accessMap[_address] = false;
    }
}