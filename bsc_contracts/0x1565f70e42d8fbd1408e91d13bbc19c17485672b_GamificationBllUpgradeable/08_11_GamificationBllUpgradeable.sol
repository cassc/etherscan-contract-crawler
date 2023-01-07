//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/INftType.sol";
import "./utils/ProxyableUpgradeable.sol";
import "./NftTypeStatsUpgradeable.sol";

contract GamificationBllUpgradeable is
    Initializable,
    OwnableUpgradeable,
    ProxyableUpgradeable,
    NftTypeStatsUpgradeable
{
    using StringsUpgradeable for uint256;

    INftType public nftContract;

    error InconsistenArrayLengths();

    function initialize(address _nftContract) public initializer {
        if (_nftContract == address(0)) revert AddressIsZero();
        nftContract = INftType(_nftContract);
        OwnableUpgradeable.__Ownable_init();
    }

    function getMultipleGroupPointsForAddress(
        address user,
        uint32[] memory groupIds
    ) external view returns (uint256 points) {
        for (uint x; x < groupIds.length; x++) {
            points += getGroupPointsForAddress(user, groupIds[x]);
        }
    }

    function getTokenIdNumericInfo(
        uint32 tokenId,
        uint256 num
    ) external view returns (uint256) {
        return
            _getNftTypeNumericInfo(nftContract.tokenIdToNftType(tokenId), num);
    }

    function getAllTokenIdNumericInfo(
        uint32 tokenId
    ) external view returns (uint256, uint256, uint256) {
        return _getAllNftTypeNumericInfo(nftContract.tokenIdToNftType(tokenId));
    }

    function getAllNftTypeNumericInfo(uint32 nftType) external view returns(uint256, uint256, uint256) {
        return _getAllNftTypeNumericInfo(nftType);
    }

    function getPointsForSeries(
        uint32 seriesId,
        uint32[] calldata tokenIds
    ) external view returns (uint256) {
        return
            checkSeriesForTokenIds(seriesId, tokenIds)
                ? nftTypeSeries[seriesId].points
                : 0;
    }

    function getPointsForTokenId(uint32 nftID) external view returns (uint256) {
        uint32 nftType = nftContract.tokenIdToNftType(nftID);
        return nftTypeToPoints[nftType];
    }

    // could run out of gas if user has a lot of Nfts
    // suggest getting token IDs off-chain and sending in batches through getPointsForTokenIds
    function getPointsForUser(
        address user
    ) external view returns (uint256 points) {
        uint32[] memory nftTypes = nftContract.getNftTypesForTokenIds(
            nftContract.getNftTypesForUser(user)
        );
        for (uint x; x < nftTypes.length; x++) {
            points += nftTypeToPoints[nftTypes[x]];
        }
        return points;
    }

    function getStakingPointsForUser(
        address user
    ) external view returns (uint256 points) {
        uint32[] memory nftTypes = nftContract.getNftTypesForTokenIds(
            nftContract.getNftTypesForUser(user)
        );
        for (uint x; x < nftTypes.length; x++) {
            points += nftTypeToPoints[nftTypes[x]];
        }
        return points;
    }

    function setNftContract(address value) external onlyOwner {
        if (value == address(0)) revert AddressIsZero();
        nftContract = INftType(value);
    }

    function checkSeriesForTokenIds(
        uint32 seriesId,
        uint32[] calldata tokenIds
    ) public view returns (bool) {
        Series memory series = nftTypeSeries[seriesId];
        if (series.nftTypes.length != tokenIds.length)
            revert InconsistenArrayLengths();
        uint32[] memory nftTypes = nftContract.getNftTypesForTokenIds(tokenIds);
        for (uint x; x < nftTypes.length; x++) {
            if (nftTypes[x] != series.nftTypes[x]) return false;
        }
        return true;
    }

    function getGroupPointsForAddress(
        address user,
        uint32 groupId
    ) public view returns (uint256 points) {
        Group memory group = nftTypeGroups[groupId];
        points = nftContract.getNftTypeCounts(user, group.nftTypes) >=
            group.nftCountRequiredForPoints
            ? group.points
            : 0;
    }

    function getPointsForTokenIds(
        uint32[] calldata nftIDs
    ) public view returns (uint256[] memory) {
        uint256[] memory points = new uint256[](nftIDs.length);
        uint32[] memory nftTypes = nftContract.getNftTypesForTokenIds(nftIDs);
        for (uint x; x < nftTypes.length; x++) {
            points[x] = nftTypeToPoints[nftTypes[x]];
        }
        return points;
    }

    function getTotalPointsForTokenIds(
        uint32[] calldata nftIDs
    ) public view returns (uint256 points) {
        uint32[] memory nftTypes = nftContract.getNftTypesForTokenIds(nftIDs);
        for (uint x; x < nftTypes.length; x++) {
            points += nftTypeToPoints[nftTypes[x]];
        }
        return points;
    }
}