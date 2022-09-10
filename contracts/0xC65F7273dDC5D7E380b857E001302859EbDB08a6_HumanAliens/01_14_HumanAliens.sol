// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract HumanAliens is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_TOKENS = 5555;
    uint256 public PRESALE_LIMIT_1 = 1555;
    uint256 public PRESALE_LIMIT_2 = 2000;
    uint256 public presaleTokensSold_1 = 0;
    uint256 public presaleTokensSold_2 = 0;
    uint256 public reservedTokensMinted = 0;
    uint256 public PRICE = 0.005 ether; 
    
    bool public preSaleIsActive_1 = false;
    bool public preSaleIsActive_2 = false;
    bool public publicIsActive = false;

    bytes32 public merkleRoot;
    bytes32 public merkleRoot2;
    mapping(address => bool) public whitelistClaimed;
    mapping(address => bool) public whitelist2Claimed;
    mapping(address => bool) public publicClaimed;

    string public uriSuffix = ".json";
    string public baseURI = "";

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol
    ) ERC721(_tokenName, _tokenSymbol) {
    }

    //Mint function
    function mintWhitelist(bytes32[] memory _proof) public payable {
        require(preSaleIsActive_1, "Sale must be active to mint");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_proof, merkleRoot, leaf), "Invalid proof!");
        require(!whitelistClaimed[msg.sender], "Address already minted a HumanAlien!");
        require(presaleTokensSold_1 + 1 <= PRESALE_LIMIT_1, "Purchase would exceed max supply");
        
        whitelistClaimed[msg.sender] = true;
        _safeMint(msg.sender, totalSupply() + 1);
        presaleTokensSold_1++;
    }

    function mintWhitelist2(bytes32[] memory _proof) public payable {
        require(preSaleIsActive_2, "Sale must be active to mint");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_proof, merkleRoot2, leaf), "Invalid proof!");
        require(!whitelist2Claimed[msg.sender], "Address already minted a HumanAlien!");
        require(presaleTokensSold_2 + 1 <= PRESALE_LIMIT_2, "Purchase would exceed max supply");
        require(msg.value >= PRICE * 1, "Insufficient funds!");

        whitelist2Claimed[msg.sender] = true;
        _safeMint(msg.sender, totalSupply() + 1);
        presaleTokensSold_2++;
    }

    function mint() public payable {
        require(publicIsActive, "Sale must be active to mint");
        require(!publicClaimed[msg.sender], "Address already adopted a sociopeth!");
        require(totalSupply() + 1 <= MAX_TOKENS - (25 - reservedTokensMinted), "Purchase would exceed max supply");
        require(msg.value >= PRICE * 1, "Insufficient funds!");

        publicClaimed[msg.sender] = true;
        _safeMint(msg.sender, totalSupply() + 1);
    }

    function mintReservedTokens(uint256 amount) external onlyOwner 
    {
        require(reservedTokensMinted + amount <= 25, "This amount is more than max allowed");

        for (uint i = 0; i < amount; i++) 
        {
            _safeMint(msg.sender, totalSupply() + 1);
            reservedTokensMinted++;
        }
    }

    //Utility function
    function setPrice(uint256 newPrice) external onlyOwner 
    {
        PRICE = newPrice;
    }

    function flipSaleState() external onlyOwner 
    {
        publicIsActive = !publicIsActive;
    }

    function flipPreSaleState_1() external onlyOwner 
    {
        preSaleIsActive_1 = !preSaleIsActive_1;
    }

    function flipPreSaleState_2() external onlyOwner 
    {
        preSaleIsActive_2 = !preSaleIsActive_2;
    }

    function withdraw() external
    {
        require(msg.sender == owner(), "Invalid sender");
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function setRoot(bytes32 _root) external onlyOwner
    {
        merkleRoot = _root;
    }

    function setRoot2(bytes32 _root) external onlyOwner
    {
        merkleRoot2 = _root;
    }
     
    function isValid(bytes32[] memory proof) public view returns (bool) {
      bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
      return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function isValid2(bytes32[] memory proof) public view returns (bool) {
      bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
      return MerkleProof.verify(proof, merkleRoot2, leaf);
    }

    ////
    //URI management part
    ////   

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
            baseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory _tokenURI = super.tokenURI(tokenId);
        return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
    }
  
}