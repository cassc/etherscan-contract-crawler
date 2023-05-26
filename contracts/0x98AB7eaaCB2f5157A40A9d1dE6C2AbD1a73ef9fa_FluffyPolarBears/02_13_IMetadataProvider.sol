// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
$$$$$$$$\ $$$$$$$\  $$$$$$$\
$$  _____|$$  __$$\ $$  __$$\
$$ |      $$ |  $$ |$$ |  $$ |
$$$$$\    $$$$$$$  |$$$$$$$\ |
$$  __|   $$  ____/ $$  __$$\
$$ |      $$ |      $$ |  $$ |
$$ |      $$ |      $$$$$$$  |
\__|      \__|      \_______/
*/

interface IMetadataProvider {
    function getMetadata(uint256 tokenId) external view returns (string memory);
}