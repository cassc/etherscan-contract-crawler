// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract MetablizzardBack is ERC1155Supply, Ownable, ReentrancyGuard {

    IERC721 public immutable METABLIZZARD;

    string public name = "Snow Battle";
    string public symbol = "SNB";

    bool public URILocked;

    mapping(uint16 => bool) public claimed;

    event Claimed(uint16[] ids);

    constructor(string memory _uri, IERC721 _metablizzard) ERC1155(_uri) {
        METABLIZZARD = _metablizzard;
    }

    function claim(uint16[] calldata ids) external nonReentrant {
        for (uint16 i; i < ids.length; i++) {
            require(METABLIZZARD.ownerOf(ids[i]) == _msgSender(), string(abi.encodePacked("Not an owner of token ", Strings.toString(ids[i]))));
            require(!claimed[ids[i]], string(abi.encodePacked("Already claimed for token ", Strings.toString(ids[i]))));
            claimed[ids[i]] = true;
        }
        _mint(_msgSender(), 0, ids.length, "");
        emit Claimed(ids);
    }

    function setURI(string memory newuri) external onlyOwner {
        require(!URILocked, "URI already locked");
        _setURI(newuri);
    }

    function lockURI() external onlyOwner {
        URILocked = true;
    }
}