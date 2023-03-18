// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    MerkleProof
} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import {
    ReentrancyGuard
} from "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import { Address } from "lib/openzeppelin-contracts/contracts/utils/Address.sol";
import { ERC721ContractMetadata } from "./ERC721ContractMetadata.sol";

contract KultDolceKeys is ERC721ContractMetadata, ReentrancyGuard {
    mapping(address => bool) public whitelistMinted;
    bytes32 public whitelistMerkleRoot;
    bool public whitelistMintActive;

    function _canMint(uint256 quantity) internal view {
        require(_totalMinted() <= maxSupply(), "REACHED_MAX_SUPPLY");
        require(quantity > 0, "QUANTITY_LESS_THAN_ONE");
        require(
            _totalMinted() + quantity <= maxSupply(),
            "QUANTITY_EXCEEDED_MAX_SUPPLY"
        );
    }

    constructor(
        string memory name,
        string memory symbol,
        uint256 reserve
    ) ERC721ContractMetadata(name, symbol) {
        _safeMint(msg.sender, reserve);
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    function setMintActive(
        bool _whitelistMintActive
    ) external nonReentrant onlyOwner {
        whitelistMintActive = _whitelistMintActive;
    }

    // Custom mints
    function mintWhitelist(
        bytes32[] calldata whitelistMerkleProof,
        uint256 quantity
    ) external nonReentrant {
        _canMint(quantity);
        require(whitelistMintActive, "WHITELIST_MINT_INACTIVE");
        require(!whitelistMinted[msg.sender], "ALREADY_MINTED");
        require(
            MerkleProof.verify(
                whitelistMerkleProof,
                whitelistMerkleRoot,
                keccak256(abi.encodePacked(msg.sender, quantity))
            ),
            "INVALID_MERKLE_PROOF"
        );

        _safeMint(msg.sender, quantity);

        whitelistMinted[msg.sender] = true;
    }

    function mintTreasury(uint256 quantity) external nonReentrant onlyOwner {
        _canMint(quantity);
        _safeMint(msg.sender, quantity);
    }
}