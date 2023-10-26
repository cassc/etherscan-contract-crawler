// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IFractonXERC721 {

    function tokenId() external view returns(uint256);
    function totalSupply() external view returns(uint256);

    function mint(address to) external returns(uint256 curTokenId);
    function burn(uint256 tokenid) external;
    function setTokenURI(string calldata tokenuri) external;
}