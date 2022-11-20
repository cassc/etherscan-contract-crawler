/*

    /$$    /$$$$$$$$ /$$       /$$   /$$
  /$$$$$$ | $$_____/| $$      | $$  / $$
 /$$__  $$| $$      | $$      |  $$/ $$/
| $$  \__/| $$$$$   | $$       \  $$$$/ 
|  $$$$$$ | $$__/   | $$        >$$  $$ 
 \____  $$| $$      | $$       /$$/\  $$
 /$$  \ $$| $$$$$$$$| $$$$$$$$| $$  \ $$
|  $$$$$$/|________/|________/|__/  |__/
 \_  $$_/                               
   \__/                                 
                                              
*/                                             
                                                                                     
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Elixir is Initializable, ERC1155Upgradeable, AccessControlUpgradeable, ERC1155BurnableUpgradeable, ERC1155SupplyUpgradeable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string public name;
    string public symbol;

    function initialize() initializer public {
        __ERC1155_init("");
        __AccessControl_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        name = "Elixir";
        symbol = "$ELX";
    }

    function setURI(string memory newuri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(newuri);
    }

    function mintElx(address account, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(account, 1, amount, "");
    }

    function totalSupply() public view virtual returns (uint256) {
        return totalSupply(1);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155Upgradeable, ERC1155SupplyUpgradeable)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}