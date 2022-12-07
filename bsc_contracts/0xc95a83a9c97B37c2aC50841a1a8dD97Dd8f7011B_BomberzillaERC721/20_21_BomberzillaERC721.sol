// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Rescueable.sol";

contract BomberzillaERC721 is AccessControlEnumerable, Rescueable, ERC721 {
    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string public baseUri;
    uint256 public nextTokenId;

    constructor(string memory _name, string memory _symbol, string memory _uri) ERC721(_name, _symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        baseUri = _uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function mint(address to) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "Only minter");
        _mint(to, nextTokenId++);
    }

    function mintBatch(address[] memory to) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "Only minter");
        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], nextTokenId++);
        }
    }

    function setBaseURI(string memory newuri) external onlyOwner {
        baseUri = newuri;
    }

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external onlyOwner {
        _setRoleAdmin(role, adminRole);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(AccessControlEnumerable, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}