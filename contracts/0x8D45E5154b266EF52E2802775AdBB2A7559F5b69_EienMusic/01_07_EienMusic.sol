// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// EIEN MUSIC Contract by arufa
// Twitter: https://twitter.com/arufa_nft

contract EienMusic is ERC721A, Ownable {
    uint public immutable maxSupply = 2000;

    string public baseTokenURI;
    string constant public uriSuffix = ".json";

    constructor() ERC721A("EienMusic", "EIENMUSIC") {}

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");
        return string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId), uriSuffix));
    }

    function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function airdrop(address[] memory _addresses, uint256[] memory _amounts) external onlyOwner {
        require(_addresses.length == _amounts.length);
        for (uint i = 0; i < _addresses.length; i++) {
            _mint(_addresses[i], _amounts[i]);
        }
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function ownerMint(address _address, uint256 count) external onlyOwner {
        require(totalSupply() + count <= maxSupply, 'Max supply exceeded');
       _mint(_address, count);
    }
}