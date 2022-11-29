// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./interface/IReap3rMint.sol";

contract HeyReap3r is ERC721A, IReap3rMint {

    string private _baseTokenURI;

    address public _proxySaleAddress;

    uint256 public immutable MAX_TOTAL_SUPPLY = 7000;

    constructor(string memory baseTokenURI, address proxySaleAddress) ERC721A("Hey! Reap3r", "REAP3R", 100) {
        _baseTokenURI = baseTokenURI;
        _proxySaleAddress = proxySaleAddress;
    }

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return _baseTokenURI;
    }

    function setURI(string memory baseTokenURI) public virtual onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function mint(address to, uint256 num) external override(IReap3rMint) {

        require(_proxySaleAddress == msg.sender, "Sale: Not the designated resale address");

        require(MAX_TOTAL_SUPPLY - totalSupply() >= num, "Max supply reached");

        _safeMint(to, num);
    }

    function totalSupply() public view virtual override(ERC721A, IReap3rMint) returns (uint256) {
        return super.totalSupply();
    }
}