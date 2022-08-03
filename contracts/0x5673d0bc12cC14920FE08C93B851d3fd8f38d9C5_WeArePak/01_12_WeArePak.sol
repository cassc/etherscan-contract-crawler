// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WeArePak is ERC721A, Ownable {

    uint constant public MAX_SUPPLY = 1500;

    string public baseURI = "https://storage.googleapis.com/wearepak/meta/";
    uint public maxMintsPerWallet = 3;

    uint public publicSaleStartTimestamp = 1659481200;

    mapping(address => uint) public mintedNFTs;

    constructor() ERC721A("We Are Pak", "PAK", 15) {
    }

    function setBaseURI(string memory _baseURIArg) external onlyOwner {
        baseURI = _baseURIArg;
    }

    function configure(
        uint _maxMintsPerWallet,
        uint _publicSaleStartTimestamp
    ) external onlyOwner {
        maxMintsPerWallet = _maxMintsPerWallet;
        publicSaleStartTimestamp = _publicSaleStartTimestamp;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mint(uint amount) external {
        require(tx.origin == msg.sender, "The caller is another contract");
        require(block.timestamp >= publicSaleStartTimestamp, "Minting is not available");
        require(amount > 0, "Zero amount to mint");

        require(totalSupply() + amount <= MAX_SUPPLY, "Tokens total supply reached limit");
        require(mintedNFTs[msg.sender] + amount <= maxMintsPerWallet, "No more mints for this wallet!");
        mintedNFTs[msg.sender] += amount;

        _safeMint(msg.sender, amount);
    }

    function dropToDevs(address[] calldata addresses, uint[] calldata amounts) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            require(totalSupply() + amounts[i] <= MAX_SUPPLY, "Tokens supply reached limit");
            _safeMint(addresses[i], amounts[i]);
        }
    }

}