// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { IHashes } from "./IHashes.sol";

interface ICollectionCloneable {
    function initialize(
        IHashes _hashesToken,
        address _factoryMaintainerAddress,
        address _createCollectionCaller,
        bytes memory _initializationData
    ) external;
}