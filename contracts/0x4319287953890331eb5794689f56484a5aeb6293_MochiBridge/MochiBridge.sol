/**
 *Submitted for verification at Etherscan.io on 2023-10-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

uint16 constant SG_ETH_POOL = 13;

interface IERC20 {
    function approve(address, uint256) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

interface IStargateFactory {
    function getPool(uint256) external view returns (IStargatePool);
}

interface IStargatePool {
    function token() external view returns (address);
    function feeLibrary() external view returns (IStargateFeeLibrary);
}

interface IStargateRouter {
    function factory() external view returns (IStargateFactory);

    struct lzTxObj {
        uint256 dstGasFor;
        uint256 dstNativeAm;
        bytes dstNative;
    }

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

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);

    function clearCachedSwap(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        address _receiver,
        bytes calldata _sgReceiveCallData
    ) external;
}

interface IStargateFeeLibrary {
    struct SwapObj {
        uint256 amount;
        uint256 eqFee;
        uint256 eqReward;
        uint256 lpFee;
        uint256 protocolFee;
        uint256 lkbRemove;
    }

    function getFees(uint256 _srcPoolId, uint256 _dstPoolId, uint16 _dstChainId, address _from, uint256 _amountSD)
        external
        view
        returns (SwapObj memory s);
}

contract MochiBridge {
    uint16 immutable dstChainId;
    address immutable bridge;

    IStargateRouter immutable sgRouter;

    uint256 internal constant CROSS_CHAIN_SWAP_GAS = 250_000;

    uint8 constant SG_TYPE_SWAP_REMOTE = 1;

    constructor(IStargateRouter _sgRouter, uint16 _dstChainId, address _bridge) {
        sgRouter = _sgRouter;
        dstChainId = _dstChainId;
        bridge = _bridge;
    }

    function buy(
        address to,
        uint256 amountIn,
        uint256 amountOutMinSg,
        uint256 amountOutMin,
        uint256 deadline,
        uint256 nativeGasAirdrop
    ) external payable {
        require(deadline > block.timestamp, "deadline");

        IStargateRouter.lzTxObj memory lzTxParams = IStargateRouter.lzTxObj({
            dstGasFor: CROSS_CHAIN_SWAP_GAS,
            dstNativeAm: nativeGasAirdrop,
            dstNative: nativeGasAirdrop > 0 ? abi.encodePacked(to) : new bytes(0)
        });

        bytes memory dstAddress = abi.encodePacked(bridge);
        bytes memory payload = abi.encode(to, amountOutMin, deadline);

        sgRouter.swap{value: msg.value}(
            dstChainId,
            SG_ETH_POOL,
            SG_ETH_POOL,
            payable(msg.sender),
            amountIn,
            amountOutMinSg,
            lzTxParams,
            dstAddress,
            payload
        );
    }

    function getStargateFees(uint256 amount) external view returns (IStargateFeeLibrary.SwapObj memory) {
        return sgRouter.factory().getPool(SG_ETH_POOL).feeLibrary().getFees(
            SG_ETH_POOL, SG_ETH_POOL, dstChainId, address(this), amount
        );
    }

    function getLayerZeroFees(uint256 nativeGasAirdrop) external view returns (uint256 fees) {
        bytes memory to = abi.encodePacked(bridge);
        IStargateRouter.lzTxObj memory lzTxParams = IStargateRouter.lzTxObj({
            dstGasFor: CROSS_CHAIN_SWAP_GAS,
            dstNativeAm: nativeGasAirdrop,
            dstNative: nativeGasAirdrop > 0 ? to : new bytes(0)
        });
        (fees,) = sgRouter.quoteLayerZeroFee(dstChainId, SG_TYPE_SWAP_REMOTE, to, new bytes(96), lzTxParams);
    }
}