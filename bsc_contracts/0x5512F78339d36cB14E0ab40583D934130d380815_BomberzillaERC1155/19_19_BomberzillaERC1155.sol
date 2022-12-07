// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BomberzillaERC1155 is AccessControlEnumerable, Ownable, ERC1155, ERC1155Supply, ERC1155Burnable {
    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string public name = "Bomberzilla Assets";
    string public symbol = "ZILLA";

    string public uriPostFix = ".json";

    constructor(string memory _uri) ERC1155(_uri) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        string memory baseURI = super.uri(tokenId);
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), uriPostFix)) : "";
    }

    function setURI(string memory newuri, string memory postFix) external onlyOwner {
        uriPostFix = postFix;
        _setURI(newuri);
    }

    function mint(address to, uint256 id, uint256 amount, bytes memory data) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "Only minter");
        _mint(to, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "Only minter");
        _mintBatch(to, ids, amounts, data);
    }

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external onlyOwner {
        _setRoleAdmin(role, adminRole);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(AccessControlEnumerable, ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}