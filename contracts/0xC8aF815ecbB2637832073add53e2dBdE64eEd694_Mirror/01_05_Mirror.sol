// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract Mirror is Ownable, ERC721A {
    string public baseUri = "ipfs://bafybeibj4so2o5nkjvlby7a3zbcq644t2tvhz4w47c4hgrsvmq6wyhgftu/";
    uint public COST = 0.008 ether;
    uint public MAX_SUPPLY = 444;
    uint public MAX_PER_WALLET = 2;
    bool public mintEnabled = true;
    mapping(address => uint) public mintedAmount;

    constructor() ERC721A("Mirror Mirror On The Wall", "MIRROR") {}

    function mint(uint _quantity) external payable {
        require(tx.origin == msg.sender, "Caller cannot be a contract");
        require(mintEnabled, "Sale is not active yet");
        require(msg.value >= COST * _quantity, "Not enough Eth");
        require(mintedAmount[msg.sender] + _quantity <= MAX_PER_WALLET, "Already minted max");
        require(MAX_SUPPLY >= totalSupply() + _quantity, "Sold out");
        mintedAmount[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);
    }

    function toggleOpen() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function setCost(uint _cost) external onlyOwner {
        COST = _cost;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseUri = baseURI;
    }

    function tokenURI(uint tokenId) public view virtual override returns(string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId + 1), ".json")) : "";
    }

    function _baseURI() internal view virtual override returns(string memory) {
        return baseUri;
    }

    function withdraw() external onlyOwner {
		(bool os,) = payable(owner()).call{value: address(this).balance}("");
		require(os);
	}
}