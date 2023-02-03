// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

interface IStargateEthRouter {
    function swapETH(
        uint16 _dstChainId,                         // destination Stargate chainId
        address payable _refundAddress,             // refund additional messageFee to this address
        bytes calldata _toAddress,                  // the receiver of the destination ETH
        uint256 _amountLD,                          // the amount, in Local Decimals, to be swapped
        uint256 _minAmountLD                        // the minimum amount accepted out on destination
    ) external payable;
}