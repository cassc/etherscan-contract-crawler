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

interface ICover {
    // the product address
    function product() external returns (address);

    // the security matrix address
    function smx() external returns (address);

    // the cover data address
    function data() external returns (address);

    // the cover config address
    function cfg() external returns (address);

    // the cover quotation address
    function quotation() external returns (address);

    // the capital pool address
    function capitalPool() external returns (address);

    // the premium pool address
    function premiumPool() external returns (address);

    // the insur token address
    function insur() external returns (address);

    // buy cover maxmimum block number latency
    function buyCoverMaxBlkNumLatency() external returns (uint256);

    // the exchange rate address
    function exchangeRate() external returns (address);

    // the referral program address
    function referralProgram() external returns (address);

    function getPremium(
        uint256[] memory products,
        uint256[] memory durationInDays,
        uint256[] memory amounts,
        address currency,
        address owner,
        uint256 referralCode,
        uint256[] memory rewardPercentages
    )
        external
        view
        returns (
            uint256,
            uint256[] memory,
            uint256,
            uint256[] memory
        );

    function buyCover(
        uint16[] memory products,
        uint16[] memory durationInDays,
        uint256[] memory amounts,
        address currency,
        address owner,
        uint256 referralCode,
        uint256 premiumAmount,
        uint256[] memory helperParameters,
        uint256[] memory securityParameters,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external payable;

    function buyCoverV3(
        uint16[] memory products,
        uint16[] memory durationInDays,
        uint256[] memory amounts,
        address[] memory addresses,
        uint256 premiumAmount,
        uint256 referralCode,
        uint256[] memory helperParameters,
        uint256[] memory securityParameters,
        string memory freeText,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external payable;

    function unlockRewardByController(address owner, address to)
        external
        returns (uint256);

    function getRewardAmount() external view returns (uint256);

    function getCoverOwnerRewardAmount(
        uint256 premiumAmount2Insur,
        uint256 overwrittenRewardPctg
    ) external view returns (uint256, uint256);

    function getINSURRewardBalanceDetails()
        external
        view
        returns (uint256, uint256);

    function removeINSURRewardBalance(address toAddress, uint256 amount)
        external;

    function setBuyCoverMaxBlkNumLatency(uint256 numOfBlocks) external;

    function setBuyCoverSigner(address signer, bool enabled) external;
}