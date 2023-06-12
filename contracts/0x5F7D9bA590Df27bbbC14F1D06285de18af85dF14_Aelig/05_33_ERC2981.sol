// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IERC2981.sol";
import "./Roles.sol";

contract ERC2981 is
    IERC2981,
    Roles
{
    uint256 public royaltyPercentage;

    constructor (uint256 _royaltyPercentage) {
        royaltyPercentage = _royaltyPercentage;
    }

    function royaltyInfo(
        uint256,
        uint256 _salePrice
    )
        external
        view
        override
        returns (
            address receiver,
            uint256 royaltyAmount
        )
    {
        return (address(this),  _salePrice / 10000 * royaltyPercentage);
    }

    function setRoyaltyInfo(
        uint256,
        uint256 _salePrice
    )
        external
        view
        override
        returns (
            address receiver,
            uint256 royaltyAmount
        )
    {
        return (address(this),  _salePrice / 10000 * royaltyPercentage);
    }

    function updateRoyaltyPercentage(
        uint256 percentage
    )
        external
        override
        isManager(msg.sender)
    {
        royaltyPercentage = percentage;
    }
}