// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC721Dogelon.sol";

contract ERC721DogelonMinter is Ownable {

    bytes32 private DOGELON_OBJECT_MINT_TYPEHASH = keccak256("DogelonObjectMint(address userAddress,uint256 timestamp,uint256 imageHash)");
    bytes32 private DOGELON_OBJECT_UPDATE_IMAGE_TYPEHASH = keccak256("DogelonObjectUpdateImage(address userAddress,uint256 timestamp,uint256 newImageHash,uint256 tokenId)");
    bytes32 public DOMAIN_SEPARATOR;

    address public baseContract;
    address public authorizedSigningAddress;
    uint256 public signatureExpireSeconds;

    constructor(address _authorizedSigningAddress, uint256 _signatureExpireSeconds) {
        authorizedSigningAddress = _authorizedSigningAddress;
        signatureExpireSeconds = _signatureExpireSeconds;

        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256("Dogelon"), // name
            keccak256("1"), // version
            block.chainid,
            this // this contract verifies the signature
        ));
    }

    function setBaseContract(address _baseContract) external onlyOwner {
        baseContract = _baseContract;
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

    function mint(uint256 timestamp, uint256 imageHash, bytes memory signature, bytes32[] calldata merkleProof, uint256 whitelistQuantity) external payable {
        // Split signature into main components
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = splitSignature(signature);

        bytes32 hashStruct = keccak256(
            abi.encode(
                DOGELON_OBJECT_MINT_TYPEHASH,
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

        // 3. mint image, checking imageHash is not already existing
        IERC721Dogelon(baseContract).mint{value: msg.value}(msg.sender, imageHash, merkleProof, whitelistQuantity);
    }

    function updateImage(uint256 timestamp, uint256 newImageHash, uint256 tokenId, bytes memory signature) external {
         // Split signature into main components
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = splitSignature(signature);

        bytes32 hashStruct = keccak256(
            abi.encode(
                DOGELON_OBJECT_UPDATE_IMAGE_TYPEHASH,
                msg.sender,
                timestamp,
                newImageHash,
                tokenId
            )
        );

        // 1. hashing the data (above is part of this) and generating the hashes
        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct));

        // 2. use the data hashes and the signature to generate the public key of the signer using ecrecover method
        address signer = ecrecover(hash, v, r, s);
        require(signer == authorizedSigningAddress, "invalid signature");
        require(signer != address(0), "signature 0x0");
        require(timestamp + signatureExpireSeconds > block.timestamp, "signature expired");

        // 3. mint image, checking imageHash is not already existing
        IERC721Dogelon(baseContract).updateImage(msg.sender, newImageHash, tokenId);
    }
}