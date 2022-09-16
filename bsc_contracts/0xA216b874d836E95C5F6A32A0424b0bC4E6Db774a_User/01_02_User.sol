// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Import this file to use console.log
//import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract User is Context {
    mapping(address => address[]) public _children;
    mapping(address => bool) public _register;
    mapping(address => address) public _father;

    event Father(address father, address child);

    constructor(){
        _register[_msgSender()] = true;
    }

    function register(address father) public {
        require(_register[father], "erro code");
        _register[_msgSender()] = true;
        _children[father].push(_msgSender());
        _father[_msgSender()] = father;

        emit Father(father, _msgSender());
    }

    function fatherLength(address user) public view returns (uint){
        return _children[user].length;
    }

}