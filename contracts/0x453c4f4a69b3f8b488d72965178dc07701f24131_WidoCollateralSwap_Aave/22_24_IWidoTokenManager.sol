// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.7;
import "./IWidoRouter.sol";

interface IWidoTokenManager {
    function pullTokens(address user, IWidoRouter.OrderInput[] calldata inputs) external;
}