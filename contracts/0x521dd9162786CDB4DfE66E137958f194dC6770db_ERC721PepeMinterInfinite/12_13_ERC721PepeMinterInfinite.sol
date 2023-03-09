// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC721PepeV3.sol";


contract ERC721PepeMinterInfinite is Ownable {

    bytes32 private PEPEOBJECT_TYPEHASH = keccak256("PepeObject(address userAddress,uint256 timestamp,uint256 imageHash)");
    bytes32 public DOMAIN_SEPARATOR;

    address public ogPepeContract;
    address public infinitePepeContract;
    uint256 public ogCollectionDeadline;
    uint256 public ogCollectionMax;
    address public authorizedSigningAddress;
    uint256 public signatureExpireSeconds;

    constructor(
        address _authorizedSigningAddress,
        uint256 _signatureExpireSeconds,
        uint256 _ogCollectionDeadline,
        uint256 _ogCollectionMax
    ) {
        authorizedSigningAddress = _authorizedSigningAddress;
        signatureExpireSeconds = _signatureExpireSeconds;

        DOMAIN_SEPARATOR = keccak256(abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256("McPepe's"),
                keccak256("1"),
                block.chainid,
                this // this contract verifies the signature
            ));

        ogCollectionDeadline = _ogCollectionDeadline;
        ogCollectionMax = _ogCollectionMax;
    }

    function setOgPepeContract(address _ogPepeContract) external onlyOwner {
        ogPepeContract = _ogPepeContract;
    }

    function setInfinitePepeContract(address _infinitePepeContract) external onlyOwner {
        infinitePepeContract = _infinitePepeContract;
    }

    function setOgCollectionDeadline(uint256 _ogCollectionDeadline) external onlyOwner {
        ogCollectionDeadline = _ogCollectionDeadline;
    }

    function setOgCollectionMax(uint256 _ogCollectionMax) external onlyOwner {
        ogCollectionMax = _ogCollectionMax;
    }

    function setAuthorizedSigningAddress(address signer) external onlyOwner {
        authorizedSigningAddress = signer;
    }

    function setSignatureExpireSeconds(uint256 expireSeconds) external onlyOwner {
        signatureExpireSeconds = expireSeconds;
    }

    function splitSignature(bytes memory sig) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(sig.length == 65, "bad signature length");

        assembly {
        // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
        // second 32 bytes.
            s := mload(add(sig, 64))
        // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function mint(uint256 timestamp, uint256 imageHash, bytes memory signature) external {
        // Split signature into main components
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = splitSignature(signature);

        bytes32 hashStruct = keccak256(
            abi.encode(
                PEPEOBJECT_TYPEHASH,
                msg.sender,
                timestamp,
                imageHash
            )
        );

        // 1. hashing the data (above is part of this) and generating the hashes
        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct));

        // 2. use the data hashes and the signature to generate the public key of the signer using ecrecover method
        address signer = ecrecover(hash, v, r, s);
        require(signer == authorizedSigningAddress, "invalid signature");
        require(signer != address(0), "signature 0x0");
        require(timestamp + signatureExpireSeconds > block.timestamp, "signature expired");

        // 3. mint pepe to correct contract depending on if OG collection is finished or not
        if (IERC721PepeV3(ogPepeContract).tokenId() > ogCollectionMax || block.timestamp > ogCollectionDeadline) {
            IERC721PepeV3(infinitePepeContract).mint(msg.sender, imageHash);
        } else {
            IERC721PepeV3(ogPepeContract).mint(msg.sender, imageHash);
        }
    }
}