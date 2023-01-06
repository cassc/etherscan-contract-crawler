//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import ".././interfaces/INftType.sol";

abstract contract NftTypeStatsUpgradeable is Initializable, OwnableUpgradeable {
    using StringsUpgradeable for uint256;

    // factory: p1 = seconds to generate; p2 = nft type to mint
    struct NftInfo {
        uint256 p1;
        uint256 p2;
        uint256 p3;
        string pString1;
        string pString2;
    }

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
    mapping(uint256 => NftInfo) public nftTypeToNftInfos;
    mapping(uint32 => Series) public nftTypeSeries;
    mapping(uint32 => uint32) public nftTypeToPoints;

    error AddressIsZero();
    error IdOutOfBounds(uint sent, uint max);
    error InvalidNum();
    error TooManyIds(uint sent, uint max);

    function _nftTypestatsUpgradeable_init() internal onlyInitializing {
        _nftTypestatsUpgradeable_init_unchained();
    }

    function _nftTypestatsUpgradeable_init_unchained()
        internal
        onlyInitializing
    {
        OwnableUpgradeable.__Ownable_init();
    }

    function addGroup(
        string calldata name,
        uint32[] calldata nftTypes,
        uint points,
        uint _nftCountRequiredForPoints
    ) external onlyOwner {
        nftTypeGroups[groupCount] = Group({
            name: name,
            nftTypes: nftTypes,
            points: points,
            nftCountRequiredForPoints: _nftCountRequiredForPoints
        });
        ++groupCount;
    }

    function addSeries(
        string calldata name,
        uint32[] calldata nftTypes,
        uint points
    ) external onlyOwner {
        nftTypeSeries[seriesCount] = Series({
            name: name,
            nftTypes: nftTypes,
            points: points
        });
        ++seriesCount;
    }

    function editGroup(
        uint32 groupId,
        string calldata name,
        uint32[] calldata nftTypes,
        uint32 points
    ) external onlyOwner {
        if (groupId >= groupCount)
            revert IdOutOfBounds({sent: groupId, max: groupCount - 1});
        nftTypeGroups[groupId].name = name;
        nftTypeGroups[groupId].nftTypes = nftTypes;
        nftTypeGroups[groupId].points = points;
    }

    function editSeries(
        uint32 seriesId,
        string calldata name,
        uint32[] calldata nftTypes,
        uint32 points
    ) external onlyOwner {
        if (seriesId >= seriesCount)
            revert IdOutOfBounds({sent: seriesId, max: seriesCount - 1});
        nftTypeSeries[seriesId].name = name;
        nftTypeSeries[seriesId].nftTypes = nftTypes;
        nftTypeSeries[seriesId].points = points;
    }

    function setNftInfo(
        uint256 id,
        uint256 p1,
        uint256 p2,
        uint256 p3,
        string memory _pString1,
        string memory _pString2
    ) public onlyOwner {
        nftTypeToNftInfos[id] = NftInfo({
            p1: p1,
            p2: p2,
            p3: p3,
            pString1: _pString1,
            pString2: _pString2
        });
    }

    error InconsistentArrayLengths();

    function setNftInfoBatch(
        uint256[] calldata ids,
        uint256[] calldata p1s,
        uint256[] calldata p2s,
        uint256[] calldata p3s,
        string[] calldata pString1s,
        string[] calldata pString2s
    ) external onlyOwner {
        if (
            ids.length != p1s.length ||
            ids.length != p2s.length ||
            ids.length != p3s.length ||
            ids.length != pString1s.length ||
            ids.length != pString2s.length
        ) revert InconsistentArrayLengths();
        for (uint256 x; x < ids.length; x++) {
            setNftInfo(
                ids[x],
                p1s[x],
                p2s[x],
                p3s[x],
                pString1s[x],
                pString2s[x]
            );
        }
    }

    function setNFtStringInfo(
        uint256 id,
        uint256 num,
        string memory value
    ) external onlyOwner {
        if (num > 3) revert InvalidNum();
        NftInfo storage nftInfo = nftTypeToNftInfos[id];
        if (num == 1) {
            nftInfo.pString1 = value;
        } else {
            nftInfo.pString2 = value;
        }
    }

    function setNftTypePoints(uint32 nftType, uint32 value) external onlyOwner {
        nftTypeToPoints[nftType] = value;
    }

    function setNftNumericInfo(
        uint256 id,
        uint256 num,
        uint256 value
    ) external onlyOwner {
        if (num > 3) revert InvalidNum();
        NftInfo storage nftInfo = nftTypeToNftInfos[id];
        if (num == 1) {
            nftInfo.p1 = value;
        } else if (num == 2) {
            nftInfo.p2 = value;
        } else {
            nftInfo.p3 = value;
        }
    }

    function _getNftTypeNumericInfo(
        uint256 id,
        uint256 num
    ) internal view returns (uint256) {
        if (num > 3) revert InvalidNum();
        NftInfo storage nftInfo = nftTypeToNftInfos[id];
        if (num == 1) {
            return nftInfo.p1;
        } else if (num == 2) {
            return nftInfo.p2;
        } else {
            return nftInfo.p3;
        }
    }

    function _getAllNftTypeNumericInfo(
        uint256 id
    ) internal view returns (uint256, uint256, uint256) {
        NftInfo storage nftInfo = nftTypeToNftInfos[id];
        return (nftInfo.p1, nftInfo.p2, nftInfo.p3);
    }
}