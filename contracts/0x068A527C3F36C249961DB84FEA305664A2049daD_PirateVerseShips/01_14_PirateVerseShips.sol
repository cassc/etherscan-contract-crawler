// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import { IERC2981, IERC165 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract PirateVerseShips is ERC721, IERC2981, Ownable, ReentrancyGuard {
  using Strings for uint256;

  uint256 constant MAX_SUPPLY = 10000;
  uint256 constant PRESALE_MAX_SUPPLY = 1111;

  uint256 private _currentId;

  string private baseURI;
  string private prerevealTokenURI;
  string public contractURI;

  bool public revealed = false;
  bool public presaleMint = true;
  bool public publicMint = false;

  uint256 public tokensPerMint = 5;
  uint256 public maxPerWallet = 10;
  uint256 public publicPrice;
  uint256 public presalePrice = 0.025 ether;

  uint256 public royaltiesBps = 250;
  string public baseExtension = ".json";

  mapping(address => uint256) private _alreadyMinted;

  address private beneficiaryAddress;

  constructor(
    address _beneficiaryAddress,
    
    string memory _initialContractURI,
    string memory _initialBaseURI,
    string memory _initialPrerevealTokenURI
  ) ERC721("PirateVerseShips", "SHIPS") ReentrancyGuard(){
    setBeneficiaryAddress(_beneficiaryAddress);
    setContractURI(_initialContractURI);
    setBaseURI(_initialBaseURI);
    setPrerevealTokenURI(_initialPrerevealTokenURI);
  }

  // Accessors

  function setBeneficiaryAddress(address _beneficiaryAddress) public onlyOwner {
    beneficiaryAddress = _beneficiaryAddress;
  }

  function setContractURI(string memory uri) public onlyOwner {
    contractURI = uri;
  }

  function setBaseURI(string memory uri) public onlyOwner {
    baseURI = uri;
  }

  function setPrerevealTokenURI(string memory uri) public onlyOwner {
    prerevealTokenURI = uri;
  }

  function setPrice(uint256 price) public onlyOwner {
    publicPrice = price;
  }

  function alreadyMinted(address addr) public view returns (uint256) {
    return _alreadyMinted[addr];
  }

  function totalSupply() public view returns (uint256) {
    return _currentId;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function _prerevealToken() internal view returns (string memory) {
    return prerevealTokenURI;
  }

  function _contractURI() internal view returns (string memory) {
    return contractURI;
  }

  function toggleReveal() public onlyOwner {
    revealed = !revealed;
  }

  function togglePresaleMint() public onlyOwner{
    presaleMint = !presaleMint;
  }

  function togglePublicMint() public onlyOwner{
    publicMint = !publicMint;
  }

  // Minting 

  function mint(
    uint256 amount
  ) public payable {

    if(presaleMint){

      require(_currentId + amount <= PRESALE_MAX_SUPPLY, "Minting Amount Exceeding Presale Supply");
      require(amount <= tokensPerMint, "Minting amount exceeds tokens per mint");
      require(amount <= maxPerWallet - _alreadyMinted[msg.sender], "Insufficient mints left");
      require(msg.value >= amount * presalePrice, "Incorrect payable amount");

      _mintTokens(msg.sender, amount);
      _alreadyMinted[msg.sender] += amount;
    }
    else if(publicMint){

      require(_currentId + amount <= MAX_SUPPLY, "Minting Amount Exceeding Total Supply");
      require(amount <= tokensPerMint, "Minting amount exceeds tokens per mint");
      require(amount <= maxPerWallet - _alreadyMinted[msg.sender], "Insufficient mints left");
      require(msg.value >= amount * publicPrice, "Incorrect payable amount");
      
      _mintTokens(msg.sender, amount);
      _alreadyMinted[msg.sender] += amount;
    }
    
  }

  // Private (Internal Minting Function)

  function _mintTokens(address to, uint256 amount) private nonReentrant{

    for (uint256 i = 0; i < amount; i++) {
      _currentId++;
      _safeMint(to, _currentId);
    }

  }

  // returns URI

  function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");

        if (revealed == false) {
            return prerevealTokenURI;
        }

        string memory currentBaseURI = _baseURI();
    
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

  // Withdraw

  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{
        value: address(this).balance
      }("");
    require(success);
  }

  // ERC165

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }

  // IERC2981 (royalty)

  function royaltyInfo(uint256 , uint256 _salePrice) external view override returns (address, uint256 royaltyAmount) {
    royaltyAmount = (_salePrice / 10000) * royaltiesBps;
    return (beneficiaryAddress, royaltyAmount);
  }

  function reserveShips(uint256 amount) public onlyOwner {     
    address sender = msg.sender;   
    _mintTokens(sender, amount);
  }
}