// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IWETH.sol";
import "./interfaces/INonFungiblePositionManager.sol";
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

  INonFungiblePositionManager public immutable positionManager;
  address public immutable token0;
  address public immutable token1;
  uint24 public immutable fee;

  uint256 public positionId;
  address public feeAddress;

  /// @notice Constructs the Liquidity contract
  /// @param _token0 The address of token0
  /// @param _token1 The address of token1
  /// @param _fee The fee to be used
  /// @param _feeAddress The address to receive the fees
  /// @param _positionManager The address of the Uniswap V3 non-fungible position manager
  constructor(
    address _token0,
    address _token1,
    uint24 _fee,
    address _feeAddress,
    address _positionManager
  ) {
    require(_token0 != address(0), "Token0 address must be valid");
    require(_token1 != address(0), "Token1 address must be valid");
    require(_feeAddress != address(0), "Fee address must be valid");
    require(_positionManager != address(0), "Position manager address must be valid");

    token0 = _token0;
    token1 = _token1;
    fee = _fee;
    feeAddress = _feeAddress;
    positionManager = INonFungiblePositionManager(_positionManager);
  }

  /// @notice Receive ETH and wrap to WETH
  receive() external payable {
    if (msg.sender != WETH) {
      IWETH(WETH).deposit{value : msg.value}();
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
  /// @param _address The address to receive fees
  function setFeeAddress(address _address) public override onlyOwner {
    feeAddress = _address;
  }

  /// @notice Close the current position
  function closePosition() public override onlyOwner {
    _closePosition();
  }

  /// @notice Change the current position
  /// @param _tickLower The lower tick boundary of the new position
  /// @param _tickUpper The upper tick boundary of the new position
  /// @param withdrawToken0Amount The amount of token0 to withdraw
  /// @param withdrawToken1Amount The amount of token1 to withdraw
  /// @param withdrawToken0Destination The address to send the withdrawn token0
  /// @param withdrawToken1Destination The address to send the withdrawn token1
  function changePosition(int24 _tickLower, int24 _tickUpper, uint256 withdrawToken0Amount, uint256 withdrawToken1Amount, address payable withdrawToken0Destination, address payable withdrawToken1Destination) public override onlyManager nonReentrant {
    if (positionId != 0) {
      _closePosition();
    }
    if (withdrawToken0Amount > 0) {
      withdraw(token0, withdrawToken0Amount, withdrawToken0Destination);
    }
    if (withdrawToken1Amount > 0) {
      withdraw(token1, withdrawToken1Amount, withdrawToken1Destination);
    }

    (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) = _openPosition(
      _tickLower,
      _tickUpper
    );
    emit PositionChanged(tokenId, amount0, amount1, liquidity, _tickLower, _tickUpper);
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
        (bool success,) = _destination.call{value : _amount}("");
        require(success, "Ether transfer failed");
      } else {
        _destination.transfer(_amount);
      }
    } else {
      IERC20(_token).safeTransfer(_destination, _amount);
    }
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

  /// @dev Close the current position
  function _closePosition() private {
    INonFungiblePositionManager.CollectParams memory collectFeeParams = INonFungiblePositionManager
    .CollectParams(positionId, feeAddress, MAX_UINT_128, MAX_UINT_128);

    positionManager.collect(collectFeeParams);

    INonFungiblePositionManager.PositionInfo memory positionInfo = positionManager.positions(
      positionId
    );

    INonFungiblePositionManager.DecreaseLiquidityParams
    memory decreaseLiquidityParams = INonFungiblePositionManager.DecreaseLiquidityParams(
      positionId,
      positionInfo.liquidity,
      0,
      0,
      block.timestamp + ACTION_DEADLINE
    );

    positionManager.decreaseLiquidity(decreaseLiquidityParams);

    INonFungiblePositionManager.CollectParams
    memory collectLiquidityParams = INonFungiblePositionManager.CollectParams(
      positionId,
      address(this),
      MAX_UINT_128,
      MAX_UINT_128
    );

    positionManager.collect(collectLiquidityParams);
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
    int24 _tickUpper
  ) private returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) {
    require(_tickLower < _tickUpper, "Tick lower must be less than tick upper");
    uint256 amount0Desired = IERC20(token0).balanceOf(address(this));
    uint256 amount1Desired = IERC20(token1).balanceOf(address(this));
    _safeApprove(token0, address(positionManager), amount0Desired);
    _safeApprove(token1, address(positionManager), amount1Desired);

    // Create the position
    INonFungiblePositionManager.MintParams memory params = INonFungiblePositionManager.MintParams(
      token0,
      token1,
      fee,
      _tickLower,
      _tickUpper,
      amount0Desired,
      amount1Desired,
      0,
      0,
      address(this),
      block.timestamp + ACTION_DEADLINE
    );

    (tokenId, liquidity, amount0, amount1) = positionManager.mint(params);
    positionId = tokenId;
  }
  // @dev Safely approve another contract to spend tokens
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