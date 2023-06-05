pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import 'OpenZeppelin/[email protected]/contracts/math/SafeMath.sol';

import '../Governable.sol';
import '../../interfaces/IOracle.sol';
import '../../interfaces/IBaseOracle.sol';
import '../../interfaces/IERC20Wrapper.sol';

contract ProxyOracle is IOracle, Governable {
  using SafeMath for uint;

  /// The governor sets oracle information for a token.
  event SetOracle(address token, Oracle info);
  /// The governor unsets oracle information for a token.
  event UnsetOracle(address token);
  /// The governor sets token whitelist for an ERC1155 token.
  event SetWhitelist(address token, bool ok);

  struct Oracle {
    uint16 borrowFactor; // The borrow factor for this token, multiplied by 1e4.
    uint16 collateralFactor; // The collateral factor for this token, multiplied by 1e4.
    uint16 liqIncentive; // The liquidation incentive, multiplied by 1e4.
  }

  IBaseOracle public immutable source;
  mapping(address => Oracle) public oracles; // Mapping from token address to oracle info.
  mapping(address => bool) public whitelistERC1155;

  /// @dev Create the contract and initialize the first governor.
  constructor(IBaseOracle _source) public {
    source = _source;
    __Governable__init();
  }

  /// @dev Set oracle information for the given list of token addresses.
  function setOracles(address[] memory tokens, Oracle[] memory info) external onlyGov {
    require(tokens.length == info.length, 'inconsistent length');
    for (uint idx = 0; idx < tokens.length; idx++) {
      require(info[idx].borrowFactor >= 10000, 'borrow factor must be at least 100%');
      require(info[idx].collateralFactor <= 10000, 'collateral factor must be at most 100%');
      require(info[idx].liqIncentive >= 10000, 'incentive must be at least 100%');
      require(info[idx].liqIncentive <= 20000, 'incentive must be at most 200%');
      oracles[tokens[idx]] = info[idx];
      emit SetOracle(tokens[idx], info[idx]);
    }
  }

  function unsetOracles(address[] memory tokens) external onlyGov {
    for (uint idx = 0; idx < tokens.length; idx++) {
      oracles[tokens[idx]] = Oracle(0, 0, 0);
      emit UnsetOracle(tokens[idx]);
    }
  }

  /// @dev Set whitelist status for the given list of token addresses.
  function setWhitelistERC1155(address[] memory tokens, bool ok) external onlyGov {
    for (uint idx = 0; idx < tokens.length; idx++) {
      whitelistERC1155[tokens[idx]] = ok;
      emit SetWhitelist(tokens[idx], ok);
    }
  }

  /// @dev Return whether the oracle supports evaluating collateral value of the given token.
  function support(address token, uint id) external view override returns (bool) {
    if (!whitelistERC1155[token]) return false;
    address tokenUnderlying = IERC20Wrapper(token).getUnderlyingToken(id);
    return oracles[tokenUnderlying].liqIncentive != 0;
  }

  /// @dev Return the amount of token out as liquidation reward for liquidating token in.
  function convertForLiquidation(
    address tokenIn,
    address tokenOut,
    uint tokenOutId,
    uint amountIn
  ) external view override returns (uint) {
    require(whitelistERC1155[tokenOut], 'bad token');
    address tokenOutUnderlying = IERC20Wrapper(tokenOut).getUnderlyingToken(tokenOutId);
    uint rateUnderlying = IERC20Wrapper(tokenOut).getUnderlyingRate(tokenOutId);
    Oracle memory oracleIn = oracles[tokenIn];
    Oracle memory oracleOut = oracles[tokenOutUnderlying];
    require(oracleIn.liqIncentive != 0, 'bad underlying in');
    require(oracleOut.liqIncentive != 0, 'bad underlying out');
    uint pxIn = source.getETHPx(tokenIn);
    uint pxOut = source.getETHPx(tokenOutUnderlying);
    uint amountOut = amountIn.mul(pxIn).div(pxOut);
    amountOut = amountOut.mul(2**112).div(rateUnderlying);
    return amountOut.mul(oracleIn.liqIncentive).mul(oracleOut.liqIncentive).div(10000 * 10000);
  }

  /// @dev Return the value of the given input as ETH for collateral purpose.
  function asETHCollateral(
    address token,
    uint id,
    uint amount,
    address owner
  ) external view override returns (uint) {
    require(whitelistERC1155[token], 'bad token');
    address tokenUnderlying = IERC20Wrapper(token).getUnderlyingToken(id);
    uint rateUnderlying = IERC20Wrapper(token).getUnderlyingRate(id);
    uint amountUnderlying = amount.mul(rateUnderlying).div(2**112);
    Oracle memory oracle = oracles[tokenUnderlying];
    require(oracle.liqIncentive != 0, 'bad underlying collateral');
    uint ethValue = source.getETHPx(tokenUnderlying).mul(amountUnderlying).div(2**112);
    return ethValue.mul(oracle.collateralFactor).div(10000);
  }

  /// @dev Return the value of the given input as ETH for borrow purpose.
  function asETHBorrow(
    address token,
    uint amount,
    address owner
  ) external view override returns (uint) {
    Oracle memory oracle = oracles[token];
    require(oracle.liqIncentive != 0, 'bad underlying borrow');
    uint ethValue = source.getETHPx(token).mul(amount).div(2**112);
    return ethValue.mul(oracle.borrowFactor).div(10000);
  }
}