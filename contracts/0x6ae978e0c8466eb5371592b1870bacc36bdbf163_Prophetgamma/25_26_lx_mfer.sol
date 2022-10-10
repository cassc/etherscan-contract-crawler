// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract TheThreeGates is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private currentTokenId;

    string public baseTokenURI;
    uint256 public maxSupply;
    bool public paused = true;

    constructor(uint256 _maxSupply, string memory _baseTokenURI) ERC721('TheThreeGates', 'TTG') {
        setPaused(true);
        maxSupply = _maxSupply;
        baseTokenURI = _baseTokenURI;
    }

    modifier pausedMintCompliance() {
        require(!paused, 'contract is paused');
        _;
    }

    function mint(address to) public payable pausedMintCompliance {
        require(balanceOf(to) < 1, 'address can not mint more than 1 times');
        require(totalSupply() < maxSupply, 'max supply exceeded');
        if (totalSupply() >= 10) {
            require(0.01 ether == msg.value, 'ether value you sent not correct');
        }
        currentTokenId.increment();
        uint256 itemId = currentTokenId.current();
        _safeMint(to, itemId);
    }

    function selfMint(uint256 _amount) public onlyOwner {
        require(totalSupply() + _amount < maxSupply, 'max supply exceeded');
        for (uint256 i = 0; i < _amount; i++) {
            currentTokenId.increment();
            uint256 itemId = currentTokenId.current();
            _safeMint(msg.sender, itemId);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), '.json')) : '';
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function getAirdropList(uint256 _amount) external view onlyOwner returns (address[] memory) {
        uint256 amount = _amount < totalSupply() ? _amount : totalSupply();
        address[] memory airdropList = new address[](amount);
        for (uint256 i = 0; i < amount; i++) {
            airdropList[i] = ownerOf(i + 1);
        }
        return airdropList;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}