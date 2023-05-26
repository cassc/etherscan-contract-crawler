// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract IslandERC1155 is ERC1155, Ownable {
    address private _signer;
    string private _baseURI = "https://ipfs.io/ipfs/";
    mapping(uint256 => uint256) private tokenCount;
    mapping(uint256 => string) public tokenMetadata; // Id to IPFS hash
    mapping(uint256 => bool) private usedNonces;

    constructor(address signer) ERC1155("https://ipfs.io/ipfs/") {
        _signer = signer;
    }

    function updateSigner(address newSigner) external onlyOwner {
        _signer = newSigner;
    }

    function mint(address to, uint256 id, uint256 amount, uint256 nonce, string memory metadata, uint8 v, bytes32 r, bytes32 s)
        external {
        require(usedNonces[nonce] == false, "can't use the same signature twice");
        usedNonces[nonce] = true;

        bytes32 payloadHash = keccak256(abi.encode(to, id, amount, nonce));
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", payloadHash));
        address recovered = ecrecover(messageHash, v, r, s);
        // Nifty Island must sign off on every mint
        require(recovered == _signer, "Signature failed to recover");

        _mint(to, id, amount, "");
        tokenCount[id] += amount;
        tokenMetadata[id] = metadata;
    }

    function updateMetadata(uint256 tokenId, string memory metadata)
        external
        onlyOwner {
        require(tokenCount[tokenId] > 0, "Token does not exist");
        tokenMetadata[tokenId] = metadata;
    }

    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    function updateBaseURI(string memory newURI) external onlyOwner {
        _baseURI = newURI;
    }

    function uri(uint256 id) public view override returns (string memory) {
        require(tokenCount[id] > 0, "token does not exist");
        string memory base = baseURI();
        return bytes(base).length > 0 ? string(abi.encodePacked(base, tokenMetadata[id])) : ""; 
    }
}