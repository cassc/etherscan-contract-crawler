// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

//  _ .-') _
// ( (  OO) )
//  \     .'_  ,--. ,--.    .-'),-----.
//  ,`'--..._) |  | |  |   ( OO'  .-.  '
//  |  |  \  ' |  | | .-') /   |  | |  |
//  |  |   ' | |  |_|( OO )\_) |  |\|  |
//  |  |   / : |  | | `-' /  \ |  | |  |
//  |  '--'  /('  '-'(_.-'    `'  '-'  '
//  `-------'   `-----'         `-----'

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

contract DUO is ERC721A, ERC721ABurnable, ERC721AQueryable, IERC2981, AccessControl, Ownable {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string public baseURI;

    constructor(string memory name_, string memory symbol_, string memory baseURI_) ERC721A(name_, symbol_) {
        baseURI = baseURI_;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        _mint(msg.sender, 1);
    }

    function setBaseURI(string memory baseURI_) external onlyRole(MANAGER_ROLE) {
        baseURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mint(address to, uint256 quantity) external onlyRole(MINTER_ROLE) {
        _mint(to, quantity);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(AccessControl, ERC721A, IERC721A, IERC165) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            ERC721A.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256, uint256 price) external view override returns (address, uint256) {
        return (owner(), (price * 10) / 100);
    }
}