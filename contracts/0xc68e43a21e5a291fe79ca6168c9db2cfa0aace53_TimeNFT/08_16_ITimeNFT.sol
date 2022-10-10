// SPDX-License-Identifier: MIT

/// @title Interface for TimeNFT ERC721 token

pragma solidity ^0.8.7;

import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

interface ITimeNFT is IERC721 {
    function mint(
        address to,
        string memory daytimeIpfshash,
        string memory nightIpfshash
    )
        external;
}