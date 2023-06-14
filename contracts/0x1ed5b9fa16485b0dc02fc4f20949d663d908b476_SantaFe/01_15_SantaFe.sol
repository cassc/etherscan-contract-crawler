// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

// ░██████╗░█████╗░███╗░░██╗████████╗░█████╗░  ███████╗███████╗
// ██╔════╝██╔══██╗████╗░██║╚══██╔══╝██╔══██╗  ██╔════╝██╔════╝
// ╚█████╗░███████║██╔██╗██║░░░██║░░░███████║  █████╗░░█████╗░░
// ░╚═══██╗██╔══██║██║╚████║░░░██║░░░██╔══██║  ██╔══╝░░██╔══╝░░
// ██████╔╝██║░░██║██║░╚███║░░░██║░░░██║░░██║  ██║░░░░░███████╗
// ╚═════╝░╚═╝░░╚═╝╚═╝░░╚══╝░░░╚═╝░░░╚═╝░░╚═╝  ╚═╝░░░░░╚══════╝
// Powered by https://nalikes.com

contract SantaFe is ERC721AQueryable, DefaultOperatorFilterer, Ownable {
    using Strings for uint256;

    bytes32 public merkleRoot;
    mapping(address => uint256) public allowlistMintedBalance;

    string public uriSuffix = "";
    string public baseURI;
    string public hiddenURI;

    uint256 public cost;
    uint256 public remainingTeamMints = 10;

    uint256 public maxSupply = 1610;

    uint256 public maxMintAmountPerTx = 10;
    uint256 public maxAllowlistMint = 30;

    bool public allowlistMintEnabled = false;
    bool public publicMintEnabled = false;
    
    bool public paused = false;
    bool public revealed = false;

    constructor() ERC721A("Santa Fe Crypto", "SFC") {}

    //******************************* MODIFIERS

    modifier mintCompliance(uint256 _mintAmount) {
        require(totalSupply() + _mintAmount <= maxSupply - remainingTeamMints, "MINT: Max Supply Exceeded.");
        require(_mintAmount <= maxMintAmountPerTx, "MINT: Invalid Amount.");
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, "MINT: Insufficient funds.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract Paused.");
        _;
    }

    //******************************* MINT
    
    function allowlistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable notPaused mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {

        require(allowlistMintEnabled, "Allowlist Mint: Disabled.");
        uint256 ownerMintedCount = allowlistMintedBalance[_msgSender()];
        require(ownerMintedCount + _mintAmount <= maxAllowlistMint, "Allowlist Mint: Mint Allowance Exceeded.");
        
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Allowlist Mint: Invalid proof.");

        allowlistMintedBalance[_msgSender()] += _mintAmount;
        _safeMint(_msgSender(), _mintAmount);
    }

    function mint(uint256 _mintAmount) public payable notPaused mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {

        require(publicMintEnabled, "Public Mint: Disabled.");
        require(tx.origin == msg.sender, "Public Mint: Caller is another contract.");

        _safeMint(_msgSender(), _mintAmount);
    }

    // @dev Admin mint
    function mintForAddress(address _receiver, uint256 _mintAmount) public notPaused mintCompliance(_mintAmount) onlyOwner {
        _safeMint(_receiver, _mintAmount);
    }

    function mintToTeamMember(address _receiver, uint256 _mintAmount) public notPaused onlyOwner {
        require(totalSupply() + _mintAmount <= maxSupply, "TEAM MINT: Max Supply Exceeded.");
        require(_mintAmount <= maxMintAmountPerTx, "TEAM MINT: Invalid Amount.");
        require(_mintAmount <= remainingTeamMints, "TEAM MINT: Exceeds reserved NFTs supply");

        remainingTeamMints -= _mintAmount;
        _safeMint(_receiver, _mintAmount);
    }

    //******************************* OVERRIDES

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 _tokenId) public view virtual override (ERC721A, IERC721A) returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        if (revealed == false) {
            return hiddenURI;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)) : "";    
    }

    //******************************* ROYALTY ENFORCEMENT OVERRIDES

    function setApprovalForAll(address operator, bool approved) public override (ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override (ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }
    
    function transferFrom(address from, address to, uint256 tokenId) public payable override (ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override (ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override (ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    //******************************* CRUD

    // MERKLE ROOT

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    // URI'S

    function setBaseURI(string memory _metadataURI) public onlyOwner {
        baseURI = _metadataURI;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setHiddenUri(string memory _hiddenURI) public onlyOwner {
        hiddenURI = _hiddenURI;
    }

    // UINT'S

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        require(_newMaxSupply >= totalSupply() + remainingTeamMints && _newMaxSupply <= maxSupply, "Invalid Max Supply.");
        maxSupply = _newMaxSupply;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setMaxAllowlistMint(uint256 _maxAllowlistMint) public onlyOwner {
        maxAllowlistMint = _maxAllowlistMint;
    }

    // BOOL's

    function setAllowlistMintEnabled(bool _state) public onlyOwner {
        allowlistMintEnabled = _state;
    }
    
    function setPublicMintEnabled(bool _state) public onlyOwner {
        publicMintEnabled = _state;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    // MINT CONTROLS

    function enableAllowlistMint(uint256 _cost, bytes32 _merkleRoot) public onlyOwner {
        setAllowlistMintEnabled(true);
        setPublicMintEnabled(false);
        setPaused(false);

        setCost(_cost);
        setMerkleRoot(_merkleRoot);
    }

    function enablePublicMint(uint256 _cost) public onlyOwner {
        setPublicMintEnabled(true);
        setAllowlistMintEnabled(false);
        setPaused(false);

        setCost(_cost);
    }

    //******************************* WITHDRAW

    function withdraw() public onlyOwner {

        uint256 balance = address(this).balance;
        
        bool success;
        (success, ) = payable(0xb13De4C44eEA28c36be9Ec82BE7Ab47a05ceeDD4).call{value: ((balance * 90) / 100)}("");
        require(success, "Transaction 1 Unsuccessful");

        bool success2;
        (success2, ) = payable(0xfBf46990Ba7e0a37B1047aF6FD317b5404be1e9E).call{value: ((balance * 10) / 100)}("");
        require(success2, "Transaction 2 Unsuccessful");

    }
}