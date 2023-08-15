//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./SANSoulbindable.sol";

interface ISAN is SANSoulbindable {
    function tokenLevel(uint256 _tokenId)
        external
        view
        returns (SoulboundLevel _level);

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _tokenIDs
    ) external;

    function ownerOf(uint256 _tokenId) external view returns (address owner);
}