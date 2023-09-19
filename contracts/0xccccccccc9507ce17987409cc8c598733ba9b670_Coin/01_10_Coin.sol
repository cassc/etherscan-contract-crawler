// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC721A} from "ERC721A/ERC721A.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {ECDSA} from "solady/utils/ECDSA.sol";

import {IERC721} from "openzeppelin/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "openzeppelin/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";
import "../IERC4906.sol";
import "../IMetadataRenderer.sol";

contract Coin is ERC721A, IERC4906, Ownable {
    address public metadataRenderer;
    address public metadataUpdater;
    address public signer;
    bool public adminMintRevoked;

    uint256 public mintEnd;

    mapping(bytes32 => bool) _mintedSeeds;
    mapping(uint256 tokenID => bytes32 seed) public seed;

    error CantAdminMint();
    error InvalidTokenId();
    error InvalidSignature();
    error MintClosed();
    error MintedAlready();
    error OnlyOwnerOrMetadataUpdater();

    constructor() ERC721A("Coin by Jan Robert Leegte", "COIN") {
        _initializeOwner(tx.origin);
    }

    function mint(uint256 quantity, uint64 nonce, bytes calldata signature) public {
        if (block.timestamp > mintEnd) revert MintClosed();

        bytes32 id = (bytes32(uint256(uint160(msg.sender)) << 96)) | bytes32(uint256(nonce));
        if (_mintedSeeds[id]) revert MintedAlready();

        address recovered =
            ECDSA.tryRecoverCalldata(keccak256(abi.encodePacked(quantity, nonce, msg.sender, block.chainid)), signature);
        if (recovered != signer) revert InvalidSignature();

        _mintedSeeds[id] = true;
        _mintSeed(msg.sender, quantity, nonce, signature);
    }

    function _mintSeed(address to, uint256 quantity, uint64 nonce, bytes calldata signature) internal {
        uint256 startTokenId = _nextTokenId();
        for (uint256 i = 0; i < quantity; i++) {
            seed[startTokenId + i] = keccak256(
                abi.encodePacked(block.prevrandao, blockhash(block.number), block.timestamp, nonce, i, signature)
            );
        }
        _mint(to, quantity);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        if (ownerOf(id) == address(0)) revert InvalidTokenId();
        return IMetadataRenderer(metadataRenderer).tokenURI(id);
    }

    // Admin functions
    function refreshMetadata() public {
        if (msg.sender != metadataUpdater && msg.sender != owner()) {
            revert OnlyOwnerOrMetadataUpdater();
        }
        emit BatchMetadataUpdate(_startTokenId(), _nextTokenId() - 1);
    }

    function adminMint(address to, uint256 quantity, uint64 nonce, bytes calldata signature) public onlyOwner {
        if (adminMintRevoked) revert CantAdminMint();
        _mintSeed(to, quantity, nonce, signature);
    }

    function setMetadataRenderer(address _metadataRenderer) public onlyOwner {
        metadataRenderer = _metadataRenderer;
        refreshMetadata();
    }

    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function setMetadataUpdater(address _metadataUpdater) public onlyOwner {
        metadataUpdater = _metadataUpdater;
    }

    function setMintEnd(uint256 _mintEnd) public onlyOwner {
        mintEnd = _mintEnd;
    }

    function revokeAdminMint() public onlyOwner {
        adminMintRevoked = true;
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual override(ERC721A) returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC4906).interfaceId || interfaceId == type(IERC721Metadata).interfaceId;
    }
}