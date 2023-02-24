// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;

import "../type/ITokenTypes.sol";

interface ITokenWithdraw is ITokenTypes {
    event WithdrawToken(address indexed sender, TokenStandart standart, TransferredToken token, uint256 timestamp);

    function withdrawToken(TokenStandart standart, TransferredToken memory token) external;
}