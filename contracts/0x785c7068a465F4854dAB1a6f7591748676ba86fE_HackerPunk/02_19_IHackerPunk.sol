// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IHackerPunk is IERC721 {
    function getO3Burned(uint256 tokenId) external view returns (uint256);

    function mint(address to, uint256 lpAmount) external;

    function setBaseURI(string memory baseURI) external;
    function setTokenURI(uint256 tokenId, string memory tokenURI) external;

    function isMintCallerAuthorized(address caller) external view returns (bool);
    function setAuthorizedMintCaller(address caller) external;
    function removeAuthorizedMintCaller(address caller) external;

    function pause() external;
    function unpause() external;

    function withdraw(address token, address to) external;
}