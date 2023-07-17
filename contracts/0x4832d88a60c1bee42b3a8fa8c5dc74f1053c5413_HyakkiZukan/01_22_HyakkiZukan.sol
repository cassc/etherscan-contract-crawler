// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./interfaces/IERC6551Registry.sol";
import "./HyakkiToken.sol";

contract HyakkiZukan is HyakkiToken {
    IERC6551Registry public registry;
    address public implementation;

    mapping (uint256 => uint256) public tokenIdToSalt;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        address mintvial_,
        address registry_,
        address implementation_
    ) HyakkiToken(name, symbol, baseURI, mintvial_) {
        registry = IERC6551Registry(registry_);
        implementation = implementation_;
    }

    function setRegistry(address registry_) public onlyOwner {
        registry = IERC6551Registry(registry_);
    }
    function setImplementation(address implementation_) public onlyOwner {
        implementation = implementation_;
    }
    function setSalt(uint256 tokenId, uint256 salt) public onlyOwner {
        tokenIdToSalt[tokenId] = salt;
    }

    function createAccount(uint256 tokenId) public returns(address) {
        uint256 _salt = tokenIdToSalt[tokenId];
        address _account = registry.createAccount(
            implementation,
            block.chainid,
            address(this),
            tokenId,
            _salt,
            ""
        );
        return _account;
    }

    function account(uint256 tokenId) public view returns (address) {
        uint256 salt = tokenIdToSalt[tokenId];
        return registry.account(
            implementation,
            block.chainid,
            address(this),
            tokenId,
            salt
        );
    }

    function accountCreated(uint256 tokenId) public view returns (bool) {
        return account(tokenId).code.length != 0;
    }
}