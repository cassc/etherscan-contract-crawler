// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';

interface IFrogLand is IERC721Enumerable {
    function canMint(uint256 quantity) external view returns (bool);

    function canMintPresale(
        address owner,
        uint256 quantity,
        bytes32[] calldata proof
    ) external view returns (bool);

    function presaleMinted(address owner) external view returns (uint256);

    function purchase(uint256 quantity) external payable;

    function purchasePresale(uint256 quantity, bytes32[] calldata proof) external payable;
}

interface IFrogLandAdmin {
    function mintToAddress(uint256 quantity, address to) external;

    function mintToAddresses(address[] calldata to) external;

    function setBaseURI(string memory baseURI) external;

    function setBaseURIRevealed(string memory baseURI) external;

    function setPresaleLimit(uint256 limit) external;

    function setPresaleRoot(bytes32 merkleRoot) external;

    function togglePresaleIsActive() external;

    function toggleSaleIsActive() external;

    function withdraw() external;
}