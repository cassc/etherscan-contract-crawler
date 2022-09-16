//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBrawlerBearzCommon} from "./IBrawlerBearzCommon.sol";
import {IBrawlerBearzEvents} from "./IBrawlerBearzEvents.sol";
import {IBrawlerBearzErrors} from "./IBrawlerBearzErrors.sol";

interface IBrawlerBearz is
    IBrawlerBearzCommon,
    IBrawlerBearzEvents,
    IBrawlerBearzErrors
{
    function getMetadata(uint256 tokenId)
        external
        view
        returns (CustomMetadata memory);

    function setName(uint256 tokenId, string calldata newName) external;

    function setLore(uint256 tokenId, string calldata newLore) external;

    function equip(
        uint256 tokenId,
        string calldata typeOf,
        uint256 itemTokenId
    ) external;

    function unequip(uint256 tokenId, string calldata typeOf) external;

    function whitelistMint(uint256 amount, bytes32[] calldata proof)
        external
        payable;

    function mint(uint256 amount) external payable;

    function freeId(uint256 tokenId, address contractAddress) external;

    function lockId(uint256 tokenId) external;

    function unlockId(uint256 tokenId) external;

    function addXP(uint256 tokenId, uint256 amount) external;

    function subtractXP(uint256 tokenId, uint256 amount) external;
}