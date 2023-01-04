//   _____    _           _       ____       _     _
//  |  ___|__| |_ ___ ___| |__   | __ ) _ __(_) __| | __ _  ___
//  | |_ / _ \ __/ __/ __| '_ \  |  _ \| '__| |/ _` |/ _` |/ _ \
//  |  _|  __/ || (_| (__| | | | | |_) | |  | | (_| | (_| |  __/
//  |_|  \___|\__\___\___|_| |_| |____/|_|  |_|\__,_|\__, |\___|
//                                                   |___/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./LiquidityPool/IFetcchPool.sol";
import "./Dex/OneInchProvider.sol";
import "./Structs.sol";

/// @title FetcchBridge
/// @notice Allows users to perform any-token to any-token cross-chain swaps
contract FetcchBridge is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice OneInch implementation address
    OneInchProvider public dex;

    /// @notice Address for native token
    address private constant NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /// @notice Mapping to get pool address from token address
    mapping(address => address) public pools;

    /// @notice Mapping to keep track of nonce for source and destination chains
    mapping(uint16 => mapping(uint16 => uint256)) internal nonce;

    /// @notice Event which emits SwapData
    event Swap(SwapData);

    /// @dev Initializes the contract by setting OneInch implementation address
    constructor(address _dex) {
        dex = OneInchProvider(_dex);
    }

    /// @notice Explain to an end user what this does
    /// @dev onlyOwner can access this function
    /// @param _dex New OneInch implementation address
    function changeDex(address _dex) external onlyOwner {
        dex = OneInchProvider(_dex);
    }

    function getNonce(uint16 _fromChainID, uint16 _toChainID)
        external
        view
        returns (uint256)
    {
        return nonce[_fromChainID][_toChainID];
    }

    /// @notice This function is responsible for mapping token to its corresponding pool
    /// @dev onlyOwner can access this function
    /// @param _token address of pool asset
    /// @param _pool address of corresponding pool
    function setPools(address _token, address _pool) external onlyOwner {
        pools[_token] = _pool;
    }

    /// @notice This function is responsible for initiating cross-chain swap
    /// @param swapData It includes all fromChain and toChain data which is required for swapping
    function swap(SwapData memory swapData) external payable nonReentrant {
        IFetcchPool pool = IFetcchPool(pools[swapData.fromChain._toToken]);
        if (swapData.fromChain._fromToken != swapData.fromChain._toToken) {
            if (swapData.fromChain._fromToken == NATIVE_TOKEN_ADDRESS) {
                uint256 _amountOut = dex.swapNative{
                    value: swapData.fromChain._amount
                }(
                    swapData.fromChain._dex._executor,
                    swapData.fromChain._dex._desc,
                    swapData.fromChain._dex._data
                );
                IERC20(swapData.fromChain._toToken).safeIncreaseAllowance(
                    address(pool),
                    _amountOut
                );
                pool.swap{value: msg.value}(
                    swapData.fromChain._toToken,
                    _amountOut,
                    swapData.fromChain._commLayerID,
                    swapData.toChain,
                    swapData.fromChain._extraParams
                );
            } else {
                IERC20(swapData.fromChain._fromToken).safeTransferFrom(
                    msg.sender,
                    address(this),
                    swapData.fromChain._amount
                );
                IERC20(swapData.fromChain._fromToken).safeIncreaseAllowance(
                    address(dex),
                    swapData.fromChain._amount
                );
                uint256 _amountOut = dex.swapERC20(
                    swapData.fromChain._dex._executor,
                    swapData.fromChain._dex._desc,
                    swapData.fromChain._dex._data
                );
                IERC20(swapData.fromChain._toToken).safeIncreaseAllowance(
                    address(pool),
                    _amountOut
                );
                pool.swap{value: msg.value}(
                    swapData.fromChain._toToken,
                    _amountOut,
                    swapData.fromChain._commLayerID,
                    swapData.toChain,
                    swapData.fromChain._extraParams
                );
            }
        } else {
            IERC20(swapData.fromChain._fromToken).safeTransferFrom(
                msg.sender,
                address(this),
                swapData.fromChain._amount
            );
            IERC20(swapData.fromChain._fromToken).safeIncreaseAllowance(
                address(pool),
                swapData.fromChain._amount
            );
            pool.swap{value: msg.value}(
                swapData.fromChain._fromToken,
                swapData.fromChain._amount,
                swapData.fromChain._commLayerID,
                swapData.toChain,
                swapData.fromChain._extraParams
            );
        }
        emit Swap(swapData);
    }

    /// @notice function responsible to rescue tokens if any
    /// @dev onlyOwner can access this function
    /// @param  tokenAddr address of locked token
    function rescueFunds(address tokenAddr) external onlyOwner {
        if (tokenAddr == NATIVE_TOKEN_ADDRESS) {
            uint256 balance = address(this).balance;
            payable(msg.sender).transfer(balance);
        } else {
            uint256 balance = IERC20(tokenAddr).balanceOf(address(this));
            IERC20(tokenAddr).safeTransfer(msg.sender, balance);
        }
    }
}