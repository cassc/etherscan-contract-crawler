pragma solidity 0.5.17;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "../interfaces/Comptroller.sol";
import "../interfaces/PriceOracle.sol";
import "../interfaces/CERC20.sol";
import "../interfaces/CEther.sol";
import "../Utils.sol";

contract CompoundOrder is Utils(address(0), address(0), address(0)), Ownable {
  // Constants
  uint256 internal constant NEGLIGIBLE_DEBT = 100; // we don't care about debts below 10^-4 USDC (0.1 cent)
  uint256 internal constant MAX_REPAY_STEPS = 3; // Max number of times we attempt to repay remaining debt
  uint256 internal constant DEFAULT_LIQUIDITY_SLIPPAGE = 10 ** 12; // 1e-6 slippage for redeeming liquidity when selling order
  uint256 internal constant FALLBACK_LIQUIDITY_SLIPPAGE = 10 ** 15; // 0.1% slippage for redeeming liquidity when selling order
  uint256 internal constant MAX_LIQUIDITY_SLIPPAGE = 10 ** 17; // 10% max slippage for redeeming liquidity when selling order

  // Contract instances
  Comptroller public COMPTROLLER; // The Compound comptroller
  PriceOracle public ORACLE; // The Compound price oracle
  CERC20 public CUSDC; // The Compound USDC market token
  address public CETH_ADDR;

  // Instance variables
  uint256 public stake;
  uint256 public collateralAmountInUSDC;
  uint256 public loanAmountInUSDC;
  uint256 public cycleNumber;
  uint256 public buyTime; // Timestamp for order execution
  uint256 public outputAmount; // Records the total output USDC after order is sold
  address public compoundTokenAddr;
  bool public isSold;
  bool public orderType; // True for shorting, false for longing
  bool internal initialized;


  constructor() public {}

  function init(
    address _compoundTokenAddr,
    uint256 _cycleNumber,
    uint256 _stake,
    uint256 _collateralAmountInUSDC,
    uint256 _loanAmountInUSDC,
    bool _orderType,
    address _usdcAddr,
    address payable _kyberAddr,
    address _comptrollerAddr,
    address _priceOracleAddr,
    address _cUSDCAddr,
    address _cETHAddr
  ) public {
    require(!initialized);
    initialized = true;

    // Initialize details of order
    require(_compoundTokenAddr != _cUSDCAddr);
    require(_stake > 0 && _collateralAmountInUSDC > 0 && _loanAmountInUSDC > 0); // Validate inputs
    stake = _stake;
    collateralAmountInUSDC = _collateralAmountInUSDC;
    loanAmountInUSDC = _loanAmountInUSDC;
    cycleNumber = _cycleNumber;
    compoundTokenAddr = _compoundTokenAddr;
    orderType = _orderType;

    COMPTROLLER = Comptroller(_comptrollerAddr);
    ORACLE = PriceOracle(_priceOracleAddr);
    CUSDC = CERC20(_cUSDCAddr);
    CETH_ADDR = _cETHAddr;
    USDC_ADDR = _usdcAddr;
    KYBER_ADDR = _kyberAddr;
    usdc = ERC20Detailed(_usdcAddr);
    kyber = KyberNetwork(_kyberAddr);

    // transfer ownership to msg.sender
    _transferOwnership(msg.sender);
  }

  /**
   * @notice Executes the Compound order
   * @param _minPrice the minimum token price
   * @param _maxPrice the maximum token price
   */
  function executeOrder(uint256 _minPrice, uint256 _maxPrice) public;

  /**
   * @notice Sells the Compound order and returns assets to PeakDeFiFund
   * @param _minPrice the minimum token price
   * @param _maxPrice the maximum token price
   */
  function sellOrder(uint256 _minPrice, uint256 _maxPrice) public returns (uint256 _inputAmount, uint256 _outputAmount);

  /**
   * @notice Repays the loans taken out to prevent the collateral ratio from dropping below threshold
   * @param _repayAmountInUSDC the amount to repay, in USDC
   */
  function repayLoan(uint256 _repayAmountInUSDC) public;

  /**
   * @notice Emergency method, which allow to transfer selected tokens to the fund address
   * @param _tokenAddr address of withdrawn token
   * @param _receiver address who should receive tokens
   */
  function emergencyExitTokens(address _tokenAddr, address _receiver) public onlyOwner {
    ERC20Detailed token = ERC20Detailed(_tokenAddr);
    token.safeTransfer(_receiver, token.balanceOf(address(this)));
  }

  function getMarketCollateralFactor() public view returns (uint256);

  function getCurrentCollateralInUSDC() public returns (uint256 _amount);

  function getCurrentBorrowInUSDC() public returns (uint256 _amount);

  function getCurrentCashInUSDC() public view returns (uint256 _amount);

  /**
   * @notice Calculates the current profit in USDC
   * @return the profit amount
   */
  function getCurrentProfitInUSDC() public returns (bool _isNegative, uint256 _amount) {
    uint256 l;
    uint256 r;
    if (isSold) {
      l = outputAmount;
      r = collateralAmountInUSDC;
    } else {
      uint256 cash = getCurrentCashInUSDC();
      uint256 supply = getCurrentCollateralInUSDC();
      uint256 borrow = getCurrentBorrowInUSDC();
      if (cash >= borrow) {
        l = supply.add(cash);
        r = borrow.add(collateralAmountInUSDC);
      } else {
        l = supply;
        r = borrow.sub(cash).mul(PRECISION).div(getMarketCollateralFactor()).add(collateralAmountInUSDC);
      }
    }

    if (l >= r) {
      return (false, l.sub(r));
    } else {
      return (true, r.sub(l));
    }
  }

  /**
   * @notice Calculates the current collateral ratio on Compound, using 18 decimals
   * @return the collateral ratio
   */
  function getCurrentCollateralRatioInUSDC() public returns (uint256 _amount) {
    uint256 supply = getCurrentCollateralInUSDC();
    uint256 borrow = getCurrentBorrowInUSDC();
    if (borrow == 0) {
      return uint256(-1);
    }
    return supply.mul(PRECISION).div(borrow);
  }

  /**
   * @notice Calculates the current liquidity (supply - collateral) on the Compound platform
   * @return the liquidity
   */
  function getCurrentLiquidityInUSDC() public returns (bool _isNegative, uint256 _amount) {
    uint256 supply = getCurrentCollateralInUSDC();
    uint256 borrow = getCurrentBorrowInUSDC().mul(PRECISION).div(getMarketCollateralFactor());
    if (supply >= borrow) {
      return (false, supply.sub(borrow));
    } else {
      return (true, borrow.sub(supply));
    }
  }

  function __sellUSDCForToken(uint256 _usdcAmount) internal returns (uint256 _actualUSDCAmount, uint256 _actualTokenAmount) {
    ERC20Detailed t = __underlyingToken(compoundTokenAddr);
    (,, _actualTokenAmount, _actualUSDCAmount) = __kyberTrade(usdc, _usdcAmount, t); // Sell USDC for tokens on Kyber
    require(_actualUSDCAmount > 0 && _actualTokenAmount > 0); // Validate return values
  }

  function __sellTokenForUSDC(uint256 _tokenAmount) internal returns (uint256 _actualUSDCAmount, uint256 _actualTokenAmount) {
    ERC20Detailed t = __underlyingToken(compoundTokenAddr);
    (,, _actualUSDCAmount, _actualTokenAmount) = __kyberTrade(t, _tokenAmount, usdc); // Sell tokens for USDC on Kyber
    require(_actualUSDCAmount > 0 && _actualTokenAmount > 0); // Validate return values
  }

  // Convert a USDC amount to the amount of a given token that's of equal value
  function __usdcToToken(address _cToken, uint256 _usdcAmount) internal view returns (uint256) {
    ERC20Detailed t = __underlyingToken(_cToken);
    return _usdcAmount.mul(PRECISION).div(10 ** getDecimals(usdc)).mul(10 ** getDecimals(t)).div(ORACLE.getUnderlyingPrice(_cToken).mul(10 ** getDecimals(t)).div(PRECISION));
  }

  // Convert a compound token amount to the amount of USDC that's of equal value
  function __tokenToUSDC(address _cToken, uint256 _tokenAmount) internal view returns (uint256) {
    return _tokenAmount.mul(ORACLE.getUnderlyingPrice(_cToken)).div(PRECISION).mul(10 ** getDecimals(usdc)).div(PRECISION);
  }

  function __underlyingToken(address _cToken) internal view returns (ERC20Detailed) {
    if (_cToken == CETH_ADDR) {
      // ETH
      return ETH_TOKEN_ADDRESS;
    }
    CERC20 ct = CERC20(_cToken);
    address underlyingToken = ct.underlying();
    ERC20Detailed t = ERC20Detailed(underlyingToken);
    return t;
  }

  function() external payable {}
}