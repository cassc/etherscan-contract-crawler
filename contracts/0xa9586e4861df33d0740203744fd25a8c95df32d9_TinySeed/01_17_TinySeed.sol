// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @dev TinySeed ERC-1155 contract:
 */
contract TinySeed is
  ERC1155,
  Ownable,
  Pausable,
  ERC1155Burnable,
  ERC1155Supply,
  PaymentSplitter
{
  /**
   * @dev Constants for token types:
   */
  uint256 public constant SERIES1 = 0;
  uint256 public constant REFILL = 1;
  uint256 public constant PLATINUM = 2;

  /**
   * @dev Constants, token supply bands and associated USD pricing:
   * ===========================================
   * MUST BE UPDATED / VALIDATED PRIOR TO DEPLOY
   * ===========================================
   */
  uint256 public constant SERIES1_SUPPLY1 = 100;
  uint256 public constant SERIES1_SUPPLY2 = 250;
  uint256 public constant SERIES1_SUPPLY3 = 500;

  uint256 public constant SERIES1_USD1 = 220;
  uint256 public constant SERIES1_USD2 = 230;
  uint256 public constant SERIES1_USD3 = 240;
  uint256 public constant SERIES1_USD4 = 250;

  uint256 public constant REFILL_USD = 250;
  uint256 public constant PLATINUM_USD = 4600;

  /**
   * @dev Add name and symbol for consistency with ERC-721 NFTs. Note that ERC-721 stores
   * these variables on-chain, but as they can only be set on the constructor we may as well
   * save the gas and have them as constants in the bytecode.
   */
  string private constant NAME = "TinySeed";
  string private constant SYMBOL = "TINYSEED";

  AggregatorV3Interface internal priceFeed;

  /**
   * @dev saleOpen - when set to false it stays false. This is how the mint
   * is permanently closed at the end. Pause is different, as it can be set and unset
   * and also controls token transfer.
   */
  bool public saleOpen;
  bool public developerAllocationComplete;
  address private developer;
  /**
   * @dev Price buffer above and below the passed amount of ETH that will be accepted. This function
   * will be used to set the price for items in the UI, but there is always the possibility of price
   * fluctuations beween the display and the mint. These parameters determine as an amount per thousance
   * how high above or below the price the passed amount of ETH can be and still make a valid sale. The
   * stored values are in the following format:
   *   - priceBufferUp: amount as a proportion of 1,000. For example, if you set this to 1005 you allow the
   *       price to be up to 1005 / 1000 of the actual price, i.e. not exceeding 0.5% greater.
   *   - priceBufferDown: amount as a proportion of 1,000. For example, if you set this to 995 you allow the
   *       price to be up to 995 / 1000 of the actual price i.e. not exceeding 0.5% less.
   */
  uint256 private priceBufferUp;
  uint256 private priceBufferDown;

  /**
   * @dev Contract events:
   */
  event SaleClosedSet(address account);
  event PriceBufferUpSet(uint256 priceBuffer);
  event PriceBufferDownSet(uint256 priceBuffer);
  event DeveloperAllocationCompleteSet(address account);
  event tinySeedMinted(
    address account,
    uint256 TiQuantity,
    uint256 RefillQuantity,
    uint256 PtQuantity,
    uint256 TiSupply,
    uint256 RefillSupply,
    uint256 PtSupply,
    uint256 cost
  );

  /**
   * @dev Constructor must be passed an array of shareholders for the payment splitter, the first
   * array holding addresses and the second the corresponding shares. For example, you could have the following:
   *   - _payees[beneficiaryAddress, developerAddress]
   *   - _shares[90,10]
   * In this example the beneficiary address passed in can claim 90% of total ETH, the developer 10%
   */
  constructor(
    uint256 _priceBufferUp,
    uint256 _priceBufferDown,
    address[] memory _payees,
    uint256[] memory _shares,
    address _developer
  )
    ERC1155(
      "https://arweave.net/jGEbN3EEPoKqTwzkPD4rBf7ujmtBFtZIkwD_T9242hQ/{id}.json"
    )
    PaymentSplitter(_payees, _shares)
  {
    setPriceBufferUp(_priceBufferUp);
    setPriceBufferDown(_priceBufferDown);
    developer = _developer;
    saleOpen = true;
    developerAllocationComplete = false;
    _pause();
    /**
     * @dev Contract address for pricefeed data.
     * ==============================================
     * MUST BE SET TO MAINNET ADDRESS PRIOR TO DEPLOY
     * ==============================================
     * MAINNET: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
     * RINKEBY: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
     */
    priceFeed = AggregatorV3Interface(
      0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
    );
  }

  /**
   * @dev The sale being open depends on the saleOpen bool. This is set to true
   * in the constructor and can be set to closed by the owner. Once closed it is closed
   * forever. Minting cannot occur, token transfers are still allows. These can be paused
   * by using _pause.
   */
  modifier whenSaleOpen() {
    require(saleOpen, "Sale is closed");
    _;
  }

  modifier whenSaleClosed() {
    require(!saleOpen, "Sale is open");
    _;
  }

  modifier whenDeveloperAllocationAvailable() {
    require(!developerAllocationComplete, "Developer allocation is complete");
    _;
  }

  /**
   * @dev admin functions:
   */
  function setPriceBufferUp(uint256 _priceBufferUpToSet)
    public
    onlyOwner
    returns (bool)
  {
    priceBufferUp = _priceBufferUpToSet;
    emit PriceBufferUpSet(priceBufferUp);
    return true;
  }

  function setPriceBufferDown(uint256 _priceBufferDownToSet)
    public
    onlyOwner
    returns (bool)
  {
    priceBufferDown = _priceBufferDownToSet;
    emit PriceBufferDownSet(priceBufferDown);
    return true;
  }

  function setSaleClosed() external onlyOwner whenSaleOpen {
    saleOpen = false;
    emit SaleClosedSet(msg.sender);
  }

  function setDeveloperAllocationComplete() external onlyOwner whenSaleClosed {
    developerAllocationComplete = true;
    emit DeveloperAllocationCompleteSet(msg.sender);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function getCurrentRate() external view returns (uint256) {
    return (uint256(getLatestPrice()));
  }

  function getDollarValueInWei(uint256 _dollarValue)
    external
    view
    returns (uint256)
  {
    uint256 latestPrice = uint256(getLatestPrice());
    return (performConversion(latestPrice, _dollarValue));
  }

  function getCurrentETHPriceById(uint256 _id)
    external
    view
    returns (uint256 priceInETH)
  {
    uint256 latestPrice = uint256(getLatestPrice());

    if (_id == SERIES1) {
      return (performConversion(latestPrice, getCurrentTitaniumUSD()));
    }

    if (_id == REFILL) {
      return (performConversion(latestPrice, REFILL_USD));
    }

    if (_id == PLATINUM) {
      return (performConversion(latestPrice, PLATINUM_USD));
    }
  }

  function getAllCurrentETHPrices()
    public
    view
    returns (
      uint256 titanium,
      uint256 refiller,
      uint256 platinum
    )
  {
    uint256 latestPrice = uint256(getLatestPrice());
    uint256 seriesOnePrice = performConversion(
      latestPrice,
      getCurrentTitaniumUSD()
    );
    uint256 refillPrice = performConversion(latestPrice, REFILL_USD);
    uint256 platinumPrice = performConversion(latestPrice, PLATINUM_USD);

    return ((seriesOnePrice), (refillPrice), (platinumPrice));
  }

  function getTotalMinted()
    external
    view
    returns (
      uint256 seriesOne,
      uint256 refiller,
      uint256 platinum
    )
  {
    return (totalSupply(SERIES1), totalSupply(REFILL), totalSupply(PLATINUM));
  }

  function getAccountMinted(address _account)
    external
    view
    returns (
      uint256 seriesOne,
      uint256 refiller,
      uint256 platinum
    )
  {
    return (
      balanceOf(_account, SERIES1),
      balanceOf(_account, REFILL),
      balanceOf(_account, PLATINUM)
    );
  }

  function getBuffers()
    external
    view
    onlyOwner
    returns (uint256 bufferUp, uint256 bufferDown)
  {
    return (priceBufferUp, priceBufferDown);
  }

  /**
   * @dev Add name, symbol and total supply for consistency with ERC-721 NFTs.
   */
  function name() public pure returns (string memory) {
    return NAME;
  }

  function symbol() public pure returns (string memory) {
    return SYMBOL;
  }

  function totalSupply() public view returns (uint256) {
    return (totalSupply(SERIES1) + totalSupply(REFILL) + totalSupply(PLATINUM));
  }

  /**
   * Returns the latest USD price to 8DP of 1 ETH
   */
  function getLatestPrice() public view returns (int256) {
    (
      uint80 roundID,
      int256 price,
      uint256 startedAt,
      uint256 timeStamp,
      uint80 answeredInRound
    ) = priceFeed.latestRoundData();
    return price;
  }

  /**
   * @dev perform price conversion USD to Wei at the prescribed number of significant figures (i.e. DP in ETH)
   */
  function performConversion(uint256 _price, uint256 _value)
    internal
    pure
    returns (uint256 convertedValue)
  {
    require(_price > 0 && _price < 9999999999999, "Pricing Error");
    // The USD figure from the price feed is one eth in USD to 8 DP. We need the value of one dollar in wei/
    // The price feed has 8DP so lets add that exponent to our wei figure to give us the value of $1 in wei
    uint256 oneUSDInWei = ((10**26) / _price);
    // 2) Mutiply our dollar value by that to get our value in wei:
    uint256 valueInWei = oneUSDInWei * _value;

    // 3) And then roundup that number to 4DP of eth by removing 10**14 digits, adding 1, then multiplying by 10**14:
    valueInWei = ((valueInWei / (10**14)) + 1) * (10**14);
    return (valueInWei);
  }

  /**
   * @dev This function is called from the UI to mint NFTs for the user. Can only be called when the sale is open
   * and the contract isn't paused. It must be passed three quantities, one for each of the token types:
   */
  function buyTinySeed(
    uint256 _quantitySeriesOne,
    uint256 _quantityRefiller,
    uint256 _quantityPlatinum
  ) external payable whenSaleOpen whenNotPaused {
    require(
      _quantitySeriesOne != 0 ||
        _quantityRefiller != 0 ||
        _quantityPlatinum != 0,
      "Order must be for an item"
    );

    uint256 orderPrice = priceOrder(
      _quantitySeriesOne,
      _quantityRefiller,
      _quantityPlatinum
    );

    checkPaymentToPrice(msg.value, orderPrice);

    // To reach here the price check must have passed. Mint the items:
    processMint(
      msg.sender,
      _quantitySeriesOne,
      _quantityRefiller,
      _quantityPlatinum,
      msg.value
    );

    // Events are emitted per order in the mint function.
  }

  /**
   * @dev Get the current price of this order in the same way that it will have been assembled in the UI,
   * i.e. get the current price of each token type in ETH (including the rounding to 4DP of ETH) and then
   * multiply that by the total quantity ordered.
   */
  function priceOrder(
    uint256 _quantitySeriesOne,
    uint256 _quantityRefiller,
    uint256 _quantityPlatinum
  ) internal view returns (uint256 price) {
    uint256 orderCostInETH = 0;

    (
      uint256 seriesOnePrice,
      uint256 refillPrice,
      uint256 platinumPrice
    ) = getAllCurrentETHPrices();

    orderCostInETH = ((seriesOnePrice * _quantitySeriesOne) +
      (refillPrice * _quantityRefiller) +
      (platinumPrice * _quantityPlatinum));

    return (orderCostInETH);
  }

  /**
   * @dev This function allows the developer allocation mint. It is closed when the bool developerAllocationComplete is set to true
   */
  function mintDeveloperAllocation(
    uint256 _quantitySeriesOne,
    uint256 _quantityRefiller,
    uint256 _quantityPlatinum
  ) external payable onlyOwner whenSaleClosed whenDeveloperAllocationAvailable {
    processMint(
      developer,
      _quantitySeriesOne,
      _quantityRefiller,
      _quantityPlatinum,
      0
    );
  }

  /**
   * @dev Unified proccessing for mint operation:
   */
  function processMint(
    address _recipient,
    uint256 _quantitySeriesOne,
    uint256 _quantityRefiller,
    uint256 _quantityPlatinum,
    uint256 _cost
  ) internal {
    // Series one (titanium) items:
    if (_quantitySeriesOne > 0) {
      _mint(_recipient, SERIES1, _quantitySeriesOne, "");
    }
    // Refiller items:
    if (_quantityRefiller > 0) {
      _mint(_recipient, REFILL, _quantityRefiller, "");
    }

    // Platinum items:
    if (_quantityPlatinum > 0) {
      _mint(_recipient, PLATINUM, _quantityPlatinum, "");
    }

    emit tinySeedMinted(
      _recipient,
      _quantitySeriesOne,
      _quantityRefiller,
      _quantityPlatinum,
      totalSupply(SERIES1),
      totalSupply(REFILL),
      totalSupply(PLATINUM),
      _cost
    );
  }

  /**
   * @dev Get the current series One price.
   */
  function getCurrentTitaniumUSD()
    internal
    view
    returns (uint256 _currentPrice)
  {
    uint256 nextTitanium = totalSupply(SERIES1) + 1;

    // For efficiency first check if we exceed the highest tier, as presumably most
    // units will be sold at the standard post-tier price:
    if (nextTitanium > SERIES1_SUPPLY3) {
      return (SERIES1_USD4);
    }
    if (nextTitanium <= SERIES1_SUPPLY1) {
      return (SERIES1_USD1);
    }
    if (nextTitanium <= SERIES1_SUPPLY2) {
      return (SERIES1_USD2);
    }
    if (nextTitanium <= SERIES1_SUPPLY3) {
      return (SERIES1_USD3);
    }
  }

  /**
   * @dev Determine if the passed cost is within bounds of current price:
   */
  function checkPaymentToPrice(uint256 _passedETH, uint256 _orderPrice)
    internal
    view
  {
    // Establish upper and lower bands of price buffer and check
    uint256 orderPriceLower = (_orderPrice * priceBufferDown) / 1000;

    require(_passedETH >= orderPriceLower, "Insufficient ETH passed for order");

    uint256 orderPriceUpper = (_orderPrice * priceBufferUp) / 1000;

    require(_passedETH <= orderPriceUpper, "Too much ETH passed for order");
  }

  /**
   * @dev The fallback function is executed on a call to the contract if
   * none of the other functions match the given function signature.
   */
  fallback() external payable {
    revert();
  }

  /**
   * @dev revert any random ETH:
   */
  receive() external payable override {
    revert();
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override(ERC1155, ERC1155Supply) whenNotPaused {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }
}