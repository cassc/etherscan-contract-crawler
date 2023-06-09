// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";

import "./interfaces/IWETH.sol";
import "./interfaces/ILiquidity.sol";
import "./interfaces/IManager.sol";
import "./interfaces/IWhitelist.sol";

/// @title Liquidity Contract V1
/// @notice A contract to manage Uniswap V3 liquidity positions.
contract Liquidity is ILiquidity, IManager, IWhitelist, Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  uint128 private constant MAX_UINT_128 = type(uint128).max;
  uint256 private constant MAX_UINT_256 = type(uint256).max;
  uint24 private constant ACTION_DEADLINE = 600;

  INonfungiblePositionManager public immutable positionManager;
  IUniswapV3Pool public immutable uniswapV3Pool;
  address public immutable token0;
  address public immutable token1;
  uint24 public immutable fee;

  uint256 public positionId;
  address public feeAddress;

  uint256 public lastChangePositionBlock;

  /// @notice Constructs the Liquidity contract
  /// @param _uniswapV3Pool The address of uniswap v3 pool contract
  /// @param _feeAddress The address to receive the fees
  /// @param _positionManager The address of the Uniswap V3 non-fungible position manager
  constructor(address _uniswapV3Pool, address _feeAddress, address _positionManager) {
    require(_positionManager != address(0), "Position manager address must be valid");

    uniswapV3Pool = IUniswapV3Pool(_uniswapV3Pool);
    {
      IUniswapV3Pool UniswapV3Pool = IUniswapV3Pool(_uniswapV3Pool);
      token0 = UniswapV3Pool.token0();
      token1 = UniswapV3Pool.token1();
      fee = UniswapV3Pool.fee();
    }

    positionManager = INonfungiblePositionManager(_positionManager);
    setFeeAddress(_feeAddress);
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

  /// @notice Set the fee address
  /// @param _feeAddress The address to receive fees
  function setFeeAddress(address _feeAddress) public override onlyOwner {
    require(_feeAddress != address(0), "Fee address must be valid");
    feeAddress = _feeAddress;
  }

  /// @notice Close the current position
  function closePosition() public override onlyOwner {
    _closePosition();
  }

  /// @notice Change the current position
  /// @param _tickLower The lower tick boundary of the new position
  /// @param _tickUpper The upper tick boundary of the new position
  /// @param withdrawToken0Destination The address to send the withdrawn token0
  /// @param withdrawToken1Destination The address to send the withdrawn token1
  /// @return tokenId The token id of new position
  function changePosition(
    int24 _tickLower,
    int24 _tickUpper,
    address payable withdrawToken0Destination,
    address payable withdrawToken1Destination
  ) public override onlyManager nonReentrant returns (uint256) {
    require(_tickLower < _tickUpper, "Tick lower must be less than tick upper");

    if (positionId != 0) {
      _closePosition();
    }

    (uint256 token0PositionAmount, uint256 token1PositionAmount) = _calculateTokensByLiquidity(
      _tickLower,
      _tickUpper
    );

    (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) = _openPosition(
      _tickLower,
      _tickUpper,
      token0PositionAmount,
      token1PositionAmount
    );

    emit PositionChanged(
      tokenId,
      amount0,
      amount1,
      liquidity,
      _tickLower,
      _tickUpper,
      block.timestamp
    );

    lastChangePositionBlock = block.number;
    _withdrawAfterChangePosition(withdrawToken0Destination, withdrawToken1Destination);
    return tokenId;
  }

  function _withdrawAfterChangePosition(address payable withdrawToken0Destination, address payable withdrawToken1Destination) private {
    uint256 amount0Balance = balanceOfToken0();
    uint256 amount1Balance = balanceOfToken1();

    if (amount0Balance > 0) {
      withdraw(token0, amount0Balance, withdrawToken0Destination);
    }
    if (amount1Balance > 0) {
      withdraw(token1, amount1Balance, withdrawToken1Destination);
    }
  }

  /// @notice Withdraw tokens from the contract
  /// @param _token The token to withdraw
  /// @param _amount The amount to withdraw
  /// @param _destination The address to send the withdrawn tokens
  function withdraw(
    address _token,
    uint256 _amount,
    address payable _destination
  ) public override onlyManager {
    require(isWhitelisted(_destination), "Address is not whitelisted");
    if (_token == WETH) {
      require(IWETH(_token).balanceOf(address(this)) >= _amount, "Not enough WETH balance");
      IWETH(_token).withdraw(_amount);
      if (_isContract(_destination)) {
        (bool success,) = _destination.call{value: _amount}("");
        require(success, "Ether transfer failed");
      } else {
        _destination.transfer(_amount);
      }
    } else {
      IERC20(_token).safeTransfer(_destination, _amount);
    }
  }

  /// @dev Show info about current position
  /// @return positionId The position ID of the current position
  /// @return tickLower The tickLower of the current position
  /// @return tickUpper The tickUpper of the current position
  /// @return reserve0 The reserve in token0 of the current position
  /// @return reserve1 The reserve in token1 of the current position
  function getPositionInfo()
  external
  view
  override
  returns (uint256, int24, int24, uint256, uint256)
  {
    (uint160 sqrtPriceX96, , , , , ,) = uniswapV3Pool.slot0();
    (, , , , , int24 tickLower, int24 tickUpper, uint128 liquidity, , , ,) = positionManager
    .positions(positionId);
    uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
    uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);
    (uint256 reserve0, uint256 reserve1) = LiquidityAmounts.getAmountsForLiquidity(
      sqrtPriceX96,
      sqrtRatioAX96,
      sqrtRatioBX96,
      liquidity
    );
    return (positionId, tickLower, tickUpper, reserve0, reserve1);
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
  /// @param _tickLower The new tick lower
  /// @param _tickUpper The new tick upper
  /// @return amount0 Calculated amounts for position in token0
  /// @return amount1 Calculated amounts for position in token1
  function _calculateTokensByLiquidity(
    int24 _tickLower,
    int24 _tickUpper
  ) public view returns (uint256, uint256) {
    (uint160 sqrtPriceX96, int24 tick, , , , ,) = uniswapV3Pool.slot0();
    require(_tickLower < tick && tick < _tickUpper, "Invalid tick boundary");

    uint160 sqrtPriceAX96 = TickMath.getSqrtRatioAtTick(_tickLower);
    uint160 sqrtPriceBX96 = TickMath.getSqrtRatioAtTick(_tickUpper);

    uint256 amount0Balance = balanceOfToken0();
    uint256 amount1Balance = balanceOfToken1();

    uint256 sqrtDiff = sqrtPriceBX96 - sqrtPriceAX96;
    uint256 sqrtCurrentA = sqrtPriceX96 - sqrtPriceAX96;
    uint256 sqrtCurrentB = sqrtPriceBX96 - sqrtPriceX96;
    uint256 token0PositionAmount = (amount0Balance * sqrtCurrentB) / sqrtDiff;
    uint256 token1PositionAmount = (amount1Balance * sqrtCurrentA) / sqrtDiff;

    uint128 liquidity;
    if (sqrtCurrentA > sqrtCurrentB) {
      liquidity = LiquidityAmounts.getLiquidityForAmount1(
        sqrtPriceAX96,
        sqrtPriceX96,
        token1PositionAmount
      );
    } else {
      liquidity = LiquidityAmounts.getLiquidityForAmount0(
        sqrtPriceX96,
        sqrtPriceBX96,
        token0PositionAmount
      );
    }

    (uint256 amount0, uint256 amount1) = LiquidityAmounts.getAmountsForLiquidity(
      sqrtPriceX96,
      sqrtPriceAX96,
      sqrtPriceBX96,
      liquidity
    );

    return (amount0, amount1);
  }

  /// @dev Close the current position
  function _closePosition() private {
    (, , , , , , , uint128 liquidity, , , ,) = positionManager.positions(positionId);

    (uint256 amount0, uint256 amount1) = positionManager.decreaseLiquidity(
      INonfungiblePositionManager.DecreaseLiquidityParams({
        tokenId: positionId,
        liquidity: liquidity,
        amount0Min: 0,
        amount1Min: 0,
        deadline: block.timestamp + ACTION_DEADLINE
      })
    );

    (uint256 collectedAmount0, uint256 collectedAmount1) = positionManager.collect(
      INonfungiblePositionManager.CollectParams({
        tokenId: positionId,
        recipient: address(this),
        amount0Max: MAX_UINT_128,
        amount1Max: MAX_UINT_128
      })
    );

    uint256 fee0Calculated;
    uint256 fee1Calculated;

    // We can use unchecked here because the result of the collect function
    // will include liquidity and fees if any. However, the decreaseLiquidity
    // will only return liquidity amounts. Therefore, collectedAmount0 and collectedAmount1
    // will always be greater than or equal to amount0 and amount1.
    // Underflow is not possible in this case.
    unchecked {
      fee0Calculated = collectedAmount0 - amount0;
      fee1Calculated = collectedAmount1 - amount1;
    }

    emit Earned(fee0Calculated, fee1Calculated);

    if (fee0Calculated > 0) {
      IERC20(token0).safeTransfer(feeAddress, fee0Calculated);
    }
    if (fee1Calculated > 0) {
      IERC20(token1).safeTransfer(feeAddress, fee1Calculated);
    }

    positionId = 0;
  }

  /// @dev Open a new position
  /// @param _tickLower The lower tick boundary of the new position
  /// @param _tickUpper The upper tick boundary of the new position
  /// @return tokenId The token ID of the new position
  /// @return liquidity The liquidity of the new position
  /// @return amount0 The amount of token0 in the new position
  /// @return amount1 The amount of token1 in the new position
  function _openPosition(
    int24 _tickLower,
    int24 _tickUpper,
    uint256 amount0Desired,
    uint256 amount1Desired
  ) private returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) {
    _safeApprove(token0, address(positionManager), amount0Desired);
    _safeApprove(token1, address(positionManager), amount1Desired);

    // Create the position
    (tokenId, liquidity, amount0, amount1) = positionManager.mint(
      INonfungiblePositionManager.MintParams({
        token0: token0,
        token1: token1,
        fee: fee,
        tickLower: _tickLower,
        tickUpper: _tickUpper,
        amount0Desired: amount0Desired,
        amount1Desired: amount1Desired,
        amount0Min: 0,
        amount1Min: 0,
        recipient: address(this),
        deadline: block.timestamp + ACTION_DEADLINE
      })
    );

    positionId = tokenId;
  }

  /// @dev Safely approve another contract to spend tokens
  /// @param token The token to approve
  /// @param receiver The address of the contract to approve
  /// @param amount The amount to approve
  function _safeApprove(address token, address receiver, uint256 amount) private {
    uint256 allowed = IERC20(token).allowance(address(this), receiver);
    if (allowed < amount) {
      if (allowed != 0) {
        IERC20(token).safeApprove(receiver, 0);
      }
      IERC20(token).safeApprove(receiver, MAX_UINT_256);
    }
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
}