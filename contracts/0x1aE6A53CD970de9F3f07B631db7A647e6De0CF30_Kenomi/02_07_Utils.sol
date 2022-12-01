// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Utils is Ownable {

    using ECDSA for bytes32;

    bytes32 zeroByte = 0x0000000000000000000000000000000000000000000000000000000000000000;
    address public signerAddress = address(0xA6088E933E4698169F45b61FA3592288aA36DfDb);

    function setSignerAddress(address _address) external onlyOwner {
        signerAddress = _address;
    }

    function _hashTx(address _address, uint256 _nonce) internal pure returns(bytes32 _hash) {
        _hash = keccak256(abi.encodePacked(_address, _nonce));
    }

    function _getSigner(bytes32 uhash, bytes memory signature) internal pure returns(address _signer) {
        _signer = uhash.toEthSignedMessageHash().recover(signature);
    }

}