// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./PriceConsumerV3.sol";
import "./OwnPause.sol";
import "./TokenNft.sol";

interface IERC20Ext is IERC20 {
  function decimals() external view returns (uint8);
}

contract TokenNftSales is PriceConsumerV3, OwnPause, ReentrancyGuard {
  using SafeERC20 for IERC20Ext;

  address payable public _beneficiary;

  uint256 public _totalErc20TokensCollected;
  uint256 public _totalNativeTokensCollected;
  uint256 public _totalStablecoinTokensCollected;

  // ERC20 token
  IERC20Ext public _erc20Token;

  // stablecoin token
  IERC20Ext public _stablecoinToken;

  // TokenNft contract
  TokenNft public _tokenNft;

  // "decimals" is 18 for ERC20 tokens
  uint256 constant E18 = 10**18;

  uint256 public _tokenNftPriceUsdCent;

  bool public _buyInErc20Enabled;

  // Keep current number of minted cards
  uint256 public _tokenNumsForSaleMinted;

  // Update frequently by external background service
  uint256 public _erc20TokenPrice; //

  // whitelisted wallets only for "feel lucky" mint
  mapping(address => bool) public _whitelist;

  uint256 public _maxSupplyForSale = 10000;
  uint256 public _maxSupplyForVIP = 200; // not included in the maxSupply
  uint256 public _maxSupplyForFeelLucky = 5000;
  uint256 public _maxSupplyForGallery = 2000;

  // imageId => tokenId
  mapping(uint256 => uint256) public _boughtImageList;

  // cryptoPaid_: "erc20", "stablecoin", "native"
  event EventBuy(
    address buyer_,
    uint256 tokenId_,
    uint256 amountPaid_,
    string cryptoPaid_,
    uint256 imageId_
  );

  event EventMintForVIP(address[] receiverList_);

  event EventSetTokenNftPriceUsdCent(uint256 tokenNftPriceUsdCent_);
  event EventSetErc20Token(address erc20TokenAddress_);
  event EventSetStablecoinToken(address stablecoinTokenAddress_);
  event EventSetBuyInErc20Enabled(bool buyInErc20Enabled_);

  event EventSetMaxSupplyForSale(uint256 maxSupplyForSale_);
  event EventSetMaxSupplyForVIP(uint256 maxSupplyForVIP_);
  event EventSetMaxSupplyForFeelLucky(uint256 maxSupplyForFeelLucky_);
  event EventSetMaxSupplyForGallery(uint256 maxSupplyForGallery_);

  event EventSetErc20TokenPrice(uint256 erc20TokenPriceInUsdCent_);
  event EventSetBeneficiary(address beneficiary_);
  event EventSetWhitelist(address walletAddress_);
  event EventRemoveWhitelist(address walletAddress_);
  event EventSetWhitelistMany(address[] walletAddressList_);

  constructor(
    address tokenNftAddress_,
    uint256 tokenNftPriceUsdCent_,
    address beneficiary_
  ) {
    require(
      tokenNftAddress_ != address(0),
      "TokenNftSales: Invalid tokenNftAddress_ address"
    );

    // tokenNftPriceUsdCent_ can be zero upon deployment

    require(
      beneficiary_ != address(0),
      "TokenNftSales: Invalid beneficiary_ address"
    );

    _tokenNft = TokenNft(tokenNftAddress_);
    _tokenNftPriceUsdCent = tokenNftPriceUsdCent_;
    _beneficiary = payable(beneficiary_);
  }

  // Applicable for feel-lucky and gallery (not for VIP)
  function checkIfCanMint(address wallet_, uint256 imageId_) public view {
    // Feel lucky (with random imageId)
    if (imageId_ == 0) {
      require(
        _whitelist[wallet_],
        "TokenNftSales: Not whitelisted wallet for feel lucky"
      );

      require(
        _tokenNft.getCurrentNumForFeelLucky() < _maxSupplyForFeelLucky,
        "TokenNftSales: _maxSupplyForFeelLucky exceed"
      );
    } else {
      require(
        _tokenNft.getCurrentNumForGallery() < _maxSupplyForGallery,
        "TokenNftSales: _maxSupplyForGallery exceed"
      );

      require(
        _boughtImageList[imageId_] == 0,
        "TokenNftSales: this image already bought"
      );
    }
  }

  function isImageBought(uint256 imageId_) external view returns (bool) {
    return _boughtImageList[imageId_] == 0 ? false : true;
  }

  ////////// Start setter /////////

  function setTokenNftPriceUsdCent(uint256 tokenNftPriceUsdCent_)
    external
    isAuthorized
  {
    require(
      tokenNftPriceUsdCent_ > 0,
      "TokenNftSales: Invalid tokenNftPriceUsdCent_"
    );

    _tokenNftPriceUsdCent = tokenNftPriceUsdCent_;

    emit EventSetTokenNftPriceUsdCent(tokenNftPriceUsdCent_);
  }

  function setStablecoinToken(address stablecoinTokenAddress_)
    public
    isAuthorized
  {
    require(
      stablecoinTokenAddress_ != address(0),
      "TokenNftSales: Invalid stablecoinTokenAddress_"
    );

    _stablecoinToken = IERC20Ext(stablecoinTokenAddress_);

    emit EventSetStablecoinToken(stablecoinTokenAddress_);
  }

  function enableBuyInErc20(
    address erc20TokenAddress_,
    uint256 erc20TokenPriceInUsdCent_
  ) external isAuthorized {
    setErc20Token(erc20TokenAddress_);
    setErc20TokenPriceInUsdCent(erc20TokenPriceInUsdCent_);
    setBuyInErc20Enabled(true);
  }

  function setErc20Token(address erc20TokenAddress_) public isAuthorized {
    require(
      erc20TokenAddress_ != address(0),
      "TokenNftSales: Invalid erc20TokenAddress_"
    );

    _erc20Token = IERC20Ext(erc20TokenAddress_);

    emit EventSetErc20Token(erc20TokenAddress_);
  }

  function setErc20TokenPriceInUsdCent(uint256 erc20TokenPrice_)
    public
    isAuthorized
  {
    // erc20TokenPriceInUsdCent_ can be zero
    _erc20TokenPrice = erc20TokenPrice_;

    emit EventSetErc20TokenPrice(erc20TokenPrice_);
  }

  function setBuyInErc20Enabled(bool buyInErc20Enabled_) public isAuthorized {
    _buyInErc20Enabled = buyInErc20Enabled_;

    emit EventSetBuyInErc20Enabled(buyInErc20Enabled_);
  }

  function setMaxSupplyForSale(uint256 maxSupplyForSale_) public isAuthorized {
    _maxSupplyForSale = maxSupplyForSale_;

    emit EventSetMaxSupplyForSale(maxSupplyForSale_);
  }

  function setMaxSupplyForVIP(uint256 maxSupplyForVIP_) public isAuthorized {
    require(
      maxSupplyForVIP_ < _maxSupplyForSale,
      "TokenNftSales: maxSupplyForVIP_ >= _maxSupplyForSale"
    );

    _maxSupplyForVIP = maxSupplyForVIP_;

    emit EventSetMaxSupplyForVIP(maxSupplyForVIP_);
  }

  function setMaxSupplyForGallery(uint256 maxSupplyForGallery_)
    public
    isAuthorized
  {
    require(
      maxSupplyForGallery_ < _maxSupplyForSale,
      "TokenNftSales: maxSupplyForGallery_ >= _maxSupplyForSale"
    );

    _maxSupplyForGallery = maxSupplyForGallery_;

    emit EventSetMaxSupplyForGallery(maxSupplyForGallery_);
  }

  function setMaxSupplyForFeelLucky(uint256 maxSupplyForFeelLucky_)
    public
    isAuthorized
  {
    require(
      maxSupplyForFeelLucky_ < _maxSupplyForSale,
      "TokenNftSales: maxSupplyForFeelLucky_ >= _maxSupplyForSale"
    );

    _maxSupplyForFeelLucky = maxSupplyForFeelLucky_;

    emit EventSetMaxSupplyForFeelLucky(maxSupplyForFeelLucky_);
  }

  function setBeneficiary(address beneficiary_) external isAuthorized {
    require(
      beneficiary_ != address(0),
      "TokenNftSales: Invalid beneficiary_ address"
    );
    _beneficiary = payable(beneficiary_);

    emit EventSetBeneficiary(beneficiary_);
  }

  function setWhitelist(address walletAddress_) public isAuthorized {
    require(
      walletAddress_ != address(0),
      "TokenNftSales: Invalid walletAddress_"
    );

    _whitelist[walletAddress_] = true;

    emit EventSetWhitelist(walletAddress_);
  }

  function removeWhitelist(address walletAddress_) external isAuthorized {
    require(
      walletAddress_ != address(0),
      "TokenNftSales: Invalid walletAddress_"
    );

    _whitelist[walletAddress_] = false;

    emit EventRemoveWhitelist(walletAddress_);
  }

  function setWhitelistMany(address[] memory walletAddressList_)
    external
    isAuthorized
  {
    for (uint256 i = 0; i < walletAddressList_.length; i++) {
      setWhitelist(walletAddressList_[i]);
    }

    emit EventSetWhitelistMany(walletAddressList_);
  }

  ////////// End setter /////////

  // Get price of ETH or BNB
  function getNativeCoinPriceInUsdCent() public view returns (uint256) {
    uint256 nativeCoinPriceInUsdCent = uint256(getThePrice() / 10**6);
    return nativeCoinPriceInUsdCent;
  }

  // Token price in ETH or BNB
  function getTokenNftPriceInNative() public view returns (uint256) {
    uint256 nativeCoinPriceInUsdCent = getNativeCoinPriceInUsdCent();

    uint256 tokenNftPriceInNative = (_tokenNftPriceUsdCent * E18) /
      nativeCoinPriceInUsdCent;

    return tokenNftPriceInNative;
  }

  function getTokenNftPriceInUSD() public view returns (uint256) {
    return (_tokenNftPriceUsdCent / 100);
  }

  // BUSD has 18 decimals
  function getTokenNftPriceInStablecoin() public view returns (uint256) {
    return ((_tokenNftPriceUsdCent * (10**_stablecoinToken.decimals())) / 100);
  }

  // Get token price in ERC20 tokens depending on the current price of ERC20
  function getTokenNftPriceInErc20Tokens() public view returns (uint256) {
    uint256 tokenNftPriceInErc20Tokens = _erc20TokenPrice;

    return tokenNftPriceInErc20Tokens;
  }

  function _mintToken(address receiver_, uint256 imageId_)
    private
    returns (uint256)
  {
    uint256 tokenId;
    if (imageId_ != 0) {
      tokenId = _tokenNft.mintForGallery(receiver_, imageId_);

      // Store the bought imageId
      _boughtImageList[imageId_] = tokenId;
    } else {
      tokenId = _tokenNft.mintForFeelLucky(receiver_);
    }

    return tokenId;
  }

  // Buy token in erc20 tokens (ETH or BNB)
  // "imageId_" is zero for feel-lucky else for gallery
  function buyInStablecoin(uint256 imageId_)
    external
    whenNotPaused
    nonReentrant
    returns (uint256)
  {
    require(_tokenNftPriceUsdCent > 0, "TokenNftSales: invalid token price");
    require(
      address(_stablecoinToken) != address(0),
      "TokenNftSales: _stablecoinToken not set"
    );

    uint256 tokenNftPriceInStablecoin = getTokenNftPriceInStablecoin();

    // Check if user balance has enough tokens
    require(
      tokenNftPriceInStablecoin <= _stablecoinToken.balanceOf(_msgSender()),
      "TokenNftSales: user balance does not have enough stablecoin tokens"
    );

    checkIfCanMint(_msgSender(), imageId_);

    _stablecoinToken.safeTransferFrom(
      _msgSender(),
      _beneficiary,
      tokenNftPriceInStablecoin
    );

    _totalStablecoinTokensCollected += tokenNftPriceInStablecoin;
    _tokenNumsForSaleMinted++;

    uint256 tokenId = _mintToken(_msgSender(), imageId_);

    emit EventBuy(
      _msgSender(),
      tokenId,
      tokenNftPriceInStablecoin,
      "stablecoin",
      imageId_
    );

    return tokenId;
  }

  // Buy token in erc20 tokens (ETH or BNB)
  // "imageId_" is zero for feel-lucky else for gallery
  function buyInErc20(uint256 imageId_)
    external
    whenNotPaused
    nonReentrant
    returns (uint256)
  {
    require(_tokenNftPriceUsdCent > 0, "TokenNftSales: invalid token price");
    require(_buyInErc20Enabled, "TokenNftSales: buyInErc20 disabled");
    require(
      _erc20TokenPrice > 0,
      "TokenNftSales: ERC20 token price not set"
    );

    uint256 tokenNftPriceInErc20Tokens = getTokenNftPriceInErc20Tokens();

    // Check if user balance has enough tokens
    require(
      tokenNftPriceInErc20Tokens <= _erc20Token.balanceOf(_msgSender()),
      "TokenNftSales: user balance does not have enough ERC20 tokens"
    );

    checkIfCanMint(_msgSender(), imageId_);

    _erc20Token.safeTransferFrom(
      _msgSender(),
      _beneficiary,
      tokenNftPriceInErc20Tokens
    );

    _totalErc20TokensCollected += tokenNftPriceInErc20Tokens;
    _tokenNumsForSaleMinted++;

    uint256 tokenId = _mintToken(_msgSender(), imageId_);

    emit EventBuy(
      _msgSender(),
      tokenId,
      tokenNftPriceInErc20Tokens,
      "erc20",
      imageId_
    );

    return tokenId;
  }

  // Buy token in native coins (ETH or BNB)
  // "imageId_" is zero for feel-lucky else for gallery
  function buyInNative(uint256 imageId_)
    external
    payable
    whenNotPaused
    nonReentrant
    returns (uint256)
  {
    require(
      _tokenNftPriceUsdCent > 0,
      "TokenNftSales: invalid token NFT price"
    );

    uint256 tokenNftPriceInNative = getTokenNftPriceInNative();

    // Check if user-transferred amount is enough
    require(
      msg.value >= tokenNftPriceInNative,
      "TokenNftSales: user-transferred amount not enough"
    );

    checkIfCanMint(_msgSender(), imageId_);

    // Transfer msg.value from user wallet to beneficiary
    (bool success, ) = _beneficiary.call{value: msg.value}("");
    require(success, "TokenNftSales: Native transfer to beneficiary failed");

    _totalNativeTokensCollected += msg.value;
    _tokenNumsForSaleMinted++;

    uint256 tokenId = _mintToken(_msgSender(), imageId_);

    emit EventBuy(_msgSender(), tokenId, msg.value, "native", imageId_);

    return tokenId;
  }

  function mintForVIP(address[] memory receiverList_)
    external
    nonReentrant
    isAuthorized
  {
    require(
      _tokenNft.getCurrentNumForVIP() < _maxSupplyForVIP,
      "TokenNftSales: _maxSupplyForVIP exceed"
    );

    _tokenNft.mintManyForVIP(receiverList_);

    emit EventMintForVIP(receiverList_);
  }

  // BNB price when running on BSC or ETH price when running on Ethereum
  function getCurrentPrice() public view returns (int256) {
    return getThePrice() / 10**8;
  }
}