// SPDX-License-Identifier: MIT

// Based on OpenZeppelin ERC1271WalletMock.sol 
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/7f6a1666fac8ecff5dd467d0938069bc221ea9e0/contracts/mocks/ERC1271WalletMock.sol
pragma solidity 0.6.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/IERC1271.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";

contract ERC1271WalletMock is Ownable, IERC1271 {
    constructor(address originalOwner) public {
        transferOwnership(originalOwner);
    }

    function isValidSignature(bytes32 hash, bytes memory signature) public view override returns (bytes4 magicValue) {
        return ECDSA.recover(hash, signature) == owner() ? this.isValidSignature.selector : bytes4(0);
    }
}