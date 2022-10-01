// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFT is Ownable, ERC721A, Pausable, ReentrancyGuard {
  bool public isRevealed = false;
  uint256 public collectionSize;
  uint256 public maxBatchSize;
  uint256 public amountForDevs;
  uint256 private withdrawnSoFar;

  struct WhitelistSaleConfig {
    uint32 startTime;
    uint64 price;
    uint64 maxPerAddress;
  }

  WhitelistSaleConfig public whitelistSaleConfig;

  struct PublicSaleConfig {
    uint32 startTime;
    uint64 price;
    uint64 maxPerAddress;
  }

  PublicSaleConfig public publicSaleConfig;

  string private _baseTokenURI;
  string private _defaultTokenURI;

    event PausedX();
    event UnpausedX();
    event WhitelistSaleSetup(uint32 whitelistSaleStartTime_, uint64 whitelistSalePriceWei_, uint64 maxPerAddressDuringWhitelistSaleMint);
    event WhiteListMint(address indexed to, uint256 quantity);
    event PublicSaleActivated(uint32 publicSaleStartTime_, uint64 publicSalePriceWei_, uint64 maxPerAddressDuringPublicSaleMint);
    event Mint(address indexed to, uint256 quantity);
    event RevealSet(bool status);
    event BaseUriSet(string baseTokenUri_);
    event DefaultTokenUriSet(string DefaultTokenUri_);
    event CollectionSizeSet(uint256 size_);
    event FundsWithdrawn(uint256 toDonation, uint256 txToThirty, uint256 txToOwner);

  constructor(
    uint256 collectionSize_,
    uint256 maxBatchSize_,
    uint256 amountForDevs_
  ) ERC721A("PLAXY NFT", "PLAXY") {
    collectionSize = collectionSize_;
    maxBatchSize = maxBatchSize_;
    amountForDevs = amountForDevs_;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract - MSGCODE: 9999");
    _;
  }

  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "need to send more ETH");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  /* @dev Triggers emergency stop mechanism. */
  function pause() external onlyOwner
  {
    _pause();
    emit PausedX();
  }


  /* @dev Returns contract to normal state. */
  function unpause() external onlyOwner
  {
    _unpause();
    emit UnpausedX();
  }

  /* @dev Hook that is called before minting and burning one token. */
  function _beforeTokenTransfers(
      address from,
      address to,
      uint256 startTokenId,
      uint256 quantity
  ) internal virtual whenNotPaused override {
    super._beforeTokenTransfers(from, to, startTokenId, quantity);
  }

  function setupWhitelistSale(
    uint32 whitelistSaleStartTime,
    uint64 whitelistSalePriceWei,
    uint64 maxPerAddressDuringWhitelistSaleMint
  ) external onlyOwner {
    whitelistSaleConfig.startTime = whitelistSaleStartTime;
    whitelistSaleConfig.price = whitelistSalePriceWei;
    whitelistSaleConfig.maxPerAddress = maxPerAddressDuringWhitelistSaleMint;
    emit WhitelistSaleSetup(whitelistSaleConfig.startTime, whitelistSaleConfig.price, whitelistSaleConfig.maxPerAddress);
  }
    
  function whitelistSaleMint(uint64 quantity)
    external
    payable
    callerIsUser
    nonReentrant
  {
    uint256 price = uint256(whitelistSaleConfig.price);
    uint256 saleStartTime = uint256(whitelistSaleConfig.startTime);
    uint64 maxPerAddress = whitelistSaleConfig.maxPerAddress;
    require(price != 0, "whitelist sale has not begun yet - MSGCODE: 2000");
    require(
      saleStartTime != 0 && block.timestamp >= saleStartTime,
      "whitelist sale has not begun yet - MSGCODE: 2001"
    );
    require(totalSupply() + quantity <= collectionSize, "reached max supply - MSGCODE: 2002");
    require(
      _getAux(_msgSender()) + quantity <= maxPerAddress,
      "can not mint this many  - MSGCODE: 2004"
    );
    _safeMint(_msgSender(), quantity);
    _setAux(_msgSender(), _getAux(_msgSender()) + quantity); 
    refundIfOver(price * quantity);
    emit WhiteListMint(_msgSender(), quantity);
  }

function devMint(uint256 quantity) external onlyOwner {
    require(
      totalSupply() + quantity <= amountForDevs,
      "too many already minted before dev mint - MSGCODE: 2012"
    );
    require(
      quantity % maxBatchSize == 0,
      "can only mint a multiple of the maxBatchSize - MSGCODE: 2013"
    );
    uint256 numChunks = quantity / maxBatchSize;
    for(uint256 i = 0; i < numChunks; i++) {
      _safeMint(msg.sender, maxBatchSize);
    }
  }
  
  function endWhitelistSaleAndSetupPublicSale(
    uint32 publicSaleStartTime,
    uint64 publicSalePriceWei,
    uint64 maxPerAddressDuringPublicSaleMint
  ) external onlyOwner {
    whitelistSaleConfig.startTime = 0;

    publicSaleConfig.startTime = publicSaleStartTime;
    publicSaleConfig.price = publicSalePriceWei;
    publicSaleConfig.maxPerAddress = maxPerAddressDuringPublicSaleMint;
    emit PublicSaleActivated(publicSaleConfig.startTime, publicSaleConfig.price, publicSaleConfig.maxPerAddress);
  }
  

  function publicSaleMint(uint64 quantity)
    external
    payable
    callerIsUser
    nonReentrant
  {
    uint256 price = uint256(publicSaleConfig.price);
    uint256 startTime = uint256(publicSaleConfig.startTime);
    uint64 maxPerAddress = publicSaleConfig.maxPerAddress;
    require(price != 0, "public sale has not begun yet  - MSGCODE: 2005");
    require(
      startTime != 0 && block.timestamp >= startTime,
      "public sale has not begun yet - MSGCODE: 2005"
    );
    require(totalSupply() + quantity <= collectionSize, "reached max supply  - MSGCODE: 2006");
    require(
      _numberMinted(_msgSender()) - _getAux(_msgSender()) + quantity
        <= maxPerAddress,
      "can not mint this many  - MSGCODE: 2007"
    );
    _safeMint(msg.sender, quantity);
    refundIfOver(price * quantity);
    emit Mint(msg.sender, quantity);
  }
    
  function setIsRevealed(bool val) external onlyOwner {
    isRevealed = val;
    emit RevealSet(isRevealed);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721A)
    returns (string memory)
  {
    if (isRevealed) {
      return super.tokenURI(tokenId);
    }

    require(tokenId <= totalSupply(), "token not exist");
    return _defaultTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
    emit BaseUriSet(_baseTokenURI);
  }
    
  function setDefaultTokenURI(string calldata uri) external onlyOwner {
    _defaultTokenURI = uri; 
    emit DefaultTokenUriSet(_defaultTokenURI);
  }

  function setCollectionSize(uint256 size) external onlyOwner {
    collectionSize = size;
    emit CollectionSizeSet(collectionSize);
  }

  function getContractStatus() external view returns (uint32, uint64, uint64, uint32, uint64, uint64) {
    return (whitelistSaleConfig.startTime, whitelistSaleConfig.price, whitelistSaleConfig.maxPerAddress, publicSaleConfig.startTime, publicSaleConfig.price, publicSaleConfig.maxPerAddress);
  }

  function getTokenInfo() external view returns (string memory, string memory) {
      return (_baseTokenURI, _defaultTokenURI);
  }

  function totalFunds() external view returns (uint256, uint256) {
      return (address(this).balance, withdrawnSoFar);
  }


  function withdrawMoney() external onlyOwner nonReentrant {
        address  donationWallet = 0xfeCb63259E9588BddE627f5161DFb407275d584e;
        address  developersWallet = 0xa518c145f1178508E67D825818Af98B5D5040277;
        
        uint256 donationAmount = address(this).balance * 2/100;
        uint256 developersAmount = address(this).balance * 49/100;
        
        
        payable(donationWallet).transfer(donationAmount);      
        payable(developersWallet).transfer(developersAmount);
        
        uint256 balanceB4Tx = address(this).balance;
        payable(msg.sender).transfer(address(this).balance);
        withdrawnSoFar += donationAmount + developersAmount + balanceB4Tx;
        emit FundsWithdrawn(donationAmount, developersAmount, balanceB4Tx);
  }

}