// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";

contract Weth is ERC721 {
    string _baseTokenURI;
    uint256 public tokenIds;
    address public owner;

    constructor (string memory baseURI) ERC721("20 Ether(Wrapped)", "wETH") {
        _baseTokenURI = baseURI;
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function mint() public onlyOwner {
        tokenIds += 1;
        _safeMint(msg.sender, tokenIds);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        string memory baseURI = _baseURI();
        return baseURI;
    }

    function withdraw() public onlyOwner  {
        address _owner = owner;
        uint256 amount = address(this).balance;
        (bool sent, ) =  _owner.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}
    fallback() external payable {}
}