// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ERC721A.sol";

contract CosmodinosPets is Ownable, ERC721A, ReentrancyGuard {
    using SafeMath for uint256;
    uint256 public immutable collectionSize = 11000;
    bytes32 public merkleRoot;
    bool public mintIsOpen = false;
    string private _baseTokenURI;

    constructor(
        string memory tokenUri_,
        string memory name_,
        string memory symbol_
    ) ERC721A(name_, symbol_) {
        _baseTokenURI = tokenUri_;
    }

    function getMyPets(
        uint256 count,
        uint256 allowance,
        bytes32[] calldata proof
    ) external payable callerIsUser {
        require(mintIsOpen == true, "mint list must be opened");
        uint256 maxQuantity = allowance.sub(_numberMinted(msg.sender));

        require(count <= maxQuantity, "quantity error");
        require(_verify(_leaf(msg.sender, allowance), proof), "Invalid merkle proof");

        internalMint(count, msg.sender);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setMintIsOpen(bool _mintIsOpen) public onlyOwner {
        mintIsOpen = _mintIsOpen;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function _leaf(address account, uint256 amount) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, amount));
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function airDrop(uint256 count, address wallet) external onlyOwner {
        internalMint(count, wallet);
    }

    function internalMint(uint256 count, address wallet) internal {
        require(totalSupply() + count <= collectionSize, "reached max supply");
        _safeMint(wallet, count);
    }

    function numberMintedOn(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return ownershipOf(tokenId);
    }
}