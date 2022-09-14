// SPDX-License-Identifier: MIT

/// Socks hand created by the one and only Digidaigaku Spirits.
/// Only mintable by questing with your Spirit.
/// Better make those socks quick before Spirits are burned for Heros....

pragma solidity ^0.8.9;

import "./utils/ERC721A.sol";
import "./utils/Ownable.sol";

contract SpiritSocks is ERC721A, Ownable {

    uint public MAX_SUPPLY = 8888;

    string baseURI;
    string _contractURI;
    mapping(address => bool) allowMinting;

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    constructor() ERC721A("SpiritSocks", "SPSOCK") {
        _contractURI = "ipfs://QmZzQAKiWQuiv2qDNBCEcLWJ216wZG9wEazk7FrPFVLpet";
        baseURI = "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newURI) external onlyOwner() {
        baseURI = newURI;
    }

    function setContractUri(string memory newURI) external onlyOwner() {
        _contractURI = newURI;
    }

    function addMinter(address minter) external onlyOwner() {
        allowMinting[minter] = true;
    }

    function removeMinter(address minter) external onlyOwner() {
        delete allowMinting[minter];
    }

    function mint(address to, uint quantity) external
    {
        require(allowMinting[_msgSenderERC721A()], 'Unauthorised');
        require(_totalMinted() + quantity < MAX_SUPPLY, "Max supply reached.");
        _mint(to, quantity);
    }
}