// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
    ░██████╗████████╗░█████╗░██╗░░██╗███████╗██████╗░░██████╗
    ██╔════╝╚══██╔══╝██╔══██╗██║░██╔╝██╔════╝██╔══██╗██╔════╝
    ╚█████╗░░░░██║░░░███████║█████═╝░█████╗░░██████╔╝╚█████╗░
    ░╚═══██╗░░░██║░░░██╔══██║██╔═██╗░██╔══╝░░██╔══██╗░╚═══██╗
    ██████╔╝░░░██║░░░██║░░██║██║░╚██╗███████╗██║░░██║██████╔╝
    ╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═════╝░
    StakersNFT / 2021

*/
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';



contract StakersNFT is ERC721Enumerable, Ownable {
  using Strings for uint256;

  uint256 public constant stakersReserve = 50;
  uint256 public constant stakersPublic = 9950;
  uint256 public constant stakersMax = stakersReserve + stakersPublic;
  uint256 public constant purchaseLimit = 10;
  uint256 public constant stakersPrice = 0.085 ether;

  bool public saleIsActive = false;
  bool public preSaleIsActive = false;
  bool public mysterySkinActive = false;

  uint256 public preSaleMaxMint = 5;

  uint256 public stakersReserveSupply;
  uint256 public stakersPublicSupply;
  

  mapping(address => bool) private _preSaleList;
  mapping(address => uint256) private _preSaleListClaimed;
  mapping (uint256 => string) private mysterySkin;
  mapping (uint256 => string) private _tokenURIs;

  string private _contractURI = '';
  string private _tokenBaseURI = '';
  string private _tokenRevealedBaseURI = '';
  
    address addr1 = 0xBBba53998855117c9Bcf85dC7bC551b061e921D1;
    address addr2 = 0xa27165136A086E278CC66d812D817405c41af3ED;
    address addr3 = 0x0664494538F599bE00c4f39fd83C944656436Ce9;
    address addr4 = 0xaA49136A0865A7B30c676D5d7Abb18a224cF39Fc;
    address addr5 = 0xFdb318348726C4102c8459cD33b5F5D72c8Cad4D;


constructor() ERC721("Stakers", "STKR") { 
        
      
    }  
      function activateMysterySkin(uint256 tokenId) public {
        require(mysterySkinActive, 'Mystery Skins are not active yet');
        address owner = ERC721.ownerOf(tokenId);
        require(
            _msgSender() == owner,
            "This isn't your Staker."
        );
        require (bytes(mysterySkin[tokenId]).length == 0, "Your Myster Skin is already active.");
           
        mysterySkin[tokenId] = "a";
    }
     function deActivateMysterySkin(uint256 tokenId) public {
        require(mysterySkinActive, 'Mystery Skins are not active yet');
        address owner = ERC721.ownerOf(tokenId);
        require(
            _msgSender() == owner,
            "This isn't your Staker."
        );
        require (bytes(mysterySkin[tokenId]).length > 0, "Your Myster Skin is already deactived.");

           
        mysterySkin[tokenId] = "";
    }
    

  function addToAllowList(address[] calldata addresses) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Cannot add the null address");

      _preSaleList[addresses[i]] = true;
      _preSaleListClaimed[addresses[i]] > 0 ? _preSaleListClaimed[addresses[i]] : 0;
    }
  }

  function onAllowList(address addr) external view returns (bool) {
    return _preSaleList[addr];
  }

  function removeFromAllowList(address[] calldata addresses) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Cannot add the null address");

      _preSaleList[addresses[i]] = false;
    }
  }


  function allowListClaimedBy(address owner) external view returns (uint256){
    require(owner != address(0), 'Zero address not on Allow List');

    return _preSaleListClaimed[owner];
  }

  function mintStaker(uint256 numberOfTokens) external payable {
   require(saleIsActive, 'Minting is not live');
    require(totalSupply() < stakersMax, 'There are no tokens left');
    
    require(numberOfTokens <= purchaseLimit, 'This would exceed the limit');

    require(stakersPublicSupply + numberOfTokens <= stakersPublic, 'There are no tokens left');
    require(stakersPrice * numberOfTokens <= msg.value, 'ETH sent is not sufficient');

    for (uint256 i = 0; i < numberOfTokens; i++) {

      if (stakersPublicSupply < stakersPublic) {

        uint256 tokenId = stakersReserve + stakersPublicSupply + 1;

        stakersPublicSupply += 1;
        _safeMint(msg.sender, tokenId);
      }
    }
  }

  function purchaseAllowList(uint256 numberOfTokens) external payable {
   require(preSaleIsActive, 'PreSale is not active');
    require(_preSaleList[msg.sender], 'You are not on the PreSale List');
    require(totalSupply() < stakersMax, 'There are no tokens left');
    require(numberOfTokens <= preSaleMaxMint, 'There are no tokens left');
    require(stakersPublicSupply + numberOfTokens <= stakersPublic, 'Purchase would exceed Public Sale');
    require(_preSaleListClaimed[msg.sender] + numberOfTokens <= preSaleMaxMint, 'Purchase exceeds the PreSale Limit');
    require(stakersPrice * numberOfTokens <= msg.value, 'ETH sent is not sufficient');

    for (uint256 i = 0; i < numberOfTokens; i++) {

      uint256 tokenId = stakersReserve + stakersPublicSupply + 1;

      stakersPublicSupply += 1;
      _preSaleListClaimed[msg.sender] += 1;
      _safeMint(msg.sender, tokenId);
    }
  }

  function gift(address[] calldata to) external onlyOwner {
    require(totalSupply() < stakersMax, 'There are no tokens left');
    require(stakersReserveSupply + to.length <= stakersReserve, 'There are no tokens left to gift');

    for(uint256 i = 0; i < to.length; i++) {
      uint256 tokenId = stakersReserveSupply + 1;

      stakersReserveSupply += 1;
      _safeMint(to[i], tokenId);
    }
  }

  function setsaleIsActive(bool _saleIsActive) external onlyOwner {
    saleIsActive = _saleIsActive;
  }

  function setpreSaleIsActive(bool _preSaleIsActive) external onlyOwner {
    preSaleIsActive = _preSaleIsActive;
  }




   function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance / 5;
        require(payable(addr1).send(balance));
        require(payable(addr2).send(balance));
        require(payable(addr3).send(balance));
        require(payable(addr4).send(balance));
        require(payable(addr5).send(balance));
        
    }

  function setContractURI(string calldata URI) external onlyOwner {
    _contractURI = URI;
  }

  function setBaseURI(string calldata URI) external onlyOwner {
    _tokenBaseURI = URI;
  }
    
  function toggleMysteryStatus() external onlyOwner {
        mysterySkinActive = !mysterySkinActive;
    }


  function setRevealedBaseURI(string calldata revealedBaseURI) external onlyOwner {
    _tokenRevealedBaseURI = revealedBaseURI;
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }
  

    
  function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
    require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

    string memory revealedBaseURI = _tokenRevealedBaseURI;
    return bytes(revealedBaseURI).length > 0 ?
      string(abi.encodePacked(revealedBaseURI, tokenId.toString(), mysterySkin[tokenId])) :
      _tokenBaseURI;
  }

}