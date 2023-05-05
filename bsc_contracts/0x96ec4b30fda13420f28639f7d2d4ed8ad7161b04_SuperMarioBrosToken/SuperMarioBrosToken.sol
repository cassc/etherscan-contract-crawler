/**
 *Submitted for verification at BscScan.com on 2023-05-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Super Mario Bros Token (SMB)
 * @dev Implementación del estándar de token BEP20 con ciertas modificaciones.
 *      No permite la transferencia ni venta de tokens por parte de los usuarios.
 *      El único que puede realizar transferencias y ventas es el propietario del contrato.
 */
contract SuperMarioBrosToken {
    string public constant name = "Super Mario Bros"; // Nombre del token
    string public constant symbol = "SMB"; // Símbolo del token
    uint8 public constant decimals = 18; // Decimales del token
    uint256 public totalSupply = 1000000000 * 10**uint256(decimals); // Total de tokens creados

    address public owner; // Dirección del propietario del contrato

    // Mapping para guardar los saldos de los usuarios
    mapping(address => uint256) private balances;

    // Eventos para notificar las transferencias y quemas de tokens
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    /**
     * @dev Constructor que asigna la dirección del propietario del contrato
     *      y los tokens creados al creador del contrato.
     */
    constructor() {
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    /**
     * @dev Función que devuelve el saldo de una dirección.
     * @param _owner La dirección de la cual se quiere obtener el saldo.
     */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    /**
     * @dev Función que permite transferir tokens a otra dirección.
     *      Solo puede ser llamada por el propietario del contrato.
     * @param _to La dirección a la cual se quiere transferir los tokens.
     * @param _value La cantidad de tokens a transferir.
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0)); // La dirección destino no puede ser nula
        require(_value <= balances[msg.sender]); // El balance del emisor debe ser mayor o igual al valor a transferir

        balances[msg.sender] -= _value; // Se resta el valor a transferir del balance del emisor
        balances[_to] += _value; // Se suma el valor a transferir al balance del destinatario

        emit Transfer(msg.sender, _to, _value); // Se emite el evento de transferencia exitosa

        return true;
    }

    /**
     * @dev Función que quema una cantidad de tokens.
     *      Solo puede ser llamada por el propietario del contrato.
     * @param _value La cantidad de tokens a quemar.
     */
    function burn(uint256 _value) public returns (bool success) {
    require(balances[msg.sender] >= _value); // El balance del emisor debe ser mayor o igual al valor a quemar

    balances[msg.sender] -= _value; // Se resta el valor a quemar del balance del emisor
    totalSupply -= _value;
    emit Burn(msg.sender, _value); // Se emite el evento de quema de tokens exitosa

    return true;
    }
}