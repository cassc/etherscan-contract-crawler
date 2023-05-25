// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// @author: miinded.com

abstract contract MekaVerseAllowed is Ownable {

    // contract => collection => allowed
    mapping(address => mapping( uint256 => bool)) public allowedContracts;

    modifier isMekaContract(uint256 _collectionId) {
        require(isAllowed(_msgSender(), _collectionId), "Not allowed");
        _;
    }

    function isAllowed(address _contract, uint256 _collectionId) public view returns(bool) {
        return allowedContracts[_contract][_collectionId] == true;
    }
    
    function setAllowedContract(address _contract, uint256[] memory _collectionIds, bool _allowed) public onlyOwner {
        for(uint256 i = 0; i < _collectionIds.length; i++){
            allowedContracts[_contract][ _collectionIds[i] ] = _allowed;
        }
    }

}