// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {ERC721A} from "ERC721A/ERC721A.sol";
import {IERC721} from "openzeppelin/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "openzeppelin/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";
import {MerkleProofLib} from "solmate/utils/MerkleProofLib.sol";

import "../Fundrop/IERC4906.sol";
import "../Fundrop/IMetadataRenderer.sol";

contract FunBirthday is ERC721A, IERC4906, Ownable {
    uint256 public publicMintPrice = 0.000614 ether;

    address public metadataRenderer;
    address public metadataUpdater;

    uint256 public mintEnd;
    bytes32 merkleRoot;

    error InvalidTokenId();
    error InvalidPrice();
    error InvalidProof();
    error MerkleRootNotSet();
    error MintClosed();
    error MintedAllowlistAlready();
    error OnlyOwnerOrMetadataUpdater();
    error TooMany();

    constructor() ERC721A("mint.fun turns one", "FUNBIRTHDAY") {
        if (msg.sender != tx.origin) {
            _transferOwnership(tx.origin);
        }
    }

    function mint(uint256 count) public payable {
        if (block.timestamp > mintEnd) revert MintClosed();
        if (msg.value != count * publicMintPrice) revert InvalidPrice();
        if (count > 100) revert TooMany();
        _mint(msg.sender, count);
    }

    function allowlistMint(bytes32[] calldata _proof) public {
        if (block.timestamp > mintEnd) revert MintClosed();
        bool hasMinted = _getAux(msg.sender) != 0;
        if (hasMinted) revert MintedAllowlistAlready();

        bool isValid = MerkleProofLib.verify(_proof, keccak256(abi.encodePacked(msg.sender)), merkleRoot);
        if (!isValid) revert InvalidProof();

        _setAux(msg.sender, 1); // used to track if minted
        _mint(msg.sender, 1);
    }

    function adminMint(address to, uint256 count) public onlyOwner {
        _mint(to, count);
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

    function setMetadataRenderer(address _metadataRenderer) public onlyOwner {
        metadataRenderer = _metadataRenderer;
        refreshMetadata();
    }

    function setMetadataUpdater(address _metadataUpdater) public onlyOwner {
        metadataUpdater = _metadataUpdater;
    }

    function setMerkleRoot(bytes32 _root) public onlyOwner {
        if (_root == bytes32(0)) {
            revert MerkleRootNotSet();
        }

        merkleRoot = _root;
    }

    function setMintEnd(uint256 _mintEnd) public onlyOwner {
        if (_mintEnd > 0 && (merkleRoot == bytes32(0))) {
            revert MerkleRootNotSet();
        }
        mintEnd = _mintEnd;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        if (_mintPrice == 0) {
            revert InvalidPrice();
        }
        publicMintPrice = _mintPrice;
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC4906).interfaceId || interfaceId == type(IERC721Metadata).interfaceId;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}