// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC721MintGo.sol";


contract ERC721MintGoMinterInfinite is Ownable {

    bytes32 private MGOBJECT_TYPEHASH = keccak256("MGObject(address userAddress,uint256 timestamp,string tokenHash)");
    bytes32 public DOMAIN_SEPARATOR;

    address public ogMGContract;
    address public infiniteMGContract;
    uint256 public ogCollectionDeadline;
    uint256 public ogCollectionMax;
    address public authorizedSigningAddress;
    uint256 public signatureExpireSeconds;
    uint256 public fee;

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
                keccak256("MintGo"),
                keccak256("1"),
                block.chainid,
                this // this contract verifies the signature
            ));

        ogCollectionDeadline = _ogCollectionDeadline;
        ogCollectionMax = _ogCollectionMax;
    }

    function setOgMGContract(address _ogMGContract) external onlyOwner {
        ogMGContract = _ogMGContract;
    }

    function setInfiniteMGContract(address _infiniteMGContract) external onlyOwner {
        infiniteMGContract = _infiniteMGContract;
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

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function withdraw(address payable _to) external onlyOwner {
        uint256 balance = address(this).balance;
        _to.transfer(balance);
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

    function mint(uint256 timestamp, string memory tokenHash, bytes memory signature) external payable {
        // Split signature into main components
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = splitSignature(signature);

        bytes32 hashStruct = keccak256(
            abi.encode(
                MGOBJECT_TYPEHASH,
                msg.sender,
                timestamp,
                keccak256(bytes(tokenHash))
            )
        );

        // 1. hashing the data (above is part of this) and generating the hashes
        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct));

        // 2. use the data hashes and the signature to generate the public key of the signer using ecrecover method
        address signer = ecrecover(hash, v, r, s);
        require(signer == authorizedSigningAddress, "invalid signature");
        require(signer != address(0), "signature 0x0");
        require(timestamp + signatureExpireSeconds > block.timestamp, "signature expired");
        require(msg.value >= fee, "Not enough ether sent to cover the fee");

        // 3. mint mintGo to correct contract depending on if OG collection is finished or not
        if (IERC721MintGo(ogMGContract).tokenId() > ogCollectionMax || block.timestamp > ogCollectionDeadline) {
            IERC721MintGo(infiniteMGContract).mint(msg.sender, tokenHash);
        } else {
            IERC721MintGo(ogMGContract).mint(msg.sender, tokenHash);
        }
    }
}