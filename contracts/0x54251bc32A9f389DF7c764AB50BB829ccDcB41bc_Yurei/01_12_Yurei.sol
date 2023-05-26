//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Yurei is ERC721A, Ownable {
    //events

    using Strings for uint256;
    //var
    bytes32 public merkleRoot;
    uint256 MAX_SUPPLY = 1111;
    uint256 private MaxMint = 2;
    uint256 private PublicMaxMint = 2;
    bool public paused = false;
    bool public isActive = false;
    string public URI;
    string private uriSuffix = ".json";
    bool public REVEAL = false;
    uint256 public tokenPrice = 0.03 ether;
    uint256 public PublictokenPrice = 0.04 ether;
    mapping(address => uint256) public PublicList;
    mapping(address => uint256) private _alreadyMinted;

    constructor(string memory initialURI, bytes32 _Root)
        ERC721A("Yurei", "Yurei")
    {
        URI = initialURI;
        merkleRoot = _Root;
    }

    modifier IsUser() {
        require(tx.origin == msg.sender, "Cannot be called by a contract");
        _;
    }

    //Metadata

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return URI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (REVEAL) {
            return
                string(
                    abi.encodePacked(URI, Strings.toString(tokenId), uriSuffix)
                );
        }
        return URI;
    }

    function toggleReveal(string memory updatedURI) public onlyOwner {
        REVEAL = !REVEAL;
        URI = updatedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        URI = _newBaseURI;
    }

    //General

    function alreadyMinted(address addr) public view returns (uint256) {
        return _alreadyMinted[addr];
    }

    function setMerkleProof(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setActive() public onlyOwner {
        isActive = !isActive;
    }

    function setPause() public onlyOwner {
        paused = !paused;
    }

    function setPrice(uint256 price) public onlyOwner {
        tokenPrice = price;
    }

    //WLMint

    function mintWListed(uint256 amount, bytes32[] calldata merkleProof)
        public
        payable
        IsUser
    {
        address sender = _msgSender();
        require(!paused, "the contract is paused");
        require((totalSupply() + amount) <= MAX_SUPPLY, "max supply reached");
        require(amount <= MaxMint - _alreadyMinted[sender],"Insufficient mints left");
        require(_verify(merkleProof, sender), "Invalid proof");
        require(msg.value == tokenPrice * amount, "Incorrect payable amount");

        _alreadyMinted[sender] += amount;
        _safeMint(sender, amount);
    }

    //merkleproof

    function _verify(bytes32[] calldata merkleProof, address sender)
        private
        view
        returns (
            bool
        )
    {
        bytes32 leaf = keccak256(abi.encodePacked(sender));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

    //public mint

    function mint(uint256 _mintAmount) public payable IsUser {
        require(isActive, "Public sale is not active");
        require((totalSupply() + _mintAmount) <= MAX_SUPPLY, "max supply reached");
        require(
            _mintAmount <= PublicMaxMint - PublicList[msg.sender],
            "Insufficient mints left"
        );
        require(
            msg.value >= PublictokenPrice * _mintAmount,
            "insufficient funds provided"
        );
        PublicList[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    //owner mint
    function OwnerMint(address to, uint256 amount) public onlyOwner {
        _safeMint(to, amount);
    }

    //bridge

    //only owner

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}