/*
  /$$$$$$  /$$$$$$$$ /$$   /$$ /$$$$$$$   /$$$$$$   /$$$$$$
 /$$__  $$|__  $$__/| $$  / $$| $$__  $$ /$$__  $$ /$$__  $$
| $$  \ $$   | $$   |  $$/ $$/| $$  \ $$| $$  \ $$| $$  \ $$
| $$$$$$$$   | $$    \  $$$$/ | $$  | $$| $$$$$$$$| $$  | $$
| $$__  $$   | $$     >$$  $$ | $$  | $$| $$__  $$| $$  | $$
| $$  | $$   | $$    /$$/\  $$| $$  | $$| $$  | $$| $$  | $$
| $$  | $$   | $$   | $$  \ $$| $$$$$$$/| $$  | $$|  $$$$$$/
|__/  |__/   |__/   |__/  |__/|_______/ |__/  |__/ \______/
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ATXDAONFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    bool public isMintable = false;
    uint256 public _mintPrice = 512000000000000000; // 0.512 ether
    uint256 public _mintQuantity = 25;

    Counters.Counter private _mintCount;
    Counters.Counter private _tokenIds;

    string private _tokenURI;

    constructor() ERC721("ATX DAO", "ATX") {}

    // Normal mint
    function mint() external payable {
        require(
            isMintable == true,
            "ATX DAO NFT is not mintable at the moment!"
        );
        require(
            balanceOf(msg.sender) == 0,
            "Minting is only available for non-holders"
        );
        require(
            _mintCount.current() < _mintQuantity,
            "No more NFTs remaining!"
        );
        require(msg.value >= _mintPrice, "Not enough ether sent to mint!");
        require(msg.sender == tx.origin, "No contracts!");

        // Mint
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _tokenURI);

        _mintCount.increment();
    }

    // Dev mint
    function mintSpecial(address[] memory recipients, string memory tokenURI)
        external
        onlyOwner
    {
        for (uint64 i = 0; i < recipients.length; i++) {
            _tokenIds.increment();
            uint256 newTokenId = _tokenIds.current();

            _safeMint(recipients[i], newTokenId);
            _setTokenURI(newTokenId, tokenURI);
        }
    }

    function startMint(
        uint256 mintPrice,
        uint256 mintQuantity,
        string memory tokenURI
    ) public onlyOwner {
        isMintable = true;
        _mintPrice = mintPrice;
        _mintQuantity = mintQuantity;
        _tokenURI = tokenURI;
        _mintCount.reset();
    }

    function endMint() public onlyOwner {
        isMintable = false;
    }

    function sweepEth() public onlyOwner {
        uint256 _balance = address(this).balance;
        payable(owner()).transfer(_balance);
    }
}