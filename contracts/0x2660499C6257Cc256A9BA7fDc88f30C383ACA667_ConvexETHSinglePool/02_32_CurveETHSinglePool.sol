// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./CurveBaseV2.sol";
import "../../interfaces/IWeth.sol";

/// @dev A strategy that supports any ETH pool in Curve. This only supports StableSwap (plain) pools. But all Curve ETH pools are StableSwaps, and only have 2 input tokens, and one of them is ETH.
contract CurveETHSinglePool is CurveBaseV2 {
  using SafeERC20 for IERC20;
  using Address for address;
  uint256 public constant NUMBER_OF_COINS = 2;
  /// @dev the index of the token this strategy will add to the Curve pool
  uint8 public immutable inputTokenIndex;

  /// @param _vault the address of the vault for this strategy
  /// @param _proposer the address of the proposer for this strategy. Can be address(0).
  /// @param _developer the address of the developer for this strategy. Can be address(0).
  /// @param _harvester the address of the harvester for this strategy
  /// @param _pool the address of the Curve pool
  /// @param _gauge the address of the gauge for this pool
  /// @param _inputTokenIndex the index of the token this strategy will add to the Curve pool
  constructor(
    address _vault,
    address _proposer,
    address _developer,
    address _harvester,
    address _pool,
    address _gauge,
    uint8 _inputTokenIndex
  ) CurveBaseV2(_vault, _proposer, _developer, _harvester, _pool, _gauge) {
    require(_inputTokenIndex < NUMBER_OF_COINS, "!inputTokenIndex");
    inputTokenIndex = _inputTokenIndex;
    _approveCurveExtra();
  }

  function name() external view virtual override returns (string memory) {
    return "CurveETHSinglePool";
  }

  function checkWantToken() internal view virtual override {
    require(address(want) == _getWETHTokenAddress(), "wrong vault token");
  }

  function _approveCurveExtra() internal virtual {
    // the pool needs this to add liquidity to the base pool
    IERC20(_getWETHTokenAddress()).safeApprove(address(curvePool), type(uint256).max);
  }

  function _getWantTokenIndex() internal view override returns (uint256) {
    return inputTokenIndex;
  }

  function _getCoinsCount() internal view virtual override returns (uint256) {
    return NUMBER_OF_COINS;
  }

  function _addLiquidityToCurvePool() internal virtual override {
    uint256 balance = _balanceOfWant();
    if (balance > 0) {
      // covert weth to eth
      IWETH(_getWETHTokenAddress()).withdraw(balance);
      uint256[2] memory params;
      params[inputTokenIndex] = balance;
      curvePool.add_liquidity{value: balance}(params, 0);
    }
  }

  /// @dev Remove the liquidity by the LP token amount
  /// @param _amount The amount of LP token (not want token)
  function _removeLiquidity(uint256 _amount) internal override returns (uint256) {
    uint256 amount = super._removeLiquidity(_amount);
    // wrap the eth to weth
    IWETH(_getWETHTokenAddress()).deposit{value: amount}();
    return amount;
  }

  function _balanceOfPoolInputToken() internal view virtual override returns (uint256) {
    return address(this).balance;
  }

  /// @dev This is needed in order to receive eth that will be returned by WETH contract
  // solhint-disable-next-line
  receive() external payable {}
}