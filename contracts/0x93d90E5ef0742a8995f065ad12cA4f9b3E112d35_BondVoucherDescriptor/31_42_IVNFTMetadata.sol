// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IVNFTMetadata /* is IERC721Metadata */ {
    function contractURI() external view returns (string memory);
    function slotURI(uint256 slot) external view returns (string memory);
}