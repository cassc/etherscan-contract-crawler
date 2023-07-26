// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ECDSASigner is Ownable {
    address private _signer;

    constructor(address signer_) {
        require(signer_ != address(0), "ECDSASign: signer_ is zero address");
        _signer = signer_;
    }

    /// @notice isValidSignature validates a message by ecrecover to ensure
    //          it is signed by signer.
    /// @param message_ - the raw message for signing
    /// @param r_ - part of signature for validating parameters integrity
    /// @param s_ - part of signature for validating parameters integrity
    /// @param v_ - part of signature for validating parameters integrity
    function isValidSignature(
        bytes32 message_,
        bytes32 r_,
        bytes32 s_,
        uint8 v_
    ) internal view returns (bool) {
        address reqSigner = ECDSA.recover(
            ECDSA.toEthSignedMessageHash(message_),
            v_,
            r_,
            s_
        );
        return reqSigner == _signer;
    }

    /// @notice set the signer
    /// @param signer_ - the address of signer
    function setSigner(address signer_) external onlyOwner {
        require(signer_ != address(0), "ECDSASign: signer_ is zero address");
        _signer = signer_;
    }

    function signer() external view returns (address) {
        return _signer;
    }
}