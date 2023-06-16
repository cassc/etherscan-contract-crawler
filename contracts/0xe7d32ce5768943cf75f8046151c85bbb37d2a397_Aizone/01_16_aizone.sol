// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Aizone is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256[] public mintPrices = [1500000000000000, 10000000000000000, 5000000000000000]; 

    bool public mintEnabled;
    string internal baseTokenUri;
    address payable public withdrawWallet;

    constructor() payable ERC721('Parti Aizone', 'PARTI') {
        withdrawWallet = payable(address(0x07D41924f7561Ec907e0e8d056D512169B3665e9));
        baseTokenUri = "https://parti-ai.s3.eu-west-1.amazonaws.com/parti-aizone/";
    }

    function setMintEnabled(bool mintEnabled_) external onlyOwner {
        mintEnabled = mintEnabled_;
    }

    function setMintPrices(uint256[] memory newPrices) external onlyOwner {
        mintPrices = newPrices;
    }

    function setBaseTokenUri(string memory uri) external onlyOwner {
        baseTokenUri = uri;
    }

    function tokenURI(uint256 tokenId_) public view override returns (string memory) {
        require(_exists(tokenId_), "Token does not exist");
        return string(abi.encodePacked(baseTokenUri, Strings.toString(tokenId_), ".json"));
    }

    function mint(uint256 priceIndex) public payable {
        require(mintEnabled, "Mint is closed.");
        require(priceIndex < mintPrices.length, "Invalid price index.");
        require(msg.value == mintPrices[priceIndex], "Incorrect funds in wallet.");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    function setWithdrawWallet(address payable wallet) external onlyOwner {
        withdrawWallet = wallet;
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "No balance to withdraw.");
        (bool success, ) = withdrawWallet.call{ value: address(this).balance }('');
        require(success, "Withdraw unsuccessful");
    }
    
    function stripeMint(address to) external onlyOwner {
        require(mintEnabled, "Mint is closed.");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}