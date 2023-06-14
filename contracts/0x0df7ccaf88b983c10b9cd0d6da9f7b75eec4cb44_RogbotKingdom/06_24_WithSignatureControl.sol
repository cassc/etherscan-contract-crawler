// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
 

abstract contract WithSignatureControl is Ownable {

    using ECDSA for bytes32;

    address public signerAddress;
    bool internal _bypassSignatureChecking = false;
    mapping(bytes => uint256) internal _ticketUsed;

     // emergency bypass signature checking
    function updateBypassSignatureChecking(bool _status) external onlyOwner {
        _bypassSignatureChecking = _status;
    }

    // update signer address
    function updateSignerAddress(address _address) external onlyOwner {
        signerAddress = _address;
    }

    // validate signature address
    function isSignedBySigner(
        address _sender,
        bytes memory _ticket,
        bytes memory _signature,
        address signer
    ) internal view returns (bool) {
        if (_bypassSignatureChecking) {
            return true;
        } else {
            bytes32 hash = keccak256(abi.encodePacked(_sender, _ticket));
            return signer == hash.recover(_signature);
        }
    }
    

}