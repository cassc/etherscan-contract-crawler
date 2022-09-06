// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '../libraries/BespokeTypes.sol';

interface IOpenSkyBespokeLoanNFT is IERC721 {
    event Mint(uint256 indexed tokenId, address indexed recipient);
    event Burn(uint256 tokenId);
    event SetLoanDescriptorAddress(address operator, address descriptorAddress);

    function mint(uint256 tokenId, address account) external;

    function burn(uint256 tokenId) external;

    function getLoanData(uint256 tokenId) external returns (BespokeTypes.LoanData memory);
}