//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/INFTType.sol";
import "./utils/ProxyableUpgradeable.sol";
import "./NFTTypeStatsUpgradeable.sol";

contract GamificationBLLUpgradeable is
    Initializable,
    OwnableUpgradeable,
    ProxyableUpgradeable,
    NFTTypeStatsUpgradeable
{
    using StringsUpgradeable for uint256;

    INFTType public nftContract;

    error InconsistenArrayLengths();

    function initialize(address _nftContract) public initializer {
        if (_nftContract == address(0)) revert addressIsZero();
        nftContract = INFTType(_nftContract);
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

    function getPointsForTokenID(uint32 nftID) external view returns (uint256) {
        uint32 nftType = nftContract.tokenIDToNFTType(nftID);
        return nftTypeToPoints[nftType];
    }

    function getPointsForTokenIDs(uint32[] calldata nftIDs)
        public
        view
        returns (uint256 points)
    {
        uint32[] memory nftTypes = nftContract.getNFTTypesForTokenIDs(nftIDs);
        for (uint x; x < nftTypes.length; x++) {
            points += nftTypeToPoints[nftTypes[x]];
        }
        return points;
    }

    // could run out of gas if user has a lot of NFTs
    // suggest getting token IDs off-chain and sending in batches through getPointsForTokenIDs
    function getPointsForUser(address user)
        external
        view
        returns (uint256 points)
    {
        uint32[] memory nftTypes = nftContract.getNFTTypesForTokenIDs(
            nftContract.getNFTTypesForUser(user)
        );
        for (uint x; x < nftTypes.length; x++) {
            points += nftTypeToPoints[nftTypes[x]];
        }
        return points;
    }

    function getStakingPointsForUser(address user)
        external
        view
        returns (uint256 points)
    {
        uint32[] memory nftTypes = nftContract.getNFTTypesForTokenIDs(
            nftContract.getNFTTypesForUser(user)
        );
        for (uint x; x < nftTypes.length; x++) {
            points += nftTypeToPoints[nftTypes[x]];
        }
        return points;
    }

    function setNFTContract(address value) external onlyOwner {
        if (value == address(0)) revert addressIsZero();
        nftContract = INFTType(value);
    }

    function getGroupPointsForAddress(address user, uint32 groupId)
        public
        view
        returns (uint256 points)
    {
        Group memory group = nftTypeGroups[groupId];
        points = nftContract.getNFTTypeCounts(user, group.nftTypes) >=
            group.nftCountRequiredForPoints
            ? group.points
            : 0;
    }

    function checkSeriesForTokenIDs(uint32 seriesId, uint32[] calldata tokenIds)
        public
        view
        returns (bool)
    {
        Series memory series = nftTypeSeries[seriesId];
        if (series.nftTypes.length != tokenIds.length)
            revert InconsistenArrayLengths();
        uint32[] memory nftTypes = nftContract.getNFTTypesForTokenIDs(tokenIds);
        for (uint x; x < nftTypes.length; x++) {
            if (nftTypes[x] != series.nftTypes[x]) return false;
        }
        return true;
    }

    function getPointsForSeries(uint32 seriesId, uint32[] calldata tokenIds)
        external
        view
        returns (uint256)
    {
        return
            checkSeriesForTokenIDs(seriesId, tokenIds)
                ? nftTypeSeries[seriesId].points
                : 0;
    }
}