// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ITheHours is IERC721 {
    function mint(bytes32 _mintDetails, address _to) external;

    function validateBid(bytes32 mintDetails, bool isInAllowlist)
        external
        returns (bool);

    function tokenCounter() external returns (uint256);

    function finished() external returns (bool);
}

interface ITheHoursArt {
    function generateSVG(bytes32[] memory mints, uint256 index) external view returns (bytes memory svg);
}