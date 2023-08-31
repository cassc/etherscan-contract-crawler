// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

interface IWithdrawInbox {
    function withdraw(
        uint64 _wdSeq,
        address _receiver,
        uint64 _toChain,
        uint64[] calldata _fromChains,
        address[] calldata _tokens,
        uint32[] calldata _ratios,
        uint32[] calldata _slippages
    ) external;
}