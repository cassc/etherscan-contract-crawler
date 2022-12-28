//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/INFTType.sol";

abstract contract NFTTypeStats is Ownable {
    using Strings for uint256;

    struct Group {
        string name;
        uint32[] nftTypes;
        uint points;
        uint nftCountRequiredForPoints;
    }

    struct Series {
        string name;
        uint32[] nftTypes;
        uint points;
    }

    uint32 public groupCount;
    uint32 public seriesCount;
    uint32 public attributeCount;
    mapping(uint32 => Group) public nftTypeGroups;
    mapping(uint32 => uint32) public nftTypeToPoints;
    mapping(uint32 => Series) public nftTypeSeries;

    error addressIsZero();
    error tooManyIDs(uint sent, uint max);
    error idOutOfBounds(uint sent, uint max);

    constructor() {}

    function addGroup(
        string calldata _name,
        uint32[] calldata _nftTypes,
        uint _points,
        uint _nftCountRequiredForPoints
    ) external onlyOwner {
        nftTypeGroups[groupCount] = Group({
            name: _name,
            nftTypes: _nftTypes,
            points: _points,
            nftCountRequiredForPoints: _nftCountRequiredForPoints
        });
        ++groupCount;
    }

    function editGroup(
        uint32 groupId,
        string calldata _name,
        uint32[] calldata _nftTypes,
        uint32 _points
    ) external onlyOwner {
        if (groupId >= groupCount)
            revert idOutOfBounds({sent: groupId, max: groupCount - 1});
        nftTypeGroups[groupId].name = _name;
        nftTypeGroups[groupId].nftTypes = _nftTypes;
        nftTypeGroups[groupId].points = _points;
    }

    function addSeries(
        string calldata _name,
        uint32[] calldata _nftTypes,
        uint _points
    ) external onlyOwner {
        nftTypeSeries[seriesCount] = Series({
            name: _name,
            nftTypes: _nftTypes,
            points: _points
        });
        ++seriesCount;
    }

    function editSeries(
        uint32 seriesId,
        string calldata _name,
        uint32[] calldata _nftTypes,
        uint32 _points
    ) external onlyOwner {
        if (seriesId >= seriesCount)
            revert idOutOfBounds({sent: seriesId, max: seriesCount - 1});
        nftTypeSeries[seriesId].name = _name;
        nftTypeSeries[seriesId].nftTypes = _nftTypes;
        nftTypeSeries[seriesId].points = _points;
    }

    function setNFTTypePoints(uint32 nftType, uint32 value) external onlyOwner {
        nftTypeToPoints[nftType] = value;
    }
}