//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./IFortress.sol";

contract Realms is ERC721Enumerable {
    IFortress public fortresses = IFortress(0x0716d44d5991b15256A2de5769e1376D569Bba7C);
    mapping(bytes32=>address) public claimed;

    constructor() ERC721("Realms of Ether", "REALM") {}

    function claimFortress(bytes32 fortressHash) external{
        (,address owner,,,) = fortresses.getFortress(fortressHash);
        require(owner == msg.sender, "not owner");
        claimed[fortressHash] = msg.sender;
    }

    function wrap(bytes32 fortressHash) external {
        require(claimed[fortressHash] == msg.sender, "not claimed");
        (,address owner,,,) = fortresses.getFortress(fortressHash);
        require(owner == address(this), "not transferred");
        claimed[fortressHash] = address(0);
        _mint(msg.sender, uint(fortressHash));
    }

    function unwrap(uint tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "not owner");
        _burn(tokenId);
        fortresses.transferFortress(bytes32(tokenId), msg.sender);
    }

    function _baseURI() internal view override returns (string memory) {
        return "ipfs://ipfs/QmQvNvcnCZ7Zg5rsveYTo1EcwKZAoinL7rvj6azUqatiKj/";
    }
}