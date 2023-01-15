// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

contract PHRHolders is Context, Ownable {
    using ECDSA for bytes32;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    mapping (address => EnumerableSet.Bytes32Set) private _owners;
    mapping (bytes32 => address) private _reverseOwners;
    address private _whiteListedSigner;

    constructor() public
    {
        _whiteListedSigner = owner();
    }

    /**
    * @notice Change white listed signer.
    */
    function setWhiteListedSigner(address newSigner) external onlyOwner
    {
        require(address(newSigner) != address(0), "White listed signer CANNOT be zero address");
        _whiteListedSigner = newSigner;
    }

    /**
    * @notice Creates message from ethAddress and phrAddress and returns hash.
    */
    function _createMessageHash(address ethAddress, string memory phrAddress) pure internal returns (bytes32) {
        return keccak256(abi.encodePacked(ethAddress, phrAddress));
    }

    /**
    * @notice Verifies signature of passed `messageHash` and compares to `account`.
    */
    function _verifySignature(bytes32 messageHash, bytes memory signature, address account) pure internal returns (bool) {
        return messageHash
        .toEthSignedMessageHash()
        .recover(signature) == account;
    }

    /**
    * @notice Checks if `ethAddress` is an owner of `phrAddress`.
    */
    function isPhoreOwner(address ethAddress, string memory phrAddress) view public returns (bool) {
        bytes32 phrAddressHash = keccak256(abi.encode(phrAddress));
        return _owners[ethAddress].contains(phrAddressHash);
    }

    /**
    * @notice Sets owner of `phrAddress` to `ethOwner` if signature is valid.
    */
    function setPhoreOwner(address ethOwner, string memory phrAddress, bytes memory signature) public returns(bool) {
        bytes32 messageHash = _createMessageHash(ethOwner, phrAddress);
        if (_verifySignature(messageHash, signature, _whiteListedSigner) == true) {
            bytes32 phrAddressHash = keccak256(abi.encode(phrAddress));
            if (_reverseOwners[phrAddressHash] != address(0)) {
                address currentOwner = _reverseOwners[phrAddressHash];
                require(_owners[currentOwner].remove(phrAddressHash), "Cannot change current owner");
            }
            _owners[ethOwner].add(phrAddressHash);
            _reverseOwners[phrAddressHash] = ethOwner;
            return true;
        }
        return false;
    }

    /**
    * @notice Sets owner of `phrAddress` to `_msgSender()` if signature is valid.
    */
    function setSenderAsPhoreOwner(string memory phrAddress, bytes memory signature) external returns(bool) {
        return setPhoreOwner(_msgSender(), phrAddress, signature);
    }
}