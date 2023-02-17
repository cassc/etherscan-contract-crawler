/**
 *Submitted for verification at BscScan.com on 2023-02-16
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract NoMorePique {
    // Variables para almacenar el saldo de cada dirección
    mapping (address => uint256) private balances;
    // Variables para almacenar el nombre y la simbología de la moneda
    string public constant name = "NoMorePique";
    string public constant symbol = "NMP";

    // Variables para almacenar la cantidad total de monedas emitidas y la cantidad máxima permitida
    uint256 public totalSupply;
    uint256 public constant maxSupply = 1000000000;

    // Evento para registrar la transferencia de la moneda
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // Función para transferir la moneda de una dirección a otra
    function transfer(address _to, uint256 _value) public {
        require(balances[msg.sender] >= _value && _value > 0, "Error: fondos insuficientes");
        require(_to != address(0), "Error: direccion invalida");
        require(balances[_to] + _value >= balances[_to], "Error: overflow de destinatario");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
    }

    // Función para obtener el saldo de una dirección
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    // Función para inicializar el contrato con la cantidad total de monedas emitidas
    constructor() {
        require(maxSupply > 0, "Error: la cantidad total de monedas emitidas debe ser mayor a cero");
        totalSupply = maxSupply;
        balances[msg.sender] = totalSupply;
    }
}