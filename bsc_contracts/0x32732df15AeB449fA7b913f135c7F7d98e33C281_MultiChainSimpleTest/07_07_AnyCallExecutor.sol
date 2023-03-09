// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import "./IApp.sol";

contract AnyCallExecutor {
    struct Context {
        address from;
        uint256 fromChainID;
        uint256 nonce;
    }

    Context public context;
    address public creator;

    constructor() {
        creator = msg.sender;
    }

    function execute(
        address _to,
        bytes calldata _data,
        address _from,
        uint256 _fromChainID,
        uint256 _nonce
    ) external returns (bool success, bytes memory result) {
        if (msg.sender != creator) {
            return (false, "AnyCallExecutor: caller is not the creator");
        }
        context = Context({from: _from, fromChainID: _fromChainID, nonce: _nonce});
        (success, result) = IApp(_to).anyExecute(_data);
        context = Context({from: address(0), fromChainID: 0, nonce: 0});
    }
}