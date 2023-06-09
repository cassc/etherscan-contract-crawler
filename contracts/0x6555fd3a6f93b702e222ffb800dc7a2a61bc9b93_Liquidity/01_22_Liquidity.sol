// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";

import "./interfaces/IWETH.sol";
import "./interfaces/ILiquidity.sol";
import "./interfaces/IManager.sol";
import "./interfaces/IWhitelist.sol";

error NotWhitelisted();

/// @title Liquidity Contract V4
/// @notice A contract to manage Uniswap V3 liquidity positions.
contract Liquidity is ILiquidity, IManager, IWhitelist, Ownable, IUniswapV3MintCallback {
  address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  uint24 private constant ACTION_DEADLINE = 600;
  uint128 private constant MAX_UINT_128 = type(uint128).max;

  IUniswapV3Pool public immutable uniswapV3Pool;
  address public immutable token0;
  address public immutable token1;
  uint24 public immutable fee;

  uint24 public positionId = 0;
  uint128 public liquidity;
  int24 public tickLower;
  int24 public tickUpper;

  /// @notice Constructs the Liquidity contract
  /// @param _uniswapV3Pool The address of uniswap v3 pool contract
  constructor(address _uniswapV3Pool) {
    uniswapV3Pool = IUniswapV3Pool(_uniswapV3Pool);
    token0 = uniswapV3Pool.token0();
    token1 = uniswapV3Pool.token1();
    fee = uniswapV3Pool.fee();
  }

  /// @notice Receive ETH and wrap to WETH
  receive() external payable {
    if (msg.sender != WETH) {
      IWETH(WETH).deposit{value: msg.value}();
      emit Received(msg.sender, msg.value);
    }
  }

  /// @notice Add a new manager address
  /// @param _manager The address of the new manager
  function addManager(address _manager) external override onlyOwner {
    _addManager(_manager);
  }

  /// @notice Remove a manager address
  /// @param _manager The address of the manager to remove
  function removeManager(address _manager) external override onlyOwner {
    _removeManager(_manager);
  }

  /// @notice Get the balance of token0 held by the contract
  /// @return The balance of token0
  function balanceOfToken0() public view override returns (uint256) {
    return IERC20(token0).balanceOf(address(this));
  }

  /// @notice Get the balance of token1 held by the contract
  /// @return The balance of token1
  function balanceOfToken1() public view override returns (uint256) {
    return IERC20(token1).balanceOf(address(this));
  }

  /// @notice Add an address to the whitelist
  /// @param _address The address to be added to the whitelist
  function addWhitelist(address _address) public override onlyOwner {
    _addWhitelist(_address);
  }

  /// @notice Remove an address from the whitelist
  /// @param _address The address to be removed from the whitelist
  function removeWhitelist(address _address) public override onlyOwner {
    _removeWhitelist(_address);
  }

  /// @notice Close the current position
  function closePosition() public override onlyOwner {
    _closePosition();
  }

  /// @notice Change the current position
  /// @param _tickLower The lower tick boundary of the new position
  /// @param _tickUpper The upper tick boundary of the new position
  /// @param sqrtPriceAX96 The sqrtPriceAX96 of the new position
  /// @param sqrtPriceBX96 The sqrtPriceBX96 of the new position
  /// @param withdrawToken0Destination The address to send the withdrawn token0
  /// @param withdrawToken1Destination The address to send the withdrawn token1
  function changePosition(
    int24 _tickLower,
    int24 _tickUpper,
    uint160 sqrtPriceAX96,
    uint160 sqrtPriceBX96,
    address payable withdrawToken0Destination,
    address payable withdrawToken1Destination
  ) public override onlyManager {
    if (positionId != 0) {
      _closePosition();
    }

    (uint128 _liquidity) = _calculateLiquidity(
      sqrtPriceAX96,
      sqrtPriceBX96
    );

    _openPosition(_tickLower, _tickUpper, _liquidity);
    _withdrawAfterChangePosition(withdrawToken0Destination, withdrawToken1Destination);
  }


  function _withdrawAfterChangePosition(address payable withdrawToken0Destination, address payable withdrawToken1Destination) private {
    uint256 amount0Balance = balanceOfToken0();
    uint256 amount1Balance = balanceOfToken1();

    if (amount0Balance > 0) {
      _withdraw(token0, amount0Balance, withdrawToken0Destination);
    }
    if (amount1Balance > 0) {
      _withdraw(token1, amount1Balance, withdrawToken1Destination);
    }
  }

  /// @notice Withdraw tokens from the contract
  /// @param _token The token to withdraw
  /// @param _amount The amount to withdraw
  /// @param _destination The address to send the withdrawn tokens
  function withdraw (
    address _token,
    uint256 _amount,
    address payable _destination
  ) public override onlyManager {
    _withdraw(_token, _amount, _destination);
  }

  function _withdraw(
    address _token,
    uint256 _amount,
    address payable _destination
  ) internal {
    if(!isWhitelisted(_destination)) revert NotWhitelisted();
    if (_token == WETH) {
      IWETH(_token).withdraw(_amount);
      if (_isContract(_destination)) {
        (bool success,) = _destination.call{value: _amount}("");
        require(success, "Ether transfer failed");
      } else {
        _destination.transfer(_amount);
      }
    } else {
      IERC20(_token).transfer(_destination, _amount);
    }
  }

  /// @dev Show info about current position
  /// @return positionId The position ID of the current position
  /// @return tickLower The tickLower of the current position
  /// @return tickUpper The tickUpper of the current position
  /// @return reserve0 The reserve in token0 of the current position
  /// @return reserve1 The reserve in token1 of the current position
  function getPositionInfo() external view override returns (uint256, int24, int24, uint256, uint256, uint128) {
    if (positionId == 0)
      return (0, 0, 0, 0, 0, 0);
    (uint160 sqrtPriceX96, , , , , ,) = uniswapV3Pool.slot0();
    uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
    uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);
    (uint256 reserve0, uint256 reserve1) = LiquidityAmounts.getAmountsForLiquidity(
      sqrtPriceX96,
      sqrtRatioAX96,
      sqrtRatioBX96,
      liquidity
    );
    return (positionId, tickLower, tickUpper, reserve0, reserve1, liquidity);
  }

  /// @notice Make an emergency call to another contract
  /// @param contractToCall The address of the contract to call
  /// @param callData to send to the contract
  function makeEmergencyCall(
    address contractToCall,
    bytes calldata callData
  ) external override onlyOwner {
    (bool success, bytes memory result) = contractToCall.call(callData);
    if (!success) {
      // Next 5 lines from https://ethereum.stackexchange.com/a/83577
      if (result.length < 68) revert();
      assembly {
        result := add(result, 0x04)
      }
      revert(abi.decode(result, (string)));
    }
  }

  /// @notice Calculate liquidity proportion
  /// @param sqrtPriceAX96 The new sqrtPriceAX96
  /// @param sqrtPriceBX96 The new sqrtPriceBX96
  /// @return _liquidity Calculated liquidity for new position
  function _calculateLiquidity(
    uint160 sqrtPriceAX96,
    uint160 sqrtPriceBX96
  ) public view returns (uint128 _liquidity) {
    (uint160 sqrtPriceX96, , , , , ,) = uniswapV3Pool.slot0();
    uint256 amount0Balance = balanceOfToken0();
    uint256 amount1Balance = balanceOfToken1();

    uint256 sqrtCurrentA;
    uint256 sqrtCurrentB;
    uint256 token0PositionAmount;
    uint256 token1PositionAmount;

    unchecked{
      uint256 sqrtDiff = sqrtPriceBX96 - sqrtPriceAX96;
      sqrtCurrentA = sqrtPriceX96 - sqrtPriceAX96;
      sqrtCurrentB = sqrtPriceBX96 - sqrtPriceX96;
      token0PositionAmount = (amount0Balance * sqrtCurrentB) / sqrtDiff;
      token1PositionAmount = (amount1Balance * sqrtCurrentA) / sqrtDiff;
    }

    if (sqrtCurrentA > sqrtCurrentB) {
      _liquidity = LiquidityAmounts.getLiquidityForAmount1(
        sqrtPriceAX96,
        sqrtPriceX96,
        token1PositionAmount
      );
    } else {
      _liquidity = LiquidityAmounts.getLiquidityForAmount0(
        sqrtPriceX96,
        sqrtPriceBX96,
        token0PositionAmount
      );
    }
  }

  /// @dev Close the current position
  function _closePosition() private {
    int24 _tickLower = tickLower;
    int24 _tickUpper = tickUpper;
    uint128 maxUint = MAX_UINT_128;

    uniswapV3Pool.burn(_tickLower, _tickUpper, liquidity);
    uniswapV3Pool.collect(
      address(this),
      _tickLower,
      _tickUpper,
      maxUint,
      maxUint
    );
  }

  /// @dev Open a new position
  /// @param _tickLower The lower tick boundary of the new position
  /// @param _tickUpper The upper tick boundary of the new position
  /// @param _newLiquidity The upper tick boundary of the new position
  /// @return amount0 The amount of token0 in the new position
  /// @return amount1 The amount of token1 in the new position
  function _openPosition(
    int24 _tickLower,
    int24 _tickUpper,
    uint128 _newLiquidity
  ) private returns (uint256 amount0, uint256 amount1) {
    (amount0, amount1) = uniswapV3Pool.mint(
      address(this),
      _tickLower,
      _tickUpper,
      _newLiquidity,
      ""
    );

    liquidity = _newLiquidity;
    tickLower = _tickLower;
    tickUpper = _tickUpper;
    positionId++;
  }

  /// @dev Check if an address is a contract
  /// @param _addr The address to check
  /// @return Whether the address is a contract
  function _isContract(address _addr) private view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(_addr)
    }
    return size > 0;
  }

  /// @inheritdoc IUniswapV3MintCallback
  function uniswapV3MintCallback(
    uint256 amount0Owed,
    uint256 amount1Owed,
    bytes calldata data
  ) external override {
    address sender = msg.sender;
    require(sender == address(uniswapV3Pool));
    if (amount0Owed > 0)  IERC20(token0).transfer(sender, amount0Owed);
    if (amount1Owed > 0)  IERC20(token1).transfer(sender, amount1Owed);
  }
}