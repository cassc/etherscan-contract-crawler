// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ITrait is IERC721 {
    function onTraitAddedToAvatar(uint16 _tokenId, uint16 _avatarId) external;

    function onAvatarTransfer(
        address _from,
        address _to,
        uint16 _tokenId
    ) external;

    function onTraitRemovedFromAvatar(uint16 _tokenId, address _owner) external;

    function traitToAvatar(uint16) external returns (uint16);

    function mint(uint256 _tokenId, address _to) external;

    function burn(uint16 _tokenId) external;
}