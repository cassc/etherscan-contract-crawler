//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WrappedStrikers is ERC721Enumerable, Ownable {
    IERC721 public strikersContract;

    string private _baseTokenURI;

    event Wrapped(uint256 indexed tokenId);
    event Unwrapped(uint256 indexed tokenId);

    constructor(IERC721 _strikersContract) ERC721("Wrapped Strikers", "wSTRK") {
        strikersContract = _strikersContract;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseTokenURI(string memory baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function wrap(uint256 tokenId) public {
        strikersContract.transferFrom(_msgSender(), address(this), tokenId);
        _mint(_msgSender(), tokenId);
        emit Wrapped(tokenId);
    }

    function unwrap(uint256 tokenId) public {
        require(
            ownerOf(tokenId) == _msgSender(),
            "You do not own this Wrapped Striker!"
        );
        strikersContract.transferFrom(address(this), _msgSender(), tokenId);
        _burn(tokenId);
        emit Unwrapped(tokenId);
    }

    function tokenIdsForOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory result = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            result[i] = tokenOfOwnerByIndex(owner, i);
        }
        return result;
    }
}