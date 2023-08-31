// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {ERC721A} from "ERC721A/ERC721A.sol";
import {IERC721} from "openzeppelin/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "openzeppelin/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";
import {MerkleProofLib} from "solmate/utils/MerkleProofLib.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

import "../IERC4906.sol";
import "../IMetadataRenderer.sol";

contract TeamsCommemorativeNFT is ERC721A, IERC4906, Ownable {
    address public metadataRenderer;
    address public metadataUpdater;

    uint256 public mintEnd;
    bytes32 public merkleRoot;

    error InvalidTokenId();
    error InvalidProof();
    error MerkleRootNotSet();
    error MintClosed();
    error MintedAlready();
    error OnlyOwnerOrMetadataUpdater();

    constructor() ERC721A("!teams player", "TPLYR") {
        if (msg.sender != tx.origin) {
            _transferOwnership(tx.origin);
        }
        _mint(tx.origin, 1);
    }

    function mint(bytes32[] calldata _proof) public {
        if (block.timestamp > mintEnd) revert MintClosed();
        bool hasMinted = _getAux(msg.sender) != 0;
        if (hasMinted) revert MintedAlready();
        bool isValid = MerkleProofLib.verify(_proof, merkleRoot, keccak256(abi.encodePacked(msg.sender)));
        if (!isValid) revert InvalidProof();

        _setAux(msg.sender, 1);
        _mint(msg.sender, 1);
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

    function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC4906).interfaceId || interfaceId == type(IERC721Metadata).interfaceId;
    }

    function withdraw() public onlyOwner {
        SafeTransferLib.safeTransferETH(owner(), address(this).balance);
    }
}