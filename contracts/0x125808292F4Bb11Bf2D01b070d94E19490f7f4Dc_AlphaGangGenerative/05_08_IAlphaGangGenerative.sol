// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IAlphaGangGenerative {
    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address);

    function setApprovalForAll(address operator, bool approved) external;

    function totalSupply() external view returns (uint256);

    function SUPPLY_MAX() external view returns (uint256);

    function mintActive(uint8 mintType) external view returns (bool);

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory ownerTokens);
}