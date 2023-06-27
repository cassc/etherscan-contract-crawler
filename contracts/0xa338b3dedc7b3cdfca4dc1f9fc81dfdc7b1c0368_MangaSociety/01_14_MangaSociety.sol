// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MangaSociety is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public MAXIMUM_SUPPLY = 5960;

    uint256 public constant MAXIMUM_MINT_WL = 3;
    uint256 public constant MAXIMUM_MINT_PUBLIC = 3;

    uint256 WL_PRICE = 0.07 ether;
    uint256 PUBLIC_PRICE = 0.07 ether;

    bytes32 public merkleRoot;
    bytes32 public freeMerkleRoot;

    string public baseURI;
    string public notRevealedUri;

    bool public isRevealed = false;

    enum WorkflowStatus {
        Before,
        Presale,
        Sale,
        SoldOut,
        Freemint
    }

    WorkflowStatus public workflow;

    mapping(address => uint256) public tokensPerWalletPublic;
    mapping(address => uint256) public tokensPerWalletWhitelist;
    mapping(address => uint256) public tokensPerWalletFreemint;

    constructor(
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721A("MANGA SOCIETY", "MS") {
        workflow = WorkflowStatus.Before;
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    function privateSalePrice() public view returns (uint256) {
        return WL_PRICE;
    }

    function getPrice() public view returns (uint256) {
        return PUBLIC_PRICE;
    }

    function getSaleStatus() public view returns (WorkflowStatus) {
        return workflow;
    }

    function hasWhitelist(bytes32[] calldata _merkleProof) public view returns (bool) {
      bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
      return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function hasOnFreemint(bytes32[] calldata _merkleProof) public view returns (bool) {
      bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
      return MerkleProof.verify(_merkleProof, freeMerkleRoot, leaf);
    }

    function freeMint(bytes32[] calldata _merkleProof) external payable nonReentrant
    {
        uint256 supply = totalSupply();

        require(workflow != WorkflowStatus.SoldOut, "MANGA SOCIETY: SOLD OUT!");
        require(workflow == WorkflowStatus.Freemint, "MANGA SOCIETY: Freemint is not started yet!");
        require(tokensPerWalletFreemint[msg.sender] + 1 <= 1, "MANGA SOCIETY: You cant mint more than 1 tokens!");
        require(supply + 1 <= MAXIMUM_SUPPLY, "MANGA SOCIETY: Mint too large!");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, freeMerkleRoot, leaf), "MANGA SOCIETY: You are not eligible for the freemint");

        tokensPerWalletFreemint[msg.sender] += 1;

        if(supply + 1 == MAXIMUM_SUPPLY) {
          workflow = WorkflowStatus.SoldOut;
        }

        _safeMint(msg.sender, 1);
    }

    function presaleMint(uint256 ammount, bytes32[] calldata _merkleProof) external payable nonReentrant
    {
        uint256 supply = totalSupply();
        uint256 price = privateSalePrice();

        require(workflow != WorkflowStatus.SoldOut, "MANGA SOCIETY: SOLD OUT!");
        require(workflow == WorkflowStatus.Presale, "MANGA SOCIETY: Presale is not started yet!");
        require(msg.value >= price * ammount, "MANGA SOCIETY: Not enough ETH sent");
        require(ammount <= MAXIMUM_MINT_WL, string(abi.encodePacked("MANGA SOCIETY: You can only mint up to ", MAXIMUM_MINT_WL.toString(), " token at once!")));
        require(tokensPerWalletWhitelist[msg.sender] + ammount <= MAXIMUM_MINT_WL, string(abi.encodePacked("MANGA SOCIETY: You cant mint more than ", MAXIMUM_MINT_WL.toString(), " tokens!")));
        require(supply + ammount <= MAXIMUM_SUPPLY, "MANGA SOCIETY: Mint too large!");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "MANGA SOCIETY: You are not whitelisted");

        tokensPerWalletWhitelist[msg.sender] += ammount;

        if(supply + ammount == MAXIMUM_SUPPLY) {
          workflow = WorkflowStatus.SoldOut;
        }

        _safeMint(msg.sender, ammount);
    }

    function publicMint(uint256 ammount) public payable nonReentrant {
        uint256 supply = totalSupply();
        uint256 price = getPrice();

        require(workflow != WorkflowStatus.SoldOut, "MANGA SOCIETY: SOLD OUT!");
        require(workflow == WorkflowStatus.Sale, "MANGA SOCIETY: Public is not started yet");
        require(msg.value >= price * ammount, "MANGA SOCIETY: Not enough ETH sent");
        require(ammount <= MAXIMUM_MINT_PUBLIC, string(abi.encodePacked("MANGA SOCIETY: You can only mint up to ", MAXIMUM_MINT_PUBLIC.toString(), " token at once!")));
        require(tokensPerWalletPublic[msg.sender] + ammount <= MAXIMUM_MINT_PUBLIC, string(abi.encodePacked("MANGA SOCIETY: You cant mint more than ", MAXIMUM_MINT_PUBLIC.toString(), " tokens!")));
        require(supply + ammount <= MAXIMUM_SUPPLY, "MANGA SOCIETY: Mint too large!");

        tokensPerWalletPublic[msg.sender] += ammount;

        if(supply + ammount == MAXIMUM_SUPPLY) {
          workflow = WorkflowStatus.SoldOut;
        }

        _safeMint(msg.sender, ammount);
    }

    function airdrop(address[] calldata addresses) public onlyOwner {
        require(addresses.length > 0, "MANGA SOCIETY : Need to airdrop at least 1 NFT");
        for (uint256 i = 0; i < addresses.length; i++) {
          _safeMint(addresses[i], 1);
        }
    }

    function gift(address addresses, uint256 quantity) public onlyOwner {
        require(quantity > 0, "MANGA SOCIETY : Need to gift at least 1 NFT");
        _safeMint(addresses, quantity);
    }

    function restart() external onlyOwner {
        workflow = WorkflowStatus.Before;
    }

    function setUpPresale() external onlyOwner {
        workflow = WorkflowStatus.Presale;
    }

    function setUpSale() external onlyOwner {
        workflow = WorkflowStatus.Sale;
    }

    function setUpFreemint() external onlyOwner {
        workflow = WorkflowStatus.Freemint;
    }

    function setMerkleRoot(bytes32 root) public onlyOwner {
        merkleRoot = root;
    }

    function setFreeMerkleRoot(bytes32 root) public onlyOwner {
        freeMerkleRoot = root;
    }

    function reveal() public onlyOwner {
        isRevealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function updateWLPrice(uint256 _newPrice) public onlyOwner {
        WL_PRICE = _newPrice;
    }

    function updatePublicPrice(uint256 _newPrice) public onlyOwner {
        PUBLIC_PRICE = _newPrice;
    }

    function updateSupply(uint256 _newSupply) public onlyOwner {
        MAXIMUM_SUPPLY = _newSupply;
    }

    function withdraw() public onlyOwner {
        payable(0x133503D4d8AC74f984222d19dE38c5c85db90E9F).transfer(address(this).balance);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (isRevealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
    }

}