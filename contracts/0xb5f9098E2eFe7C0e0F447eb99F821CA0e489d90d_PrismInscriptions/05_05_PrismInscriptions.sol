// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PrismInscriptions is ERC721A, Ownable {

    /*
    * 777 Artisan Digital Collectibles, redeemable for ordinal inscriptions on BTC
    * Burn your token to join the waiting queue to receive a 1 to 1 inscription. More
    * details to come on our twitter: https://twitter.com/PrismsBTC
    */

    struct InscriptionOrder {
        uint256 tokenID;
        string btcAddress;
    }

    uint256 public index = 0;
    uint256 public maxPerTxn = 5;
    uint256 public maxSupply = 777;
    uint256 public mintCost = 0.003 ether;
    uint256 public burnCost = 0.025 ether;

    string public baseURI = "ipfs://QmeACVu926MRL2v1GAqJ35iei1epP8mAQ5ZzqJim6BPpfe/";

    mapping(uint256 => InscriptionOrder) public orderQueue;

    constructor() ERC721A("Prism Inscriptions", "PRISM") {}

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : '';
    }

    function mint(uint256 _amount) public payable {
        require(totalSupply() + _amount <= maxSupply, "exceeds max supply");
        require(_amount <= maxPerTxn, "exceeds max per txn");
        require(msg.value >= _amount * mintCost, "not enough ether");

        _safeMint(msg.sender, _amount);
    }

    function burnForOrdinal(uint256 _tokenID, string memory btcAddress) public payable {
        require(msg.value >= burnCost, "not enough ether");
        require(msg.sender == ownerOf(_tokenID), "you dont own that token");

        _burn(_tokenID);
        orderQueue[index] = InscriptionOrder(_tokenID, btcAddress);
        index++;
    }

    function ownerMint(uint256 _amount) public onlyOwner {
        require(totalSupply() + _amount <= maxSupply, "exceeds max supply");

        _safeMint(msg.sender, _amount);
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }
}