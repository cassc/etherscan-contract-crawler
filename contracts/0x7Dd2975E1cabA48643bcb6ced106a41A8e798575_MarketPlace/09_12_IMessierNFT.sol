// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IMessierNFT {

    function mint(address _to, uint256 _tokenId) external;

    function maxSupply() external view returns (uint256);
    
    function setBaseURI(string memory _link) external;

    function balanceOf(address  _ask) external   returns (uint256);
    
    function ownerOf(uint  _ask)  external  returns (address);

    function safeTransferFrom(address from,address to,uint tokenId) external;

}