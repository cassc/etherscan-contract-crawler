// SPDX-License-Identifier: Unlicense
// Developed by EasyChain Blockchain Development Team (easychain.tech)
//
pragma solidity ^0.4.24;

import "../../contracts/lib/Ownable.sol";

contract WeeziCore is Ownable {
    // Address of Oracle
    //
    address public oracleAddress = 0x94568b630329555Ebc5b2aC8F16b10994422bB42;
    address public feeWalletAddress;
    // Signature expiration time
    //
    uint256 public signatureValidityDuractionSec = 3600;

    event SetOracleAddress(address oracleAddress);
    event SetFeeWalletAddress(address feeWalletAddress);

    function isValidSignatureDate(uint256 _timestamp)
        public
        view
        returns (bool)
    {
        return computeSignatureDateDelta(_timestamp) <= signatureValidityDuractionSec;
    }

    function computeSignatureDateDelta(uint256 _timestamp)
        public
        view
        returns (uint256)
    {
        uint256 timeDelta = 0;
        if (_timestamp >= block.timestamp) {
            timeDelta = _timestamp - block.timestamp;
        } else {
            timeDelta = block.timestamp - _timestamp;
        }
        return timeDelta;
    }

    // Validates oracle price signature
    //
    function isValidSignature(
        bytes32 _hash,
        bytes memory _signature
    ) public view returns (bool) {
        return recover(_hash, _signature) == oracleAddress;
    }

    // Validates oracle price signature
    //
    function recover(
        bytes32 _hash,
        bytes memory _signature
    ) public pure returns (address) {
        bytes32 signedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
        );
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        address signer = ecrecover(signedMessageHash, v, r, s);
        return signer;
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature
            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature
            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    function setSignatureValidityDurationSec(
        uint256 _signatureValidityDuractionSec
    ) public onlyOwner {
        require(_signatureValidityDuractionSec > 0);

        signatureValidityDuractionSec = _signatureValidityDuractionSec;
    }

    // Sets an address of Oracle
    // _oracleAddres - Oracle
    //
    function setOracleAddress(address _oracleAddres) public onlyOwner {
        oracleAddress = _oracleAddres;
        emit SetOracleAddress(_oracleAddres);
    }

    // Sets an address of Fee Wallet
    // _feeWalletAddress - Fee Wallet
    //
    function setFeeWalletAddress(address _feeWalletAddress) public onlyOwner {
        feeWalletAddress = _feeWalletAddress;
        emit SetFeeWalletAddress(_feeWalletAddress);
    }

    function getFeeWalletAddress() view public returns (address) {
        return feeWalletAddress;
    }
}