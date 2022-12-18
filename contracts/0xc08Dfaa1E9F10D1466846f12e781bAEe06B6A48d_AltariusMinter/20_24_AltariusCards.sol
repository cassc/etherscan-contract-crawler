// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./AltariusMetadata.sol";

/**
 * @title Altarius Cards
 *
 * @dev This contract holds the Altarius cards tokens using an ERC1155 implementation.
 * Metadata is stored in AltariusMetadata contract.
 */
contract AltariusCards is
    ERC1155,
    ERC1155Burnable,
    AccessControl,
    ERC1155Supply
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    AltariusMetadata public altariusMetadata;

    constructor(AltariusMetadata _altariusMetadata) ERC1155("") {
        altariusMetadata = _altariusMetadata;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external onlyRole(MINTER_ROLE) {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external onlyRole(MINTER_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }

    function metadata(
        uint256 id
    ) external view returns (AltariusMetadata.Metadata memory) {
        return altariusMetadata.getMetadata(id);
    }

    function name(uint256 id) external view returns (bytes32) {
        return altariusMetadata.getName(id);
    }

    function images(
        uint256 id
    ) external view returns (AltariusMetadata.Images memory) {
        return altariusMetadata.getImages(id);
    }

    function metadataLength() external view returns (uint256) {
        return altariusMetadata.getMetadataLength();
    }

    function uri(uint256 id) public view override returns (string memory) {
        return altariusMetadata.uri(id);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}