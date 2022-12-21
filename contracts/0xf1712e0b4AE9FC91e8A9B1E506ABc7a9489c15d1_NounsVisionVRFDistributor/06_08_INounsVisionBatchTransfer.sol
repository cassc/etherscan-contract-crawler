// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for ERC721Like
interface ERC721Like {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function setApprovalForAll(address operator, bool approved) external;
    
    function totalSupply() external returns (uint256);

}

/// @dev Interface for NounsVisionBatchTransfer
interface INounsVisionBatchTransfer {
    function getStartId() external view returns (uint256 startId);

    function getStartIdAndBatchAmount(address receiver) external
        returns (uint256 startId, uint256 amount);

    function claimGlasses(uint256 startId, uint256 amount) external;

    function sendGlasses(uint256 startId, address recipient) external;

    function sendManyGlasses(uint256 startId, address[] calldata recipients) external;
}