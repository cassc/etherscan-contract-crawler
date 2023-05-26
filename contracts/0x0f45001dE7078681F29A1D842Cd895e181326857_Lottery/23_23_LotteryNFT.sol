// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract LotteryNFT is ERC721, AccessControl {
    uint16 public tokenId;
    uint16 constant MAX_TOKENS = 2222;
    bytes32 public constant MINTER = keccak256("MINTER_ROLE");
    string private uri;

    constructor(
        string memory name,
        string memory symbol,
        string memory _uri
    ) ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER, msg.sender);
        uri = _uri;
    }

    function mint(address to) external {
        require(hasRole(MINTER, msg.sender), "Caller is not a minter");
        require(tokenId < MAX_TOKENS, "Max tokens minted");
        unchecked {
            ++tokenId;
        }
        _mint(to, tokenId);
    }

    function tokenURI(uint256) public view override returns (string memory) {
        return uri;
    }

    function setURI(string memory _uri) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not an admin"
        );
        uri = _uri;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControl, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}