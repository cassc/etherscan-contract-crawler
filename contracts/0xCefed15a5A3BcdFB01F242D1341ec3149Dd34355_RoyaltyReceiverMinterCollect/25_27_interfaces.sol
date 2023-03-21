// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

// interface Minter {
//     function getMinter(uint tokenId) external view returns (address);
// }

interface ERC721struct {
    struct ERC721s {
        address erc721;
        uint256 tokenId;
    }
}

// solhint-disable-next-line contract-name-camelcase
interface iMinterAndParent is ERC721struct {
    function getMinterAndParent(uint256 tokenId) external view returns (address minter, address parent);

    function getMinterParentHolder(
        uint256 tokenId
    ) external view returns (address minter, address parent, address holder);

    function getParentNftHolder(uint256 tokenId) external view returns (address holder);
    // function getParent(uint256 tokenId) external view returns(ERC721s memory);
    // function getMinter(uint tokenId) external view returns (address);
}