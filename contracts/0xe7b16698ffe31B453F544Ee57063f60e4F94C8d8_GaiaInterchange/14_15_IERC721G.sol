// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/interfaces/IERC721.sol";

interface IERC721G is IERC721 {
    event SetBaseURI(string baseURI_);

    function exists(uint256 tokenId) external view returns (bool);

    function totalSupply() external view returns (uint256);

    function setBaseURI(string calldata baseURI_) external;

    function setPause(bool status) external;

    function mint(address to, uint256 tokenId) external;

    function mintBatch(address to, uint256[] calldata tokenIds) external;

    function burn(uint256 tokenId) external;

    function burnBatch(address from, uint256[] calldata tokenIds) external;

    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata tokenIds
    ) external;
}