// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./security/Pausable.sol";
import "./access/Ownable.sol";
import "./token/ERC721A/ERC721A.sol";

contract Benders is ERC721A, Ownable, Pausable {

    string public baseURI;
    string public baseExtension = ".json";

    uint256 public PRICE = 0.002 ether;
    uint256 public PURCHASE_LIMIT = 10;
    uint256 public MAX_SUPPLY = 999;

    //_baseURI has to include the '/' at the end
    constructor(string memory _baseURI) ERC721A("Benders", "BNDRS") {
        setBaseURI(_baseURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function mint(uint256 numberOfTokens) external payable {
        uint256 supply = totalSupply();

        require(numberOfTokens > 0, "Cannot mint less than 1");
        require(numberOfTokens <= PURCHASE_LIMIT, "Purchase limit exceeded");
        require(supply + numberOfTokens <= MAX_SUPPLY, "Max supply exceeded");
        if (supply + numberOfTokens >= 500) {
            require(PRICE * numberOfTokens == msg.value, "Wrong ETH amount");
        }

        _safeMint(msg.sender, numberOfTokens);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns(string memory) {
        require(_exists(tokenId), "Token not found");

        uint256 _newTokenId = tokenId + 1;

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _toString(_newTokenId), baseExtension)) : "";
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

}