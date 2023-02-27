// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IBabyWealthyClubMintable {

    function mint(address to) external;

    function mint(address to, uint256 tokenId) external;
    
    function batchMint(address[] memory recipients) external;

}