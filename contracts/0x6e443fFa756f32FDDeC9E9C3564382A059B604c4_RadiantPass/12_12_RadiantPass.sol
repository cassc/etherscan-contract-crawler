// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./ERC721A.sol";

contract RadiantPass is ERC721A, Ownable {
    string public _baseTokenURI;
    uint256 public maxMints = 333;

    event Mint(address indexed owner, uint256 indexed tokenId);

    constructor(address _owner) ERC721A("Radiant Launch Pass", "RAD", 1) {
        require(_owner != address(0x0), "set_owner");
        transferOwnership(_owner);
    }

    function mintTo(uint256 amount, address to) external onlyOwner {
        _mintWithoutValidation(to, amount);
    }

    function _mintWithoutValidation(address to, uint256 amount) internal {
        uint256 _totalSupply = totalSupply();
        require(_totalSupply < maxMints, "max_items_reached");
        _safeMint(to, amount);
    }

    function setBaseTokenURI(string memory __baseTokenURI) public onlyOwner {
        _baseTokenURI = __baseTokenURI;
    }

    // METADATA FUNCTIONALITY

    /**
     * @dev Returns a URI for a given token ID's metadata
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
    }
}