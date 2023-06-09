// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

import "./IToken.sol";

interface IBaseTokenLogic {

    function handleTransfer(
        address from,
        address to,
        uint256 amount
    ) external returns (IToken.TransferResult memory);

    function predictTransfer(
        address from,
        address to,
        uint256 amount
    ) external view returns (IToken.TransferResult memory);
}