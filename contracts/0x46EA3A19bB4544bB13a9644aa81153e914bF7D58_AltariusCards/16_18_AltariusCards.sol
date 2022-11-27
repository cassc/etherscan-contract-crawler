// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./AltariusMetadata.sol";

contract AltariusCards is
    ERC1155,
    ERC1155Burnable,
    AccessControl,
    ERC1155Supply
{
    string public constant name = "Test Cards";

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    AltariusMetadata public altariusMetadata;

    constructor(AltariusMetadata _altariusMetadata) ERC1155("") {
        altariusMetadata = _altariusMetadata;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    receive() external payable {}

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

    function withdraw(uint256 amount) external onlyRole(WITHDRAWER_ROLE) {
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function metadata(
        uint256 id
    ) external view returns (AltariusMetadata.Metadata memory) {
        return altariusMetadata.getMetadata(id);
    }

    function metadataLength() external view returns (uint256) {
        return altariusMetadata.getMetadataLength();
    }

    function uri(uint256 id) public view override returns (string memory) {
        return altariusMetadata.uri(id);
    }

    // OpenZeppelin: The following functions are overrides required by Solidity.

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

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}