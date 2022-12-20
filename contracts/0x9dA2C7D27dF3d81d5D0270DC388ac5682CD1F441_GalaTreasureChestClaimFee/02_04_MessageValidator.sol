// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';

contract MessageValidator is Ownable {
    address public signerAddress;
    uint256 public blockMaxThreshold = 10;

    function setSignerAddress(address _signer) public onlyOwner {
        signerAddress = _signer;
    }

    modifier isValidMessage(
        string memory refId,
        uint256 amount,
        uint256 blockSigned,
        bytes memory sig,
        uint256 value
    ) {
        bytes32 message = keccak256(
            abi.encodePacked(refId, amount, blockSigned)
        );
        require(
            recoverSigner(message, sig) == signerAddress,
            'Invalid signature'
        );
        require(
            (block.number - blockSigned) <= blockMaxThreshold,
            'Signature expired'
        );
        require(value >= amount, 'Invalid amount');
        _;
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65, 'Signature must be 65 bytes long');
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function setBlockMaxThreshold(uint256 _blockThreshold) public onlyOwner {
        blockMaxThreshold = _blockThreshold;
    }
}