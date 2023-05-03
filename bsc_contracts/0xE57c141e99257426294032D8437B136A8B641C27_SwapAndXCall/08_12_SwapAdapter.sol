//SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

import {ISwapper} from "./interfaces/ISwapper.sol";

/**
 * @title SwapAdapter
 * @author Connext
 * @notice This contract is used to provide a generic interface to swap tokens through
 * a variety of different swap routers. It is used to swap tokens
 * before proceeding with other actions. Swap router implementations can be added by owner.
 * This is designed to be owned by the Connext DAO and swappers can be added by the DAO.
 */
contract SwapAdapter is Ownable2Step {
  using Address for address;
  using Address for address payable;

  mapping(address => bool) public allowedSwappers;

  address public immutable uniswapSwapRouter = address(0xE592427A0AEce92De3Edee1F18E0157C05861564);

  constructor() {
    allowedSwappers[address(this)] = true;
    allowedSwappers[uniswapSwapRouter] = true;
  }

  /// Payable
  // @dev On the origin side, we can accept native assets for a swap.
  receive() external payable virtual {}

  /// ADMIN
  /**
   * @notice Add a swapper to the list of allowed swappers.
   * @param _swapper Address of the swapper to add.
   */
  function addSwapper(address _swapper) external onlyOwner {
    allowedSwappers[_swapper] = true;
  }

  /**
   * @notice Remove a swapper from the list of allowed swappers.
   * @param _swapper Address of the swapper to remove.
   */
  function removeSwapper(address _swapper) external onlyOwner {
    allowedSwappers[_swapper] = false;
  }

  /// EXTERNAL
  /**
   * @notice Swap an exact amount of tokens for another token.
   * @param _swapper Address of the swapper to use.
   * @param _amountIn Amount of tokens to swap.
   * @param _fromAsset Address of the token to swap from.
   * @param _toAsset Address of the token to swap to.
   * @param _swapData Data to pass to the swapper. This data is encoded for a particular swap router, usually given
   * by an API. The swapper will decode the data and re-encode it with the new amountIn.
   */
  function exactSwap(
    address _swapper,
    uint256 _amountIn,
    address _fromAsset,
    address _toAsset,
    bytes calldata _swapData // comes directly from API with swap data encoded
  ) public payable returns (uint256 amountOut) {
    require(allowedSwappers[_swapper], "!allowedSwapper");

    // If from == to, no need to swap
    if (_fromAsset == _toAsset) {
      return _amountIn;
    }

    if (IERC20(_fromAsset).allowance(address(this), _swapper) < _amountIn) {
      TransferHelper.safeApprove(_fromAsset, _swapper, type(uint256).max);
    }
    amountOut = ISwapper(_swapper).swap(_amountIn, _fromAsset, _toAsset, _swapData);
  }

  /**
   * @notice Swap an exact amount of tokens for another token. Uses a direct call to the swapper to allow
   * easy swaps on the source side where the amount does not need to be changed.
   * @param _swapper Address of the swapper to use.
   * @param swapData Data to pass to the swapper. This data is encoded for a particular swap router.
   */
  function directSwapperCall(address _swapper, bytes calldata swapData) public payable returns (uint256 amountOut) {
    bytes memory ret = _swapper.functionCallWithValue(swapData, msg.value, "!directSwapperCallFailed");
    amountOut = abi.decode(ret, (uint256));
  }
}