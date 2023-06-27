// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

/**
 * @title IBridgeStargate Interface Contract.
 * @notice Interface used by Stargate-L1 and L2 Router implementations
 * @dev router and routerETH addresses will be distinct for L1 and L2
 */
interface IBridgeStargate {
    // @notice Struct to hold the additional-data for bridging ERC20 token
    struct lzTxObj {
        // gas limit to bridge the token in Stargate to destinationChain
        uint256 dstGasForCall;
        // destination nativeAmount, this is always set as 0
        uint256 dstNativeAmount;
        // destination nativeAddress, this is always set as 0x
        bytes dstNativeAddr;
    }

    /// @notice function in stargate bridge which is used to bridge ERC20 tokens to recipient on destinationChain
    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    /// @notice function in stargate bridge which is used to bridge native tokens to recipient on destinationChain
    function swapETH(
        uint16 _dstChainId, // destination Stargate chainId
        address payable _refundAddress, // refund additional messageFee to this address
        bytes calldata _toAddress, // the receiver of the destination ETH
        uint256 _amountLD, // the amount, in Local Decimals, to be swapped
        uint256 _minAmountLD // the minimum amount accepted out on destination
    ) external payable;
}