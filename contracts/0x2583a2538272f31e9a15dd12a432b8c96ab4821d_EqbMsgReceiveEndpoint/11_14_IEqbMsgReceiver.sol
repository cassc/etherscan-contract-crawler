// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IEqbMsgReceiver {
    function executeMessage(
        uint256 _srcChainId,
        address _srcAddr,
        bytes calldata _message
    ) external;
}