// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

import "./IStargateRouter.sol";

interface IStargateComposer {
    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        IStargateRouter.lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function factory() external view returns (address);

    function stargateBridge() external view returns (address);

    function stargateRouter() external view returns (IStargateRouter);

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        IStargateRouter.lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);

    function peers(uint16 _chainId) external view returns (address);
}