// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../interfaces/IWETH.sol";
import "../interfaces/IZap.sol";

import "./Vesting.sol";

// solhint-disable reason-string, not-rely-on-time

contract TokenSale is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  event Buy(address indexed sender, address _token, uint256 _amountIn, uint256 _refundAmount, uint256 _amountOut);
  event Claim(address indexed _recipient, uint256 _vestingAmount, uint256 _claimAmount);
  event UpdatePrice(uint256 _initialPrice, uint256 _upRatio, uint256 _variation);
  event UpdateSaleTime(uint256 _whitelistSaleTime, uint256 _publicSaleTime, uint256 _publicSaleDuration);
  event UpdateVesting(address _vesting, uint256 _vestRatio, uint256 _duration);
  event UpdateWhitelistCap(address indexed _whitelist, uint256 _cap);
  event UpdateSupportedToken(address indexed _token, bool _status);

  uint256 private constant PRICE_PRECISION = 1e18;
  uint256 private constant RATIO_PRECISION = 1e9;

  address public immutable weth;
  address public immutable base;
  address public immutable zap;
  address public quota;

  struct PriceData {
    uint96 initialPrice;
    uint32 upRatio;
    uint128 variation;
  }

  struct SaleTimeData {
    uint64 whitelistSaleTime;
    uint64 publicSaleTime;
    uint64 saleDuration;
  }

  struct VestingData {
    address vesting;
    uint32 vestRatio;
    uint64 duration;
  }

  SaleTimeData public saleTimeData;
  PriceData public priceData;
  VestingData public vestingData;

  uint128 public cap;
  uint128 public totalSold;

  mapping(address => bool) public isSupported;
  mapping(address => uint256) public whitelistCap;
  mapping(address => uint256) public shares;
  mapping(address => bool) public claimed;

  constructor(
    address _weth,
    address _base,
    address _zap,
    uint128 _cap
  ) {
    weth = _weth;
    base = _base;
    zap = _zap;
    cap = _cap;
  }

  /********************************** View Functions **********************************/

  /// @notice Return current price (base/quota) of quota token.
  /// @dev                                                  / totalSold \
  ///      CurrenetPrice = InitPrice * (1 + UpRatio * floor|  ---------  |)
  ///                                                       \ Variation /
  function getPrice() public view returns (uint256) {
    PriceData memory _data = priceData;
    uint256 _totalSold = totalSold;
    uint256 _level = _totalSold / _data.variation;

    return RATIO_PRECISION.add(_level.mul(_data.upRatio)).mul(_data.initialPrice).div(RATIO_PRECISION);
  }

  /********************************** Mutated Functions **********************************/

  /// @notice Purchase some quota in contract using supported base token.
  ///
  /// @dev The contract will refund `_token` back to caller if the sale cap is not enough.
  ///
  /// @param _token The address of token used to buy quota token.
  /// @param _amountIn The amount of `_token` to use.
  /// @param _minOut The minimum recieved quota token.
  function buy(
    address _token,
    uint256 _amountIn,
    uint256 _minOut
  ) external payable nonReentrant returns (uint256) {
    require(_amountIn > 0, "TokenSale: zero input amount");

    // 1. check supported token
    require(isSupported[_token], "TokenSale: token not support");

    // 2. check sale time
    SaleTimeData memory _saleTime = saleTimeData;
    require(block.timestamp >= _saleTime.whitelistSaleTime, "TokenSale: sale not start");
    require(block.timestamp <= _saleTime.publicSaleTime + _saleTime.saleDuration, "TokenSale: sale ended");

    // 3. determine account sale cap
    uint256 _cap = cap;
    uint256 _totalSold = totalSold;
    uint256 _saleCap = _cap.sub(_totalSold);
    require(_saleCap > 0, "TokenSale: sold out");

    uint256 _userCap;
    if (block.timestamp < _saleTime.publicSaleTime) {
      _userCap = whitelistCap[msg.sender].sub(shares[msg.sender]);
      if (_userCap > _saleCap) {
        _userCap = _saleCap;
      }
    } else {
      _userCap = _saleCap;
    }
    require(_userCap > 0, "TokenSale: no cap to buy");

    // 4. transfer token in contract
    if (_token == address(0)) {
      require(_amountIn == msg.value, "TokenSale: msg.value mismatch");
      _token = weth;
      IWETH(_token).deposit{ value: _amountIn }();
    } else {
      require(0 == msg.value, "TokenSale: nonzero msg.value");
      uint256 _before = IERC20(_token).balanceOf(address(this));
      IERC20(_token).safeTransferFrom(msg.sender, address(this), _amountIn);
      _amountIn = IERC20(_token).balanceOf(address(this)) - _before;
    }

    // 5. zap input token to base token
    address _base = base;
    uint256 _baseAmountIn;
    if (_token != _base) {
      address _zap = zap;
      IERC20(_token).safeTransfer(_zap, _amountIn);
      _baseAmountIn = IZap(_zap).zap(_token, _amountIn, _base, 0);
    } else {
      _baseAmountIn = _amountIn;
    }

    // 6. buy and update storage
    uint256 _price = getPrice();
    uint256 _amountOut = _baseAmountIn.mul(PRICE_PRECISION).div(_price);
    uint256 _refundAmount;
    if (_userCap < _amountOut) {
      _refundAmount = (_amountOut - _userCap).mul(_price).div(PRICE_PRECISION);
      _amountOut = _userCap;
    }
    require(_amountOut >= _minOut, "TokenSale: insufficient output");
    shares[msg.sender] += _amountOut;

    _totalSold += _amountOut;
    require(_totalSold <= uint128(-1), "TokenSale: overflow");
    totalSold = uint128(_totalSold);

    // 7. refund extra token
    if (_refundAmount > 0) {
      _refundAmount = _refund(_token, _refundAmount);
    }

    emit Buy(msg.sender, msg.value > 0 ? address(0) : _token, _amountIn, _refundAmount, _amountOut);

    return _amountOut;
  }

  /// @notice Claim purchased quota token.
  function claim() external nonReentrant {
    // 1. check timestamp and claimed.
    SaleTimeData memory _saleTime = saleTimeData;
    require(block.timestamp > _saleTime.publicSaleTime + _saleTime.saleDuration, "TokenSale: sale not end");
    require(!claimed[msg.sender], "TokenSale: already claimed");

    // 2. check claiming amount
    VestingData memory _vesting = vestingData;
    uint256 _claimAmount = shares[msg.sender];
    require(_claimAmount > 0, "TokenSale: no share to claim");
    claimed[msg.sender] = true;

    address _quota = quota;

    // 3. vesting
    uint256 _vestingAmount = _claimAmount.mul(_vesting.vestRatio).div(RATIO_PRECISION);
    if (_vestingAmount > 0) {
      IERC20(_quota).safeApprove(_vesting.vesting, 0);
      IERC20(_quota).safeApprove(_vesting.vesting, _vestingAmount);
      Vesting(_vesting.vesting).newVesting(
        msg.sender,
        uint128(_vestingAmount),
        uint64(block.timestamp),
        uint64(block.timestamp + _vesting.duration)
      );
    }

    // 4. transfer
    _claimAmount = _claimAmount - _vestingAmount;
    if (_claimAmount > 0) {
      IERC20(_quota).safeTransfer(msg.sender, _claimAmount);
    }

    emit Claim(msg.sender, _vestingAmount, _claimAmount);
  }

  /********************************** Restricted Functions **********************************/

  /// @notice Update supported tokens.
  /// @param _tokens The list of addresses of token to update.
  /// @param _status The status to update.
  function updateSupportedTokens(address[] memory _tokens, bool _status) external onlyOwner {
    for (uint256 i = 0; i < _tokens.length; i++) {
      isSupported[_tokens[i]] = _status;
      emit UpdateSupportedToken(_tokens[i], _status);
    }
  }

  /// @notice Update token cap for whitelists.
  /// @param _whitelist The list of whitelist to update.
  /// @param _caps The list of cap to update.
  function updateWhitelistCap(address[] memory _whitelist, uint256[] memory _caps) external onlyOwner {
    require(_whitelist.length == _caps.length, "TokenSale: length mismatch");

    for (uint256 i = 0; i < _whitelist.length; i++) {
      whitelistCap[_whitelist[i]] = _caps[i];
      emit UpdateWhitelistCap(_whitelist[i], _caps[i]);
    }
  }

  /// @notice Update sale start time, including whitelist/public sale start time and duration.
  ///
  /// @param _whitelistSaleTime The timestamp when whitelist sale started.
  /// @param _publicSaleTime The timestamp when public sale started.
  /// @param _publicSaleDuration The durarion of public sale in seconds.
  function updateSaleTime(
    uint64 _whitelistSaleTime,
    uint64 _publicSaleTime,
    uint64 _publicSaleDuration
  ) external onlyOwner {
    require(_whitelistSaleTime >= block.timestamp, "TokenSale: start time too small");
    require(_whitelistSaleTime <= _publicSaleTime, "TokenSale: whitelist after public");

    SaleTimeData memory _saleTime = saleTimeData;
    require(
      _saleTime.whitelistSaleTime == 0 || block.timestamp < _saleTime.whitelistSaleTime,
      "TokenSale: sale started"
    );

    saleTimeData = SaleTimeData(_whitelistSaleTime, _publicSaleTime, _publicSaleDuration);

    emit UpdateSaleTime(_whitelistSaleTime, _publicSaleTime, _publicSaleDuration);
  }

  /// @notice Update token sale price info.
  /// @dev See comments in function `getPrice()` for the usage of each parameters.
  ///
  /// @param _initialPrice The initial price for the sale, with precision 1e18.
  /// @param _upRatio The up ratio for the token sale, with precision 1e9.
  /// @param _variation The variation for price change base on the amount of quota token sold.
  function updatePrice(
    uint96 _initialPrice,
    uint32 _upRatio,
    uint128 _variation
  ) external onlyOwner {
    require(_upRatio <= RATIO_PRECISION, "TokenSale: ratio too large");
    require(_variation > 0, "TokenSale: zero variation");

    SaleTimeData memory _saleTime = saleTimeData;
    require(
      _saleTime.whitelistSaleTime == 0 || block.timestamp < _saleTime.whitelistSaleTime,
      "TokenSale: sale started"
    );

    priceData = PriceData(_initialPrice, _upRatio, _variation);

    emit UpdatePrice(_initialPrice, _upRatio, _variation);
  }

  /// @notice Update vesting information.
  /// @param _vesting The address of vesting contract.
  /// @param _vestRatio The percentage of quota token to vest.
  /// @param _duration The vesting duration, in seconds.
  function updateVesting(
    address _quota,
    address _vesting,
    uint32 _vestRatio,
    uint64 _duration
  ) external onlyOwner {
    require(_vestRatio <= RATIO_PRECISION, "TokenSale: ratio too large");
    require(_duration > 0, "TokenSale: zero duration");

    quota = _quota;
    vestingData = VestingData(_vesting, _vestRatio, _duration);

    emit UpdateVesting(_vesting, _vestRatio, _duration);
  }

  function withdrawFund(address[] memory _tokens, address _recipient) external onlyOwner {
    for (uint256 i = 0; i < _tokens.length; i++) {
      if (_tokens[i] == address(0)) {
        uint256 _balance = address(this).balance;
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = _recipient.call{ value: _balance }("");
        require(success, "TokenSale: failed to withdraw ETH");
      } else {
        uint256 _balance = IERC20(_tokens[i]).balanceOf(address(this));
        IERC20(_tokens[i]).safeTransfer(_recipient, _balance);
      }
    }
  }

  /********************************** Internal Functions **********************************/

  /// @dev Refund extra token back to sender, will call zap if needed.
  /// @param _token The address of token to refund.
  /// @param _amount The amount of base token to refund.
  function _refund(address _token, uint256 _amount) internal returns (uint256) {
    address _base = base;
    if (_token != _base) {
      address _zap = zap;
      IERC20(_base).safeTransfer(_zap, _amount);
      uint256 _before = IERC20(_token).balanceOf(address(this));
      IZap(_zap).zap(_base, _amount, _token, 0);
      _amount = IERC20(_token).balanceOf(address(this)) - _before;
    }
    if (msg.value > 0) {
      IWETH(_token).withdraw(_amount);
      // solhint-disable-next-line avoid-low-level-calls
      (bool success, ) = msg.sender.call{ value: _amount }("");
      require(success, "TokenSale: failed to refund ETH");
    } else {
      IERC20(_token).safeTransfer(msg.sender, _amount);
    }
    return _amount;
  }

  // solhint-disable-next-line no-empty-blocks
  receive() external payable {}
}