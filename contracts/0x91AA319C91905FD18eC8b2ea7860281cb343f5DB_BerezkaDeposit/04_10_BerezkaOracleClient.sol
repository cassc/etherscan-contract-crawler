// SPDX-License-Identifier: Unlicense
// Developed by EasyChain Blockchain Development Team (easychain.tech)
//
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BerezkaOracleClient is Ownable {
    // Address of Oracle
    //
    address public oracleAddress = 0xAb66dE3DF08318922bb4cE15553E4C2dCf9187A1;

    // Signature expiration time
    //
    uint256 public signatureValidityDuractionSec = 3600;

    modifier withValidOracleData(
        address _token,
        uint256 _optimisticPrice,
        uint256 _optimisticPriceTimestamp,
        bytes memory _signature
    ) {
        // Check price is not Zero
        //
        require(_optimisticPrice > 0, "ZERO_OPTIMISTIC_PRICE");

        // Check that signature is not expired and is valid
        //
        require(
            isValidSignatureDate(_optimisticPriceTimestamp),
            "EXPIRED_PRICE_DATA"
        );

        require(
            isValidSignature(
                _optimisticPrice,
                _optimisticPriceTimestamp,
                _token,
                _signature
            ),
            "INVALID_SIGNATURE"
        );

        _;
    }

    function isValidSignatureDate(uint256 _optimisticPriceTimestamp)
        public
        view
        returns (bool)
    {
        return computeSignatureDateDelta(_optimisticPriceTimestamp) <= signatureValidityDuractionSec;
    }

    function computeSignatureDateDelta(uint256 _optimisticPriceTimestamp)
        public
        view
        returns (uint256)
    {
        uint256 timeDelta = 0;
        if (_optimisticPriceTimestamp >= block.timestamp) {
            timeDelta = _optimisticPriceTimestamp - block.timestamp;
        } else {
            timeDelta = block.timestamp - _optimisticPriceTimestamp;
        }
        return timeDelta;
    }

    // Validates oracle price signature
    //
    function isValidSignature(
        uint256 _price,
        uint256 _timestamp,
        address _token,
        bytes memory _signature
    ) public view returns (bool) {
        return recover(_price, _timestamp, _token, _signature) == oracleAddress;
    }

    // Validates oracle price signature
    //
    function recover(
        uint256 _price,
        uint256 _timestamp,
        address _token,
        bytes memory _signature
    ) public pure returns (address) {
        bytes32 dataHash = keccak256(
            abi.encodePacked(_price, _timestamp, _token)
        );
        bytes32 signedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)
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

    // Adds possible tokens (stableconins) to withdraw to
    // _whitelisted - list of stableconins to withdraw to
    //
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
    }
}