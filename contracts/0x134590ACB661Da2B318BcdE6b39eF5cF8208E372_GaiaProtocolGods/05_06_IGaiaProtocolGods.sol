// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./standards/ERC721A.sol";

interface IGaiaProtocolGods is IERC721A {
    error PausedNow();

    event SetBaseURI(string baseURI_);
    event CompleteAirdrop();

    function airdropCompleted() external view returns (bool);

    function exists(uint256 tokenId) external view returns (bool);

    function setBaseURI(string calldata baseURI_) external;

    function setPause(bool status) external;

    function batchTransferFrom(address from, address to, uint256[] calldata tokenIds) external;
}