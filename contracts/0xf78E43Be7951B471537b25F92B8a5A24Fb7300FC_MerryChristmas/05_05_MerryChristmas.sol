pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MerryChristmas is ERC721A, Ownable {
    constructor() ERC721A("Merry Christmas", "Merry Christmas") {
        baseURI = 'ipfs://bafybeia7odfozsimxz4dsncc7lvltg3fhzpecjmzb4derwlufjhk7oc4ae/';
    }

    string public baseURI;
    uint256 maxSupply = 500;
    address[] public allowlist;

    function airdrop() external onlyOwner {
        require(totalSupply() <= maxSupply, "mint over");
        for (uint256 i; i < allowlist.length; i++) {
            _mint(allowlist[i], 20);
        }
    }

    function seedAllowlist(address[] memory addresses)
    external
    onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlist.push(addresses[i]);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }
}