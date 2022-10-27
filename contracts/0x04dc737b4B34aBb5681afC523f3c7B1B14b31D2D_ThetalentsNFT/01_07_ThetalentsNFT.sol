// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ThetalentsNFT is ERC721A, Ownable, ReentrancyGuard {

    enum Status {
        NotLive,
        PreSale,
        PublicSale,
        Finished
    }

    Status public status;
    bytes32 public merkleRoot;
    mapping(address => uint256) private _publicNumberMinted;
    string public baseURI = "";
    bool public isRevealed = false;
    uint256 public presalePrice = 0.0069 ether;
    uint256 public publicPrice = 0.0089 ether;
    uint8 public maxAllowListMint = 3;
    uint8 public maxPublicMint = 10;
    uint256 public constant MAX_SUPPLY = 5555;

    event Minted(address minter, uint256 amount);
    event StatusChanged(Status status);
    event ReservedToken(address minter, address recipient, uint256 amount);
    event BaseURIChanged(string newBaseURI);

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol
    ) ERC721A(_tokenName, _tokenSymbol) {
    }

    function MintAllowlist(uint256 _amount, bytes32[] memory _proof) public payable {
        require(status == Status.PreSale, "Presale is not active.");
        require(
            tx.origin == msg.sender,
            "Contract is not allowed to mint."
        );
        require(totalSupply() + _amount <= MAX_SUPPLY, "Max supply exceeded");
        require(msg.value >= presalePrice * _amount, 'Not enough eth');
        require(
            numberMinted(msg.sender) + _amount <= maxAllowListMint,
            "Max mint amount per wallet exceeded."
        );
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_proof, merkleRoot, leaf), "Invalid proof!");
        _safeMint(msg.sender, _amount);
        emit Minted(msg.sender, _amount);
    }

    function mint(uint256 _amount) public payable {
        require(status == Status.PublicSale, "Public sale is not active.");
        require(
            tx.origin == msg.sender,
            "Contract is not allowed to mint."
        );
        require(totalSupply() + _amount <= MAX_SUPPLY, "Max supply exceeded");
        require(msg.value >= publicPrice * _amount, 'Not enough eth');
        require(
            publicNumberMinted(msg.sender) + _amount <= maxPublicMint,
            "Max mint amount per wallet exceeded."
        );
        _safeMint(msg.sender, _amount);
        _publicNumberMinted[msg.sender] = _publicNumberMinted[msg.sender] + _amount;
        emit Minted(msg.sender, _amount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function publicNumberMinted(address owner) public view returns (uint256) {
        require(
            owner != address(0),
            "ERC721A: number minted query for the zero address"
        );
        return _publicNumberMinted[owner];
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!isRevealed) {
            return _baseURI();
        }
        return super.tokenURI(tokenId);
    }

    function setPresalePrice(uint256 _newPresalePrice) external onlyOwner {
        presalePrice = _newPresalePrice;
    }

    function setPublicPrice(uint256 _newPublicPrice) external onlyOwner {
        publicPrice = _newPublicPrice;
    }

    function setStatus(Status _status) external onlyOwner {
        status = _status;
        emit StatusChanged(_status);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setMaxAllowListMint(uint8 _amount) external onlyOwner {
        maxAllowListMint = _amount;
    }

    function setMaxPublicMint(uint8 _amount) external onlyOwner {
        maxPublicMint = _amount;
    }

    function withdrawBalance() external onlyOwner {
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success, "WITHDRAW FAILED!");
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
        emit BaseURIChanged(_newBaseURI);
    }

    function reveal(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
        isRevealed = true;
    }

    function flipReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    receive() external payable {

    }
}