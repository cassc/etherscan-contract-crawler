// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

interface IHive {

    function depositHoneyToTokenIdsOfCollections(
        address[] calldata _collections,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) external;

    function spendHoneyFromTokenIdsOfCollections(
        address[] calldata _collections,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) external;
    
}