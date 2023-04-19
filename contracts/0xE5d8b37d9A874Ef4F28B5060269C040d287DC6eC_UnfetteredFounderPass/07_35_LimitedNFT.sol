// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../../../ext-contracts/@openzeppelin/contracts/utils/Counters.sol";
import "../../../ext-contracts/@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "../util/Errors.sol";

abstract contract LimitedNFT is ERC721Enumerable {
    mapping(address => uint256) _mintCounter; // address => mint count
    uint256 public _maxMintCountForPerAddress;
    uint256 public _maxSupply;

    error MaxMintCountExceed();

    constructor(uint256 maxSupply, uint256 maxMintCountForPerAddress) {
        _maxSupply = maxSupply;
        _maxMintCountForPerAddress = maxMintCountForPerAddress;
    }

    // function _mintTo(address to) internal virtual {
    //     _mint(to, totalSupply());
    // }

    function _mint(address to, uint256 tokenId) internal virtual override {
        if (
            _maxMintCountForPerAddress > 0 &&
            _mintCounter[to] == _maxMintCountForPerAddress
        ) revert MaxMintCountExceed();

        if (_maxSupply > 0 && totalSupply() == _maxSupply)
            revert MaxSupplyReached();

        ERC721._mint(to, tokenId);
        _mintCounter[to]++;
    }

    function getMintCount(address tokenOwner) public view returns (uint256) {
        return _mintCounter[tokenOwner];
    }
}