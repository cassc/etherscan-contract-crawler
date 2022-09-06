/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

interface ICoverData {
    function hasCoverOwner(address owner) external view returns (bool);

    function addCoverOwner(address owner) external;

    function getAllCoverOwnerList() external view returns (address[] memory);

    function getAllCoverCount() external view returns (uint256);

    function getCoverCount(address owner) external view returns (uint256);

    function increaseCoverCount(address owner) external returns (uint256);

    function setNewCoverDetails(
        address owner,
        uint256 coverId,
        uint256 productId,
        uint256 amount,
        address currency,
        uint256 beginTimestamp,
        uint256 endTimestamp,
        uint256 maxClaimableTimestamp,
        uint256 estimatedPremium
    ) external;

    function getCoverBeginTimestamp(address owner, uint256 coverId)
        external
        view
        returns (uint256);

    function setCoverBeginTimestamp(
        address owner,
        uint256 coverId,
        uint256 timestamp
    ) external;

    function getCoverEndTimestamp(address owner, uint256 coverId)
        external
        view
        returns (uint256);

    function setCoverEndTimestamp(
        address owner,
        uint256 coverId,
        uint256 timestamp
    ) external;

    function getCoverMaxClaimableTimestamp(address owner, uint256 coverId)
        external
        view
        returns (uint256);

    function setCoverMaxClaimableTimestamp(
        address owner,
        uint256 coverId,
        uint256 timestamp
    ) external;

    function getCoverProductId(address owner, uint256 coverId)
        external
        view
        returns (uint256);

    function setCoverProductId(
        address owner,
        uint256 coverId,
        uint256 productId
    ) external;

    function getCoverCurrency(address owner, uint256 coverId)
        external
        view
        returns (address);

    function setCoverCurrency(
        address owner,
        uint256 coverId,
        address currency
    ) external;

    function getCoverAmount(address owner, uint256 coverId)
        external
        view
        returns (uint256);

    function setCoverAmount(
        address owner,
        uint256 coverId,
        uint256 amount
    ) external;

    function getAdjustedCoverStatus(address owner, uint256 coverId)
        external
        view
        returns (uint256);

    function setCoverStatus(
        address owner,
        uint256 coverId,
        uint256 coverStatus
    ) external;

    function isCoverClaimable(address owner, uint256 coverId)
        external
        view
        returns (bool);

    function getCoverEstimatedPremiumAmount(address owner, uint256 coverId)
        external
        view
        returns (uint256);

    function setCoverEstimatedPremiumAmount(
        address owner,
        uint256 coverId,
        uint256 amount
    ) external;

    function getBuyCoverInsurTokenEarned(address owner)
        external
        view
        returns (uint256);

    function increaseBuyCoverInsurTokenEarned(address owner, uint256 amount)
        external;

    function decreaseBuyCoverInsurTokenEarned(address owner, uint256 amount)
        external;

    function getTotalInsurTokenRewardAmount() external view returns (uint256);

    function increaseTotalInsurTokenRewardAmount(uint256 amount) external;

    function decreaseTotalInsurTokenRewardAmount(uint256 amount) external;

    function getCoverRewardPctg(address owner, uint256 coverId)
        external
        view
        returns (uint256);

    function setCoverRewardPctg(
        address owner,
        uint256 coverId,
        uint256 rewardPctg
    ) external;

    function getCoverClaimedAmount(address owner, uint256 coverId)
        external
        view
        returns (uint256);

    function increaseCoverClaimedAmount(
        address owner,
        uint256 coverId,
        uint256 amount
    ) external;

    function getCoverReferralRewardPctg(address owner, uint256 coverId)
        external
        view
        returns (uint256);

    function setCoverReferralRewardPctg(
        address owner,
        uint256 coverId,
        uint256 referralRewardPctg
    ) external;
}