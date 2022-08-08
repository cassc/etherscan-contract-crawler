/* Copyright (C) 2021 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */
// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.4;

interface IGateway {
    enum ClaimStatus {
        IN_PROGRESS,
        ACCEPTED,
        REJECTED
    }

    enum CoverType {
        SIGNED_QUOTE_CONTRACT_COVER
    }

    function buyCover(
        address contractAddress,
        address coverAsset,
        uint256 sumAssured,
        uint16 coverPeriod,
        CoverType coverType,
        bytes calldata data
    ) external payable returns (uint256);

    function getCoverPrice(
        address contractAddress,
        address coverAsset,
        uint256 sumAssured,
        uint16 coverPeriod,
        CoverType coverType,
        bytes calldata data
    ) external view returns (uint256 coverPrice);

    function getCover(uint256 coverId)
        external
        view
        returns (
            uint8 status,
            uint256 sumAssured,
            uint16 coverPeriod,
            uint256 validUntil,
            address contractAddress,
            address coverAsset,
            uint256 premiumInNXM,
            address memberAddress
        );

    function submitClaim(uint256 coverId, bytes calldata data)
        external
        returns (uint256);

    function claimTokens(
        uint256 coverId,
        uint256 incidentId,
        uint256 coveredTokenAmount,
        address coverAsset
    )
        external
        returns (
            uint256 claimId,
            uint256 payoutAmount,
            address payoutToken
        );

    function getClaimCoverId(uint256 claimId) external view returns (uint256);

    function getPayoutOutcome(uint256 claimId)
        external
        view
        returns (
            ClaimStatus status,
            uint256 paidAmount,
            address asset
        );

    function executeCoverAction(
        uint256 tokenId,
        uint8 action,
        bytes calldata data
    ) external payable returns (bytes memory, uint256);

    function switchMembership(address _newAddress) external payable;

    function claimsData() external view returns (address);

    function ETH() external view returns (address);
}