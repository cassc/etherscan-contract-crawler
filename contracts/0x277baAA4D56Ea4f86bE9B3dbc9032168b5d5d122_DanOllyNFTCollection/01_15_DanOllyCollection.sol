// contracts/ERC721/new_contract_example/RamperToken721.sol
// SPDX-License-Identifier: MIT
// This is an example showing a contract that is compatible with Ramper's NFT Checkout
// Find out more at https://www.ramper.xyz/nftcheckout

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./IRamperInterface721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DanOllyNFTCollection is ERC721Enumerable, Ownable, IRamperInterface721 {
    uint256 constant public MAX_TOKENS = 100;
    uint256 constant public MAX_TOKENS_PER_TXN = 10;
    uint256 constant public MAX_TOKENS_PER_ADDRESS = 100;
    uint256 constant public TOKEN_PRICE = 0.006 ether;

    string public baseTokenURI = "ipfs://bafybeidvcrtmu5g3szz7pj7jvxt2dy6ez5v4l2e2kvs5tgmwuremwoqbxa/";

    constructor() ERC721("DanOllyNFTCollection", "DANOLLYNFT") {

    }

    function availableTokens(address _userWallet) override external view returns (uint256 quantity) {
        // The example shows a 3-part limitation for users:
        // 1. a remaining-tokens limit (required)
        // 2. a per-wallet limit (optional)
        // 3. a per-transaction limit (optional)
        // Where the limit retured is the lowest of these 3

        // Because we don't limit transfers, balanceOf can be larger than max tokens per address
        if (MAX_TOKENS_PER_ADDRESS < balanceOf(_userWallet)) {
            return 0;
        }

        uint256 userRemaining = MAX_TOKENS_PER_ADDRESS - balanceOf(_userWallet);
        uint256 remainingSupply = MAX_TOKENS - totalSupply();

        // Find minimum value and return
        if (MAX_TOKENS_PER_TXN < userRemaining && MAX_TOKENS_PER_TXN < remainingSupply) {
            return MAX_TOKENS_PER_TXN;
        } else if (userRemaining < remainingSupply) {
            return userRemaining;
        } else {
            return remainingSupply;
        }
    }

    function price() override external pure returns (uint256) {
        return TOKEN_PRICE;
    }

    function mint(address _userWallet, uint256 _quantity) override external payable {
        require(msg.value >= TOKEN_PRICE * _quantity, "Insufficient funds for requested tokens");
        require(this.availableTokens(_userWallet) >= _quantity, "Requested number of tokens is over limit for minting");

        uint256 tokenStart = totalSupply();

        for(uint256 i=0; i < _quantity; i++) {
            uint256 _tokenId = tokenStart + i;
            _safeMint(_userWallet, _tokenId);
        }
    }

    // ERC721Metadata
    function _baseURI() override internal view virtual returns (string memory) {
        return baseTokenURI;
    }

    function safeBulkTransferFrom(address _from, address _to, uint256[] memory _tokenIds) override external {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function withdraw() public payable onlyOwner {
uint256 balance = address(this).balance;
payable(owner()).transfer(balance);

}
}