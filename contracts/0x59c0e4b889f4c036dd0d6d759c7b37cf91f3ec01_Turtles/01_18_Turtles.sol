// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; 
import "./SHELL.sol";

contract Turtles is ERC721Enumerable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  mapping(address => uint256) public addressMintedBalance;

  SHELL public shell; 

  address public stakingAddress;
  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public cost = 0.05 ether;
  uint256 public maxSupply = 8888;
  uint256 public publicSupply = 4444;  
  uint256 public maxMintAmount = 10;
  uint256 public turtlesPerAddressLimit = 10;
  uint256 public mintingIndex = 1;
  uint256 public turtlesMinted = 0;
  uint256 public supply = totalSupply(); 
  uint256 internal oneOfOneStartingIndex; 
  uint256 internal oneOfOneIndex; 

  //minting and burning fees in SHELL
  uint[] public shellMintingCosts = [25 ether, 50 ether, 75 ether, 100 ether]; 
  uint public shellMintingCost = 25 ether;
  uint[] public turtleBurningCosts = [5 ether, 10 ether, 20 ether, 30 ether]; 
  uint public turtleBurningCost = 5 ether; 

  bool public paused = false;
  bool public revealed = false;
  bool public burningPaused = true; 
  bool public shellMintingPaused = true;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri,
    address _shell,
    uint256 _oneOfOneStartingIndex,
    uint256 _oneOfOneIndex

  ) ERC721(_name, _symbol) {
    shell = SHELL(_shell);
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
    oneOfOneIndex = _oneOfOneIndex;
    oneOfOneStartingIndex = _oneOfOneStartingIndex;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // MINTING AND BURNING TURTLES

  /**
   * Mints the given amount of Turtles using ETH
   * @param _mintAmount amount of Turtles to be minted
   */
  function mint(uint256 _mintAmount) public payable nonReentrant {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmount, "INVALID MINT AMOUNT!");
    require(turtlesMinted < maxSupply, "NO MORE TURTLES LEFT!");
    if (msg.sender != owner()) {
        require(!paused, "MINTING IS PAUSED!");
        require(mintingIndex <= publicSupply, "ONLY MINTABLE WITH $SHELL!");
        require((mintingIndex + _mintAmount) <= publicSupply + 1, "NOT ENOUGH PUBLIC SUPPLY LEFT!");
        require(msg.value >= cost * _mintAmount, "INSUFFICIENT FUNDS!");
        require(addressMintedBalance[msg.sender] + _mintAmount <= turtlesPerAddressLimit, "YOU CAN ONLY HOLD 10 TURTLES!");
    }
    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, mintingIndex++); 
      turtlesMinted++;
    }
  }
  
  /**
   * Mints the given amount of Turtles using $SHELL 
   * Available once the public sale of the first 4444 Turtles has ended
   * @param _mintAmount amount of Turtles to be minted
   */
  function mintWithShell(uint256 _mintAmount) public payable nonReentrant{
    require(!shellMintingPaused, "SHELL MINTING IS PAUSED!");
    require(turtlesMinted > publicSupply, "CAN'T MINT WITH SHELL YET!");
    require(mintingIndex + _mintAmount <= oneOfOneStartingIndex + 1, "NO MORE TURTLES LEFT TO MINT WITH $SHELL"); 
    require(queryShellOfAddress(msg.sender) >= shellMintingCost * _mintAmount, "YOU NEED TO EARN MORE $SHELL!");
    require(msg.sender == owner() || addressMintedBalance[msg.sender] + _mintAmount <= turtlesPerAddressLimit, "YOU CAN ONLY HOLD 10 TURTLES!");
    shell.burn(_msgSender(), shellMintingCost * _mintAmount);
    for (uint256 i = 1; i <= _mintAmount; i++){
      if(turtlesMinted % 1111 == 0) {
          shellMintingCost = shellMintingCosts[(turtlesMinted - 4444) / 1111];
          turtleBurningCost = turtleBurningCosts[(turtlesMinted - 4444) / 1111];
       }
      addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, mintingIndex++); 
      turtlesMinted++;
    }
  }

  /**
   * Burns an owned Turtle at the current burning cost and mints a new one
   * @param _tokenId ID of the Turtle to be burned
   */
  function burnTurtle(uint256 _tokenId) public nonReentrant payable { 
      require(burningPaused == false, "BURNING IS CURRENTLY PAUSED!");
      require(msg.sender == ownerOf(_tokenId), "HEY! THIS IS NOT YOURS!");
      require(mintingIndex < oneOfOneStartingIndex, "NO MORE TURTLES LEFT TO MINT!");
      if(turtlesMinted % 1111 == 0 && turtlesMinted >= publicSupply) {
        turtleBurningCost = turtleBurningCosts[(turtlesMinted - 4444) / 1111];
        shellMintingCost = shellMintingCosts[(turtlesMinted - 4444) / 1111];
      }
      require(queryShellOfAddress(msg.sender) >= turtleBurningCost, "YOU NEED TO EARN MORE $SHELL!");
      _burn(_tokenId);
      shell.burn(_msgSender(), turtleBurningCost); 
      _safeMint(msg.sender, mintingIndex++); 
      turtlesMinted++;
  }

  /**
   * Burns two owned Turtles and mints a new one with a 5% chance of it being a super rare 1of1 Turtle
   * @param _turtle1 ID of the first Turtle to be burned
   * @param _turtle2 ID of the second Turtle to be burned
   */
  function burnTwoTurtles(uint256 _turtle1, uint256 _turtle2) public nonReentrant {
    require(burningPaused == false, "BURNING IS CURRENTLY PAUSED!");
    require(msg.sender == ownerOf(_turtle1) && msg.sender == ownerOf(_turtle2), "HEY! BURN YOUR OWN TURTLES!");
    require(_turtle1 != _turtle2, "PLEASE USE 2 DIFFERENT TURTLES!");
    require(turtlesMinted < maxSupply, "NO MORE TURTLES LEFT TO MINT!");
    _burn(_turtle1);
    _burn(_turtle2);
    if(turtlesMinted % 1111 == 0 && turtlesMinted >= publicSupply) {
      turtleBurningCost = turtleBurningCosts[(turtlesMinted - 4444) / 1111];
      shellMintingCost = shellMintingCosts[(turtlesMinted - 4444) / 1111];
    }
    if((random(_turtle1) % 100) <= 5) { 
      if(oneOfOneIndex <= maxSupply) {
        _safeMint(msg.sender, oneOfOneIndex++);
        turtlesMinted++;
      } 
      else {
        _safeMint(msg.sender, mintingIndex++);
        turtlesMinted++;
      }
    }
    else {
      _safeMint(msg.sender, mintingIndex++); 
      turtlesMinted++;
    }
    addressMintedBalance[msg.sender]--;
  }

  // USEFUL QUERIES

  /**
   * Returns IDs of Turtles that are in your wallet
   */
  function myTurtles() public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(msg.sender);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(msg.sender, i);
    }
    return tokenIds;
  }

  /**
   * Returns amount of $SHELL that a given address holds
   * @param _address address of the user to be queried 
   */
  function queryShell(address _address) external view onlyOwner returns (uint256) {
    return shell.balanceOf(_address);
  }

  /**
   * Returns amount of $SHELL that a given address holds
   * @param _address address of the user to be queried 
   */
  function queryShellOfAddress(address _address) internal view returns (uint256) {
    return shell.balanceOf(_address);
  }
  
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    if(revealed == false) {
        return notRevealedUri;
    }
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }
  function queryOneOfOneIndex() external view onlyOwner returns(uint256 index) {
    return oneOfOneIndex;
  }

  // ONLY FOR TURTLE ADMINS

  function reveal(bool _revealed) public onlyOwner {
      revealed = _revealed;
  }
  function setturtlesPerAddressLimit(uint256 _limit) public onlyOwner {
    turtlesPerAddressLimit = _limit;
  }
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }
  function setShellMintingCost(uint256 _shellCost) external onlyOwner {
    shellMintingCost = _shellCost;
  }
  function setShellBurningCost(uint256 _shellCost) external onlyOwner {
    turtleBurningCost = _shellCost;
  }
  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
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
  function setPublicMintingPaused(bool _state) public onlyOwner {
    paused = _state;
  }
  function setShellMintingPaused(bool _state) public onlyOwner {
    shellMintingPaused = _state;
  }
  function setBurningPaused(bool _state)  public onlyOwner {
    burningPaused = _state; 
  }
  function setPublicSupply(uint256 _amount)  public onlyOwner {
    publicSupply = _amount; 
  }
  function withdraw() public payable onlyOwner {  
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
  function setStakingAddress(address _stakingAddress) public onlyOwner {
    setApprovalForAll(_stakingAddress, true);
    stakingAddress = _stakingAddress;
  }

  // UTILS

  /**
   * generates a pseudorandom number
   * @param _input a value ensure different outcomes for different sources in the same block
   * @return a pseudorandom value
   */
  function random(uint256 _input) internal view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(
      tx.origin,
      blockhash(block.number - 1),
      block.timestamp,
      block.difficulty,
      _input
    )));
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
     if (_msgSender() != address(stakingAddress)) require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
    _transfer(from, to, tokenId);
  } 
}