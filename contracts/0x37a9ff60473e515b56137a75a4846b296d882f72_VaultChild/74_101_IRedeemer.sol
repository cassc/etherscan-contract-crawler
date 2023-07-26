// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IRedeemerEvents } from './IRedeemerEvents.sol';

interface IRedeemer is IRedeemerEvents {
    // For some assets, closing a portion directly to the user is not possible
    // Or some assets only allow the claiming all rewards to the owner (you can't claim a portion of the rewards)
    // In this case these operations have to happen first, returning those assets to the vault
    // And then being distributed to the withdrawer during normal erc20 withdraw processing
    // A good example of this is with GMX, where sometimes we will have to close the entire position to the vault
    // And then distribute a portion of the proceeds downstream to the withdrawer.
    // The function of having preWithdraw saves us the drama of having to try and ORDER asset withdraws.
    function preWithdraw(
        uint tokenId,
        address asset,
        address withdrawer,
        uint portion
    ) external payable;

    function withdraw(
        uint tokenId,
        address asset,
        address withdrawer,
        uint portion
    ) external payable;

    function hasPreWithdraw() external view returns (bool);
}