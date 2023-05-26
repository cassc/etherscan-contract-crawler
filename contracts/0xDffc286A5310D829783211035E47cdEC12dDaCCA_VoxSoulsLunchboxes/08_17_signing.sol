// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Signing is Ownable {
    address public importantAddress;

    constructor(address _importantAddress) {
        importantAddress = _importantAddress;
    }

    /**
     * @notice Set the Important Address for the contract.
     * @param _importantAddress The address of the Important Address.
     */
    function setImportantAddress(address _importantAddress) public onlyOwner {
        importantAddress = _importantAddress;
    }

    /**
     * @notice Return the sign for the given mintTime seconds.
     * @param account The account to check
     * @param _contract The contract address
     * @param mintTime mintTime seconds
     * @param sig The signature
     */
    function isValidData(
        address account,
        address _contract,
        uint256 id,
        uint256 mintTime,
        bytes memory sig
    ) public view returns (bool) {
        bytes32 message = keccak256(
            abi.encodePacked(account, _contract, id, mintTime)
        );
        return (recoverSigner(message, sig) == importantAddress);
    }

    /**
     * @notice Recover the message signer.
     * @param message The message to recover the signer.
     * @param sig The signature.
     */
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

    /**
     * @notice Split the signature into v, r, s.
     * @param sig The signature.
     */
    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65, "Signature must be 65 bytes long");
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
}