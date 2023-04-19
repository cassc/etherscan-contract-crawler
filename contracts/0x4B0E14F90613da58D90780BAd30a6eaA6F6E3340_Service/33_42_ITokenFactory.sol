// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IToken.sol";

interface ITokenFactory {
    function createToken(
        address pool,
        IToken.TokenInfo memory info,
        address primaryTGE
    ) external returns (IToken token);
}