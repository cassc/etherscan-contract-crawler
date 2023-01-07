//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IGamificationBll {
    function getMultipleGroupPointsForAddress(
        address user,
        uint32[] memory groupIds
    ) external view returns (uint256 points);

    function getTokenIdNumericInfo(
        uint32 tokenId,
        uint256 num
    ) external view returns (uint256);

    function getAllTokenIdNumericInfo(
        uint32 tokenId
    ) external view returns (uint256, uint256, uint256);

    function getPointsForSeries(
        uint32 seriesId,
        uint32[] calldata tokenIds
    ) external view returns (uint256);

    function getPointsForTokenId(uint32 nftID) external view returns (uint256);

    function getPointsForUser(
        address user
    ) external view returns (uint256 points);

    function getStakingPointsForUser(
        address user
    ) external view returns (uint256 points);

    function setNftContract(address value) external;

    function checkSeriesForTokenIds(
        uint32 seriesId,
        uint32[] calldata tokenIds
    ) external view returns (bool);

    function getGroupPointsForAddress(
        address user,
        uint32 groupId
    ) external view returns (uint256 points);

    function getPointsForTokenIds(
        uint32[] calldata nftIDs
    ) external view returns (uint256[] memory);

    function getTotalPointsForTokenIds(
        uint32[] calldata nftIDs
    ) external view returns (uint256 points);

    function addGroup(
        string calldata name,
        uint32[] calldata nftTypes,
        uint points,
        uint _nftCountRequiredForPoints
    ) external;

    function addSeries(
        string calldata name,
        uint32[] calldata nftTypes,
        uint points
    ) external;

    function editSeries(
        uint32 seriesId,
        string calldata name,
        uint32[] calldata nftTypes,
        uint32 points
    ) external;

    function setNftInfo(
        uint256 id,
        uint256 p1,
        uint256 p2,
        uint256 p3,
        string memory _pString1,
        string memory _pString2
    ) external;

    function setNFtStringInfo(
        uint256 id,
        uint256 num,
        string memory value
    ) external;

    function setNftTypePoints(uint32 nftType, uint32 value) external;

    function setNftNumericInfo(uint256 id, uint256 num, uint256 value) external;

    function getAllNftTypeNumericInfo(
        uint32 nftType
    ) external view returns (uint256, uint256, uint256);
}