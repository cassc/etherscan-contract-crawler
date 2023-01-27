// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {NATIVE_TOKEN} from "../constants/Tokens.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

function _getBalance(address token, address user) view returns (uint256) {
    if (token == address(0)) return 0;
    return token == NATIVE_TOKEN ? user.balance : IERC20(token).balanceOf(user);
}

function _simulateAndRevert(
    address _service,
    uint256 _gasleft,
    bytes memory _data
) {
    assembly {
        let success := call(
            gas(),
            _service,
            0,
            add(_data, 0x20),
            mload(_data),
            0,
            0
        )

        mstore(0x00, success) // store success bool in first word
        mstore(0x20, sub(_gasleft, gas())) // store gas after success
        mstore(0x40, returndatasize()) // store length of return data size in third word
        returndatacopy(0x60, 0, returndatasize()) // store actual return data in fourth word and onwards
        revert(0, add(returndatasize(), 0x60))
    }
}

function _revertWithFee(
    bool _success,
    uint256 _estimatedGasUsed,
    uint256 _observedFee
) pure {
    assembly {
        mstore(0x00, _success)
        mstore(0x20, _estimatedGasUsed)
        mstore(0x40, _observedFee)
        mstore(0x60, returndatasize())
        returndatacopy(0x80, 0, returndatasize())

        revert(0, add(returndatasize(), 0x80))
    }
}