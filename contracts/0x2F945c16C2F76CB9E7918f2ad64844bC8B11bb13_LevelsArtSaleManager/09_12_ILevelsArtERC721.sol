// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {IERC721AUpgradeable} from "../ERC721A/upgradeable/IERC721AUpgradeable.sol";
import {ILevelsArtERC721TokenURI} from "./ILevelsArtERC721TokenURI.sol";
import {LevelsArtERC721Storage} from "./LevelsArtERC721Storage.sol";

interface ILevelsArtERC721 is IERC721AUpgradeable {
    // Errors
    error MaxSupplyMinted();

    /// @custom:oz-upgrades-unsafe-allow constructor

    function initialize(string memory _name, string memory _symbol) external;

    function setupCollection(
        address _tokenUriContract,
        uint256 _maxEditions,
        string memory _description,
        string memory _externalLink
    ) external;

    function setTokenURIContract(address _tokenUriContract) external;

    function setMaxEditions(uint256 _maxEditions) external;

    function setContractMetadata(
        string memory _description,
        string memory _externalLink
    ) external;

    function setMinter(address _minter) external;

    /*
      Getter functions
    */

    function version() external view returns (uint16);

    function tokenURIContract() external view returns (address);

    function description() external view returns (string memory);

    function maxEditions() external view returns (uint256);

    function externalLink() external view returns (string memory);

    function MINTER() external view returns (address);

    /**
     * @notice Function that returns the Contract URI
     */
    function contractURI() external view returns (string memory);

    /**
     * @notice Function that returns the Token URI from the TokenURI contract
     */
    function tokenURI(
        uint256 tokenId
    ) external view override returns (string memory);

    function mint(address to, uint quantity) external;

    function setApprovalForAll(
        address operator,
        bool approved
    ) external override;

    function approve(
        address operator,
        uint256 tokenId
    ) external payable override;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable override;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable override;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external payable override;

    function supportsInterface(
        bytes4 interfaceId
    ) external view override returns (bool);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;

    /**
     * @notice Disable the isOperatorFilterRegistryRevoked flag. OnlyOwner.
     */
    function revokeOperatorFilterRegistry() external;

    function isOperatorFilterRegistryRevoked() external view returns (bool);
}