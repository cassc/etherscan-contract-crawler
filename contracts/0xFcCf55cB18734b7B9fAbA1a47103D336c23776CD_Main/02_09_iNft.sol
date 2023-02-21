// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface iNft is IERC721Enumerable {

    // store lock meta data
    struct Trait {
        uint256 tokenId;
        uint8 tokenType; // 1=Popsteak, 2=Popsteak-X
    }

    function maxTokens() external returns (uint256);
    function totalMinted() external returns (uint16);

    function getWalletOfOwner(address owner) external view returns (uint256[] memory);
    function getLicenseURI() external view returns (string memory);

    function burn(uint256 tokenId) external;

    function mint(address recipient, uint8 tokenType) external; // onlyAdmin
    function setLicenseURI(string memory uri) external; // onlyOwner
}