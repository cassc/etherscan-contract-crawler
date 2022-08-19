//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract PixelPuppers is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public immutable collectionSize = 5555;
    string public baseUri;
    string public unrevealedUri;
    bool public vipActive;
    bool public premintActive;
    bool public publicActive;
    bool public isRevealed;
    bytes32 private vipMerkleRoot;
    bytes32 private premintMerkleRoot;

    mapping(address => bool) public hasMinted;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Cannot be called by contract");
        _;
    }

    constructor() ERC721A("PixelPuppersNFT", "PXP") {
        vipActive = false;
        premintActive = false;
        publicActive = false;
        isRevealed = false;
        unrevealedUri = "ipfs://bafkreicmg4mbuxkkj7cpg3tvbh77um6q7xguqeeysviqsrmn5nkmguohsq";
    }

    function publicMint() public callerIsUser {
        require(!hasMinted[msg.sender], "Already minted in public sale");
        require(
            totalSupply() + 1 <= collectionSize,
            "Minting over collection size"
        );
        require(publicActive, "Public Sale isn't Active");

        _safeMint(msg.sender, 1);
        hasMinted[msg.sender] = true;
    }

    function premintMint(bytes32[] calldata _merkleProof)
        public
        callerIsUser
    {
        require(!hasMinted[msg.sender], "Already minted in premint sale");
        require(
            totalSupply() + 1 <= collectionSize,
            "Minting over premint allocation"
        );
        require(premintActive, "Premint Sale isn't active");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, premintMerkleRoot, leaf) || MerkleProof.verify(_merkleProof, vipMerkleRoot, leaf) ,
            "Invalid Proof"
        );

        _safeMint(msg.sender, 1);
        hasMinted[msg.sender] = true;
    }

    function vipMint(bytes32[] calldata _merkleProof)
        public
        callerIsUser
    {
        require(vipActive, "VIP Sale isn't active");
        require(!hasMinted[msg.sender], "Already minted");
        require(
            totalSupply() + 2 <= collectionSize,
            "Minting over VIP allocation"
        );

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, vipMerkleRoot, leaf),
            "Invalid Proof"
        );
        _safeMint(msg.sender, 2);
        hasMinted[msg.sender] = true;
    }

    function ownerMint(uint _quantity) public onlyOwner(){
        require(
            totalSupply() + _quantity <= collectionSize,
            "Minting over collection size"
        );
        require(_quantity > 0, "Quantity must be greater than 0");
        _safeMint(msg.sender, _quantity);
    }

    function togglePublicSale() public onlyOwner {
        publicActive = !publicActive;
    }

    function togglePremintSale() public onlyOwner {
        premintActive = !premintActive;
    }


    function toggleVipSale() public onlyOwner {
        vipActive = !vipActive;
    }

    function vipToPremint() public onlyOwner {
        vipActive = false;
        premintActive = true;
    }

    function premintToPublic() public onlyOwner {
        premintActive = false;
        publicActive = true;
    }

    function toggleReveal() public onlyOwner {
        isRevealed = !isRevealed;
    }

    function setPremintMerkleRoot(bytes32 _premintMerkleRoot) public onlyOwner {
        premintMerkleRoot = _premintMerkleRoot;
    }

    function setVipMerkleRoot(bytes32 _vipMerkleRoot) public onlyOwner {
        vipMerkleRoot = _vipMerkleRoot;
    }

    function setBaseUri(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function setUnrevealedUri(string memory _unrevealedUri) public onlyOwner {
        unrevealedUri = _unrevealedUri;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();
        if (!isRevealed) {
            return unrevealedUri;
        }

        return string(abi.encodePacked(baseUri, _tokenId.toString(), ".json"));
    }

    function getPremintMerkleRoot() public view onlyOwner returns (bytes32) {
        return premintMerkleRoot;
    }

    function getVipMerkleRoot() public view onlyOwner returns (bytes32) {
        return vipMerkleRoot;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}