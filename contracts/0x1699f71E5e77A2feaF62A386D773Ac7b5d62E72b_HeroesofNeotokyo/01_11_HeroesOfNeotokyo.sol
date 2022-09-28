// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
/// @title Heroes of NeoTokyo
/// @dev 0xCitizen

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract HeroesofNeotokyo is ERC721A, Ownable {

    string  public baseURI;

    address public proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    address public lead;

    bool public paused = true;
    
    uint256 public cost = 0.002 ether;
    uint256 public maxSupply = 111;
    uint256 public maxPerWallet = 2;
    uint256 public maxPerTx = 2;
    address public heroesOfNeotokyoV1;
    uint256 supply = totalSupply();

    mapping(address => uint) public addressMintedBalance;

 constructor(
    string memory _baseURI,
    address _lead,
    address _heroesOfNeotokyoV1
  )ERC721A("Heroes of Neotokyo", "HoN") {
    baseURI = _baseURI;
    lead = _lead;
    heroesOfNeotokyoV1 = _heroesOfNeotokyoV1;
  }

  modifier notPaused() {
    require(!paused, "Contract is Paused");
     _;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, 'The caller is another contract.');
    _;
  }


 function _startTokenId() internal view override virtual returns (uint256) {
        return 1;
 }


  function setHeroesOfNeotokyoV1Address(address _heroesOfNeotokyoV1) public onlyOwner {
    heroesOfNeotokyoV1 =_heroesOfNeotokyoV1;
  }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    require(_exists(_tokenId), "Token does not exist.");
    return string(abi.encodePacked(baseURI, Strings.toString(_tokenId),".json"));
  }

  function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
    proxyRegistryAddress = _proxyRegistryAddress;
  }
  
  function togglePublic(bool _state) external onlyOwner {
    paused = _state;
  }

  function reserveTokens(uint256 _quanitity) public onlyOwner {        
    uint256 supply = totalSupply();
    require(_quanitity + supply <= maxSupply);
    _safeMint(msg.sender, _quanitity);
  }

  function setBaseURI(string memory _baseURI) public onlyOwner {
    baseURI = _baseURI;
  }

  function publicMint(uint256 _quantity)
    public 
    payable 
    notPaused() 
    callerIsUser() 
  {
    uint256 supply = totalSupply();
    require(_quantity <= maxPerTx, "Over Tx Limit");
    require(_quantity + supply <= maxSupply, "SoldOut");
    require(addressMintedBalance[msg.sender] < maxPerWallet, "Over MaxPerWallet");
    addressMintedBalance[msg.sender] += _quantity;
    
    _safeMint(msg.sender, _quantity);
  }

  function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
    OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(_owner)) == operator) return true;
    return super.isApprovedForAll(_owner, operator);
  }
    
  function withdraw() public onlyOwner {
    (bool success, ) = lead.call{value: address(this).balance}("");
    require(success, "Failed to send to lead.");
  }

}

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
    }