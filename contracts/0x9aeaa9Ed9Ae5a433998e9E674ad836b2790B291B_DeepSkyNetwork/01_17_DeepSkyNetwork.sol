// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract DeepSkyNetwork is ERC1155Supply, ERC1155Burnable, AccessControlEnumerable, Pausable, Ownable {
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC1155("") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(URI_SETTER_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) whenNotPaused {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) whenNotPaused {
        _mintBatch(to, ids, amounts, data);
    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public override whenNotPaused {
        ERC1155Burnable.burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public override whenNotPaused {
        ERC1155Burnable.burnBatch(account, ids, values);
    }

    // ------------------
    // Pause capability
    // ------------------

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // ------------------
    // Functions for the owner
    // ------------------

    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // ------------------
    // Explicit overrides
    // ------------------

    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal override(ERC1155, ERC1155Supply) {
        ERC1155Supply._burn(account, id, amount);
    }

    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal override(ERC1155, ERC1155Supply) {
        ERC1155Supply._burnBatch(account, ids, amounts);
    }

    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        ERC1155Supply._mint(account, id, amount, data);
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        ERC1155Supply._mintBatch(to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControlEnumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}