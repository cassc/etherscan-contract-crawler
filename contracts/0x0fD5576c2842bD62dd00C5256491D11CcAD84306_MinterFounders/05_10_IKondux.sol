// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IKondux {

    function changeDenominator(uint96 _denominator) external returns (uint96);

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external;

    function setTokenRoyalty(uint256 tokenId,address receiver,uint96 feeNumerator) external;

    function setBaseURI(string memory _newURI) external returns (string memory);

    function pause() external;

    function unpause() external;

    function safeMint(address to, uint256 dna) external returns (uint256);

    function setDna(uint256 _tokenID, uint256 _dna) external;

    function setMinter(address _minter) external;

}