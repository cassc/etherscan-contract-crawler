// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


contract OperationWithSigner is Ownable {    
    using ECDSA for bytes32;

    address private _signerAddress;    
    mapping(address => bool) private _operators;
    
    modifier onlyOperators() {
        require(
            owner() == _msgSender() || _operators[_msgSender()] == true,
            "CALLER_NOT_OPERATOR"
        );
        _;
    }

    function addOperator(address operator) external onlyOperators {
        _operators[operator] = true;
    }   

    function removeOperator(address operator) external onlyOperators {
        _operators[operator] = false;
        delete _operators[operator];
    }    
    
    function setSignerAddress(address newAddress) external onlyOperators {
        _signerAddress = newAddress;
    }

    function getSignerAddress() public view returns (address) {
        return _signerAddress;
    }
}