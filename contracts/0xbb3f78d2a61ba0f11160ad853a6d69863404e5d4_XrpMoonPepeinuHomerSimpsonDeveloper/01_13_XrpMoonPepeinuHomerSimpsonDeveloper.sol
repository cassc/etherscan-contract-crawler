// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


contract XrpMoonPepeinuHomerSimpsonDeveloper is ERC721, Ownable {

    bytes32 private XphOBJECT_TYPEHASH = keccak256("XphObject(address userAddress,uint256 timestamp)");
    bytes32 public DOMAIN_SEPARATOR;

    address public authorizedSigningAddress;
    uint256 public signatureExpireSeconds;
    string public baseURI = "";
    uint256 public tokenId = 1;

    constructor(
        string memory name_,
        string memory symbol_,
        address _authorizedSigningAddress,
        uint256 _signatureExpireSeconds,
        string memory baseURI_
    ) ERC721(name_, symbol_) {
        authorizedSigningAddress = _authorizedSigningAddress;
        signatureExpireSeconds = _signatureExpireSeconds;
        baseURI = baseURI_;

        DOMAIN_SEPARATOR = keccak256(abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256("Xph"),
                keccak256("1"),
                block.chainid,
                this // this contract verifies the signature
            ));

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

    function toString(uint256 value) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory data = abi.encodePacked(value);
        bytes memory str = new bytes(1);
        uint i = data.length - 1;
        str[0] = alphabet[uint(uint8(data[i] & 0x0f))];
        return string(str);
    }


    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        _requireMinted(_tokenId);

        string memory hashStr = toString(_tokenId);
        return string(abi.encodePacked(baseURI, hashStr, ".json"));
    }

    function mint(uint256 timestamp, bytes memory signature) external {
        // Split signature into main components
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = splitSignature(signature);

        bytes32 hashStruct = keccak256(
            abi.encode(
                XphOBJECT_TYPEHASH,
                msg.sender,
                timestamp
            )
        );

        // 1. hashing the data (above is part of this) and generating the hashes
        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct));

        // 2. use the data hashes and the signature to generate the public key of the signer using ecrecover method
        address signer = ecrecover(hash, v, r, s);
        require(signer == authorizedSigningAddress, "invalid signature");
        require(signer != address(0), "signature 0x0");
        require(timestamp + signatureExpireSeconds > block.timestamp, "signature expired");


        _mint(msg.sender, tokenId++);
    }
}