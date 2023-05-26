// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

/// @title ERC1155 Contract for Lazy Drinks
/// @author Akshat Mittal
contract LazyDrinks is ERC1155, AccessControl, ERC1155Supply {
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");

    string public constant name = "Lazy Drinks";
    string public constant symbol = "DRINKS";

    bool public mintingOpen = true;

    constructor() ERC1155("https://metadata.lazylionsnft.com/api/lazydrinks/{id}") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(CONTROLLER_ROLE, msg.sender);
    }

    function setURI(string memory newuri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(newuri);
    }

    function finishMinting() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(mintingOpen);
        mintingOpen = false;
    }

    function approveController(address controller) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(CONTROLLER_ROLE, controller);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyRole(CONTROLLER_ROLE) {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyRole(CONTROLLER_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public onlyRole(CONTROLLER_ROLE) {
        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public onlyRole(CONTROLLER_ROLE) {
        _burnBatch(account, ids, values);
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

        if (from == address(0)) {
            require(mintingOpen, "Minting has finished");
        }
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}