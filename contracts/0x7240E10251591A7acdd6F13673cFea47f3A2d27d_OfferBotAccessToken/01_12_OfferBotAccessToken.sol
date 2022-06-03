// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";

contract OfferBotAccessToken is ERC721A, Ownable {
    using Strings for uint256;

    string private _baseTokenURI;
    uint256 public PRICE = 0.2 ether;
    uint16 public totalMinted = 0;
    uint16 MAX_TOKENS = 555;
    bool public publicMintActive = true;

    constructor(string memory _baseUri)
        ERC721A("Offer Bot Access Token", "OBAT", 55, MAX_TOKENS) // limit 10 mint
    {
        _baseTokenURI = _baseUri;
        _safeMint(msg.sender, 55);
        totalMinted = 55;
    }

    function mintShibaNFT(uint8 num_tokens) payable public {
        require (totalMinted + num_tokens <= MAX_TOKENS, "Mint would go above max supply");
        require (publicMintActive, "Minting is not active");
        require(msg.value >= (num_tokens * PRICE), "Not enough ether sent");

        _safeMint(msg.sender, num_tokens, "");
        totalMinted = totalMinted + num_tokens;

    }

    function updateBaseUri(string memory _newBaseUri) external onlyOwner {
        _baseTokenURI = _newBaseUri;
    }

    function togglePublicMintActive() external onlyOwner returns (bool) {
        publicMintActive = !publicMintActive;
        return publicMintActive;
    }

   function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;
        require(payable(msg.sender).send(_balance));
    }

}