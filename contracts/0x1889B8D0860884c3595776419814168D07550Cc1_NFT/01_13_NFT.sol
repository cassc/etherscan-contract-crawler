// SPDX-License-Identifier: GPL-3.0


pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public cost = 0.04 ether;
  uint256 public maxSupply = 7777;
  uint256 public maxMintAmount = 5; //5
  uint256 public nftPerAddressLimit = 3; //3
  uint256 public wave2MaxMintAmt = 3; //1
  uint256 public counter = 0;
  uint256 public limit = 300; //300 for wave 1
  uint256 public mathP = 225; //
  uint256 public deuxP = 250; //
  uint256 public frkP = 0; //
  uint256 public sarP = 100;
  bool public paused = false;
  bool public revealed = false;
  bool public onlyWhitelisted = true;
  bool public wave2Auth = false;
  // address[] public whitelistedAddresses;
  address[] public pushWhitelist;
  mapping(address => uint256) public addressMintedBalance;
  mapping(address => uint256) public wave2Counter;
  // mapping(address =>bool) public whiteListMap;


//   address payable public payments;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
    // address _payments
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
    // payments = payable(_payments);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    counter+=_mintAmount;

    require(counter <= limit, "The Current Minting Limit for this Wave has been reached");
    require(!paused, "the contract is paused");
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

    if (msg.sender != owner()) {
        if(onlyWhitelisted == true) {
            require(pushisWhitelisted(msg.sender), "user is not whitelisted");
            uint256 ownerMintedCount = addressMintedBalance[msg.sender];
            require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
        }
        require(msg.value >= cost * _mintAmount, "insufficient funds");
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressMintedBalance[msg.sender]++;
      if (wave2Auth == true)
      {
        wave2Counter[msg.sender]++;
        require(wave2Counter[msg.sender] <= wave2MaxMintAmt, "Exceeded Mint Allowance for Wave 2");
      }
      
      _safeMint(msg.sender, supply + i);
    }
    
  }
  

  function startWave2() public onlyOwner()
  {
    wave2Auth = true;
  }

  function shutOffWave2() public onlyOwner()
  {
    wave2Auth = false;
  }

  function saveWave2MintAmount(uint256 _newMax) public onlyOwner(){
    wave2MaxMintAmt = _newMax;
  }

  function setPayouts(uint256 newMath, uint256 newKiks, uint256 newFrk, uint256 newSarp) public onlyOwner() {
    mathP = newMath;
    deuxP = newKiks;
    frkP = newFrk;
    sarP = newSarp;

  }
  // function isWhitelisted(address _user) public view returns (bool) {
  //   for (uint i = 0; i < whitelistedAddresses.length; i++) {
  //     if (whitelistedAddresses[i] == _user) {
  //         return true;
  //     }
  //   }
  //   return false;
  // }

    function pushisWhitelisted(address _user) public view returns (bool) {
    for (uint i = 0; i < pushWhitelist.length; i++) {
      if (pushWhitelist[i] == _user) {
          return true;
      }
    }
    return false;
  }
  
  function refreshCounter() public onlyOwner()
  {
      counter = 0;
  }
  function setLimit(uint256 new_limit) public onlyOwner(){
    limit = new_limit;
  }
  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function reveal() public onlyOwner() {
      revealed = true;
  }
  
  function setNftPerAddressLimit(uint256 _limit) public onlyOwner() {
    nftPerAddressLimit = _limit;
  }
  
  function setCost(uint256 _newCost) public onlyOwner() {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
  function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }
  
  // function whitelistUsers(address[] calldata _users) public onlyOwner {
  //   delete whitelistedAddresses;
  //   whitelistedAddresses = _users;
  // }

    function pushToWhitelist(address []calldata _users) public onlyOwner {
    for(uint256 i=0; i<_users.length;i++){
      pushWhitelist.push(_users[i]);
  }
  }




 
  function withdraw() public payable onlyOwner {

    (bool mathieu, ) = payable(0x4cfC51822814fF99543189d5fBC9963C9AD36cc8).call{value: address(this).balance * mathP / 1000}(""); //22.5% Sour Ce Wallet
    require(mathieu);
    (bool kiki, ) = payable(0xb208a8106B71F3999a5B659D517d79DD8Feaf6C5).call{value: address(this).balance * deuxP / 775}(""); //25% 
    require(kiki);
    (bool farouk, ) = payable(0x70C2B4f4923208123572671580BBc218479D90e4).call{value: address(this).balance * frkP / 525}("");  //7%
    require(farouk);
    (bool simon_ariel, ) = payable(msg.sender).call{value: address(this).balance * sarP /100}("");  //Le Rest
    require(simon_ariel);
    // (bool pay,) = payable(payments).call{value: address(this).balance}("");
    // require(pay);

  }
}