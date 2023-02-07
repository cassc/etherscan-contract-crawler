// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

interface IHedgepieAdapterInfoBsc {
    function updateTVLInfo(
        uint256 _tokenId,
        uint256 _value,
        bool _adding
    ) external;

    function updateTradedInfo(
        uint256 _tokenId,
        uint256 _value,
        bool _adding
    ) external;

    function updateProfitInfo(
        uint256 _tokenId,
        uint256 _value,
        bool _adding
    ) external;

    function updateParticipantInfo(
        uint256 _tokenId,
        address _account,
        bool _adding
    ) external;
}