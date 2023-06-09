// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract NftPremium is ERC721Enumerable, ReentrancyGuard, Ownable {
  address tokenAddress;
  using Strings for uint256;
  string public baseURI;
  string public baseExtension = '.json';
  string public notRevealedUri;
  address constant VAULT_ADDRESS = 0x3C10D90796Ce828644951c0682012B3fabA52F8f;
  uint256 public constant MAX_SUPPLY = 8888;
  uint256 public constant MAX_MINT_SUPPLY_SALE = 7000;
  uint256 public constant USER_LIMIT = 10;
  bool public revealed = false;
  // mint window variables
  uint256 public price = 2.5 ether;
  uint256 public price_premint1 = 2 ether; 
  uint256 public price_premint2 = 2.5 ether;
  uint256 public makeNftLimit = 7000;
  uint256 public makeNftLimit_premint1 = 5000;
  uint256 public makeNftLimit_premint2 = 7000;
  uint256 public nftSaleCounter = 0;
  uint256 public nftSaleCounter_premint1 = 0;
  uint256 public nftSaleCounter_premint2 = 0;
  bool public saleIsActive = false;
  bool public saleIsActive_premint1 = false;
  bool public saleIsActive_premint2 = false;

  struct UserMakeNft {
    uint256 counter;
  }
  mapping(address => UserMakeNft) userMakeNftStruct;
  mapping(address => UserMakeNft) userMakeNftStruct_premint1;
  mapping(address => UserMakeNft) userMakeNftStruct_premint2;

  event MintedPremium(
    uint256 tokenId,
    uint256 amount,
    address indexed buyer,
    string saleType
  );

  constructor(
    string memory name,
    string memory symbol,
    string memory initBaseURI,
    string memory initNotRevealedUri
  ) ERC721(name, symbol) {
    setBaseURI(initBaseURI);
    setNotRevealedURI(initNotRevealedUri);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function giftNft(
    uint256 mintAmount,
    address _address,
    string memory _saleType
  ) public onlyOwner {
    uint256 supply = totalSupply();
    require(supply + mintAmount <= MAX_SUPPLY, 'Sold out');
    require(mintAmount > 0, 'need to mint at least 1 NFT');

    for (uint256 i = 1; i <= mintAmount; i++) {
      _safeMint(_address, supply + i);
      emit MintedPremium(supply + i, mintAmount, msg.sender, _saleType);
    }
  }

  function setMintPass(address _tokenAddress) external onlyOwner {
    tokenAddress = _tokenAddress;
  }

  /** makeNft for all windows *****************/

  function makeNft(uint256 mintAmount) external payable nonReentrant {
    uint256 supply = totalSupply();
    require(saleIsActive, 'Sale is not active');
    require(supply + mintAmount <= MAX_SUPPLY, 'Sold out');
    require(supply + mintAmount <= MAX_MINT_SUPPLY_SALE, 'Sale Ended');
    require(mintAmount > 0, 'need to mint at least 1 NFT');
    require(msg.value == price * mintAmount, 'Funds Incorrect');
    require(
      nftSaleCounter + mintAmount <= makeNftLimit,
      'NFT Sale Limit Reached'
    );
    require(
      viewUserMakeNftCount(msg.sender) + mintAmount <= USER_LIMIT,
      'you have reached your limit'
    );
    uint256 count = viewUserMakeNftCount(msg.sender);
    for (uint256 i = 1; i <= mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
      emit MintedPremium(supply + i, mintAmount, msg.sender, 'Make NFT');
    }

    addNftCount(mintAmount);
    addMakeNftUserCount(count + mintAmount);
  }

  function makeNft_premint1(uint256 mintAmount) external payable nonReentrant {
    IERC1155 token = IERC1155(tokenAddress);
    require(tokenAddress != address(0), 'Zero address found');
    uint256 supply = totalSupply();
    uint256 brandPass = token.balanceOf(msg.sender, 1);
    uint256 artistPass = token.balanceOf(msg.sender, 2);
    uint256 legendaryPlusPass = token.balanceOf(msg.sender, 3);
    uint256 legendaryPass = token.balanceOf(msg.sender, 4);
    require(
      brandPass >= 1 ||
        artistPass >= 1 ||
        legendaryPlusPass >= 1 ||
        legendaryPass >= 1,
      'No Mintpass found'
    );
    require(saleIsActive_premint1, 'Sale is not active');
    require(supply + mintAmount <= MAX_SUPPLY, 'Sold out');
    require(supply + mintAmount <= MAX_MINT_SUPPLY_SALE, 'Premint Ended');
    require(mintAmount > 0, 'need to mint at least 1 NFT');
    require(msg.value == price_premint1 * mintAmount, 'Funds Incorrect');
    require(
      nftSaleCounter_premint1 + mintAmount <= makeNftLimit_premint1,
      'Premint Sale Limit Reached'
    );
    require(
      viewUserMakeNftCount_premint1(msg.sender) + mintAmount <= USER_LIMIT,
      'you have reached your limit'
    );
    uint256 count = viewUserMakeNftCount_premint1(msg.sender);

    for (uint256 i = 1; i <= mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
      emit MintedPremium(supply + i, mintAmount, msg.sender, 'Premint');
    }
    addNftCount_premint1(mintAmount);
    addMakeNftUserCount_premint1(count + mintAmount);
  }

  function makeNft_premint2(uint256 mintAmount) external payable nonReentrant {
    IERC1155 token = IERC1155(tokenAddress);
    require(tokenAddress != address(0), 'Zero address found');
    uint256 supply = totalSupply();
    uint256 brandPass = token.balanceOf(msg.sender, 1);
    uint256 artistPass = token.balanceOf(msg.sender, 2);
    uint256 legendaryplusPass = token.balanceOf(msg.sender, 3);
    uint256 legendaryPass = token.balanceOf(msg.sender, 4);
    uint256 premiumPass = token.balanceOf(msg.sender, 5);
    require(
      brandPass >= 1 ||
        artistPass >= 1 ||
        legendaryplusPass >= 1 ||
        legendaryPass >= 1 ||
        premiumPass >= 1,
      'No Mintpass found'
    );
    require(saleIsActive_premint2, 'Sale is not active');
    require(supply + mintAmount <= MAX_SUPPLY, 'Sold out');
    require(supply + mintAmount <= MAX_MINT_SUPPLY_SALE, 'Premint Ended');
    require(mintAmount > 0, 'need to mint at least 1 NFT');
    require(
      nftSaleCounter_premint2 + mintAmount <= makeNftLimit_premint2,
      'premint2 Sale Limit Reached'
    );
    require(msg.value == price_premint2 * mintAmount, 'insufficient funds');
    require(
      viewUserMakeNftCount_premint2(msg.sender) + mintAmount <= USER_LIMIT,
      'you have reached your limit'
    );
    uint256 count = viewUserMakeNftCount_premint2(msg.sender);

    for (uint256 i = 1; i <= mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
      emit MintedPremium(supply + i, mintAmount, msg.sender, 'Brand NFT');
    }
    addNftCounts_premint1(mintAmount);
    addMakeNftUserCount_premint2(count + mintAmount);
  }

  /** SaleCounters for all windows ***************/

  function addNftCount(uint256 y) private {
    nftSaleCounter = nftSaleCounter + y;
  }

  function addNftCount_premint1(uint256 y) private {
    nftSaleCounter_premint1 = nftSaleCounter_premint1 + y;
  }

  function addNftCounts_premint1(uint256 y) private {
    nftSaleCounter_premint2 = nftSaleCounter_premint2 + y;
  }

  /**  Usercounts for all windows  **************/

  function addMakeNftUserCount(uint256 counter) private {
    userMakeNftStruct[msg.sender].counter = counter;
  }

  function addMakeNftUserCount_premint1(uint256 counter) private {
    userMakeNftStruct_premint1[msg.sender].counter = counter;
  }

  function addMakeNftUserCount_premint2(uint256 counter) private {
    userMakeNftStruct_premint2[msg.sender].counter = counter;
  }

  /** Limits for all windows ****************/

  function setMakeNftLimit(uint256 newMakeNftLimit) external onlyOwner {
    makeNftLimit = newMakeNftLimit;
  }

  function setMakeNftLimit_premint1(uint256 newmakeNftLimit_premint1)
    external
    onlyOwner
  {
    makeNftLimit_premint1 = newmakeNftLimit_premint1;
  }

  function setMakeNftLimit_premint2(uint256 _newpremint2Limit)
    external
    onlyOwner
  {
    makeNftLimit_premint2 = _newpremint2Limit;
  }

  /** FlipSale for all windows ****************/

  function flipSale() external onlyOwner {
    saleIsActive = !saleIsActive;
  }

  function flipSale_premint1() external onlyOwner {
    saleIsActive_premint1 = !saleIsActive_premint1;
  }

  function flipSale_premint2() external onlyOwner {
    saleIsActive_premint2 = !saleIsActive_premint2;
  }

  /** view User Counts for all windows **************/

  function viewUserMakeNftCount(address userAddress)
    public
    view
    returns (uint256)
  {
    return userMakeNftStruct[userAddress].counter;
  }

  function viewUserMakeNftCount_premint1(address userAddress)
    public
    view
    returns (uint256)
  {
    return userMakeNftStruct_premint1[userAddress].counter;
  }

  function viewUserMakeNftCount_premint2(address userAddress)
    public
    view
    returns (uint256)
  {
    return userMakeNftStruct_premint2[userAddress].counter;
  }

  /** view Price for all windows **************/

  function viewPrice() public view returns (uint256) {
    return price;
  }

  function viewPrice_premint1() public view returns (uint256) {
    return price_premint1;
  }

  function viewPrice_premint2() public view returns (uint256) {
    return price_premint2;
  }

  /** view IsActive for all windows **************/

  function viewIsActive() public view returns (bool) {
    return saleIsActive;
  }

  function viewIsActive_premint1() public view returns (bool) {
    return saleIsActive_premint1;
  }

  function viewIsActive_premint2() public view returns (bool) {
    return saleIsActive_premint2;
  }

  /** view Limit for all windows **************/

  function viewNftLimit() public view returns (uint256) {
    return makeNftLimit;
  }

  function viewNftLimit_premint1() public view returns (uint256) {
    return makeNftLimit_premint1;
  }

  function viewNftLimit_premint2() public view returns (uint256) {
    return makeNftLimit_premint2;
  }

  /** view Minted Counts for all windows **************/

  function viewNftCount() public view returns (uint256) {
    return nftSaleCounter;
  }

  function viewNftCount_premint1() public view returns (uint256) {
    return nftSaleCounter_premint1;
  }

  function viewNftCount_premint2() public view returns (uint256) {
    return nftSaleCounter_premint2;
  }

  /** view User Limit for all windows **************/

  function viewUserLimit() public pure returns (uint256) {
    return USER_LIMIT;
  }

  function viewUserLimit_premint1() public pure returns (uint256) {
    return USER_LIMIT; 
  }

  function viewUserLimit_premint2() public pure returns (uint256) {
    return USER_LIMIT; 
  }

  /** set Price for all windows **************/

  function setPrice(uint256 _newCost) external onlyOwner {
    price = _newCost;
  }

  // ?? Why is ther eno setPrice for Premint1?
  function setPrice_premint1(uint256 _newCost) external onlyOwner {
    price_premint1 = _newCost;
  }

  function setPrice_premint2(uint256 _newCost) external onlyOwner {
    price_premint2 = _newCost;
  }

  /**************************/

  function reveal() external onlyOwner {
    revealed = true;
  }

  function notreveal() external onlyOwner {
    revealed = false;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory newBaseExtension) external onlyOwner {
    baseExtension = newBaseExtension;
  }

  function setNotRevealedURI(string memory newNotRevealedURI) public onlyOwner {
    notRevealedUri = newNotRevealedURI;
  }

  function withdrawAll() external payable onlyOwner {
    (bool success, ) = payable(VAULT_ADDRESS).call{
      value: address(this).balance
    }('');
    require(success);
  }

  function withdrawFixed(uint256 fixedAmount) external payable onlyOwner {
    (bool success, ) = payable(VAULT_ADDRESS).call{value: fixedAmount}('');
    require(success);
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
      'ERC721Metadata: URI query for nonexistent token'
    );

    if (revealed == false) {
      return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return
      bytes(currentBaseURI).length > 0
        ? string(
          abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)
        )
        : '';
  }
}