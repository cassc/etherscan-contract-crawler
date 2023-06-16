// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IStargateRouter } from '@layerzerolabs/solidity-examples/contracts/interfaces/IStargateRouter.sol';
import { IStargateReceiver } from '@layerzerolabs/solidity-examples/contracts/interfaces/IStargateReceiver.sol';

import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';
import { SafeERC20 } from '@solidstate/contracts/utils/SafeERC20.sol';

import { Transport } from '../transport/Transport.sol';

contract MockStargateRouter {
    using SafeERC20 for IERC20;

    struct QueuedSwap {
        uint16 srcChainId;
        bytes srcAddress;
        uint nonce;
        address token;
        uint amount;
        address to;
        bytes payload;
        IStargateRouter.lzTxObj lzTxParams;
    }

    uint nonce;

    uint fee = 5;

    mapping(uint => address) poolIdToAssetAddress;

    QueuedSwap[] queuedSwaps;

    function setPoolIdToAddress(uint poolId, address asset) external {
        poolIdToAssetAddress[poolId] = asset;
    }

    function swap(
        uint16, //_dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable, // _refundAddress,
        uint256 _amountLD,
        uint256, //_minAmountLD,
        IStargateRouter.lzTxObj memory _lzTxParams,
        bytes memory _to,
        bytes memory _payload
    ) external payable {
        require(msg.value == fee, 'no fee');
        address asset = poolIdToAssetAddress[_srcPoolId];
        require(asset != address(0), 'no asset');
        require(_srcPoolId == _dstPoolId, 'poolIds must match');
        address toAddress;
        assembly {
            toAddress := mload(add(_to, 20))
        }
        IERC20(asset).safeTransferFrom(msg.sender, address(this), _amountLD);
        queuedSwaps.push(
            QueuedSwap({
                srcChainId: Transport(payable(msg.sender)).registry().chainId(),
                srcAddress: abi.encodePacked(msg.sender),
                token: asset,
                nonce: nonce,
                amount: _amountLD,
                to: toAddress,
                payload: _payload,
                lzTxParams: _lzTxParams
            })
        );
        nonce++;
    }

    // uint16 srcChainId,
    // bytes memory /*_srcAddress*/,
    // uint /*_nonce*/,
    // address _token,
    // uint amountLD,
    // bytes memory _payload

    function executeSwaps() external {
        while (queuedSwaps.length > 0) {
            QueuedSwap memory payload = queuedSwaps[queuedSwaps.length - 1];
            IERC20(payload.token).safeTransfer(payload.to, payload.amount);
            IStargateReceiver(payload.to).sgReceive(
                payload.srcChainId,
                payload.srcAddress,
                payload.nonce,
                payload.token,
                payload.amount,
                payload.payload
            );
            queuedSwaps.pop();
        }
    }

    function quoteLayerZeroFee(
        uint16, //_dstChainId,
        uint8, //_functionType,
        bytes calldata, // _toAddress,
        bytes calldata, // _transferAndCallPayload,
        IStargateRouter.lzTxObj memory // _lzTxParams
    ) external view returns (uint256, uint256) {
        return (fee, 0);
    }
}