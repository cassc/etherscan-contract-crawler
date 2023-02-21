// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

error MaxSupplyReached();

contract Sekala is Ownable, ERC721A {
    uint256 public constant MAX_SUPPLY = 16;

    string private _baseTokenURI;

    constructor() ERC721A("Sekala", "SEKALA") {}

    function mint(address to, uint256 amount) public onlyOwner {
        if (_totalMinted() + amount > MAX_SUPPLY) revert MaxSupplyReached();
        _mint(to, amount);
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function approveMulti(address _to, uint256[] calldata _tokenIds) external {
        for (uint256 i; i < _tokenIds.length; ) {
            approve(_to, _tokenIds[i]);

            unchecked {
                ++i;
            }
        }
    }
}