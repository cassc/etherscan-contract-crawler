/**
 *Submitted for verification at Etherscan.io on 2023-06-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Celer Network Bridge
interface IBridge {
    function sendNative(
        address _receiver,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage
    ) external payable;

    function transfers(
        bytes32 transferId
    ) external view returns (bool);
}

contract ETHBridge {
    IBridge public immutable bridge;

    address public immutable nativeWrap;
    address public immutable receiver;

    uint64 public immutable dstChainId;

    event NativeSent(
        bytes32 transferId,
        uint256 amount,
        uint256 amountToken,
        address controller,
        bytes4 selector,
        bytes args
    );

    constructor(
        IBridge _bridge,
        address _nativeWrap,
        address _receiver,
        uint64 _dstChainId
    )
    {
        bridge = _bridge;
        nativeWrap = _nativeWrap;
        receiver = _receiver;
        dstChainId = _dstChainId;
    }

    function sendNative(
        uint32 maxSlippage,
        uint64 nonce,

        uint256 amountToken,
        address controller,
        bytes4 selector,
        bytes calldata args
    )
        external
        payable
    {
        require(amountToken > 0, "insufficient amountToken");

        uint256 amount = msg.value;

        bridge.sendNative{ value: amount }(
            receiver,
            amount,
            dstChainId,
            nonce,
            maxSlippage
        );

        bytes32 transferId = keccak256(
            abi.encodePacked(address(this), receiver, nativeWrap, amount, dstChainId, nonce, uint64(block.chainid))
        );

        emit NativeSent(transferId, amount, amountToken, controller, selector, args);
    }

    function transfers(
        bytes32 transferId
    )
        external
        view
        returns (bool)
    {
        return bridge.transfers(transferId);
    }
}