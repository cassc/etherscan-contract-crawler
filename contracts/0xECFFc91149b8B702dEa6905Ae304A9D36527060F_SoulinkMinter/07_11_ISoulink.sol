// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ISoulBoundToken.sol";

interface ISoulink is ISoulBoundToken {
    event SetBaseURI(string uri);
    event SetMinter(address indexed target, bool indexed isMinter);
    event CancelLinkSig(address indexed caller, uint256 indexed targetId, uint256 deadline);
    event ResetLink(uint256 indexed tokenId);
    event SetLink(uint256 indexed id0, uint256 indexed id1);
    event BreakLink(uint256 indexed id0, uint256 indexed id1);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function totalSupply() external view returns (uint256);

    function isMinter(address target) external view returns (bool);

    function getTokenId(address owner) external pure returns (uint256);

    function cancelLinkSig(
        uint256 targetId,
        uint256 deadline,
        bytes calldata sig
    ) external;

    function mint(address to) external returns (uint256 id);

    function burn(uint256 tokenId) external;

    function isLinked(uint256 id0, uint256 id1) external view returns (bool);

    function setLink(
        uint256 targetId,
        bytes[2] calldata sigs,
        uint256[2] calldata deadlines
    ) external;

    function breakLink(uint256 targetId) external;
}