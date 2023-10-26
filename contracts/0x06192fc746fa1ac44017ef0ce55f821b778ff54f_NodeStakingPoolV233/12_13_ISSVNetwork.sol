// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "./ISSVNetworkCore.sol";

interface ISSVNetwork is ISSVNetworkCore {
    function registerValidator(
        bytes calldata publicKey,
        uint64[] memory operatorIds,
        bytes calldata sharesData,
        uint256 amount,
        ISSVNetworkCore.Cluster memory cluster
    ) external;

    function removeValidator(
        bytes calldata publicKey,
        uint64[] calldata operatorIds,
        ISSVNetworkCore.Cluster memory cluster
    ) external;

    function reactivate(
        uint64[] memory operatorIds,
        uint256 amount,
        Cluster memory cluster
    ) external;
}