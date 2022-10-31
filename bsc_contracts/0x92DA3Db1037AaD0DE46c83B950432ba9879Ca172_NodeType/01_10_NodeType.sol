// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

import "./INodeType.sol";
import "./OwnersUpgradeable.sol";
import "./libraries/NodeRewards.sol";
import "./libraries/Percentage.sol";

import "hardhat/console.sol";

error AlreadyAjustedRewards(uint256 tokenId);
error AmmoLimitReached(uint256 tokenId);

contract NodeType is INodeType, OwnersUpgradeable, NodeRewards {
    struct User {
        uint256[] keys; // userTokenId
        mapping(uint256 => Node) values;
        mapping(uint256 => uint256) indexOf;
        mapping(uint256 => bool) inserted;
        uint256 countLevelUp;
        uint256 countPending;
    }

    mapping(address => User) private userOf;
    mapping(uint256 => address) public tokenIdToOwner;

    string public name;

    uint256 public totalCreatedNodes;

    uint256 public maxCount;
    uint256 public price;
    uint256 public claimTime;
    uint256 public rewardAmount;
    uint256 public claimTaxGRP;
    uint256 public globalTax;

    bool public openCreateNodesWithTokens;
    bool public openCreateNodesLevelUp;
    bool public openCreateNodesWithPending;
    bool public openCreateNodesWithLuckyBoxes;
    bool public openCreateNodesMigration;

    string[] features;
    mapping(string => uint256) public featureToBoostRate;
    mapping(string => uint256) public featureCount;

    address[] public nodeOwners;
    mapping(address => bool) public nodeOwnersInserted;

    mapping(address => uint256) public ownersMigrated;

    address public handler;

    uint256 private nonce;
    mapping(uint256 => bool) public blockRewards;

    function initialize(
        string memory _name,
        uint256[] memory values,
        address _handler
    ) external initializer {
        __NodeType_init(_name, values, _handler);
    }

    function __NodeType_init(
        string memory _name,
        uint256[] memory values,
        address _handler
    ) internal onlyInitializing {
        __Owners_init_unchained();
        __NodeType_init_unchained(_name, values, _handler);
    }

    function __NodeType_init_unchained(
        string memory _name,
        uint256[] memory values,
        address _handler
    ) internal onlyInitializing {
        require(bytes(_name).length > 0, "NodeType: Name cannot be empty");
        name = _name;

        require(values.length == 6, "NodeType: Values.length mismatch");
        maxCount = values[0];
        price = values[1];
        claimTime = values[2];
        rewardAmount = values[3];

        require(
            values[4] < 10000,
            "NodeType: ClaimTaxGRP must be lower than 10000"
        );
        claimTaxGRP = values[4];
        globalTax = values[5];

        handler = _handler;

        openCreateNodesWithTokens = false;
        openCreateNodesLevelUp = false;
        openCreateNodesWithPending = false;
        openCreateNodesWithLuckyBoxes = false;
        openCreateNodesMigration = false;
    }

    modifier onlyHandler() {
        require(msg.sender == handler, "NodeType: Only Handler");
        _;
    }

    // External tokens like
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external onlyHandler {
        require(userOf[from].inserted[tokenId], "NodeType: Transfer failure");
        if (nodeOwnersInserted[to] == false) {
            nodeOwners.push(to);
            nodeOwnersInserted[to] = true;
        }
        User storage u = userOf[from];
        u.values[tokenId].owner = to;
        u.values[tokenId].obtainingTime = block.timestamp;
        userSet(userOf[to], tokenId, u.values[tokenId]);
        userRemove(userOf[from], tokenId);
        tokenIdToOwner[tokenId] = to;
    }

    function burnFrom(address from, uint256[] memory tokenIds)
        external
        onlyHandler
        returns (uint256)
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                userOf[from].inserted[tokenIds[i]],
                "NodeType: Burn failure"
            );

            Node memory n = userOf[from].values[tokenIds[i]];
            if (featureCount[n.feature] > 0) featureCount[n.feature]--;

            userRemove(userOf[from], tokenIds[i]);
            tokenIdToOwner[tokenIds[i]] = address(0);
        }
        totalCreatedNodes -= tokenIds.length;
        return price * tokenIds.length;
    }

    function createNodeWithLuckyBox(
        address user,
        uint256[] memory tokenIds,
        string memory feature
    ) external onlyHandler {
        require(openCreateNodesWithLuckyBoxes, "NodeType: Not open");
        _createNodes(user, tokenIds, feature);
    }

    function createNodeCustom(
        address user,
        uint256[] memory tokenIds,
        string memory feature
        // uint256 feature_index
    ) external onlyHandler {
        if (bytes(feature).length > 0) {
        //     string memory _feature = features[feature_index];
        //     require(
        //         keccak256(abi.encodePacked((_feature))) ==
        //             keccak256(abi.encodePacked((feature))),
        //         "NodeType: Feature doesnt exist"
        //     );
        // }
            require(
                featureToBoostRate[feature] != 0,
                "NodeType: Feature doesnt exist"
            );
        _createNodes(user, tokenIds, feature);
        }
    }

    function claimRewardsAll(address user)
        external
        onlyHandler
        returns (uint256, uint256)
    {
        uint256 rewardsTotal;
        uint256 feesTotal;
        User storage u = userOf[user];

        for (uint256 i = 0; i < u.keys.length; i++) {
            if (blockRewards[u.keys[i]]) {
                continue;
            }

            Node storage userNode = u.values[u.keys[i]];
            (
                uint256 rewards,
                uint256 fees,
                uint256 baseRewards
            ) = _calculateNodeRewards(userNode);

            rewardsTotal += rewards;
            feesTotal += fees;

            _persistRewards(userNode);
            userNode.lastClaimTime = block.timestamp;
            userNode.accumulatedRewards = 0;
            userNode.totalClaimedRewards += baseRewards;
        }

        return (rewardsTotal, feesTotal); // transfer to user
    }

    function claimRewardsBatch(address user, uint256[] memory tokenIds)
        external
        onlyHandler
        returns (uint256, uint256)
    {
        uint256 rewardsTotal;
        uint256 feesTotal;
        User storage u = userOf[user];

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                u.inserted[tokenIds[i]],
                "NodeType: User doesnt own this node"
            );

            if (blockRewards[tokenIds[i]]) {
                continue;
            }

            Node storage userNode = u.values[tokenIds[i]];
            (
                uint256 rewards,
                uint256 fees,
                uint256 baseRewards
            ) = _calculateNodeRewards(userNode);

            rewardsTotal += rewards;
            feesTotal += fees;

            _persistRewards(userNode);
            userNode.lastClaimTime = block.timestamp;
            userNode.accumulatedRewards = 0;
            userNode.totalClaimedRewards += baseRewards;
        }

        return (rewardsTotal, feesTotal);
    }

    function applyFertilizerBatch(
        address user,
        uint256[] memory tokenIds,
        uint256 durationEffect,
        uint256 boostAmount,
        uint256[] memory amounts
    ) external onlyHandler {
        require(tokenIds.length == amounts.length, "NodeType: Length mismatch");
        User storage u = userOf[user];

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                u.inserted[tokenIds[i]],
                "NodeType: User doesnt own this node"
            );
            Node storage userNode = u.values[tokenIds[i]];
            _addFertilizer(userNode, durationEffect, boostAmount, amounts[i]);
        }
    }

    function applyWaterpackBatch(
        address user,
        uint256[] memory tokenIds,
        uint256 ratioOfGRPExtended,
        uint256[] memory amounts
    ) external onlyHandler {
        require(tokenIds.length == amounts.length, "NodeType: Length mismatch");
        User storage u = userOf[user];

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                u.inserted[tokenIds[i]],
                "NodeType: User doesnt own this node"
            );
            Node storage userNode = u.values[tokenIds[i]];
            //ex: i have 1 ammo used and i want buy 2 ammo
    
            // if (userNode.ammosUsed < 3 && amounts[i] <= 3 - userNode.ammosUsed) continue;
            // userNode.ammosUsed += amounts[i];

            require(userNode.ammosUsed + uint8(amounts[i]) <= 3, "NodeType: Maximum Ammos reached");
            userNode.ammosUsed += uint8(amounts[i]);
            _extendLifetime(userNode, ratioOfGRPExtended, amounts[i]);
        }
    }

    function setPlotAdditionalLifetime(
        address user,
        uint256 tokenId,
        uint256 amountOfGRP
    ) external onlyHandler {
        User storage u = userOf[user];
        require(u.inserted[tokenId], "NodeType: User doesnt own this node");
        Node storage node = u.values[tokenId];
        node.plotAdditionalLifetime = Percentages.times(
            amountOfGRP,
            _timeToGRP(node.feature)
        );
    }

    function addPlotAdditionalLifetime(
        address user,
        uint256 tokenId,
        uint256 amountOfGRP,
        uint256 amount
    ) external onlyHandler {
        User storage u = userOf[user];
        require(u.inserted[tokenId], "NodeType: User doesnt own this node");
        Node storage node = u.values[tokenId];
        node.plotAdditionalLifetime +=
            Percentages.times(amountOfGRP, _timeToGRP(node.feature)) *
            amount;
    }

    // External setters
    function addFeature(string memory _name, uint256 _rate)
        external
        onlyOwners
    {
        require(
            featureToBoostRate[name] == 0,
            "NodeType: Feature already exist"
        );
        require(bytes(_name).length > 0, "NodeType: Name cannot be empty");
        features.push(_name);
        featureToBoostRate[_name] = _rate;
    }

    function deleteFeature(string memory _name, uint256 index)
        external
        onlyOwners
    {
        delete featureToBoostRate[_name];
        delete features[index];
    }

    function updateFeature(string memory _name, uint256 _rate)
        external
        onlyOwners
    {
        require(
            featureToBoostRate[name] != 0,
            "NodeType: Feature doesnt exist"
        );
        featureToBoostRate[_name] = _rate;
    }

    function setHandler(address _new) external onlyOwners {
        require(_new != address(0), "NodeType: Handler cannot be address zero");
        handler = _new;
    }

    function setBasics(
        uint256 _newPrice,
        uint256 _claimTime,
        uint256 _rewardAmount
    ) external onlyOwners {
        require(_newPrice > 0, "NodeType: Price cannot be zero");
        price = _newPrice;
        require(_claimTime > 0, "NodeType: Claim Time cannot be zero");
        claimTime = _claimTime;
        require(_rewardAmount > 0, "NodeType: Reward Amount cannot be zero");
        rewardAmount = _rewardAmount;
    }

    function setTax(uint256 _claimTaxGRP, uint256 _globalTax)
        external
        onlyOwners
    {
        claimTaxGRP = _claimTaxGRP;
        globalTax = _globalTax;
    }

    function setOpenCreate(
        bool _openCreateNodesWithTokens,
        bool _openCreateNodesLevelUp,
        bool _openCreateNodesWithPending,
        bool _openCreateNodesWithLuckyBoxes,
        bool _openCreateNodesMigration
    ) external onlyOwners {
        openCreateNodesWithTokens = _openCreateNodesWithTokens;
        openCreateNodesLevelUp = _openCreateNodesLevelUp;
        openCreateNodesWithPending = _openCreateNodesWithPending;
        openCreateNodesWithLuckyBoxes = _openCreateNodesWithLuckyBoxes;
        openCreateNodesMigration = _openCreateNodesMigration;
    }

    function setTokenIdSpecs(uint256 tokenId, string memory _feature)
        external
        onlyOwners
    {
        Node storage node = userOf[tokenIdToOwner[tokenId]].values[tokenId];

        require(
            featureToBoostRate[_feature] != 0,
            "NodeType: Feature doesnt exist"
        );

        node.feature = _feature;
    }

    // external view
    function getAmmosUsed(address user, uint256 tokenId)
        external
        view
        returns (uint8)
    {
        User storage u = userOf[user];
        Node storage node = u.values[tokenId];

        return node.ammosUsed;
    }

    function nodeIsDead(address user, uint256 tokenId)
        external
        view
        returns (bool)
    {
        User storage u = userOf[user];
        Node storage node = u.values[tokenId];

        return node.totalClaimedRewards + node.accumulatedRewards >= price;
    }

    function nodeIsActive(address user, uint256 tokenId)
        external
        view
        returns (bool)
    {
        User storage u = userOf[user];
        Node storage node = u.values[tokenId];

        uint256 ceiling = _getCeiling(node);

        return node.totalClaimedRewards + node.accumulatedRewards < ceiling;
    }

    function _nodeIsActive(address user, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        User storage u = userOf[user];
        Node storage node = u.values[tokenId];

        uint256 ceiling = _getCeiling(node);

        return node.totalClaimedRewards + node.accumulatedRewards < ceiling;
    }

    function getCeiling(address user, uint256 tokenId)
        external
        view
        returns (uint256)
    {
        User storage u = userOf[user];
        Node storage node = u.values[tokenId];

        return _getCeiling(node);
    }

    function _getCeiling(Node memory node) internal view returns (uint256) {
        return (price / 2) * (node.ammosUsed + 1);
    }

    function getTimeLeftUntilAmmo(address user, uint256 tokenId)
        external
        view
        returns (uint256)
    {
        User storage u = userOf[user];
        Node storage node = u.values[tokenId];

        uint256 ceiling = _getCeiling(node);

        return
            Math.subOrZero(
                ceiling,
                node.totalClaimedRewards + node.accumulatedRewards
            );
    }

    function getNode(address user, uint256 tokenId)
        external
        view
        returns (Node memory)
    {
        User storage u = userOf[user];
        Node storage node = u.values[tokenId];

        return node;
    }

    function getTotalClaimedRewards(address user, uint256 tokenId)
        external
        view
        returns (uint256)
    {
        User storage u = userOf[user];
        Node storage node = u.values[tokenId];

        return node.totalClaimedRewards;
    }

    function getTotalNodesNumberOf(address user)
        external
        view
        returns (uint256)
    {
        return userOf[user].keys.length;
    }

    function getNodeFromTokenId(uint256 tokenId)
        external
        view
        returns (Node memory)
    {
        return userOf[tokenIdToOwner[tokenId]].values[tokenId];
    }

    function getNodesCountLevelUpOf(address user)
        external
        view
        returns (uint256)
    {
        return userOf[user].countLevelUp;
    }

    function getNodesCountPendingOf(address user)
        external
        view
        returns (uint256)
    {
        return userOf[user].countPending;
    }

    function getTokenIdsOfBetweenIndexes(
        address user,
        uint256 iStart,
        uint256 iEnd
    ) external view returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](iEnd - iStart);
        User storage u = userOf[user];
        for (uint256 i = iStart; i < iEnd; i++)
            tokenIds[i - iStart] = u.keys[i];
        return tokenIds;
    }

    function getNodesOfBetweenIndexes(
        address user,
        uint256 iStart,
        uint256 iEnd
    ) external view returns (Node[] memory) {
        Node[] memory nodes = new Node[](iEnd - iStart);
        User storage u = userOf[user];
        for (uint256 i = iStart; i < iEnd; i++)
            nodes[i - iStart] = u.values[u.keys[i]];
        return nodes;
    }

    function getTimeGRPOfBetweenIndexes(
        address user,
        uint256 iStart,
        uint256 iEnd
    ) external view returns (uint256[] memory) {
        uint256[] memory roiTimes = new uint256[](iEnd - iStart);
        User storage u = userOf[user];
        Node storage node = u.values[u.keys[iStart]];
        for (uint256 i = iStart; i < iEnd; i++) {
            uint256 basePerSecond = _baseRewardsPerSecond(node.feature);
            roiTimes[i - iStart] = (price / basePerSecond) + node.creationTime;
        }

        return roiTimes;
    }

    function getFeaturesSize() external view returns (uint256) {
        return features.length;
    }

    function getFeaturesBetweenIndexes(uint256 iStart, uint256 iEnd)
        external
        view
        returns (string[] memory)
    {
        string[] memory f = new string[](iEnd - iStart);
        for (uint256 i = iStart; i < iEnd; i++) f[i - iStart] = features[i];
        return f;
    }

    function getNodeOwnersSize() external view returns (uint256) {
        return nodeOwners.length;
    }

    function getAttribute(uint256 tokenId)
        external
        view
        returns (string memory)
    {
        return userOf[tokenIdToOwner[tokenId]].values[tokenId].feature;
    }

    function getNodeOwnersBetweenIndexes(uint256 iStart, uint256 iEnd)
        external
        view
        returns (address[] memory)
    {
        address[] memory no = new address[](iEnd - iStart);
        for (uint256 i = iStart; i < iEnd; i++) no[i - iStart] = nodeOwners[i];
        return no;
    }

    function calculateUserRewardsBatch(address user, uint256[] memory tokenIds)
        external
        view
        returns (uint256[] memory, uint256[] memory)
    {
        uint256[] memory rewardsTotal = new uint256[](tokenIds.length);
        uint256[] memory feesTotal = new uint256[](tokenIds.length);
        User storage u = userOf[user];

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                u.inserted[tokenIds[i]],
                "NodeType: User doesnt own this node"
            );

            if (blockRewards[tokenIds[i]]) {
                continue;
            }

            if (_nodeIsActive(user, tokenIds[i]))
            {
                Node storage userNode = u.values[tokenIds[i]];
                (uint256 rewards, uint256 fees, ) = _calculateNodeRewards(userNode);
                rewardsTotal[i] += rewards;
                feesTotal[i] = fees;
            } else {
                rewardsTotal[i] = 0;
                feesTotal[i] = 0;
            }
        }
        return (rewardsTotal, feesTotal);
    }

    function getCurrentRewardsPerSecondsForNode(uint256 tokenId)
        external
        view
        returns (uint256 currentRewardsPerSeconds, uint256 currentTime)
    {
        if (blockRewards[tokenId]) {
            return (0, block.timestamp);
        }

        Node storage node = userOf[tokenIdToOwner[tokenId]].values[tokenId];
        return _getCurrentRewardsPerSeconds(node);
    }

    function getCurrentLifetimeOfNode(uint256 tokenId)
        external
        view
        returns (uint256 currentLifetime, uint256 currentTime)
    {
        if (blockRewards[tokenId]) {
            return (0, block.timestamp);
        }

        Node storage node = userOf[tokenIdToOwner[tokenId]].values[tokenId];
        return (_getCurrentNodeLifetime(node), block.timestamp);
    }

    // public
    function calculateUserRewards(address user)
        public
        view
        returns (uint256, uint256)
    {
        uint256 rewardsTotal;
        uint256 feesTotal;
        User storage u = userOf[user];

        for (uint256 i = 0; i < u.keys.length; i++) {
            uint256 tokenId = u.keys[i];
            if (blockRewards[tokenId]) {
                continue;
            }

            (uint256 rewards, uint256 fees, ) = _calculateNodeRewards(
                u.values[tokenId]
            );
            rewardsTotal += rewards;
            feesTotal += fees;
        }

        return (rewardsTotal, feesTotal);
    }

    function getGRP() public view returns (uint256) {
        return _timeToGRP("");
    }

    function getGRP(string memory feature) public view returns (uint256) {
        return _timeToGRP(feature);
    }

    // private
    function _createNodes(
        address user,
        uint256[] memory tokenIds,
        string memory feature
    ) private {
        require(tokenIds.length > 0, "NodeType: Nothing to create");

        if (nodeOwnersInserted[user] == false) {
            nodeOwners.push(user);
            nodeOwnersInserted[user] = true;
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            Node memory node = _newNode(user, feature);

            userSet(userOf[user], tokenIds[i], node);
            tokenIdToOwner[tokenIds[i]] = user;
        }

        featureCount[feature] += tokenIds.length;
        totalCreatedNodes += tokenIds.length;
    }

    function calculateNodeRewards(address user, uint256 tokenId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        User storage u = userOf[user];
        Node storage node = u.values[tokenId];

        return _calculateNodeRewards(node);
    }

    function calculateBaseNodeRewards(address user, uint256 tokenId)
        external
        view
        returns (uint256)
    {
        User storage u = userOf[user];
        Node storage node = u.values[tokenId];

        return _calculateBaseNodeRewards(node);
    }

    function _calculateNodeRewards(Node storage node)
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rewardsTotal;
        uint256 fees;

        uint256 baseRewards = _calculateBaseNodeRewards(node);
        rewardsTotal = baseRewards;

        // if (featureToBoostRate[node.feature] > 0) {
        //     rewardsTotal =
        //         (rewardsTotal * (10000 + featureToBoostRate[node.feature])) /
        //         10000;
        // }

        uint256 ceiling = _getCeiling(node);

        if (node.totalClaimedRewards + rewardsTotal > ceiling) {
            rewardsTotal = ceiling - node.totalClaimedRewards;
        }

        if (globalTax > 0) {
            fees += (rewardsTotal * globalTax) / 10000;
        }

        return (rewardsTotal - fees, fees, baseRewards);
    }

    function userSet(
        User storage user,
        uint256 key,
        Node memory value
    ) private {
        if (user.inserted[key]) {
            user.values[key] = value;
        } else {
            user.inserted[key] = true;
            user.values[key] = value;
            user.indexOf[key] = user.keys.length;
            user.keys.push(key);
        }
    }

    function userRemove(User storage user, uint256 key) private {
        if (!user.inserted[key]) {
            return;
        }

        delete user.inserted[key];
        delete user.values[key];

        uint256 index = user.indexOf[key];
        uint256 lastIndex = user.keys.length - 1;
        uint256 lastKey = user.keys[lastIndex];

        user.indexOf[lastKey] = index;
        delete user.indexOf[key];

        if (lastIndex != index) user.keys[index] = lastKey;
        user.keys.pop();
    }

    function _price() internal view override returns (uint256) {
        return price;
    }

    function _baseRewardsPerSecond(string memory feature)
        internal
        view
        override
        returns (uint256)
    {
        return
            (rewardAmount +
                ((rewardAmount * featureToBoostRate[feature]) / 10000)) /
            claimTime;
    }

    function baseRewardsPerSecond() public view returns (uint256) {
        return _baseRewardsPerSecond("");
    }

    function baseRewardsPerSecond(string memory feature)
        public
        view
        returns (uint256)
    {
        return _baseRewardsPerSecond(feature);
    }

    function setBlockRewards(uint256 tokenId, bool _block)
        external
        onlyHandler
    {
        blockRewards[tokenId] = _block;
    }
}