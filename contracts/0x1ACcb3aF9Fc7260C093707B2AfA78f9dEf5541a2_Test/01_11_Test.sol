// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
/// @title Test
/// @dev TheRatKing

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Test is ERC721A, Ownable {

    string  public baseURI;

    address public proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    address public lead;

    bool public publicPaused = true;
    bool public whitelistPaused = true;
    bool public claimPaused = true;
    
    uint256 public cost = 0.005 ether;
    uint256 public costWL = 0 ether;
    uint256 public costClaim = 0 ether;
    uint256 public maxSupply = 2500;
    uint256 public maxPerWalletPublic = 1;
    uint256 public maxPerWalletWL = 1;
    uint256 public maxPerWalletOG = 2;
    uint256 public maxPerTx = 1;
    address public testV1;
    uint256 supply = totalSupply();

    mapping(address => uint) public addressMintedBalance;
    mapping(address => uint) public addressMintedBalanceWL;
    mapping(address => uint) public addressMintedBalanceOG;
    mapping (address => bool) public isWhitelisted;
    mapping (address => bool) public isOg;
    

 constructor(
    string memory _baseURI,
    address _lead,
    address _testV1
  )ERC721A("Test", "TST") {
    baseURI = _baseURI;
    lead = _lead;
    testV1 = _testV1;
  }

  modifier publicnotPaused() {
    require(!publicPaused, "Contract is Paused");
     _;
  }

  modifier whitelistnotPaused() {
    require(!whitelistPaused, "Contract is Paused");
     _;
  }

  modifier claimnotPaused() {
    require(!claimPaused, "Contract is Paused");
     _;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, 'The caller is another contract.');
    _;
  }


 function _startTokenId() internal view override virtual returns (uint256) {
        return 1;
 }


  function setTestV1Address(address _testV1) public onlyOwner {
    testV1 =_testV1;
  }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    require(_exists(_tokenId), "Token does not exist.");
    return string(abi.encodePacked(baseURI, Strings.toString(_tokenId),".json"));
  }

  function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  function addToWhitelist(address[] calldata entries) external onlyOwner {
        for(uint8 i = 0; i < entries.length; i++) {
            isWhitelisted[entries[i]] = true;
        }   
    }

   function addToOG(address[] calldata entries) external onlyOwner {
        for(uint8 i = 0; i < entries.length; i++) {
            isOg[entries[i]] = true;
        }   
    } 
  
  function togglePublic(bool _state) external onlyOwner {
    publicPaused = _state;
  }

  function toggleWhitelist(bool _state) external onlyOwner {
    whitelistPaused = _state;
  }

  function toggleClaim(bool _state) external onlyOwner {
    claimPaused = _state;
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
    publicnotPaused() 
    callerIsUser() 
  {
    uint256 supply = totalSupply();
    require(msg.value >= cost, "Not Enough Ether");
    require(_quantity <= maxPerTx, "Over Tx Limit");
    require(_quantity + supply <= maxSupply, "SoldOut");
    require(addressMintedBalance[msg.sender] < maxPerWalletPublic, "Over MaxPerWallet");
    addressMintedBalance[msg.sender] += _quantity;
    
    _safeMint(msg.sender, _quantity);
  }

  function whitelistMint(uint256 _quantitty)
    public 
    whitelistnotPaused() 
    callerIsUser() 
  {
    uint256 supply = totalSupply();
    require(_quantitty <= maxPerTx, "Over Tx Limit");
    require(_quantitty + supply <= maxSupply, "SoldOut");
    require(addressMintedBalanceWL[msg.sender] < maxPerWalletWL, "Over maxPerWallet");
    require(isWhitelisted[msg.sender],  "You are not whitelisted");
    addressMintedBalanceWL[msg.sender] += _quantitty;

     _safeMint(msg.sender, _quantitty);
  }

  function claimMint(uint256 _quanttity)
    public 
    claimnotPaused() 
    callerIsUser() 
  {
    uint256 supply = totalSupply();
    require(addressMintedBalanceOG[msg.sender] < maxPerWalletOG, "Already Claimed");
    require(_quanttity + supply <= maxSupply, "SoldOut");
    require(_quanttity <= maxPerWalletOG, "Over maxPerWallet");
    require(isOg[msg.sender], "You are not OG");
    addressMintedBalanceOG[msg.sender] += _quanttity;

     _safeMint(msg.sender, _quanttity);
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