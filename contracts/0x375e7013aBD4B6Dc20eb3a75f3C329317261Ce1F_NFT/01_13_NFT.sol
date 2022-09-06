//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC1155Burnable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenCounter;

    string private _baseTokenURI;

    constructor() ERC1155(_baseTokenURI) {}

    function uri(uint256 _id) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(_baseTokenURI, Strings.toString(_id), ".json")
            );
    }

    function mint(uint256 _amounts) public onlyOwner {
        uint256 supply = _tokenCounter.current();
        uint256 tokenId = supply > 0 ? supply : 0;
        _mint(msg.sender, tokenId, _amounts, "");
        _tokenCounter.increment();
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        _baseTokenURI = _uri;
    }

    function multicastTransfer(address[] calldata _to, uint256 _id) external onlyOwner {
        require(
            balanceOf(msg.sender, _id) >= _to.length,
            "Insufficient number of tokens owned"
        );

        for (uint256 i = 0; i < _to.length; ++i) {
            address _dst = _to[i];
            _safeTransferFrom(msg.sender, _dst, _id, 1, "");
        }
    }
}