// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IRender3NUM {

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error Unauthorized();
    error MintLimitReached();
    error InvalidMaxMintCount(uint256 tokenId);
    error TokenIdAlreadyMinted(uint256 tokenId);
    error InvalidTokenId(uint256 tokenId);

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event PFPMinted(string name, uint256 indexed tokenId, uint256 indexed subTokenId);

    event BaseURIUpdated(string newBaseURI);

    event MinterUpdated(address addr);

    event MaxMintCountUpdated(uint256 newMax);

    /*//////////////////////////////////////////////////////////////
                             Interfaces
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function mintPFP(uint256 tokenId) external returns (uint256);

    function getMaxMintCount() external view returns (uint256);

    function getMintCount() external view returns (uint256);
}