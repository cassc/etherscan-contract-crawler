// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

import "./OwnersFacet.sol";
import "./AppStorage.sol";
import "./AddonsFacet.sol";

library LibAdministration {
    function mapNtSet(
        AppStorage storage s,
        string memory key,
        address value
    ) internal {
        if (s.mapNt.inserted[key]) {
            s.mapNt.values[key] = value;
        } else {
            s.mapNt.inserted[key] = true;
            s.mapNt.values[key] = value;
            s.mapNt.indexOf[key] = s.mapNt.keys.length;
            s.mapNt.keys.push(key);
        }
    }

    function mapTokenSet(
        AppStorage storage s,
        uint256 key,
        string memory value
    ) internal {
        if (s.mapToken.inserted[key]) {
            s.mapToken.values[key] = value;
        } else {
            s.mapToken.inserted[key] = true;
            s.mapToken.values[key] = value;
            s.mapToken.indexOf[key] = s.mapToken.keys.length;
            s.mapToken.keys.push(key);
        }
    }

    function mapNtRemove(AppStorage storage s, string memory key) internal {
        if (!s.mapNt.inserted[key]) {
            return;
        }

        delete s.mapNt.inserted[key];
        delete s.mapNt.values[key];

        uint256 index = s.mapNt.indexOf[key];
        uint256 lastIndex = s.mapNt.keys.length - 1;
        string memory lastKey = s.mapNt.keys[lastIndex];

        s.mapNt.indexOf[lastKey] = index;
        delete s.mapNt.indexOf[key];

        if (lastIndex != index) s.mapNt.keys[index] = lastKey;
        s.mapNt.keys.pop();
    }

    function mapTokenRemove(AppStorage storage s, uint256 key) internal {
        if (!s.mapToken.inserted[key]) {
            return;
        }

        delete s.mapToken.inserted[key];
        delete s.mapToken.values[key];

        uint256 index = s.mapToken.indexOf[key];
        uint256 lastIndex = s.mapToken.keys.length - 1;
        uint256 lastKey = s.mapToken.keys[lastIndex];

        s.mapToken.indexOf[lastKey] = index;
        delete s.mapToken.indexOf[key];

        if (lastIndex != index) s.mapToken.keys[index] = lastKey;
        s.mapToken.keys.pop();
    }
}

contract Handler_AdministrationFacet {
    modifier onlyOwners() {
        LibOwners.enforceOnlyOwners();
        _;
    }

    function postUpgrade() external {
        if (!LibOwners.facetStorage().initialized) {
            LibOwners.initialize();
        }
    }

    function addNodeType(address _addr) external onlyOwners {
        AppStorage storage s = LibAppStorage.appStorage();

        string memory name = INodeType(_addr).name();
        require(!s.mapNt.inserted[name], "Handler: NodeType already exists");
        LibAdministration.mapNtSet(s, name, _addr);
    }

    function hasNodeType(address _addr) external view returns (bool) {
        AppStorage storage s = LibAppStorage.appStorage();
        try INodeType(_addr).name() returns (string memory name) {
            return s.mapNt.inserted[name];
        } catch {
            return false;
        }
    }

    function addMultipleNodeTypes(address[] memory _addrs) external onlyOwners {
        AppStorage storage s = LibAppStorage.appStorage();

        for (uint256 i = 0; i < _addrs.length; i++) {
            string memory name = INodeType(_addrs[i]).name();
            LibAdministration.mapNtSet(s, name, _addrs[i]);
        }
    }

    function updateNodeTypeAddress(string memory name, address _addr)
        external
        onlyOwners
    {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.mapNt.inserted[name], "Handler: NodeType doesnt exist");
        s.mapNt.values[name] = _addr;
    }

    function setPlotType(
        string memory name,
        uint256 price,
        uint256 maxNodes,
        string[] memory allowedNodeTypes,
        uint256 additionalGRPTime,
        uint256 waterpackGRPBoost
    ) external onlyOwners {
        AppStorage storage s = LibAppStorage.appStorage();
        s.plot.setPlotType({
            name: name,
            price: price,
            maxNodes: maxNodes,
            allowedNodeTypes: allowedNodeTypes,
            additionalGRPTime: additionalGRPTime,
            waterpackGRPBoost: waterpackGRPBoost
        });
    }

    function setWaterpackType(
        string calldata name,
        uint256 ratioOfGRP,
        uint256[] calldata prices
    ) external onlyOwners {
        LibWaterpack.setWaterpackType(name, ratioOfGRP, prices);
    }

    function setFertilizerType(
        string calldata name,
        uint256 durationEffect,
        uint256 rewardBoost,
        uint256[] calldata limits,
        uint256[] calldata prices
    ) external onlyOwners {
        LibFertilizer.setFertilizerType(
            name,
            durationEffect,
            rewardBoost,
            limits,
            prices
        );
    }

    function setNft(address _new) external onlyOwners {
        AppStorage storage s = LibAppStorage.appStorage();
        require(_new != address(0), "Handler: Nft cannot be address zero");
        s.nft = _new;
    }

    function setLucky(address _new) external onlyOwners {
        AppStorage storage s = LibAppStorage.appStorage();
        require(_new != address(0), "Handler: Loot cannot be address zero");
        s.lucky = ISpringLuckyBox(_new);
    }

    function setSwapper(address _new) external onlyOwners {
        AppStorage storage s = LibAppStorage.appStorage();
        require(_new != address(0), "Handler: Swapper cannot be address zero");
        s.swapper = ISwapper(_new);
    }

    function setPlot(address _new) external onlyOwners {
        AppStorage storage s = LibAppStorage.appStorage();
        require(_new != address(0), "Handler: Plot cannot be address zero");
        s.plot = ISpringPlot(_new);
    }

    function nft() public view returns (address) {
        return LibAppStorage.appStorage().nft;
    }

    function lucky() public view returns (ISpringLuckyBox) {
        return LibAppStorage.appStorage().lucky;
    }

    function swapper() public view returns (ISwapper) {
        return LibAppStorage.appStorage().swapper;
    }

    function plot() public view returns (ISpringPlot) {
        return LibAppStorage.appStorage().plot;
    }

    function getNodeTypesSize() external view returns (uint256) {
        return LibAppStorage.appStorage().mapNt.keys.length;
    }

    function getNodeTypesNames() external view returns (string[] memory) {
        return LibAppStorage.appStorage().mapNt.keys;
    }

    function getTotalCreatedNodes() external view returns (uint256) {
        AppStorage storage s = LibAppStorage.appStorage();
        uint256 totalNodes;
        for (uint256 i = 0; i < s.mapNt.keys.length; i++) {
            totalNodes += INodeType(s.mapNt.values[s.mapNt.keys[i]])
                .totalCreatedNodes();
        }
        return totalNodes;
    }

    function getNodeTypesBetweenIndexes(uint256 iStart, uint256 iEnd)
        external
        view
        returns (string[] memory)
    {
        AppStorage storage s = LibAppStorage.appStorage();
        string[] memory nodeTypes = new string[](iEnd - iStart);
        for (uint256 i = iStart; i < iEnd; i++)
            nodeTypes[i - iStart] = s.mapNt.keys[i];
        return nodeTypes;
    }

    function getNodeTypesAddress(string memory key)
        external
        view
        returns (address)
    {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.mapNt.inserted[key], "NodeType doesnt exist");
        return s.mapNt.values[key];
    }

    function getAttribute(uint256 tokenId)
        external
        view
        returns (string memory)
    {
        AppStorage storage s = LibAppStorage.appStorage();
        return
            INodeType(s.mapNt.values[s.mapToken.values[tokenId]]).getAttribute(
                tokenId
            );
    }

    function getTokenIdsSize() external view returns (uint256) {
        return LibAppStorage.appStorage().mapToken.keys.length;
    }

    function getTokenIdsBetweenIndexes(uint256 iStart, uint256 iEnd)
        external
        view
        returns (uint256[] memory)
    {
        AppStorage storage s = LibAppStorage.appStorage();
        uint256[] memory ids = new uint256[](iEnd - iStart);
        for (uint256 i = iStart; i < iEnd; i++)
            ids[i - iStart] = s.mapToken.keys[i];
        return ids;
    }

    function getTokenIdsNodeTypeBetweenIndexes(uint256 iStart, uint256 iEnd)
        external
        view
        returns (string[] memory)
    {
        AppStorage storage s = LibAppStorage.appStorage();
        string[] memory names = new string[](iEnd - iStart);
        for (uint256 i = iStart; i < iEnd; i++)
            names[i - iStart] = s.mapToken.values[s.mapToken.keys[i]];
        return names;
    }

    function getTokenIdNodeTypeName(uint256 key)
        external
        view
        returns (string memory)
    {
        return LibAppStorage.getTokenIdNodeTypeName(key);
    }

    function getTotalNodesOf(address user) external view returns (uint256) {
        AppStorage storage s = LibAppStorage.appStorage();
        uint256 totalNodes;
        for (uint256 i = 0; i < s.mapNt.keys.length; i++) {
            totalNodes += INodeType(s.mapNt.values[s.mapNt.keys[i]])
                .getTotalNodesNumberOf(user);
        }
        return totalNodes;
    }

    function getClaimableRewardsOf(address user)
        external
        view
        returns (uint256, uint256)
    {
        AppStorage storage s = LibAppStorage.appStorage();
        uint256 rewardsTotal;
        uint256 feesTotal;
        for (uint256 i = 0; i < s.mapNt.keys.length; i++) {
            (uint256 rewards, uint256 fees) = INodeType(
                s.mapNt.values[s.mapNt.keys[i]]
            ).calculateUserRewards(user);
            rewardsTotal += rewards;
            feesTotal += fees;
        }
        return (rewardsTotal, feesTotal);
    }

    function setBlockRewards(uint256[] calldata tokenIds, bool _block)
        external
        onlyOwners
    {
        AppStorage storage s = LibAppStorage.appStorage();
        for (uint256 i = 0; i < tokenIds.length; i++) {
            INodeType nodeType = INodeType(s.mapNt.values[
                LibAppStorage.getTokenIdNodeTypeName(tokenIds[i])
            ]);
            
            nodeType.setBlockRewards(tokenIds[i], _block);
        }
    }
}