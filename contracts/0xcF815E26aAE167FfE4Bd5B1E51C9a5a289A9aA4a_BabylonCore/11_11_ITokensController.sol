// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;
import "./IBabylonCore.sol";

interface ITokensController {
    function createMintPass(
        uint256 listingId
    ) external returns (address);

    function checkApproval(
        address creator,
        IBabylonCore.ListingItem calldata item
    ) external view returns (bool);

    function sendItem(IBabylonCore.ListingItem calldata item, address from, address to) external;
}