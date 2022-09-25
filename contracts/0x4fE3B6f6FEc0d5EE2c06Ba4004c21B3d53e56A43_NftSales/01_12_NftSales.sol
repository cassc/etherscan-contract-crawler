// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./OwnPause.sol";

// Interface for ERC721
interface IErc721 {
  function currentTokenID() external view returns (uint256);
  function currentLuckyTokenID() external view returns (uint256);
  function mint(address _beneficiary) external;
  function luckyMint(address _beneficiary) external;
}

contract NftSales is OwnPause, ReentrancyGuard {

  address payable public _rewardVault;

  uint256 public _totalNativeTokensCollected;
  uint256 public _tokenNumsForSaleMinted;
  uint256 public _maxSupplyForSale = 5555;

  // TokenNft contract
  address public _nft;

  // Price of this sale event
  uint256 public _nativePrice;

  // Open public for anyone
  bool public  _openPublic;

  // whitelisted wallets for participating this event
  mapping(address => bool) public _whitelist;

  // cryptoPaid_: "erc20", "stablecoin", "native"
  event EventBuy(address _buyer, uint256 _tokenId, uint256 _amountPaid);
  
  // cryptoPaid_: "erc20", "stablecoin", "native"
  event EventLuckyBuy(address _buyer, uint256 _tokenId, uint256 _amountPaid);

  event EventSetupPrice(uint256 tokenNftPrice_);

  event EventSetWhitelistMany(address[] walletAddressList_);

  event EventSetWhitelist(address walletAddress_);

  event EventRemoveWhitelist(address walletAddress_);

  event EventSetMaxSupply(uint256 maxSupply_);

  event EventRewardVault(address rewardVault_);

  event EventSetOpenPublic(bool openPublic_);

  constructor(
    address tokenNftAddress_,
    uint256 tokenNftPrice_,
    address rewardVault_
  ) {
    require(
      tokenNftAddress_ != address(0),
      "TokenNftSales: Invalid tokenNftAddress_ address"
    );

    require(
      tokenNftPrice_ >= 1000000000,
      "tokenNftPrice: Invalid tokenNftPrice_ address"
    );
  
    require(
      rewardVault_ != address(0),
      "rewardVault: Invalid rewardVault_ address"
    );

    _nft = tokenNftAddress_;
    _nativePrice = tokenNftPrice_;
    _rewardVault = payable(rewardVault_);
    _openPublic = false;
  }

  modifier isInWhitelist() {
        require(_whitelist[msg.sender]||_openPublic == true, "Not in whitelist or not open yet");
        _;
    }

  function setOpenPublic(bool openPublic_)
    external
    isAuthorized
  {
    _openPublic = openPublic_;

    emit EventSetOpenPublic(openPublic_);
  }

  function setTokenNftPrice(uint256 tokenNftPrice_)
    external
    isAuthorized
  {
    require(
      tokenNftPrice_ > 1000000000,
      "tokenNftPrice: Invalid tokenNftPrice_"
    );

    _nativePrice = tokenNftPrice_;

    emit EventSetupPrice(tokenNftPrice_);
  }

  function setMaxSupply(uint256 maxSupplyForSale_) public isAuthorized {
    require(
      maxSupplyForSale_ > 0,
      "TokenNftSales: _maxSupplyForSale == 0"
    );

    _maxSupplyForSale = maxSupplyForSale_;

    emit EventSetMaxSupply(_maxSupplyForSale);
  }

  function setRewardVault(address rewardVault_) external isAuthorized {
    require(
      rewardVault_ != address(0),
      "TokenNftSales: Invalid rewardVault_ address"
    );
    _rewardVault = payable(rewardVault_);

    emit EventRewardVault(rewardVault_);
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

  function buyInNative()
    external
    payable
    whenNotPaused
    isInWhitelist
    nonReentrant
  {    
    // Check if user-transferred amount is enough
    require(
      msg.value >= _nativePrice,
      "TokenNftSales: user-transferred amount not enough"
    );

    // Transfer msg.value from user wallet to rewardVault
    (bool success, ) = _rewardVault.call{value: msg.value}("");
    require(success, "TokenNftSales: Native transfer to beneficiary failed");

    _totalNativeTokensCollected += msg.value;
    _tokenNumsForSaleMinted++;

    // mint the nft to sender
    IErc721(_nft).mint(msg.sender);

    emit EventBuy(msg.sender, IErc721(_nft).currentTokenID() - 1, msg.value);

  }

  function luckyDrawInNative()
  external
  payable
  whenNotPaused
  isInWhitelist
  nonReentrant
  {    
    // Check if user-transferred amount is enough
    require(
      msg.value >= _nativePrice,
      "TokenNftSales: user-transferred amount not enough"
    );

    // Transfer msg.value from user wallet to rewardVault
    (bool success, ) = _rewardVault.call{value: msg.value}("");
    require(success, "TokenNftSales: Native transfer to beneficiary failed");

    _totalNativeTokensCollected += msg.value;
    _tokenNumsForSaleMinted++;

    // mint the nft to sender
    IErc721(_nft).luckyMint(msg.sender);

    emit EventLuckyBuy(msg.sender, IErc721(_nft).currentLuckyTokenID() - 1, msg.value);

  }
}