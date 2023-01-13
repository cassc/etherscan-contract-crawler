// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IB3DLNft {
    function isOwnerOf(address, uint256) external view returns (bool);

    function getNumMinted() external view returns (uint256);

    // mint
    function mint(address account) external payable returns (uint256);

    function mintBatch(address account, uint256 amount) external payable returns (uint256[] memory);

    function burn(uint256 id) external;

    function burnBatch(uint256[] calldata ids) external;
}