pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FuckBen is Ownable, ERC721 {
    constructor() ERC721("fuckben", "FB") {}

    string public baseURI;

    function mint(uint256 id) external onlyOwner {
        _mint(msg.sender, id);
    }

    function setBaseURI(string calldata _base) external onlyOwner  {
        baseURI = _base;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}