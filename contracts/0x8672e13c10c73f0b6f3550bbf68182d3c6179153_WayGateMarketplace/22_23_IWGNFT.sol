// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWGNFT {
    function getWhitelistTokenIdStatus(
        uint256 _tokenId
    ) external view returns (bool);

    function getNftTypeStatus(uint256 _tokenId) external view returns (uint);

    function getSpecialNftTokenIdStatus(
        uint256 _tokenId
    ) external view returns (bool);

    function setMaxRoyaltyPercentage(uint _royaltyPercentage) external;
}