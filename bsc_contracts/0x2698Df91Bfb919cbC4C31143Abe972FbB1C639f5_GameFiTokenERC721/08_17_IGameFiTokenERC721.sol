// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

interface IGameFiTokenERC721 is IERC721Upgradeable, IERC721MetadataUpgradeable {
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        string memory tokenURI_,
        bytes memory data_
    ) external;

    function setContractURI(string memory newURI) external;

    function setTokenURI(string memory newURI) external;

    function mint(address to, bytes memory data) external;

    function burn(uint256 tokenId, bytes memory data) external;

    function contractURI() external view returns (string memory);

    function tokenURI() external view returns (string memory);
}