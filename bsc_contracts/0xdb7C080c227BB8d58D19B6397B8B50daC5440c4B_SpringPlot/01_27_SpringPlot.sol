// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./OwnersUpgradeable.sol";
import "./SpringNode.sol";
import "./libraries/NodeRewards.sol";
import "./HandlerAwareUpgradeable.sol";
import "./ISpringNode.sol";
import "./ISpringPlot.sol";

struct PlotTypeSpec {
    uint256 price;
    uint256 maxNodes;
    string[] allowedNodeTypes;
    uint256 additionalGRPTime;
    uint256 waterpackGRPBoost;
}

struct PlotInstance {
    uint256[] nodeTokenIds;
    mapping(uint256 => uint256) nodeTokenIdsToIndexPlusOne;
}

/// @notice A plot houses trees (nodes) and adds additional lifetime to the
contract SpringPlot is
    ERC721EnumerableUpgradeable,
    OwnersUpgradeable,
    ISpringPlot,
    HandlerAwareUpgradeable
{
    using Counters for Counters.Counter;
    using Percentages for uint256;

    ISpringNode private _springNode;

    /// @dev Incremented at construction time, so the first plot is 1. Therefore
    /// we can use 0 as a null value, useful for mappings.
    Counters.Counter private _tokenIdCounter;

    struct PlotTypes {
        string[] names;
        mapping(string => PlotTypeSpec) types;
        mapping(string => bool) exists;
    }

    PlotTypes internal _plotTypes;

    /// @dev As the plot token IDs starts at 1, we can use 0 as a null value.
    /// We can also consider that any node mapped to a null value means that
    /// the node doesn't exist.
    mapping(uint256 => uint256) public nodeTokenIdToPlotTokenId;

    mapping(uint256 => PlotInstance) internal _instances;
    mapping(uint256 => string) public tokenIdToType;

    mapping(address => mapping(string => uint256))
        internal _userToPlotTypeToTokenId;

    string internal _defaultPlotTypeName;

    function initialize(
        IHandler _handler,
        ISpringNode springNode,
        string memory defaultPlotTypeName,
        uint256 defaultMaxNodes
    ) external initializer {
        __SpringPlot_init(
            _handler,
            springNode,
            defaultPlotTypeName,
            defaultMaxNodes
        );
    }

    function __SpringPlot_init(
        IHandler _handler,
        ISpringNode springNode,
        string memory defaultPlotTypeName,
        uint256 defaultMaxNodes
    ) internal onlyInitializing {
        __HandlerAware_init_unchained(_handler);
        __Owners_init_unchained();
        __ERC721_init_unchained("Spring Plot", "SP");
        __SpringPlot_init_unchained(
            springNode,
            defaultPlotTypeName,
            defaultMaxNodes
        );
    }

    function __SpringPlot_init_unchained(
        ISpringNode springNode,
        string memory defaultPlotTypeName,
        uint256 defaultMaxNodes
    ) internal onlyInitializing {
        _springNode = springNode;
        _tokenIdCounter.increment();
        _defaultPlotTypeName = defaultPlotTypeName;
        _setPlotType(
            defaultPlotTypeName,
            PlotTypeSpec({
                price: 0,
                maxNodes: defaultMaxNodes,
                allowedNodeTypes: new string[](0),
                additionalGRPTime: 0,
                waterpackGRPBoost: 0
            })
        );
    }

    function createNewPlot(address user, string memory plotTypeName)
        public
        onlyHandler
        returns (uint256, uint256)
    {
        require(user != address(0), "SpringPlot: Null address");
        (uint256 tokenId, PlotTypeSpec storage plotType) = _createNewPlot(
            user,
            plotTypeName
        );
        uint256 price = plotType.price;
        return (price, tokenId);
    }

    function moveNodeToPlot(
        address user,
        uint256 nodeTokenId,
        uint256 plotTokenId
    ) public onlyHandler {
        if (plotTokenId == 0) {
            plotTokenId = findOrCreateDefaultPlot(user);
        }

        _moveNodeToPlot(nodeTokenId, plotTokenId);
        require(
            _hasPlotValidCapacity(plotTokenId),
            "SpringPlot: Plot reached max capacity"
        );
    }

    function moveNodesToPlots(
        address user,
        uint256[][] memory nodeTokenIds,
        uint256[] memory plotTokenIds
    ) public onlyHandler {
        require(
            nodeTokenIds.length == plotTokenIds.length,
            "SpringPlot: nodeTokenIds and plotTokenIds must have the same length"
        );

        for (uint256 i = 0; i < plotTokenIds.length; i++) {
            if (plotTokenIds[i] == 0) {
                plotTokenIds[i] = findOrCreateDefaultPlot(user);
            }

            for (uint256 j = 0; j < nodeTokenIds[i].length; j++) {
                _moveNodeToPlot(nodeTokenIds[i][j], plotTokenIds[i]);
            }
        }
        for (uint256 i = 0; i < plotTokenIds.length; i++) {
            require(
                _hasPlotValidCapacity(plotTokenIds[i]),
                "SpringPlot: Plot reached max capacity"
            );
        }
    }

    function findOrCreateDefaultPlot(address user)
        public
        onlyHandler
        returns (uint256)
    {
        require(user != address(0), "SpringPlot: Null address");
        uint256 defaultPlotTokenId = _userToPlotTypeToTokenId[user][
            _defaultPlotTypeName
        ];
        if (
            defaultPlotTokenId == 0 ||
            _hasPlotReachedMaxCapacity(defaultPlotTokenId)
        ) {
            (uint256 totalPrice, uint256 tokenId) = createNewPlot(
                user,
                _defaultPlotTypeName
            );
            assert(totalPrice == 0);
            return tokenId;
        }

        return defaultPlotTokenId;
    }

    function setPlotType(
        string memory plotTypeName,
        uint256 price,
        uint256 maxNodes,
        string[] memory allowedNodeTypes,
        uint256 additionalGRPTime,
        uint256 waterpackGRPBoost
    ) external onlyHandler {
        _setPlotType(
            plotTypeName,
            PlotTypeSpec({
                price: price,
                maxNodes: maxNodes,
                allowedNodeTypes: allowedNodeTypes,
                additionalGRPTime: additionalGRPTime,
                waterpackGRPBoost: waterpackGRPBoost
            })
        );
    }

    //====== View API ========================================================//

    function tokensOfOwner(address user)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](balanceOf(user));
        for (uint256 i = 0; i < balanceOf(user); i++)
            result[i] = tokenOfOwnerByIndex(user, i);
        return result;
    }

    function getPlotTypeSize() public view returns (uint256) {
        return _plotTypes.names.length;
    }

    function getPlotTypeBetweenIndexes(uint256 startIndex, uint256 endIndex)
        public
        view
        returns (PlotTypeView[] memory)
    {
        require(
            startIndex <= endIndex,
            "SpringPlot: startIndex must be less than or equal to endIndex"
        );
        require(
            endIndex <= _plotTypes.names.length,
            "SpringPlot: endIndex must be less than or equal to the number of plot types"
        );

        PlotTypeView[] memory plotTypes = new PlotTypeView[](
            endIndex - startIndex
        );
        for (uint256 i = startIndex; i < endIndex; i++) {
            string memory plotTypeName = _plotTypes.names[i];
            PlotTypeSpec memory plotTypeSpec = _getPlotType(plotTypeName);
            plotTypes[i - startIndex] = PlotTypeView({
                name: plotTypeName,
                price: plotTypeSpec.price,
                maxNodes: plotTypeSpec.maxNodes,
                allowedNodeTypes: plotTypeSpec.allowedNodeTypes,
                additionalGRPTime: plotTypeSpec.additionalGRPTime,
                waterpackGRPBoost: plotTypeSpec.waterpackGRPBoost
            });
        }

        return plotTypes;
    }

    function getPlotTypeByTokenId(uint256 tokenId)
        public
        view
        returns (PlotTypeView memory)
    {
        require(_exists(tokenId), "SpringPlot: nonexistant token ID");
        string memory plotTypeName = tokenIdToType[tokenId];
        PlotTypeSpec memory plotTypeSpec = _getPlotType(plotTypeName);

        return
            PlotTypeView({
                name: plotTypeName,
                price: plotTypeSpec.price,
                maxNodes: plotTypeSpec.maxNodes,
                allowedNodeTypes: plotTypeSpec.allowedNodeTypes,
                additionalGRPTime: plotTypeSpec.additionalGRPTime,
                waterpackGRPBoost: plotTypeSpec.waterpackGRPBoost
            });
    }

    function getPlotByTokenId(uint256 tokenId)
        public
        view
        returns (PlotInstanceView memory)
    {
        require(_exists(tokenId), "SpringPlot: nonexistant token ID");
        PlotInstance storage plot = _instances[tokenId];
        return
            PlotInstanceView({
                plotType: tokenIdToType[tokenId],
                owner: ownerOf(tokenId),
                nodeTokenIds: plot.nodeTokenIds
            });
    }

    function getPlotTypeByNodeTokenId(uint256 nodeTokenId)
        public
        view
        returns (PlotTypeView memory)
    {
        require(
            _nodeTokenIdExists(nodeTokenId),
            "SpringPlot: nonexistant node token ID"
        );
        uint256 plotTokenId = nodeTokenIdToPlotTokenId[nodeTokenId];
        return getPlotTypeByTokenId(plotTokenId);
    }

    //====== Internal API ====================================================//

    function _setPlotType(string memory name, PlotTypeSpec memory spec)
        internal
    {
        // If this check is installed again, update the tests accordingly in
        // plots.ts, as the "should allow only one plot type per user" check
        // is based on the ability to update a plot type.
        // require(!_plotTypes.exists[name], "SpringPlot: type already exists");
        _plotTypes.types[name] = spec;
        if(!_plotTypes.exists[name]) {
            _plotTypes.exists[name] = true;
            _plotTypes.names.push(name);
        }
    }

    function _safeGetPlotType(string memory name)
        internal
        view
        returns (bool exists, PlotTypeSpec storage spec)
    {
        exists = _plotTypes.exists[name];
        spec = _plotTypes.types[name];
    }

    function _getPlotType(string memory name)
        internal
        view
        returns (PlotTypeSpec storage)
    {
        require(_plotTypes.exists[name], "SpringPlot: nonexistant plot type");
        return _plotTypes.types[name];
    }

    function _moveNodeToPlot(
        uint256 nodeTokenId,
        uint256 plotTokenId
    ) internal {
        require(
            _nodeTokenIdExists(nodeTokenId),
            "SpringPlot: Node does not exist"
        );
        require(_exists(plotTokenId), "SpringPlot: nonexistant token ID");

        PlotTypeSpec storage plotType = _getPlotType(
            tokenIdToType[plotTokenId]
        );
        string memory nodeType = _springNode.tokenIdsToType(nodeTokenId);
        bool hasAllowedType = plotType.allowedNodeTypes.length == 0;
        for (uint256 i = 0; i < plotType.allowedNodeTypes.length; i++) {
            string memory currentAllowedType = plotType.allowedNodeTypes[i];
            if (_compareStrings(currentAllowedType, nodeType)) {
                hasAllowedType = true;
                break;
            }
        }

        require(hasAllowedType, "SpringPlot: Node type not allowed");

        (
            uint256 oldPlotTokenId,
            PlotInstance storage oldPlot
        ) = _safeGetPlotFromNodeTokenId(nodeTokenId);

        if (oldPlotTokenId != 0) {
            uint256 indexPlusOne = oldPlot.nodeTokenIdsToIndexPlusOne[
                nodeTokenId
            ];
            if (indexPlusOne != 0) {
                uint256 lastIndex = oldPlot.nodeTokenIds.length - 1;
                if (lastIndex != indexPlusOne - 1) {
                    uint256 movedTokenId = oldPlot.nodeTokenIds[lastIndex];
                    oldPlot.nodeTokenIds[indexPlusOne - 1] = movedTokenId;
                    oldPlot.nodeTokenIdsToIndexPlusOne[
                        movedTokenId
                    ] = indexPlusOne;
                }

                oldPlot.nodeTokenIds.pop();
                oldPlot.nodeTokenIdsToIndexPlusOne[nodeTokenId] = 0;
            }
        }

        PlotInstance storage newPlot = _instances[plotTokenId];
        if (newPlot.nodeTokenIdsToIndexPlusOne[nodeTokenId] == 0) {
            newPlot.nodeTokenIds.push(nodeTokenId);
            newPlot.nodeTokenIdsToIndexPlusOne[nodeTokenId] = newPlot
                .nodeTokenIds
                .length;
            nodeTokenIdToPlotTokenId[nodeTokenId] = plotTokenId;
        }
    }

    function _nodeTokenIdExists(uint256 nodeTokenId)
        internal
        view
        returns (bool)
    {
        return bytes(_getNodeTypeFromTokenId(nodeTokenId)).length != 0;
    }

    function _getNodeTypeFromTokenId(uint256 nodeTokenId)
        internal
        view
        returns (string memory)
    {
        return _springNode.tokenIdsToType(nodeTokenId);
    }

    function _safeGetPlotFromNodeTokenId(uint256 nodeTokenId)
        internal
        view
        returns (uint256 plotTokenId, PlotInstance storage plot)
    {
        plotTokenId = nodeTokenIdToPlotTokenId[nodeTokenId];
        plot = _instances[plotTokenId];
    }

    function _createNewPlot(address owner, string memory plotTypeName)
        internal
        returns (uint256 tokenId, PlotTypeSpec storage plotType)
    {
        bool plotTypeExists;
        (plotTypeExists, plotType) = _safeGetPlotType(plotTypeName);
        require(plotTypeExists, "SpringPlot: nonexistant plot type");

        tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(owner, tokenId);
        tokenIdToType[tokenId] = plotTypeName;
        _userToPlotTypeToTokenId[owner][plotTypeName] = tokenId;
    }

    function _hasPlotReachedMaxCapacity(uint256 plotTokenId)
        internal
        view
        returns (bool)
    {
        require(_exists(plotTokenId), "SpringPlot: nonexistant token ID");
        PlotInstance storage plot = _instances[plotTokenId];
        PlotTypeSpec storage plotType = _plotTypes.types[
            tokenIdToType[plotTokenId]
        ];
        return plot.nodeTokenIds.length >= plotType.maxNodes;
    }

    function _hasPlotValidCapacity(uint256 plotTokenId)
        internal
        view
        returns (bool)
    {
        require(_exists(plotTokenId), "SpringPlot: nonexistant token ID");
        PlotInstance storage plot = _instances[plotTokenId];
        PlotTypeSpec storage plotType = _plotTypes.types[
            tokenIdToType[plotTokenId]
        ];
        return plot.nodeTokenIds.length <= plotType.maxNodes;
    }

    function _compareStrings(string memory a, string memory b)
        private
        pure
        returns (bool)
    {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        IHandler(_handler).plotTransferFrom(from, to, tokenId);
    }
}