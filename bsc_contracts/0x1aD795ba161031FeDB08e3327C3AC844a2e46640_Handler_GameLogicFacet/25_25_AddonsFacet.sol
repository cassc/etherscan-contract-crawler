// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

import {OwnersAware} from "./OwnersFacet.sol";
import {LibAppStorage} from "./AppStorage.sol";

struct Waterpack {
    /// @dev How much lifetime is added to the node, expressed relative to the
    /// node's GRP time.
    uint256 ratioOfGRP;
}

struct WaterpackFacetStorage {
    Waterpack[] items;
    string[] names;
    /// @dev Name to index + 1, 0 means the waterpack doesn't exists.
    mapping(string => uint256) indexOfPlusOne;
    mapping(string => mapping(string => uint256)) itemToNodeTypeToPrice;
}

library LibWaterpack {
    bytes32 constant STORAGE_POSITION =
        keccak256("diamond.handler.waterpack.storage");

    function facetStorage()
        internal
        pure
        returns (WaterpackFacetStorage storage fs)
    {
        bytes32 position = STORAGE_POSITION;
        assembly {
            fs.slot := position
        }
    }

    function hasWaterpackType(string memory name) internal view returns (bool) {
        WaterpackFacetStorage storage fs = facetStorage();
        return fs.indexOfPlusOne[name] != 0;
    }

    function getWaterpackType(string memory name)
        internal
        view
        returns (Waterpack storage)
    {
        WaterpackFacetStorage storage fs = facetStorage();
        uint256 idx = fs.indexOfPlusOne[name];
        require(idx != 0, "Waterpacks: nonexistant key");
        return fs.items[idx - 1];
    }

    function setWaterpackType(
        string memory name,
        uint256 ratioOfGRP,
        uint256[] memory prices
    ) internal {
        WaterpackFacetStorage storage fs = facetStorage();
        string[] memory nodeTypes = LibAppStorage.appStorage().mapNt.keys;
        require(
            nodeTypes.length == prices.length,
            "Waterpacks: length mismatch"
        );

        uint256 indexPlusOne = fs.indexOfPlusOne[name];
        if (indexPlusOne == 0) {
            fs.names.push(name);
            fs.items.push(Waterpack({ratioOfGRP: ratioOfGRP}));
            fs.indexOfPlusOne[name] = fs.names.length;
        } else {
            Waterpack storage waterpack = fs.items[indexPlusOne - 1];
            waterpack.ratioOfGRP = ratioOfGRP;
        }

        for (uint256 i = 0; i < nodeTypes.length; i++) {
            fs.itemToNodeTypeToPrice[name][nodeTypes[i]] = prices[i];
        }
    }

    function getWaterpackPriceByNameAndNodeType(
        string memory name,
        string memory nodeType
    ) internal view returns (uint256) {
        require(hasWaterpackType(name), "Waterpack type does not exist");
        WaterpackFacetStorage storage fs = facetStorage();
        return fs.itemToNodeTypeToPrice[name][nodeType];
    }
}

struct Fertilizer {
    /// @dev Duration of the effect of the fertilizer, expressed in seconds.
    uint256 durationEffect;
    /// @dev Percentage of additional boost provided during the effect of the
    /// fertilizer.
    uint256 rewardBoost;
    /// @dev Global limit on the number of fertilizers of that type that can be
    /// applied.
    uint256 globalLimit;
    /// @dev Not used anymore
    uint256 userLimit;
    /// @dev Limit on the number of fertilizers of that type that can be applied
    /// per node type, per user.
    uint256 userNodeTypeLimit;
    /// @dev Limit on the number of fertilizers of that type that can be applied
    /// on a single node.
    uint256 nodeLimit;
}

struct FertilizerFacetStorage {
    Fertilizer[] items;
    string[] names;
    /// @dev Name to index + 1, 0 means the fertilizer doesn't exists.
    mapping(string => uint256) indexOfPlusOne;
    mapping(string => mapping(string => uint256)) itemToNodeTypeToPrice;
    mapping(string => uint256) totalCreatedPerType;
    mapping(address => mapping(string => uint256)) totalCreatedPerUserPerType;
    mapping(uint256 => uint256) totalCreatedPerNodeTokenId;
}

library LibFertilizer {
    bytes32 constant STORAGE_POSITION =
        keccak256("diamond.handler.fertilizer.storage");

    function facetStorage()
        internal
        pure
        returns (FertilizerFacetStorage storage fs)
    {
        bytes32 position = STORAGE_POSITION;
        assembly {
            fs.slot := position
        }
    }

    function hasFertilizerType(string memory name)
        internal
        view
        returns (bool)
    {
        FertilizerFacetStorage storage fs = facetStorage();
        return fs.indexOfPlusOne[name] != 0;
    }

    function getFertilizerType(string memory name)
        internal
        view
        returns (Fertilizer storage)
    {
        FertilizerFacetStorage storage fs = facetStorage();
        uint256 idx = fs.indexOfPlusOne[name];
        require(idx != 0, "Fertilizers: nonexistant key");
        return fs.items[idx - 1];
    }

    function setFertilizerType(
        string memory name,
        uint256 durationEffect,
        uint256 rewardBoost,
        uint256[] memory limits,
        uint256[] memory prices
    ) internal {
        FertilizerFacetStorage storage fs = facetStorage();
        require(limits.length == 3, "Fertilizers: invalid arguments");
        string[] memory nodeTypes = LibAppStorage.appStorage().mapNt.keys;
        require(
            prices.length == nodeTypes.length,
            "Fertilizers: length mismatch"
        );
        uint256 indexPlusOne = fs.indexOfPlusOne[name];
        if (indexPlusOne == 0) {
            fs.names.push(name);
            fs.items.push(
                Fertilizer({
                    durationEffect: durationEffect,
                    rewardBoost: rewardBoost,
                    globalLimit: limits[0],
                    userLimit: 0, // Unused
                    userNodeTypeLimit: limits[1],
                    nodeLimit: limits[2]
                })
            );
            fs.indexOfPlusOne[name] = fs.names.length;
        } else {
            Fertilizer storage fertilizer = fs.items[indexPlusOne - 1];
            fertilizer.durationEffect = durationEffect;
            fertilizer.rewardBoost = rewardBoost;
            fertilizer.globalLimit = limits[0];
            fertilizer.userNodeTypeLimit = limits[1];
            fertilizer.nodeLimit = limits[2];
        }

        for (uint256 i = 0; i < nodeTypes.length; i++) {
            fs.itemToNodeTypeToPrice[name][nodeTypes[i]] = prices[i];
        }
    }

    function applyFertilizer(
        string memory name,
        uint256 nodeTokenId,
        uint256 amount,
        bool bypassLimits
    ) internal {
        FertilizerFacetStorage storage fs = facetStorage();

        Fertilizer memory fertilizerType = getFertilizerType(name);
        string memory nodeType = LibAppStorage.getTokenIdNodeTypeName(
            nodeTokenId
        );
        address user = LibAppStorage.nft().ownerOf(nodeTokenId);

        if (bypassLimits) return;
        
        fs.totalCreatedPerType[name] += amount;
        require(
            fs.totalCreatedPerType[name] <= fertilizerType.globalLimit,
            "Fertilizers: Global limit exceeded"
        );

        fs.totalCreatedPerUserPerType[user][nodeType] += amount;
        require(
            fs.totalCreatedPerUserPerType[user][nodeType] <=
                fertilizerType.userNodeTypeLimit,
            "Fertilizers: User node type limit exceeded"
        );

        fs.totalCreatedPerNodeTokenId[nodeTokenId] += amount;
        require(
            fs.totalCreatedPerNodeTokenId[nodeTokenId] <=
                fertilizerType.nodeLimit,
            "Fertilizers: Node limit exceeded"
        );
    }

    function getFertilizerPriceByNameAndNodeType(
        string memory name,
        string memory nodeType
    ) internal view returns (uint256) {
        require(
            LibFertilizer.hasFertilizerType(name),
            "Fertilizer type does not exist"
        );
        FertilizerFacetStorage storage fs = LibFertilizer.facetStorage();
        return fs.itemToNodeTypeToPrice[name][nodeType];
    }
}

struct NodeAddonLog {
    uint256[] creationTime;
    string[] addonKind;
    string[] addonTypeName;
}

struct AddonsFacetStorage {
    mapping(uint256 => NodeAddonLog) nodeAddonLogs;
}

library LibAddons {
    bytes32 constant STORAGE_POSITION =
        keccak256("diamond.handler.addons.storage");

    function facetStorage()
        internal
        pure
        returns (AddonsFacetStorage storage fs)
    {
        bytes32 position = STORAGE_POSITION;
        assembly {
            fs.slot := position
        }
    }

    function logAddon(
        uint256 nodeTokenId,
        string memory addonKind,
        string memory addonTypeName,
        uint256 creationTime
    ) internal {
        AddonsFacetStorage storage fs = facetStorage();
        fs.nodeAddonLogs[nodeTokenId].creationTime.push(creationTime);
        fs.nodeAddonLogs[nodeTokenId].addonKind.push(addonKind);
        fs.nodeAddonLogs[nodeTokenId].addonTypeName.push(addonTypeName);

        assert(
            fs.nodeAddonLogs[nodeTokenId].creationTime.length ==
                fs.nodeAddonLogs[nodeTokenId].addonKind.length
        );

        assert(
            fs.nodeAddonLogs[nodeTokenId].creationTime.length ==
                fs.nodeAddonLogs[nodeTokenId].addonTypeName.length
        );
    }

    function logWaterpacks(
        uint256[] memory nodeTokenIds,
        string memory waterpackType,
        uint256 creationTime,
        uint256[] memory amounts
    ) internal {
        require(
            nodeTokenIds.length == amounts.length,
            "Addons: Length mismatch"
        );
        for (uint256 i = 0; i < nodeTokenIds.length; i++) {
            for (uint256 j = 0; j < amounts[i]; j++) {
                logAddon(
                    nodeTokenIds[i],
                    "Waterpack",
                    waterpackType,
                    creationTime
                );
            }
        }
    }

    function logFertilizers(
        uint256[] memory nodeTokenIds,
        string memory fertilizerType,
        uint256 creationTime,
        uint256[] memory amounts,
        bool bypassLimits
    ) internal {
        require(
            nodeTokenIds.length == amounts.length,
            "Addons: Length mismatch"
        );

        for (uint256 i = 0; i < nodeTokenIds.length; i++) {
            LibFertilizer.applyFertilizer(
                fertilizerType,
                nodeTokenIds[i],
                amounts[i],
                bypassLimits
            );

            for (uint256 j = 0; j < amounts[i]; j++) {
                logAddon(
                    nodeTokenIds[i],
                    "Fertilizer",
                    fertilizerType,
                    creationTime
                );
            }
        }
    }
}

contract Handler_AddonsFacet is OwnersAware {
    function hasWaterpackType(string memory name) external view returns (bool) {
        return LibWaterpack.hasWaterpackType(name);
    }

    function getWaterpackType(string memory name)
        external
        view
        returns (Waterpack memory)
    {
        return LibWaterpack.getWaterpackType(name);
    }

    function getWaterpackPriceByNameAndNodeType(
        string memory name,
        string memory nodeType
    ) external view returns (uint256) {
        return LibWaterpack.getWaterpackPriceByNameAndNodeType(name, nodeType);
    }

    struct WaterpackView {
        string name;
        uint256 ratioOfGRP;
        uint256[] prices;
    }

    function getWaterpackTypes() public view returns (WaterpackView[] memory) {
        WaterpackFacetStorage storage fs = LibWaterpack.facetStorage();

        string[] memory nodeTypes = LibAppStorage.appStorage().mapNt.keys;
        WaterpackView[] memory output = new WaterpackView[](fs.items.length);

        for (uint256 i = 0; i < fs.items.length; i++) {
            uint256[] memory prices = new uint256[](nodeTypes.length);
            for (uint256 j = 0; j < nodeTypes.length; j++) {
                prices[j] = fs.itemToNodeTypeToPrice[fs.names[i]][nodeTypes[j]];
            }
            output[i] = WaterpackView({
                name: fs.names[i],
                ratioOfGRP: fs.items[i].ratioOfGRP,
                prices: prices
            });
        }

        return output;
    }

    function hasFertilizerType(string memory name)
        external
        view
        returns (bool)
    {
        return LibFertilizer.hasFertilizerType(name);
    }

    function getFertilizerType(string memory name)
        external
        view
        returns (Fertilizer memory)
    {
        return LibFertilizer.getFertilizerType(name);
    }

    function getFertilizerPriceByNameAndNodeType(
        string memory name,
        string memory nodeType
    ) external view returns (uint256) {
        return
            LibFertilizer.getFertilizerPriceByNameAndNodeType(name, nodeType);
    }

    struct FertilizerView {
        string name;
        uint256 durationEffect;
        uint256 rewardBoost;
        uint256[] prices;
        uint256 globalLimit;
        uint256 userNodeTypeLimit;
        uint256 nodeLimit;
    }

    function getFertilizerTypes()
        public
        view
        returns (FertilizerView[] memory)
    {
        FertilizerFacetStorage storage fs = LibFertilizer.facetStorage();
        string[] memory nodeTypes = LibAppStorage.appStorage().mapNt.keys;
        FertilizerView[] memory output = new FertilizerView[](fs.items.length);

        for (uint256 i = 0; i < fs.items.length; i++) {
            string storage fertilizerName = fs.names[i];
            uint256[] memory prices = new uint256[](nodeTypes.length);
            for (uint256 j = 0; j < nodeTypes.length; j++) {
                prices[j] = fs.itemToNodeTypeToPrice[fertilizerName][
                    nodeTypes[j]
                ];
            }

            output[i] = FertilizerView({
                name: fertilizerName,
                durationEffect: fs.items[i].durationEffect,
                rewardBoost: fs.items[i].rewardBoost,
                prices: prices,
                globalLimit: fs.items[i].globalLimit,
                userNodeTypeLimit: fs.items[i].userNodeTypeLimit,
                nodeLimit: fs.items[i].nodeLimit
            });
        }

        return output;
    }

    struct NodeAddonLogItemView {
        uint256 creationTime;
        string addonKind;
        string addonTypeName;
    }

    function getItemLogForNode(uint256 nodeId)
        public
        view
        returns (NodeAddonLogItemView[] memory)
    {
        AddonsFacetStorage storage fs = LibAddons.facetStorage();
        NodeAddonLog memory log = fs.nodeAddonLogs[nodeId];
        uint256 logLength = log.creationTime.length;
        NodeAddonLogItemView[] memory logItems = new NodeAddonLogItemView[](
            logLength
        );

        for (uint256 i = 0; i < logLength; i++) {
            logItems[i].creationTime = log.creationTime[i];
            logItems[i].addonKind = log.addonKind[i];
            logItems[i].addonTypeName = log.addonTypeName[i];
        }

        return logItems;
    }

    function totalFertilizerCreatedPerType(string calldata typeName)
        public
        view
        returns (uint256)
    {
        FertilizerFacetStorage storage fs = LibFertilizer.facetStorage();
        return fs.totalCreatedPerType[typeName];
    }

    function totalFertilizerCreatedPerUserPerType(
        address user,
        string calldata nodeType
    ) public view returns (uint256) {
        FertilizerFacetStorage storage fs = LibFertilizer.facetStorage();
        return fs.totalCreatedPerUserPerType[user][nodeType];
    }

    function totalFertilizerCreatedPerNodeTokenId(uint256 nodeTokenId)
        public
        view
        returns (uint256)
    {
        FertilizerFacetStorage storage fs = LibFertilizer.facetStorage();
        return fs.totalCreatedPerNodeTokenId[nodeTokenId];
    }
}