// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BrianNftsByBraindom is ReentrancyGuard , ERC721("Brian Nfts By Braindom", "BRIAN") {
  using SafeMath for uint256;

  string public baseURI;
  string public endingPrefix;

  // Booleans
  bool public isPublicSaleActive = false;
  bool public isWhitelistActive = false;
  bool public isRaffleSaleActive = false;
  bool public isDevSaleStarted = false;
  bool public isRevealed = false;

  // Base variables
  uint256 public circulatingSupply;
  address public owner = msg.sender;
  uint256 public itemPrice = 0.25 ether;
  uint256 public whitelistPrice = 0.25 ether;
  uint256 public raffleSalePrice = 0.25 ether;
  uint256 public constant _totalSupply = 9_999;
  uint256 public devReserved = 300;

  // Limits
  uint256 internal walletLimit = 2;

  mapping(address => bool) private whitelist;
  mapping(address => bool) private raffleSaleList;
  mapping(address => bool) private devAllowlist;
  mapping(address => uint256) private addressIndices;

  // Variables for random indexed tokens
  uint internal nonce = 0;
  
  //Public mint, Whitelist mint, Raffle mint and Dev mint
  function publicMint(uint256 _amount)
    external
    payable
    tokensAvailable(_amount)
    callerIsUser()
  {
    address minter = msg.sender;
    require(isPublicSaleActive, "Public sale not started");
    require(addressIndices[minter] + _amount <= walletLimit, "Max wallet mint limit reached");
    require(msg.value >= _amount * itemPrice, "Incorrect payable amount");

    for (uint256 i = 0; i < _amount; i++) {
      ++addressIndices[minter];
      _safeMint(minter, ++circulatingSupply);
    }
  }
  function whitelistMint(uint256 _amount) external payable
    tokensAvailable(_amount)
    whitelistSaleStarted()
    callerIsUser()
  {
    address minter = msg.sender;
    require(whitelist[minter] == true, "Not allowed to whitelist mint");
    require(addressIndices[minter] + _amount <= walletLimit, "Max wallet mint limit reached");
    require(msg.value >= _amount * whitelistPrice, "Incorrect payable amount");
    
    if(addressIndices[minter] + _amount >= walletLimit) {
      whitelist[minter] = false;
    }

    for(uint256 i = 0; i < _amount; i++) {
      ++addressIndices[minter];
      _safeMint(minter, ++circulatingSupply);
    }
  }
  function raffleMint(uint256 _amount) external payable
    tokensAvailable(_amount)
    raffleSaleStarted()
    callerIsUser()
  {
    address minter = msg.sender;
    require(raffleSaleList[minter] == true, "Not allowed to raffle mint");
    require(addressIndices[minter] + _amount <= walletLimit, "Max wallet mint limit reached");
    require(msg.value >= _amount * raffleSalePrice, "Incorrect payable amount");

    if(addressIndices[minter] + _amount >= walletLimit) {
      raffleSaleList[minter] = false;
    }

    for(uint256 i = 0; i < _amount; i++) {
      ++addressIndices[minter];
      _safeMint(minter, ++circulatingSupply);
    }
  }
  function devMint(uint256 _amount) external payable
    tokensAvailable(_amount)
    devSaleStarted()
    callerIsUser()
  {
      address minter = msg.sender;
      require(devAllowlist[minter] == true, "Not allowed");
      require(addressIndices[minter] + _amount <= walletLimit, "Max wallet mint limit reached");
      require(devReserved - _amount > 0, "Dev sale sold out");

      if(addressIndices[minter] + _amount >= walletLimit) {
        devAllowlist[minter] = false;
      }

      for(uint256 i = 0; i < _amount; i++) {
        --devReserved;
        ++addressIndices[minter];
        _safeMint(minter, ++circulatingSupply);
      }

  }


  //QUERIES
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    return isRevealed ? string(abi.encodePacked(baseURI, '/', Strings.toString(tokenId), endingPrefix)) : baseURI;
  }
  function tokensRemaining() public view returns (uint256) {
    return _totalSupply - circulatingSupply;
  }
  function getWalletLimit() public view returns (uint256) {
    return walletLimit;
  }
  function isRaffleSaleAllowed() public view returns(bool) {
    return raffleSaleList[msg.sender] == true;
  }
  function isWhitelistSaleAllowed() public view returns(bool) {
    return whitelist[msg.sender] == true;
  }
  function isDevSaleAllowed() public view returns(bool) {
    return devAllowlist[msg.sender] == true;
  }
  //OWNER ONLY
  function addToWhitelistSaleList(address[] calldata _whitelistMinters) external onlyOwner {
    for(uint256 i = 0; i < _whitelistMinters.length; i++)
      whitelist[_whitelistMinters[i]] = true;
  }
  function addToRaffleList(address[] calldata _raffleSaleMinters) external onlyOwner {
    for(uint256 i = 0; i < _raffleSaleMinters.length; i++)
      raffleSaleList[_raffleSaleMinters[i]] = true;
  }
  function addToDevList(address[] calldata _devSaleMinters) external onlyOwner {
    for(uint256 i = 0; i < _devSaleMinters.length; i++)
      devAllowlist[_devSaleMinters[i]] = true;
  }
  function setBaseURI(string memory __baseURI) external onlyOwner {
        baseURI = __baseURI;
    }
  
  function togglePublicSale() external onlyOwner {
    isPublicSaleActive = !isPublicSaleActive;
  }
  function toggleWhitelistSale() external onlyOwner {
    isWhitelistActive = !isWhitelistActive;
  }
  function toggleRaffleSale() external onlyOwner {
    isRaffleSaleActive = !isRaffleSaleActive;
  }
  function toggleDevSale() external onlyOwner {
    isDevSaleStarted = !isDevSaleStarted;
  }
  function toggleReveal() external onlyOwner {
    isRevealed = !isRevealed;
  }
  function updateWhitelistSalePrice(uint256 _price) external onlyOwner {
    whitelistPrice = _price;
  }
  function updatePublicSalePrice(uint256 _price) external onlyOwner {
    itemPrice = _price;
  }
  function updateRaffleSalePrice(uint256 _price) external onlyOwner {
    raffleSalePrice = _price;
  }
  function updateDevSaleReserveds(uint256 _amount) external onlyOwner {
    devReserved = _amount;
  }
  function updateWalletLimit(uint256 _newLimit) external onlyOwner {
    walletLimit = _newLimit;
  }
  function unlistWhitelistMinter(address[] calldata _minters) external onlyOwner {
    for(uint256 i = 0; i < _minters.length; i++)
      whitelist[_minters[i]] = false;
  }
  function unlistRaffleMinter(address[] calldata _minters) external onlyOwner {
    for(uint256 i = 0; i < _minters.length; i++)
      raffleSaleList[_minters[i]] = false;
  }

  function setEndingPrefix(string calldata _prefix) external onlyOwner {
    endingPrefix = _prefix;
  }

  function withdraw() external onlyOwner nonReentrant callerIsUser() {
      (bool isTransfered, ) = msg.sender.call{value: address(this).balance}("");
      require(isTransfered, "Transfer failed");
  }

  function totalSupply() public view returns (uint256) {
    return circulatingSupply;
  }

  function burn(
    uint256 _tokenId
  ) external onlyOwner validNFToken(_tokenId)
  {
    circulatingSupply--;
    _burn(_tokenId);
  }

  //MODIFIERS
  modifier tokensAvailable(uint256 _amount) {
      require(_amount <= tokensRemaining(), "Try minting less tokens");
      _;
  }
  modifier raffleSaleStarted() {
    require(isRaffleSaleActive == true, "Raffle Minting is not started");
    _;
  }
  modifier whitelistSaleStarted() {
    require(isWhitelistActive == true, "Whitelist sale is not started");
    _;
  }
  modifier devSaleStarted() {
    require(isDevSaleStarted == true, "Dev sale not started");
    _;
  }
  modifier onlyOwner() {
    require(owner == msg.sender, "Ownable: Caller is not the owner");
    _;
  }
    /**
   * @dev Guarantees that _tokenId is a valid Token.
   * @param _tokenId ID of the NFT to validate.
   */
  modifier validNFToken(
    uint256 _tokenId
  )
  {
    require(ownerOf(_tokenId) != address(0));
    _;
  }
  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }
}