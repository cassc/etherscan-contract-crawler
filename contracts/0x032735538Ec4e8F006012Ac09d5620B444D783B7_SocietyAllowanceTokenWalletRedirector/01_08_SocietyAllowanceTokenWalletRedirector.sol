// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
    Smart Contract to store
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SocietyAllowanceTokenWalletRedirector is Ownable, AccessControl
{
    using Strings for string;

    mapping(address => mapping(uint256 => address )) public allowanceReceiver;

    constructor() {
    }

    function updateAllowanceReceiver(uint256 tokenId, address receiver) public {
        require(receiver != address(0), "receiver missing!");
        allowanceReceiver[msg.sender][tokenId] = receiver;
    }

    function resetAllowanceReceiver(uint256[] calldata tokenIds) public {
        uint arrayLength = tokenIds.length;
        for (uint i=0; i<arrayLength; i++) {
            delete allowanceReceiver[msg.sender][tokenIds[i]];
        }
    }

    function getAllowanceReceiver(address owner, uint256 tokenId) external view returns (address){
        if (allowanceReceiver[owner][tokenId] != address(0)) {
            return allowanceReceiver[owner][tokenId];
        } else {
            return allowanceReceiver[owner][0];
        }
    }
}