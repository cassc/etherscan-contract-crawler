/**
 *Submitted for verification at BscScan.com on 2023-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Token {
    mapping(address => uint) saldos;
    mapping(address => mapping(address => uint)) asignacion;
    uint public totalSupply = 1000000000000000000 * 10 ** 18;
    string public name = "Pepe Killer";
    string public symbol = "PEPEKI";
    uint public decimals = 18;
    address public owner;
    
    event Transfer(address indexed desde, address indexed a, uint valor);
    event Approval(address indexed propietario, address indexed gastador, uint valor);
    event OwnershipRenounced(address indexed previousOwner);
    
    constructor() {
        owner = msg.sender;
        saldos[msg.sender] = totalSupply;
    }
    
    function balanceOf(address propietario) public view returns (uint) {
        return saldos[propietario];
    }
    
    function transfer(address a, uint valor) public returns (bool) {
        require(saldos[msg.sender] >= valor, 'saldo demasiado bajo');
        saldos[a] += valor;
        saldos[msg.sender] -= valor;
        emit Transfer(msg.sender, a, valor);
        return true;
    }
    
    function transferFrom(address de, address a, uint valor) public returns (bool) {
        require(balanceOf(de) >= valor, 'saldo demasiado bajo');
        require(asignacion[de][msg.sender] >= valor, 'asignacion demasiado baja');
        saldos[a] += valor;
        saldos[de] -= valor;
        emit Transfer(de, a, valor);
        return true;
    }
    
    function approve(address gastador, uint valor) public returns (bool) {
        asignacion[msg.sender][gastador] = valor;
        emit Approval(msg.sender, gastador, valor);
        return true;
    }
    
    function renunciarPropiedad() public {
        require(msg.sender == owner, 'Solo el propietario puede renunciar');
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
}