// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./Admins.sol";

// @author: miinded.com

abstract contract Signature is Admins{
    using BitMaps for BitMaps.BitMap;

    uint256 public HASH_SIGN;

    address public signAddress;
    BitMaps.BitMap private signatureIds;

    modifier signedNotUnique(bytes32 _hash, bytes memory _signature){
        require(checkSignature(_hash, _signature) == signAddress, "Signature error : bad result");
        _;
    }
    modifier signedUnique(bytes32 _hash, uint256 _signatureId, bytes memory _signature){
        require(signatureIds.get(_signatureId) == false, "Signature already used");
        require(checkSignature(_hash, _signature) == signAddress, "Signature error : bad result");
        signatureIds.set(_signatureId);
        _;
    }

    function setHashSign(uint256 _hash) public virtual onlyOwnerOrAdmins {
        HASH_SIGN = _hash;
    }

    function setSignAddress(address _signAddress) public virtual onlyOwnerOrAdmins {
        signAddress = _signAddress;
    }

    function checkSignature(bytes32 _hash, bytes memory _signature) public pure virtual returns (address) {
        return ECDSA.recover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)), _signature);
    }
}