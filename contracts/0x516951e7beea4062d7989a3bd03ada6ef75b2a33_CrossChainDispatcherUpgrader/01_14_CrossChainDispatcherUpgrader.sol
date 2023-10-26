// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./UpgraderBase.sol";

contract CrossChainDispatcherUpgrader is UpgraderBase {
    constructor(address _owner) {
        transferOwnership(_owner);
    }

    /// @inheritdoc UpgraderBase
    function _calls() internal pure override returns (bytes[] memory _callsList) {
        _callsList = new bytes[](9);
        _callsList[0] = abi.encodeWithSignature("poolRegistry()");
        _callsList[1] = abi.encodeWithSignature("lzBaseGasLimit()");
        _callsList[2] = abi.encodeWithSignature("stargateSlippage()");
        _callsList[3] = abi.encodeWithSignature("flashRepayCallbackTxGasLimit()");
        _callsList[4] = abi.encodeWithSignature("flashRepaySwapTxGasLimit()");
        _callsList[5] = abi.encodeWithSignature("leverageCallbackTxGasLimit()");
        _callsList[6] = abi.encodeWithSignature("leverageSwapTxGasLimit()");
        _callsList[7] = abi.encodeWithSignature("isBridgingActive()");
        _callsList[8] = abi.encodeWithSignature("stargateRouter()");
    }
}