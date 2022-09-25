// SPDX-License-Identifier: GPL-3.0

/// @title Interface for burning ForgottenRunesWarriorsGuild ERC721 token

pragma solidity ^0.8.6;

import "IERC1155.sol";

interface IBurnableERC1155 is IERC1155 {
    function burn(
        address account,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external;
}