pragma solidity ^0.8.0;

interface IFootballClub {
    function safeMint(address, uint256) external;

    function pause() external;

    function unpause() external;

    function tokenURI() external view;

    function supportsInterface(bytes4) external view;
}