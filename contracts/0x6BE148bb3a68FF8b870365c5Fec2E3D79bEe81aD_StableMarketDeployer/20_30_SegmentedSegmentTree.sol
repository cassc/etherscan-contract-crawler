// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "./PackedUint256.sol";
import "./DirtyUint64.sol";

/**
🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲

                  Segmented Segment Tree
                               by Clober

____________/\\\_______________/\\\\\____________/\\\____
 __________/\\\\\___________/\\\\////___________/\\\\\____
  ________/\\\/\\\________/\\\///______________/\\\/\\\____
   ______/\\\/\/\\\______/\\\\\\\\\\\_________/\\\/\/\\\____
    ____/\\\/__\/\\\_____/\\\\///////\\\_____/\\\/__\/\\\____
     __/\\\\\\\\\\\\\\\\_\/\\\______\//\\\__/\\\\\\\\\\\\\\\\_
      _\///////////\\\//__\//\\\______/\\\__\///////////\\\//__
       ___________\/\\\_____\///\\\\\\\\\/_____________\/\\\____
        ___________\///________\/////////_______________\///_____

          4 Layers of 64-bit nodes, hence 464

🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲
*/

library SegmentedSegmentTree {
    using PackedUint256 for uint256;
    using DirtyUint64 for uint64;

    error SegmentedSegmentTreeError(uint256 errorCode);
    uint256 private constant _INDEX_ERROR = 0;
    uint256 private constant _OVERFLOW_ERROR = 1;

    //    uint8 private constant _R = 2; // There are `2` root node groups
    //    uint8 private constant _C = 4; // There are `4` children (each child is a node group of its own) for each node
    uint8 private constant _L = 4; // There are `4` layers of node groups
    uint256 private constant _P = 4; // uint256 / uint64 = `4`
    uint256 private constant _P_M = 3; // % 4 = & `3`
    uint256 private constant _P_P = 2; // 2 ** `2` = 4
    uint256 private constant _N_P = 4; // C * P = 2 ** `4`
    uint256 private constant _MAX_NODES = 2**15; // (R * P) * ((C * P) ** (L - 1)) = `32768`
    uint256 private constant _MAX_NODES_P_MINUS_ONE = 14; // MAX_NODES / R = 2 ** `14`

    struct Core {
        mapping(uint256 => uint256)[_L] layers;
    }

    struct LayerIndex {
        uint256 group;
        uint256 node;
    }

    function get(Core storage core, uint256 index) internal view returns (uint64 ret) {
        if (index >= _MAX_NODES) {
            revert SegmentedSegmentTreeError(_INDEX_ERROR);
        }
        unchecked {
            ret = core.layers[_L - 1][index >> _P_P].get64(index & _P_M).toClean();
        }
    }

    function total(Core storage core) internal view returns (uint64) {
        return
            DirtyUint64.sumPackedUnsafe(core.layers[0][0], 0, _P) +
            DirtyUint64.sumPackedUnsafe(core.layers[0][1], 0, _P);
    }

    function query(
        Core storage core,
        uint256 left,
        uint256 right
    ) internal view returns (uint64 sum) {
        if (left == right) {
            return 0;
        }
        // right should be greater than left
        if (left >= right) {
            revert SegmentedSegmentTreeError(_INDEX_ERROR);
        }
        if (right > _MAX_NODES) {
            revert SegmentedSegmentTreeError(_INDEX_ERROR);
        }

        LayerIndex[] memory leftIndices = _getLayerIndices(left);
        LayerIndex[] memory rightIndices = _getLayerIndices(right);
        uint256 ret;
        uint256 deficit;

        unchecked {
            uint256 leftNodeIndex;
            uint256 rightNodeIndex;
            for (uint256 l = _L - 1; ; --l) {
                LayerIndex memory leftIndex = leftIndices[l];
                LayerIndex memory rightIndex = rightIndices[l];
                leftNodeIndex += leftIndex.node;
                rightNodeIndex += rightIndex.node;

                if (rightIndex.group == leftIndex.group) {
                    ret += DirtyUint64.sumPackedUnsafe(core.layers[l][leftIndex.group], leftNodeIndex, rightNodeIndex);
                    break;
                }

                if (rightIndex.group - leftIndex.group < 4) {
                    ret += DirtyUint64.sumPackedUnsafe(core.layers[l][leftIndex.group], leftNodeIndex, _P);

                    ret += DirtyUint64.sumPackedUnsafe(core.layers[l][rightIndex.group], 0, rightNodeIndex);

                    for (uint256 group = leftIndex.group + 1; group < rightIndex.group; group++) {
                        ret += DirtyUint64.sumPackedUnsafe(core.layers[l][group], 0, _P);
                    }
                    break;
                }

                if (leftIndex.group % 4 == 0) {
                    deficit += DirtyUint64.sumPackedUnsafe(core.layers[l][leftIndex.group], 0, leftNodeIndex);
                    leftNodeIndex = 0;
                } else if (leftIndex.group % 4 == 1) {
                    deficit += DirtyUint64.sumPackedUnsafe(core.layers[l][leftIndex.group - 1], 0, _P);
                    deficit += DirtyUint64.sumPackedUnsafe(core.layers[l][leftIndex.group], 0, leftNodeIndex);
                    leftNodeIndex = 0;
                } else if (leftIndex.group % 4 == 2) {
                    ret += DirtyUint64.sumPackedUnsafe(core.layers[l][leftIndex.group], leftNodeIndex, _P);
                    ret += DirtyUint64.sumPackedUnsafe(core.layers[l][leftIndex.group + 1], 0, _P);
                    leftNodeIndex = 1;
                } else {
                    ret += DirtyUint64.sumPackedUnsafe(core.layers[l][leftIndex.group], leftNodeIndex, _P);
                    leftNodeIndex = 1;
                }

                if (rightIndex.group % 4 == 0) {
                    ret += DirtyUint64.sumPackedUnsafe(core.layers[l][rightIndex.group], 0, rightNodeIndex);
                    rightNodeIndex = 0;
                } else if (rightIndex.group % 4 == 1) {
                    ret += DirtyUint64.sumPackedUnsafe(core.layers[l][rightIndex.group - 1], 0, _P);
                    ret += DirtyUint64.sumPackedUnsafe(core.layers[l][rightIndex.group], 0, rightNodeIndex);
                    rightNodeIndex = 0;
                } else if (rightIndex.group % 4 == 2) {
                    deficit += DirtyUint64.sumPackedUnsafe(core.layers[l][rightIndex.group], rightNodeIndex, _P);
                    deficit += DirtyUint64.sumPackedUnsafe(core.layers[l][rightIndex.group + 1], 0, _P);
                    rightNodeIndex = 1;
                } else {
                    deficit += DirtyUint64.sumPackedUnsafe(core.layers[l][rightIndex.group], rightNodeIndex, _P);
                    rightNodeIndex = 1;
                }
            }
            ret -= deficit;
        }
        sum = uint64(ret);
    }

    function update(
        Core storage core,
        uint256 index,
        uint64 value
    ) internal returns (uint64 replaced) {
        if (index >= _MAX_NODES) {
            revert SegmentedSegmentTreeError(_INDEX_ERROR);
        }
        LayerIndex[] memory indices = _getLayerIndices(index);
        unchecked {
            LayerIndex memory bottomIndex = indices[_L - 1];
            replaced = core.layers[_L - 1][bottomIndex.group].get64Unsafe(bottomIndex.node).toClean();
            if (replaced >= value) {
                uint64 diff = replaced - value;
                for (uint256 l = 0; l < _L; ++l) {
                    LayerIndex memory layerIndex = indices[l];
                    uint256 node = core.layers[l][layerIndex.group];
                    core.layers[l][layerIndex.group] = node.update64(
                        layerIndex.node,
                        node.get64(layerIndex.node).subClean(diff)
                    );
                }
            } else {
                uint64 diff = value - replaced;
                if (total(core) > type(uint64).max - diff) revert SegmentedSegmentTreeError(_OVERFLOW_ERROR);
                for (uint256 l = 0; l < _L; ++l) {
                    LayerIndex memory layerIndex = indices[l];
                    uint256 node = core.layers[l][layerIndex.group];
                    core.layers[l][layerIndex.group] = node.update64(
                        layerIndex.node,
                        node.get64(layerIndex.node).addClean(diff)
                    );
                }
            }
        }
    }

    function _getLayerIndices(uint256 index) private pure returns (LayerIndex[] memory) {
        unchecked {
            LayerIndex[] memory indices = new LayerIndex[](_L);
            uint256 shifter = _MAX_NODES_P_MINUS_ONE;
            for (uint256 l = 0; l < _L; ++l) {
                indices[l] = LayerIndex({group: index >> shifter, node: (index >> (shifter - _P_P)) & _P_M});
                shifter = shifter - _N_P;
            }
            return indices;
        }
    }
}

/*
 * Segmented Segment Tree is a Segment Tree
 * that has been compressed so that `C` nodes
 * are compressed into a single uint256.
 *
 * Each node in a non-leaf node group is the sum of the
 * total sum of each child node group that it represents.
 * Each non-leaf node represents `E` node groups.
 *
 * A node group consists of `S` uint256.
 *
 * By expressing the index in `N` notation,
 * we can find the index in each respective layer
 *
 * S: Size of each node group
 * C: Compression Coefficient
 * E: Expansion Coefficient
 * L: Number of Layers
 * N: Notation, S * C * E
 *
 * `E` will not be considered for this version of the implementation. (E = 2)
 */