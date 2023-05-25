// SPDX-License-Identifier: GPL-3.0

/// @title Interface for ForgottenRunesWarriorsGuild ERC721 token

pragma solidity ^0.8.6;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface IForgottenRunesWarriorsGuild is IERC721 {
    function mint(address recipient) external returns (uint256);
}