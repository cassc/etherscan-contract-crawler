// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title Interface to the WrappedPunk contract
 */
 
interface IWrappedPunk {
    function punkContract() external view returns (address);
    function setBaseURI(string memory baseUri) external;
    function pause() external;
    function unpause() external;
    function registerProxy() external;
    function proxyInfo(address user) external view returns (address);
    function mint(uint256 punkIndex) external;
    function burn(uint256 punkIndex) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool allowed) external;
}