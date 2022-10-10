// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

struct PlotTypeView {
    string name;
    uint256 maxNodes;
    uint256 price;
    string[] allowedNodeTypes;
    uint256 additionalGRPTime;
    uint256 waterpackGRPBoost;
}

struct PlotInstanceView {
    string plotType;
    address owner;
    uint256[] nodeTokenIds;
}

/// @notice A plot houses trees (nodes) and adds additional lifetime to the
/// nodes it owns.
/// @dev Token IDs should start at `1`, so we can use `0` as a null value.
interface ISpringPlot is IERC721EnumerableUpgradeable {
    function createNewPlot(address user, string memory plotTypeName)
        external
        returns (uint256 price, uint256 tokenId);

    function moveNodeToPlot(
        address user,
        uint256 nodeTokenId,
        uint256 plotTokenId
    ) external;

    function moveNodesToPlots(
        address user,
        uint256[][] memory nodeTokenId,
        uint256[] memory plotTokenId
    ) external;

    function setPlotType(
        string memory name,
        uint256 price,
        uint256 maxNodes,
        string[] memory allowedNodeTypes,
        uint256 additionalGRPTime,
        uint256 waterpackGRPBoost
    ) external;

    /// @dev Returns the plot type of an instanciated plot, given its `tokenId`.
    /// Reverts if the plot doesn't exist.
    function getPlotTypeByTokenId(uint256 tokenId)
        external
        view
        returns (PlotTypeView memory);

    function findOrCreateDefaultPlot(address user)
        external
        returns (uint256 tokenId);

    function getPlotTypeByNodeTokenId(uint256 tokenId)
        external
        view
        returns (PlotTypeView memory);

    // /// @dev Returns the total amount of plot types.
    // function getPlotTypeSize() external view returns (uint256 plotTypeAmount);

    // /// @dev Returns the plot type at a given `index`. Use along with
    // /// {getPlotTypeSize} to enumerate all plot types, or {getPlotTypes}.
    // function getPlotTypeByIndex(uint256 index) external view
    //     returns (PlotTypeView memory);

    // /// @dev Returns the plot type with a given `name`. Reverts if the plot type
    // /// doesn't exist.
    // function getPlotTypeByName(string memory name) external view
    //     returns (PlotTypeView memory);

    // /// @dev Returns the list of all enumerable plot types.
    // function getPlotTypes() external view returns (PlotTypeView[] memory);

    // /// @dev Returns the number of plots detained by a given user.
    // function getPlotsOfUserSize(address user) external view
    //     returns (uint256 plotAmount);

    /// @dev Returns the plot instance of a given token id. Reverts if the plot
    /// doesn't exist.
    function getPlotByTokenId(uint256 tokenId)
        external
        view
        returns (PlotInstanceView memory);

    // /// @dev Returns the plot instance of a given user at a given `index`. Use
    // /// along with {getPlotsOfUserSize} to enumerate all plots of a user, or
    // /// {getPlotsOfUser}.
    // function getPlotsOfUserByIndex(address user, uint256 index) external view
    //     returns (PlotTypeInstance memory);

    // /// @dev Returns the list of all plots of a given user.
    // function getPlotsOfUser(address user) external view
    //     returns (PlotTypeInstance[] memory);

    // /// @dev Returns the token ID of the next available plot of a given type for
    // /// a given user, or `0` if no plot is available.
    // function getPlotTokenIdOfNextEmptyOfType(address user, string memory plotType) external view
    //     returns (uint256 plotTokenIdOrZero);

    // /// @dev Returns the token ID of the plot housing the given node. Reverts if
    // /// the node token ID is not attributed.
    // function getPlotTokenIdOfNodeTokenId(uint256 nodeTokenId) external view
    //     returns (uint256 plotTokenId);
}