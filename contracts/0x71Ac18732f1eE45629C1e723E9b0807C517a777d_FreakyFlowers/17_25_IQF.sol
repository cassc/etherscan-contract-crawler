// SPDX-License-Identifier: GPL-3.0

/// @title Interface for the Token

pragma solidity ^0.8.6;

import './IERC721.sol';

interface IQF is IERC721 {
    event OperatorFlagged(address flaggedOperator, bool status);

    event TokenCreated(uint256 indexed tokenId, address mintedTo);

    event TokenHashCreated(uint256 indexed tokenId, bytes32 hash);

    event TokenBurned(uint256 indexed tokenId);

    event MinterUpdated(address minter);

    event MinterLocked();

    event Revealed(bool revealed);

    function mint(address _to) external returns (uint256);

    //function allowlistMint(address _to) external returns (uint256);

    //function promoMint(address to, uint256 quantity) external returns (uint256);

    function setReveal(bool _revealed) external;

    function burn(uint256 tokenId) external;

    function setMinter(address minter) external;

    //function lockMinter() external;

    function setBaseURI(string memory _newBaseURI) external;
}