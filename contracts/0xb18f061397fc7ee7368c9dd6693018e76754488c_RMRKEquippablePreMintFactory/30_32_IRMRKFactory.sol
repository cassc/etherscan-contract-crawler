// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@rmrk-team/evm-contracts/contracts/implementations/IRMRKInitData.sol";

interface IRMRKFactory is IRMRKInitData {
    function deployRMRKCollection(
        string memory name,
        string memory symbol,
        string memory collectionMetadata,
        string memory tokenURI,
        InitData memory data
    ) external;
}