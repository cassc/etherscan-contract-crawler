// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Pepeth is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_TOKENS = 10000;
    uint256 public PRESALE_LIMIT_1 = 4000;
    uint256 public presaleTokensSold_1 = 0;
    uint256 public reservedTokensMinted = 0;
    uint256 public PRICE = 0.005 ether; 
    
    bool public preSaleIsActive_1 = false;
    bool public publicIsActive = false;

    bytes32 public merkleRoot;
    mapping(address => bool) public whitelistClaimed;
    mapping(address => uint256) public publicClaimed;

    string public uriSuffix = ".json";
    string public baseURI = "";

    address payable private guy = payable(0xA778705aD62FC052c814b0d6b2F7c64aA1b10AE1);

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
        require(!whitelistClaimed[msg.sender], "Address already minted a pepeth!");
        require(presaleTokensSold_1 + 1 <= PRESALE_LIMIT_1, "Purchase would exceed max supply");
        
        whitelistClaimed[msg.sender] = true;
        _safeMint(msg.sender, totalSupply() + 1);
        presaleTokensSold_1++;
    }


    function mint() public payable {
        require(publicIsActive, "Sale must be active to mint");
        require(publicClaimed[msg.sender] <= 1, "Address already minted max allowed");
        require(totalSupply() + 1 <= MAX_TOKENS - (100 - reservedTokensMinted), "Purchase would exceed max supply");
        require(msg.value >= PRICE * 1, "Insufficient funds!");

        publicClaimed[msg.sender] = publicClaimed[msg.sender] + 1;
        _safeMint(msg.sender, totalSupply() + 1);
    }

    function mintReservedTokens(uint256 amount) external onlyOwner 
    {
        require(reservedTokensMinted + amount <= 100, "This amount is more than max allowed");

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


    function withdraw() external
    {
        require(msg.sender == guy || msg.sender == owner(), "Invalid sender");
        (bool success, ) = guy.call{value: address(this).balance / 100 * 50}("");
        (bool success2, ) = owner().call{value: address(this).balance}("");
        require(success, "Transfer 1 failed");
        require(success2, "Transfer 2 failed");
    }

    function setRoot(bytes32 _root) external onlyOwner
    {
        merkleRoot = _root;
    }
     
    function isValid(bytes32[] memory proof) public view returns (bool) {
      bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
      return MerkleProof.verify(proof, merkleRoot, leaf);
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