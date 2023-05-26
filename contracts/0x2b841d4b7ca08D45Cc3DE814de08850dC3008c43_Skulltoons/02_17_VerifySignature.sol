// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract VerifySignature is Ownable {
    using ECDSA for bytes32;
    
    string private signVersion;
    address private signer;

    constructor(string memory _signVersion, address _signer){
        signVersion = _signVersion;
        signer = _signer;
    }

    function updateSignVersion(string calldata _signVersion) external onlyOwner {
        signVersion = _signVersion;
    }

    function updateSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function _verify(address _sender, uint256 _amount, bytes memory _signature) internal view returns (bool) {
        return keccak256(abi.encodePacked(_sender, signVersion, _amount))
            .toEthSignedMessageHash()
            .recover(_signature) == signer;
    }

    function _verify(address _sender, uint256 _amount, uint256 _nonce, bytes memory _signature) internal view returns (bool) {
        return keccak256(abi.encodePacked(_sender, signVersion, _amount, _nonce))
            .toEthSignedMessageHash()
            .recover(_signature) == signer;
    }
}