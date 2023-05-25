// SPDX-License-Identifier: AGPL-3.0

pragma solidity >=0.6.0 <=0.8.9;


interface ITokenTransferProxy {

    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    )
        external;

    function freeReduxTokens(address user, uint256 tokensToFree) external;
}