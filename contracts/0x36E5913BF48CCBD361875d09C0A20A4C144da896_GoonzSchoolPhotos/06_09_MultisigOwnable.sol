//SPDX-License-Identifier: CC0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/*
Opensea only allows EOAs to make changes to collections,
which makes it impossible to use multisigs to secure these NFT contracts
since when you want to make changes you need to transfer ownership to an EOA, who can rug.

This contract establishes a second owner that can change the EOA owner,
this way a multisig can give ownership to an EOA and later claim it back.
*/
abstract contract MultisigOwnable is Ownable {
    address public realOwner;

    constructor() {
        realOwner = msg.sender;
    }

    modifier onlyRealOwner() {
        require(realOwner == msg.sender, "MultisigOwnable: caller is not the real owner");
        _;
    }

    function transferRealOwnership(address newRealOwner) public onlyRealOwner {
        realOwner = newRealOwner;
    }

    function transferLowerOwnership(address newOwner) public onlyRealOwner {
        _transferOwnership(newOwner);
    }
}