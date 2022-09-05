// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICustomToken {
    function walletOfOwner(address _wallet) external view returns (uint256[] memory);
    function tokenIdToSVG(uint256 _tokenId) external view returns (string memory);
    function contractURI() external view returns (string memory);
    function mint() external;
}