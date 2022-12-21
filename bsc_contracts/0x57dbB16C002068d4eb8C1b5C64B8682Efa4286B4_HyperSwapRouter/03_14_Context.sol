//SPDX-License-Identifier: BUSL
pragma solidity 0.8.10;

abstract contract Context {
    function _msgSenderContext() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgDataContext() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}