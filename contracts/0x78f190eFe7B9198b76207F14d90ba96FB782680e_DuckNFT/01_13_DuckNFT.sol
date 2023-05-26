// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DuckNFT is ERC721Enumerable, Ownable {

    address private _manager;
    string private baseURI;

    constructor() ERC721("Forever Fomo Duck Squad", "FFDS") {
        baseURI = 'https://highstreet.market/FFDS/';
    }

    function setManager(address addr_) external onlyOwner {
        require(addr_ != address(0), 'invalid address');
        _manager = addr_;
    }

    function getManager() external view returns(address) {
        return _manager;
    }

    function setBaseURI(string memory uri_) external {
        require(msg.sender == owner() || msg.sender == _manager, 'permission denied');
        baseURI = uri_;
    }

    function mintToken(address to_, uint256 tokenId_) external {
        require(msg.sender == owner() || msg.sender == _manager, 'permission denied');
        _safeMint(to_, tokenId_);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

}