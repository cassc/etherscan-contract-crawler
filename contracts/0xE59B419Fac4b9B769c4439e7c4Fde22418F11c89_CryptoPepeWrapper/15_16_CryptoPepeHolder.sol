// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ICryptoPepe {
    function transfer(address _to, uint256 _tokenId) external returns (bool);
}

error NotPepeOwner();

contract CryptoPepeHolder {

    address immutable owner;

    constructor(address _owner) {
         owner = _owner;
    }
    
    function transfer(address _cryptoPepeAddress, address _to, uint256 _tokenId) public {
        if(msg.sender != owner)
            revert NotPepeOwner();
        ICryptoPepe pepe = ICryptoPepe(_cryptoPepeAddress);
        pepe.transfer(_to, _tokenId);
    }
}