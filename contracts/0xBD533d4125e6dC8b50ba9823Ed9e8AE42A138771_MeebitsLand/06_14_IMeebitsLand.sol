//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IMeebitsLand {
    event Mint(address indexed _to, uint256 indexed _tokenId);

    function setBaseURI(string memory uri) external;

    function toggleContractMintable() external;

    function togglePause() external;

    function mint() external returns (uint256);
}