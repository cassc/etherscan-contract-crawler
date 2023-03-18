// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {IPool} from "../interfaces/external/synth/IPool.sol";
import {ISyntheticToken} from "../interfaces/external/synth/ISyntheticToken.sol";

contract SynthAdapter {
    function swap(address pool_, address tokenIn_, address tokenOut_) external payable {
        ISyntheticToken _tokenIn = ISyntheticToken(tokenIn_);
        IPool(pool_).swap(_tokenIn, ISyntheticToken(tokenOut_), _tokenIn.balanceOf(address(this)));
    }
}