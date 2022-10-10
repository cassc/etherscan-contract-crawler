// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

import "./AppStorage.sol";
import "./OwnersFacet.sol";
import "./AdministrationFacet.sol";

contract Handler_GameLogicFacet {
    event NewNode(address indexed owner, string indexed nodeType);

    event NewLuckyBox(
        address indexed owner,
        string indexed luckyBoxType,
        uint256 amount,
        uint256 price
    );

    event NewPlot(
        address indexed owner,
        string indexed plotType,
        uint256 price
    );

    event WaterpackApplied(
        address indexed owner,
        string indexed waterpackType,
        uint256 nodeTokenId,
        uint256 count,
        uint256 price
    );

    event FertilizerApplied(
        address indexed owner,
        string indexed fertilizerType,
        uint256 nodeTokenId,
        uint256 count,
        uint256 price
    );

    function createPlotWithTokens(
        address tokenIn,
        string memory plotType,
        string memory sponso
    ) external returns (uint256) {
        AppStorage storage s = LibAppStorage.appStorage();

        (uint256 totalPrice, uint256 tokenId) = s.plot.createNewPlot(
            msg.sender,
            plotType
        );
        if (totalPrice > 0) {
            s.swapper.swapNewPlot(tokenIn, msg.sender, totalPrice, sponso);
        }

        emit NewPlot(msg.sender, plotType, totalPrice);

        return tokenId;
    }

    function createNodesWithLuckyBoxes(
        uint256[] memory tokenIdsLuckyBoxes,
        uint256[] memory tokenIdsPlots
    ) external {
        require(
            tokenIdsLuckyBoxes.length == tokenIdsPlots.length,
            "Handler: Length mismatch"
        );

        AppStorage storage s = LibAppStorage.appStorage();

        string[] memory nodeTypes;
        string[] memory features;

        (nodeTypes, features) = s.lucky.createNodesWithLuckyBoxes(
            msg.sender,
            tokenIdsLuckyBoxes
        );

        assert(nodeTypes.length == tokenIdsPlots.length);

        for (uint256 i = 0; i < nodeTypes.length; i++) {
            uint256[] memory tokenIdArray = _setUpNodes(
                nodeTypes[i],
                msg.sender,
                1
            );
            assert(tokenIdArray.length == 1);

            INodeType nodeType = INodeType(s.mapNt.values[nodeTypes[i]]);
            nodeType.createNodeWithLuckyBox(
                msg.sender,
                tokenIdArray,
                features[i]
            );

            if (tokenIdsPlots[i] == 0) {
                tokenIdsPlots[i] = s.plot.findOrCreateDefaultPlot(msg.sender);
            }

            s.plot.moveNodeToPlot(
                msg.sender,
                tokenIdArray[0],
                tokenIdsPlots[i]
            );
            _onMoveNodeToPlot(msg.sender, tokenIdArray[0], tokenIdsPlots[i]);

            emit NewNode(msg.sender, nodeTypes[i]);
        }
    }

    function createNodesAirDrop(
        string memory name,
        address user,
        string memory feature,
        uint256 count,
        uint256 feature_index
    ) external {
        LibOwners.enforceOnlyOwners();

        require(count > 0, "Handler: Count must be greater than 0");
        AppStorage storage s = LibAppStorage.appStorage();

        for (uint256 i = 0; i < count; i++) {
            uint256[] memory tokenIds = _setUpNodes(name, user, 1);
            assert(tokenIds.length == 1);

            INodeType(s.mapNt.values[name]).createNodeCustom(
                user,
                tokenIds,
                feature,
                feature_index
            );

            uint256 plotTokenId = s.plot.findOrCreateDefaultPlot(user);
            s.plot.moveNodeToPlot(user, tokenIds[0], plotTokenId);
            _onMoveNodeToPlot(user, tokenIds[0], plotTokenId);
        }

        emit NewNode(user, name);
    }

    function createLuckyBoxesWithTokens(
        address tokenIn,
        address user,
        string memory name,
        uint256 count,
        string memory sponso
    ) external {
        AppStorage storage s = LibAppStorage.appStorage();
        uint256 price = s.lucky.createLuckyBoxesWithTokens(name, count, user);

        emit NewLuckyBox(user, name, count, price);

        s.swapper.swapCreateLuckyBoxesWithTokens(
            tokenIn,
            msg.sender,
            price,
            sponso
        );
    }

    function createLuckyBoxesAirDrop(
        string memory name,
        address user,
        uint256 count
    ) external {
        LibOwners.enforceOnlyOwners();
        AppStorage storage s = LibAppStorage.appStorage();
        s.lucky.createLuckyBoxesAirDrop(name, count, user);
        emit NewLuckyBox(user, name, count, 0);
    }

    function claimRewardsAll(address tokenOut, address user) external {
        require(
            user == msg.sender || LibOwners.isOwner(msg.sender),
            "Handler: Dont mess with other claims"
        );

        AppStorage storage s = LibAppStorage.appStorage();

        uint256 rewardsTotal;
        uint256 feesTotal;

        for (uint256 i = 0; i < s.mapNt.keys.length; i++) {
            (uint256 rewards, uint256 fees) = INodeType(
                s.mapNt.values[s.mapNt.keys[i]]
            ).claimRewardsAll(user);
            rewardsTotal += rewards;
            feesTotal += fees;
        }

        s.swapper.swapClaimRewardsAll(tokenOut, user, rewardsTotal, feesTotal);
    }

    function claimRewardsBatch(
        address tokenOut,
        address user,
        string[] memory names,
        uint256[][] memory tokenIds
    ) public {
        require(
            user == msg.sender || LibOwners.isOwner(msg.sender),
            "Handler: Dont mess with other claims"
        );

        AppStorage storage s = LibAppStorage.appStorage();

        uint256 rewardsTotal;
        uint256 feesTotal;

        require(names.length == tokenIds.length, "Handler: Length mismatch");

        for (uint256 i = 0; i < names.length; i++) {
            require(
                s.mapNt.inserted[names[i]],
                "Handler: NodeType doesnt exist"
            );

            (uint256 rewards, uint256 fees) = INodeType(
                s.mapNt.values[names[i]]
            ).claimRewardsBatch(user, tokenIds[i]);
            rewardsTotal += rewards;
            feesTotal += fees;
        }

        s.swapper.swapClaimRewardsBatch(
            tokenOut,
            user,
            rewardsTotal,
            feesTotal
        );
    }

    function claimRewardsNodeType(
        address tokenOut,
        address user,
        string memory name
    ) public {
        require(
            user == msg.sender || LibOwners.isOwner(msg.sender),
            "Handler: Dont mess with other claims"
        );
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.mapNt.inserted[name], "Handler: NodeType doesnt exist");

        (uint256 rewardsTotal, uint256 feesTotal) = INodeType(
            s.mapNt.values[name]
        ).claimRewardsAll(user);

        s.swapper.swapClaimRewardsNodeType(
            tokenOut,
            user,
            rewardsTotal,
            feesTotal
        );
    }

    struct _INTERNAL_ApplyWaterpack {
        uint256[] waterpackTokenIds;
        uint256[] amountTokenId;
        uint256 ratioOfGRP;
        string nodeTypeName;
        uint256 plotBoost;
    }

    function applyWaterpackBatch(
        address tokenIn,
        address user,
        uint256[] memory tokenIds,
        string calldata waterpackTypeName,
        uint256[] memory amounts,
        string memory sponso
    ) external {
        require(
            user == msg.sender || LibOwners.isOwner(msg.sender),
            "Handler: Dont mess with other claims"
        );

        AppStorage storage s = LibAppStorage.appStorage();
        require(
            LibWaterpack.hasWaterpackType(waterpackTypeName),
            "Handler: Waterpack type doesn't exists"
        );

        require(tokenIds.length == amounts.length, "Handler: Length mismatch");

        _INTERNAL_ApplyWaterpack memory ctx;
        ctx.waterpackTokenIds = new uint256[](1);
        ctx.amountTokenId = new uint256[](1);

        ctx.ratioOfGRP = LibWaterpack
            .getWaterpackType(waterpackTypeName)
            .ratioOfGRP;

        uint256 totalPrice = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            ctx.nodeTypeName = ISpringNode(s.nft).tokenIdsToType(tokenIds[i]);
            assert(s.mapNt.inserted[ctx.nodeTypeName]);

            ctx.waterpackTokenIds[0] = tokenIds[i];
            ctx.amountTokenId[0] = amounts[i];
            INodeType(s.mapNt.values[ctx.nodeTypeName]).applyWaterpackBatch(
                user,
                ctx.waterpackTokenIds,
                ctx.ratioOfGRP,
                ctx.amountTokenId
            );

            uint256 plotBoost = s
                .plot
                .getPlotTypeByNodeTokenId(tokenIds[i])
                .waterpackGRPBoost;

            INodeType(s.mapNt.values[ctx.nodeTypeName])
                .addPlotAdditionalLifetime({
                    user: user,
                    tokenId: tokenIds[i],
                    amountOfGRP: plotBoost,
                    amount: amounts[i]
                });

            totalPrice +=
                LibWaterpack.getWaterpackPriceByNameAndNodeType(
                    waterpackTypeName,
                    ctx.nodeTypeName
                ) *
                amounts[i];

            emit WaterpackApplied(
                user,
                waterpackTypeName,
                tokenIds[i],
                amounts[i],
                LibWaterpack.getWaterpackPriceByNameAndNodeType(
                    waterpackTypeName,
                    ctx.nodeTypeName
                ) * amounts[i]
            );
        }

        LibAddons.logWaterpacks(
            tokenIds,
            waterpackTypeName,
            block.timestamp,
            amounts
        );

        if (!LibOwners.isOwner(msg.sender)) {
            s.swapper.swapApplyWaterpack(tokenIn, user, totalPrice, sponso);
        }
    }

    function applyFertilizerBatch(
        address tokenIn,
        address user,
        string[] memory nodeTypesNames,
        uint256[][] memory tokenIds,
        string calldata fertilizerTypeName,
        uint256[][] memory amount,
        string memory sponso
    ) external {
        bool isOwner = LibOwners.isOwner(msg.sender);
        require(
            user == msg.sender || isOwner,
            "Handler: Dont mess with other claims"
        );
        AppStorage storage s = LibAppStorage.appStorage();
        require(
            LibFertilizer.hasFertilizerType(fertilizerTypeName),
            "Handler: Fertilizer type doesn't exists"
        );

        require(
            nodeTypesNames.length == tokenIds.length,
            "Handler: Length mismatch"
        );

        Fertilizer memory fertilizer = LibFertilizer.getFertilizerType(
            fertilizerTypeName
        );

        uint256 totalPrice = 0;
        for (uint256 i = 0; i < nodeTypesNames.length; i++) {
            string memory name = nodeTypesNames[i];
            require(s.mapNt.inserted[name], "Handler: NodeType doesnt exist");
            require(
                tokenIds[i].length == amount[i].length,
                "Handler: Length mismatch"
            );

            INodeType(s.mapNt.values[name]).applyFertilizerBatch(
                user,
                tokenIds[i],
                fertilizer.durationEffect,
                fertilizer.rewardBoost,
                amount[i]
            );

            for (uint256 j = 0; j < tokenIds[i].length; j++) {
                uint256 thisPrice = isOwner
                    ? 0
                    : LibFertilizer.getFertilizerPriceByNameAndNodeType(
                        fertilizerTypeName,
                        name
                    ) * amount[i][j];

                totalPrice += thisPrice;

                emit FertilizerApplied(
                    user,
                    fertilizerTypeName,
                    tokenIds[i][j],
                    amount[i][j],
                    thisPrice
                );
            }

            LibAddons.logFertilizers(
                tokenIds[i],
                fertilizerTypeName,
                block.timestamp,
                amount[i],
                isOwner // bypass limits if not owner
            );
        }

        // Calls emitted from owner is considered to be an air drop
        if (totalPrice > 0) {
            s.swapper.swapApplyFertilizer(tokenIn, user, totalPrice, sponso);
        }
    }

    function moveNodesToPlots(
        uint256[] memory plotTokenIds,
        uint256[][] memory nodeTokenIds
    ) external {
        require(
            plotTokenIds.length == nodeTokenIds.length,
            "Handler: Length mismatch"
        );

        AppStorage storage s = LibAppStorage.appStorage();
        s.plot.moveNodesToPlots(msg.sender, nodeTokenIds, plotTokenIds);

        for (uint256 i = 0; i < plotTokenIds.length; i++) {
            for (uint256 j = 0; j < nodeTokenIds[i].length; j++) {
                _onMoveNodeToPlot(
                    msg.sender,
                    nodeTokenIds[i][j],
                    plotTokenIds[i]
                );
            }
        }
    }

    function _setUpNodes(
        string memory name,
        address user,
        uint256 count
    ) private returns (uint256[] memory) {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.mapNt.inserted[name], "Handler: NodeType doesnt exist");

        uint256[] memory tokenIds = ISpringNode(s.nft).generateNfts(
            name,
            user,
            count
        );

        for (uint256 i = 0; i < tokenIds.length; i++)
            LibAdministration.mapTokenSet(s, tokenIds[i], name);

        return tokenIds;
    }

    function _onMoveNodeToPlot(
        address owner,
        uint256 nodeTokenId,
        uint256 plotTokenId
    ) private {
        AppStorage storage s = LibAppStorage.appStorage();
        string memory nodeTypeName = ISpringNode(s.nft).tokenIdsToType(
            nodeTokenId
        );
        require(
            s.mapNt.inserted[nodeTypeName],
            "Handler: NodeType doesn't exist"
        );
        return
            _onMoveNodeToPlot(
                owner,
                nodeTokenId,
                plotTokenId,
                INodeType(s.mapNt.values[nodeTypeName])
            );
    }

    function _onMoveNodeToPlot(
        address owner,
        uint256 nodeTokenId,
        uint256 plotTokenId,
        INodeType nodeType
    ) private {
        AppStorage storage s = LibAppStorage.appStorage();
        nodeType.setPlotAdditionalLifetime(
            owner,
            nodeTokenId,
            s.plot.getPlotTypeByTokenId(plotTokenId).additionalGRPTime
        );
    }
}