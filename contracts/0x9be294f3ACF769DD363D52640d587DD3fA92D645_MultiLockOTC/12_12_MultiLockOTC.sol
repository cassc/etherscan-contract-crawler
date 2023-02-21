// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import './interfaces/Decimals.sol';
import './libraries/TransferHelper.sol';
import './interfaces/INFT.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

/**
 * @title MultiLockOTC
 * @notice MultiLockOTC is an over the counter peer to peer trading contract
 * @notice This contract allows for a seller to generate a unique public over the counter deal
 */
contract MultiLockOTC is ReentrancyGuard {
  using SafeERC20 for IERC20;
  address payable public weth;
  uint256 public dealId;
  address public futuresContract;
  mapping(uint256 => mapping(address => bool)) public hasPurchased;

  /// Deal is the struct that defines a single OTC offer, created by a seller
  /// @param seller This is the creator and seller of the deal
  /// @param token This is the token that the seller is selling! Must be a standard ERC20 token, parameter is the contract address of the ERC20,
  /// the ERC20 contract is required to have a public call function decimals() that returns a uint. This is required to price the amount of tokens being purchase
  /// @param paymentCurrency This is also an ERC20 which the seller will get paid in during the act of a buyer buying tokens - also the ERC20 contract address
  /// @param remainingAmount This initially is the entire deposit the seller is selling, but as people purchase chunks of the deal, the remaining amount is decreased to 0
  /// @param minimumPurchase This is the minimum chunk size that a buyer can purchase, defined by the seller, must be greater than 0
  /// @param price The Price is the per token cost which buyers pay to the seller, denominated in the payment currency. This is not the total price of the deal
  /// the total price is calculated by the remainingAmount * price (then adjusting for the decimals of the payment currency)
  /// @param maturity This is the unix time defining the period in which the deal is valid. After the maturity no purchases can be made
  /// @param _unlockDates these are the dates in which tokens will be locked, multiple dates can be passed in for a series of vesting cliffs
  /// @param _nft is a special option to make this deal require that the buyers hold a specific other NFT to participate in the buy
  struct Deal {
    address seller;
    address token;
    address paymentCurrency;
    uint256 remainingAmount;
    uint256 minimumPurchase;
    uint256 price;
    uint256 maturity;
    uint256[] unlockDates;
    address nft;
    bool onlyBuyOnce;
  }

  /// Mapping of index to deal
  mapping(uint256 => Deal) public deals;

  /// Method to allow this contract receive ETH
  receive() external payable {}

  /// Event emitted when a deal is created
  event NewNFTGatedDeal(
    uint256 indexed _dealId,
    address indexed _seller,
    address _token,
    address _paymentCurrency,
    uint256 _remainingAmount,
    uint256 _minimumPurchase,
    uint256 _price,
    uint256 _maturity,
    uint256[] _unlockDates,
    address _nft,
    bool _onlyBuyOnce
  );

  /// Event emitted when tokens are bought
  /// @param _dealId The deal index
  /// @param _amount The amount of tokens bought
  /// @param _remainingAmount The remaining number of tokens in the deal
  event TokensBought(uint256 indexed _dealId, uint256 _amount, uint256 _remainingAmount);

  /// Event emitted when the deal is closed
  /// @param _dealId The deal index
  event DealClosed(uint256 indexed _dealId);

  /// Event emitted when a future NFT is created
  /// @param _owner The address that bought tokens from the deal and owns the future NFT
  /// @param _token The address of the token contract
  /// @param _amount The amount of tokens locked
  /// @param _unlockDate The date when the future NFT is unlocked
  event FutureCreated(address indexed _owner, address _token, uint256 _amount, uint256 _unlockDate);

  /// @notice Creates a MultiLockOTC instance
  /// @param _weth The address for the weth contract, weth is used to wrap and unwrap ETH sending to and from the smart contract
  /// @param _fc The address for the futures contract, used to generate the future NFT
  constructor(address payable _weth, address _fc) {
    require(_weth != address(0));
    require(_fc != address(0));
    weth = _weth;
    futuresContract = _fc;
  }

  /// This function is what the seller uses to create a new OTC offering, Once this function has been completed
  /// buyers can purchase tokens from the seller based on the price and parameters set
  /// @param _token is the ERC20 contract address that the seller is going to create the over the counter offering for
  /// @param _paymentCurrency is the ERC20 contract address of the opposite ERC20 that the seller wants to get paid in when selling the token (use WETH for ETH)
  /// this can also be used for a token SWAP - where the ERC20 address of the token being swapped to is input as the paymentCurrency
  /// @param _amount is the amount of tokens that you as the seller want to sell
  /// @param _min is the minimum amount of tokens that a buyer can purchase from you. this should be less than or equal to the total amount
  /// @param _price is the price per token which the seller will get paid, denominated in the payment currency
  /// if this is a token SWAP, then the _price needs to be set as the ratio of the tokens being swapped - ie 10 for 10 paymentCurrency tokens to 1 token
  /// @param _maturity is how long you would like to allow buyers to purchase tokens from this deal, in unix time. this needs to be beyond current block time
  /// @param _unlockDates is the dates in which the tokens will be cliff vested
  /// @param _nft is a special option to make this deal require that the buyers hold a specific other NFT to participate in the buy
  function createNFTGatedDeal(
    address _token,
    address _paymentCurrency,
    uint256 _amount,
    uint256 _min,
    uint256 _price,
    uint256 _maturity,
    uint256[] memory _unlockDates,
    address _nft,
    bool _onlyBuyOnce
  ) external payable nonReentrant {
    require(_maturity > block.timestamp, 'OTC01');
    require(_amount >= _min, 'OTC02');
    require((_min * _price) / (10**Decimals(_token).decimals()) > 0, 'OTC03');
    deals[dealId++] = Deal(
      msg.sender,
      _token,
      _paymentCurrency,
      _amount,
      _min,
      _price,
      _maturity,
      _unlockDates,
      _nft,
      _onlyBuyOnce
    );

    emit NewNFTGatedDeal(
      dealId - 1,
      msg.sender,
      _token,
      _paymentCurrency,
      _amount,
      _min,
      _price,
      _maturity,
      _unlockDates,
      _nft,
      _onlyBuyOnce
    );

    TransferHelper.transferPayment(weth, _token, payable(msg.sender), payable(address(this)), _amount);
  }

  /// @notice This function lets a seller cancel their existing deal anytime they if they want to, including before the maturity date,
  /// all that is required is that the deal has not been closed, and that there is still a reamining balance
  /// @param _dealId is the dealID that is mapped to the Struct Deal
  function close(uint256 _dealId) external nonReentrant {
    Deal memory deal = deals[_dealId];
    require(msg.sender == deal.seller, 'OTC04');
    require(deal.remainingAmount > 0, 'OTC05');
    delete deals[_dealId];
    emit DealClosed(_dealId);
    TransferHelper.withdrawPayment(weth, deal.token, payable(msg.sender), deal.remainingAmount);
  }

  /// @notice Checks if the address owns one of the NFTs configured for the deal
  /// @param _dealId The deal index
  /// @param buyer The buyer address
  function canBuy(uint256 _dealId, address buyer) public view returns (bool _canBuy) {
    Deal memory deal = deals[_dealId];
    if (!hasPurchased[_dealId][buyer]) {
      if (deal.nft == address(0x0)) {
        _canBuy = true;
      } else if (IERC721(deal.nft).balanceOf(buyer) > 0) {
        _canBuy = true;
      }
    }
  }

  /// This function is what buyers use to make purchases from the sellers
  /// @param _dealId is the index of the deal that a buyer wants to participate in and make a purchase
  /// @param _amount is the amount of tokens the buyer is purchasing, which must be at least the minimumPurchase and at
  /// @param _beneficiary is typically the msg.sender - but the buyer can denote a separate wallet to receive the NFTs or purchase in the case
  /// that they want to send it to a cold storage or other wallet not doing the purchasing
  /// most the remainingAmount for this deal (or the remainingAmount if that is less than the minimum)
  /// @dev this function can also be used to execute a token SWAP function, where the swap is executed through this function
  function buy(
    uint256 _dealId,
    uint256 _amount,
    address _beneficiary
  ) external payable nonReentrant {
    Deal memory deal = deals[_dealId];
    require(deal.maturity >= block.timestamp, 'OTC07');
    require(canBuy(_dealId, msg.sender), 'OTC08');
    require(_beneficiary != address(this));
    require(
      (_amount >= deal.minimumPurchase || _amount == deal.remainingAmount) && deal.remainingAmount >= _amount,
      'OTC09'
    );
    if (deal.onlyBuyOnce) hasPurchased[_dealId][msg.sender] = true;
    address beneficiary = _beneficiary == address(0) ? msg.sender : _beneficiary;
    uint256 decimals = Decimals(deal.token).decimals();
    uint256 purchase = (_amount * deal.price) / (10**decimals);
    TransferHelper.transferPayment(weth, deal.paymentCurrency, msg.sender, payable(deal.seller), purchase);
    deal.remainingAmount -= _amount;
    emit TokensBought(_dealId, _amount, deal.remainingAmount);
    if (deal.remainingAmount == 0) {
      delete deals[_dealId];
    } else {
      deals[_dealId].remainingAmount = deal.remainingAmount;
    }
    if (deal.unlockDates.length > 0) {
      SafeERC20.safeIncreaseAllowance(IERC20(deal.token), futuresContract, _amount);
      uint256 proRataLockAmount = _amount / deal.unlockDates.length;
      uint256 remainder = _amount % proRataLockAmount;
      uint256 amountCheck;
      uint256 currentNFTBalance = IERC20(deal.token).balanceOf(futuresContract);
      for (uint256 i; i < deal.unlockDates.length - 1; i++) {
        require(deal.unlockDates[i] > block.timestamp, 'NHL01');
        INFT(futuresContract).createNFT(beneficiary, proRataLockAmount, deal.token, deal.unlockDates[i]);
        emit FutureCreated(beneficiary, deal.token, proRataLockAmount, deal.unlockDates[i]);
        amountCheck += proRataLockAmount;
      }
      amountCheck += proRataLockAmount + remainder;
      require(amountCheck == _amount, 'amount total mismatch');
      require(deal.unlockDates[deal.unlockDates.length - 1] > block.timestamp, 'NHL01');
      INFT(futuresContract).createNFT(
        beneficiary,
        proRataLockAmount + remainder,
        deal.token,
        deal.unlockDates[deal.unlockDates.length - 1]
      );
      uint256 postNFTBalance = IERC20(deal.token).balanceOf(futuresContract);
      require(postNFTBalance - currentNFTBalance == _amount, 'token deliver failure');
      emit FutureCreated(
        beneficiary,
        deal.token,
        proRataLockAmount + remainder,
        deal.unlockDates[deal.unlockDates.length - 1]
      );
    } else {
      TransferHelper.withdrawPayment(weth, deal.token, payable(beneficiary), _amount);
    }
  }
}