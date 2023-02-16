//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./SANSoulbindable.sol";

interface ISAN is SANSoulbindable {
    function tokenLevel(uint256 _tokenId)
        external
        view
        returns (SoulboundLevel _level);

    function ownerOf(uint256 _tokenId) external view returns (address owner);
}