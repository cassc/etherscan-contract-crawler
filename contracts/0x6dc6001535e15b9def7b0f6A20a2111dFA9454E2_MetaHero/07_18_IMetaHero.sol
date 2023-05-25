// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";


interface IMetaHero is IERC721Enumerable {

    function geneOf(uint256 tokenId) external view returns (uint256 gene);
    function redeem(uint256 amount) external;
    function setRedeemStart(uint256 _windowOpen) external;
    function unpause() external;
    function pause() external;
    function setBaseURI(string memory _baseTokenURI) external;
    function setIpfsURI(string memory _ipfsURI) external;
}