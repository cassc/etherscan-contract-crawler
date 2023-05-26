// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC721Membership {
    /// @dev emit when points increase
    event IncreasePoints(
        uint256 tokenId,
        address from,
        uint256 originalPoints,
        uint256 updatedPoints
    );
    /// @dev emit when level update
    event UpdateLevel(
        uint256 tokenId,
        uint256 originalLevel,
        uint256 updatedLevel
    );

    /// @dev increase points of appointed token
    /// @param tokenId the ID of the token to be increased to the points
    /// @param points the points to be increased
    /// @return isUpgraded is the token upgraded after increasing points
    function increasePoints(
        uint256 tokenId,
        uint256 points
    ) external returns (bool isUpgraded);

    /// @dev upgrade appointed token
    /// @param tokenId the ID of the token
    /// @param level the level is going to be setted
    function upgradeToken(uint256 tokenId, uint256 level) external;

    /// @dev set new level's required points and base token URI
    ///   overwrite the last level's property is allowed, the others is not
    /// @param level the new level
    /// @param points the required points of new level
    /// @param baseURI the base token URI of new level
    function setLevel(
        uint256 level,
        uint256 points,
        string calldata baseURI
    ) external;

    /// @dev return the last level
    /// @return the last level
    function lastLevel() external view returns (uint256);

    /// @dev points of appointed token
    /// @param tokenId the ID of appointed token
    /// @return points of appointed token
    function pointsOf(uint256 tokenId) external view returns (uint256);

    /// @dev level of appointed token
    /// @param tokenId the ID of appointed token
    /// @return level of appointed token
    function levelOf(uint256 tokenId) external view returns (uint256);

    /// @dev required points of appointed level
    /// @param level of the query
    /// @return points the required points of the points
    function requiredPointsOf(uint256 level) external view returns (uint256);
}