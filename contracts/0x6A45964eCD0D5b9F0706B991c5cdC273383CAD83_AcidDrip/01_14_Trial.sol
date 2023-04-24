// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AcidDrip is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI = "https://ipfs.io/ipfs/Qmc4qKnkm98rvnZwDwfKvxbYxwVeoYmq5bW8EmmATBZoeW/";
    string public constant baseExtension = ".json";
    uint256 public constant maxSupply = 6969;
    uint256 public cost = 0.0069 ether;
    uint256 public maxMintAmount = 5;
    mapping(address => bool) public hasFreeMint;

    constructor() ERC721("AcidDrip WAG-MI-GOS", "ACID") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory tokenIdStr = tokenId.toString();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenIdStr, baseExtension)) : "";
    }

    function mint(uint256 _mintAmount) public payable {
        require(_mintAmount > 0 && _mintAmount <= maxMintAmount, "Invalid mint amount");
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= maxSupply, "Exceeds max supply");

        for (uint256 i = 0; i < _mintAmount; i++) {
            if (supply == 0 && !hasFreeMint[msg.sender]) {
                // First mint is free
                hasFreeMint[msg.sender] = true;
            } else {
                require(hasFreeMint[msg.sender], "No more free mints available");
            }

            uint256 tokenId = supply + i;
            _safeMint(msg.sender, tokenId);
        }
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function updateBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficient balance");
        payable(owner()).transfer(balance);
    }
}