// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract Waveblocks is ERC721Enumerable, ReentrancyGuard, Ownable {
    uint256 public constant MAX_SUPPLY = 1024;
    uint256 public constant MAX_PER_TX = 4;
    uint256 public constant MAX_PER_ADDRESS = 4;

    uint256 public price = .25 ether;
    bool public isSaleActive;

    uint256 private _tokensMinted;
    bool private _hasTeamMinted;
    string private _baseTokenURI;

    constructor() ERC721('Waveblocks', 'WAVE') {}

    function mint(uint256 numTokens) external payable virtual nonReentrant {
        require(isSaleActive, 'Sale is not active');
        require(price * numTokens == msg.value, 'ETH amount is incorrect');
        require(numTokens <= MAX_PER_TX, 'Mint fewer waves');
        require(balanceOf(_msgSender()) + numTokens <= MAX_PER_ADDRESS, 'Max waves obtained');

        _mint(numTokens);
    }

    function _mint(uint256 numTokens) private {
        require(totalSupply() < MAX_SUPPLY, 'All waves minted');
        require(totalSupply() + numTokens <= MAX_SUPPLY, 'Minting exceeds max supply');
        require(numTokens > 0, 'Must mint at least 1 wave');

        for (uint256 i = 0; i < numTokens; i++) {
            if (_tokensMinted < MAX_SUPPLY) {
                uint256 tokenId = _tokensMinted + 1;
                _safeMint(_msgSender(), tokenId);
                _tokensMinted += 1;
            }
        }
    }

    function teamMint() external onlyOwner {
        require(!_hasTeamMinted, 'Team already minted');

        _mint(15);
        _hasTeamMinted = true;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function toggleSale() public onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function setPriceInWei(uint256 priceInWei) public onlyOwner {
        price = priceInWei;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }
}