//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract EScapes is ERC721Royalty, Ownable {
    uint256 public constant MAX_SUPPLY = 16;
    string public _baseTokenURI;

    constructor(string memory baseURI)
        ERC721('E/SCAPES by Pullman', 'E/SCAPES')
    {
        setBaseURI(baseURI);
        _setDefaultRoyalty(
            address(0x7425Dc654E8cd0794e9a818A1BAb22809bE74c55),
            0
        );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * All artworks will be bought via online auction, and therefore the owner will mint to the recipient.
     */
    function ownerMint(uint256 tokenId, address to) public onlyOwner {
        require(tokenId < MAX_SUPPLY, 'Failed to Mint. TokenId out of range.');
        _safeMint(to, tokenId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);
    }
}