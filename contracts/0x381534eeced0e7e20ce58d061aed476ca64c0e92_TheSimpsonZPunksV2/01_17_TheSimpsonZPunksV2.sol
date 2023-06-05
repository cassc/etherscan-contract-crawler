// SPDX-License-Identifier: MIT
// thanks Chiru Labs

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import './ERC721APausable.sol';
import './ERC721ABurnable.sol';
import './ERC721AQueryable.sol';
import './ERC721AOwnersExplicit.sol';

contract TheSimpsonZPunksV2 is ERC721A, ERC721APausable, ERC721ABurnable, ERC721AQueryable, ERC721AOwnersExplicit, Ownable, ReentrancyGuard {

    uint public   maxPerTx          = 10;
    uint public   maxPerWallet      = 100;
    uint public   price             = 0.024 ether;
    uint public   totalAvailable    = 1989;
    bool public   mintPaused        = true;

    string public baseURI;

    constructor() ERC721A('TheSimpsonZPunksV2', 'SPV2') {}

    function mint(uint256 quantity) external payable {
        require( mintPaused == false, 'Minting is paused.');
        require( msg.sender == tx.origin, 'Sender does not match origin.');
        require(totalSupply() + quantity < totalAvailable + 1, 'SOLD OUT!');
        require(quantity < maxPerTx + 1, 'Too many in this transaction!');
        require(msg.value == quantity * price,'Please send the right amount');
        require(numberMinted(msg.sender) + quantity <= maxPerWallet,'Minting too many on this wallet');

        _safeMint(msg.sender, quantity);
    }

    function reserve(uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity < totalAvailable + 1, 'Sorry do not have that many');
        _safeMint(msg.sender, quantity);
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }

    function setCost(uint256 price_) external onlyOwner {
        price = price_;
    }

    function setMaxPerWallet(uint256 maxPerWallet_) external onlyOwner {
        maxPerWallet = maxPerWallet_;
    }

    function setMaxPerTx(uint256 maxPerTx_) external onlyOwner {
        maxPerTx = maxPerTx_;
    }

    function setTotalAvailable(uint256 totalAvailable_) external onlyOwner {
        totalAvailable = totalAvailable_;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}('');
        require(success, 'Transfer failed.');
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function burn(uint256 tokenId, bool approvalCheck) public {
        _burn(tokenId, approvalCheck);
    }

    function safeMint(address to, uint256 quantity) public {
        _safeMint(to, quantity);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(ERC721A, ERC721APausable) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function pauseMint() external {
        mintPaused = true;
    }

    function unpauseMint() external {
        mintPaused = false;
    }

    function pauseAllTransactions() external {
        _pause();
    }

    function unpauseAllTransactions() external {
        _unpause();
    }
}