// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @title: nyc365
// @creator: Barry Sutton
// @author: 96 Studio

//////////////////////////////////////////////////////////
//                                                      //
//  ███╗░░██╗██╗░░░██╗░█████╗░██████╗░░█████╗░███████╗  //
//  ████╗░██║╚██╗░██╔╝██╔══██╗╚════██╗██╔═══╝░██╔════╝  //
//  ██╔██╗██║░╚████╔╝░██║░░╚═╝░█████╔╝██████╗░██████╗░  //
//  ██║╚████║░░╚██╔╝░░██║░░██╗░╚═══██╗██╔══██╗╚════██╗  //
//  ██║░╚███║░░░██║░░░╚█████╔╝██████╔╝╚█████╔╝██████╔╝  //
//  ╚═╝░░╚══╝░░░╚═╝░░░░╚════╝░╚═════╝░░╚════╝░╚═════╝░  //
//                                                      //
//////////////////////////////////////////////////////////

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract nyc365 is ERC721A, Ownable {
    enum ContractStatus {
        Public,
        AllowListOnly,
        Paused
    }

    event Minted(address indexed account, uint256 quantity, uint256 supply);

    // Contract Variables
    ContractStatus public contractStatus = ContractStatus.Paused;
    bytes32 public merkleRoot;
    string  public baseURI;
    string  public contractURI;
    uint256 public price;
    uint256 public maxSupply;

    // Counters
    mapping(address => uint256) public quantityMintedPublic;
    mapping(address => uint256) public quantityMintedPrivate;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor(bytes32 _merkleRoot, string memory _contractBaseURI, string memory _contractURI, uint256 _price, uint256 _maxSupply) 
    ERC721A ("nyc365", "nyc365") {
        merkleRoot = _merkleRoot;
        baseURI = _contractBaseURI;
        contractURI = _contractURI;
        price = _price;
        maxSupply = _maxSupply;    
    }

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setContractURI(string memory uri) public onlyOwner {
        contractURI = uri;
    }

    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 1;
    }

    function mintPublic(uint256 quantity) public payable callerIsUser {
        require(contractStatus == ContractStatus.Public, "Public minting not available");
        require(price > 0, "Price must be greater than zero");
        require(msg.value >= price * quantity * 10**9, "Not enough ETH sent");
        require(_totalMinted() + quantity <= maxSupply, "Not enough supply");
        require(quantityMintedPublic[msg.sender] + quantity <= 10, "Exceeds allowed wallet quantity");

        quantityMintedPublic[msg.sender] = quantityMintedPublic[msg.sender] + quantity;

        _safeMint(msg.sender, quantity);
        emit Minted(msg.sender, quantity, totalSupply());
    }

    function mintPrivate(uint256 quantity, bytes32[] calldata proof) public payable callerIsUser {
        require(contractStatus == ContractStatus.AllowListOnly, "Private minting not available");
        require(price > 0, "Price must be greater than zero");
        require(msg.value >= price * quantity * 10**9, "Not enough ETH sent");
        require(_totalMinted() + quantity <= maxSupply, "Not enough supply");
        require(canMintPrivate(msg.sender, proof), "Failed wallet verification");
        require(quantityMintedPrivate[msg.sender] + quantity <= 10, "Exceeds allowed wallet quantity");

        quantityMintedPrivate[msg.sender] = quantityMintedPrivate[msg.sender] + quantity;

        _safeMint(msg.sender, quantity);
        emit Minted(msg.sender, quantity, totalSupply());
    }

    function airdrop(address[] calldata collectors) public onlyOwner {
        uint256 i = 0;
        while (i < collectors.length) {
            address collector = collectors[i];
            _safeMint(collector, 1);
            emit Minted(collector, 1, totalSupply());
            i++;
        }
    } 

    function canMintPrivate(address account, bytes32[] calldata proof) public view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, generateMerkleLeaf(account));
    }

    function generateMerkleLeaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setContractStatus(ContractStatus status) public onlyOwner {
        contractStatus = status;
    }

    function getPublicMintedForAddress(address account) public view returns (uint256) {
        return quantityMintedPublic[account];
    }

    function getPrivateMintedForAddress(address account) public view returns (uint256) {
        return quantityMintedPrivate[account];
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setMaxSupply(uint256 supply) public onlyOwner {
        maxSupply = supply;
    }

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;

        address b = payable(0x38baeBB524Bd1ce081e5c9b75739bce6E091e95f);
        address d = payable(0x3a01b57b32bb300d839D5fb7E98f340A2685Fc96);

        bool success;

        (success, ) = b.call{value: (sendAmount * 900/1000)}("");
        require(success, "Transaction Unsuccessful");

        (success, ) = d.call{value: (sendAmount * 100/1000)}("");
        require(success, "Transaction Unsuccessful");
    }
}