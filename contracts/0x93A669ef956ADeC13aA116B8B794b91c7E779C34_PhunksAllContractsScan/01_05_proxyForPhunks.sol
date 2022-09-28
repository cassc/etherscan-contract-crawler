// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PhunksAllContractsScan is Ownable {

    address public phunksContractAddress;
    address public v3ContractAddress;
    address public internsContractAddress;

    constructor(address _phunksContractAddress, address _v3ContractAddress, address _internsContractAddress) {

        // 0xf07468ead8cf26c752c676e43c814fee9c8cf402
        phunksContractAddress = _phunksContractAddress;

        // 0xb7d405bee01c70a9577316c1b9c2505f146e8842
        v3ContractAddress = _v3ContractAddress;

        // 0xA82F3a61F002F83Eba7D184c50bB2a8B359cA1cE
        internsContractAddress = _internsContractAddress;

    }

    function balanceOf (address _wallet) public view returns (uint256 result) {
        result += IERC721(phunksContractAddress).balanceOf(_wallet);

        if (result > 0) {
            return result;
        } 
        
        result += IERC721(v3ContractAddress).balanceOf(_wallet);

        if (result > 0) {
            return result;
        } 

        result += IERC721(internsContractAddress).balanceOf(_wallet);
        return result;

    }

}