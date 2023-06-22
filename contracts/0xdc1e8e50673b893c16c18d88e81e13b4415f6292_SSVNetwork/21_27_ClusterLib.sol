// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import "../interfaces/ISSVNetworkCore.sol";
import "./SSVStorage.sol";
import "./SSVStorageProtocol.sol";
import "./Types.sol";

library ClusterLib {
    using Types64 for uint64;

    function updateBalance(
        ISSVNetworkCore.Cluster memory cluster,
        uint64 newIndex,
        uint64 currentNetworkFeeIndex
    ) internal pure {
        uint64 networkFee = uint64(currentNetworkFeeIndex - cluster.networkFeeIndex) * cluster.validatorCount;
        uint64 usage = (newIndex - cluster.index) * cluster.validatorCount + networkFee;
        cluster.balance = usage.expand() > cluster.balance ? 0 : cluster.balance - usage.expand();
    }

    function isLiquidatable(
        ISSVNetworkCore.Cluster memory cluster,
        uint64 burnRate,
        uint64 networkFee,
        uint64 minimumBlocksBeforeLiquidation,
        uint64 minimumLiquidationCollateral
    ) internal pure returns (bool) {
        if (cluster.balance < minimumLiquidationCollateral.expand()) return true;
        uint64 liquidationThreshold = minimumBlocksBeforeLiquidation * (burnRate + networkFee) * cluster.validatorCount;

        return cluster.balance < liquidationThreshold.expand();
    }

    function validateClusterIsNotLiquidated(ISSVNetworkCore.Cluster memory cluster) internal pure {
        if (!cluster.active) revert ISSVNetworkCore.ClusterIsLiquidated();
    }

    function validateHashedCluster(
        ISSVNetworkCore.Cluster memory cluster,
        address owner,
        uint64[] memory operatorIds,
        StorageData storage s
    ) internal view returns (bytes32) {
        bytes32 hashedCluster = keccak256(abi.encodePacked(owner, operatorIds));
        bytes32 hashedClusterData = hashClusterData(cluster);

        bytes32 clusterData = s.clusters[hashedCluster];
        if (clusterData == bytes32(0)) {
            revert ISSVNetworkCore.ClusterDoesNotExists();
        } else if (clusterData != hashedClusterData) {
            revert ISSVNetworkCore.IncorrectClusterState();
        }

        return hashedCluster;
    }

    function updateClusterData(
        ISSVNetworkCore.Cluster memory cluster,
        uint64 clusterIndex,
        uint64 currentNetworkFeeIndex
    ) internal pure {
        updateBalance(cluster, clusterIndex, currentNetworkFeeIndex);
        cluster.index = clusterIndex;
        cluster.networkFeeIndex = currentNetworkFeeIndex;
    }

    function hashClusterData(ISSVNetworkCore.Cluster memory cluster) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    cluster.validatorCount,
                    cluster.networkFeeIndex,
                    cluster.index,
                    cluster.balance,
                    cluster.active
                )
            );
    }
}