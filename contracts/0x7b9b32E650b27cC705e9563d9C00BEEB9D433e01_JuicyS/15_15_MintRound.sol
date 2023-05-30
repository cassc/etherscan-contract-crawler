// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ERC721A} from "erc721a/ERC721A.sol";

abstract contract MintRound is Ownable, EIP712, ReentrancyGuard, ERC721A {
    struct MintRoundQuantity {
        uint64 whitelistMinted;
        uint64 publicMinted;
    }

    struct MintRoundConfig {
        bool whitelistOpen;
        bool publicOpen;
        uint64 whitelistMaxSupply;
        uint64 publicMaxSupply;
        uint64 whitelistMaxEachAddress;
        uint64 publicMaxEachAddress;
        uint256 whitelistPrice;
        uint256 publicPrice;
        address approvalSigner;
    }

    event MintConfigUpdated(MintRoundConfig config);
    event DevMint(uint256 quantity);

    uint256 private maxSupply;
    MintRoundConfig public mintConfig;
    MintRoundQuantity public roundMinted;
    mapping(address => MintRoundQuantity) public addressMinted;

    constructor(uint256 maxSupply_) {
        maxSupply = maxSupply_;
    }

    function setMintRoundConfig(MintRoundConfig calldata config) external onlyOwner {
        mintConfig = config;
        emit MintConfigUpdated(config);
    }

    function whitelistMint(uint64 quantity, bytes calldata signature) external payable nonReentrant {
        require(mintConfig.whitelistOpen, "Whitelist round is not open");
        require(verifyWhitelistMintSignature(quantity, signature), "Invalid approval signature");
        require(roundMinted.whitelistMinted + quantity <= mintConfig.whitelistMaxSupply, "Exceed round's max supply");
        require(totalSupply() + quantity <= maxSupply, "Exceed max supply");
        require(
            addressMinted[_msgSender()].whitelistMinted + quantity <= mintConfig.whitelistMaxEachAddress,
            "Exceed max supply for each address"
        );
        require(msg.value >= mintConfig.whitelistPrice * quantity, "Insufficient paymenet");

        addressMinted[_msgSender()].whitelistMinted += quantity;
        roundMinted.whitelistMinted += quantity;
        _safeMint(_msgSender(), quantity);
    }

    function publicMint(uint64 quantity, bytes calldata signature) external payable nonReentrant {
        require(mintConfig.publicOpen, "Public round is not open");
        require(verifyPublicMintSignature(quantity, signature), "Invalid approval signature");
        require(roundMinted.publicMinted + quantity <= mintConfig.publicMaxSupply, "Exceed round's max supply");
        require(totalSupply() + quantity <= maxSupply, "Exceed max supply");
        require(
            addressMinted[_msgSender()].publicMinted + quantity <= mintConfig.publicMaxEachAddress,
            "Exceed max supply for each address"
        );
        require(msg.value >= mintConfig.publicPrice * quantity, "Insufficient paymenet");

        addressMinted[_msgSender()].publicMinted += quantity;
        roundMinted.publicMinted += quantity;
        _safeMint(_msgSender(), quantity);
    }

    /**
     * @notice
     * After the public round ends, all unminted tokens could be minted by owner and burn them.
     */
    function devMint(uint256 quantity) external onlyOwner {
        _safeMint(_msgSender(), quantity);
        emit DevMint(quantity);
    }

    function devBurn(uint256[] calldata tokenIds) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _burn(tokenIds[i]);
        }
    }

    function verifyWhitelistMintSignature(uint256 quantity, bytes calldata signature) internal view returns (bool) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(keccak256("WhitelistMint(address wallet,uint256 quantity)"), _msgSender(), quantity))
        );
        return ECDSA.recover(digest, signature) == mintConfig.approvalSigner;
    }

    function verifyPublicMintSignature(uint256 quantity, bytes calldata signature) internal view returns (bool) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(keccak256("PublicMint(address wallet,uint256 quantity)"), _msgSender(), quantity))
        );
        return ECDSA.recover(digest, signature) == mintConfig.approvalSigner;
    }
}