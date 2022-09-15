// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Kungfungus is ERC721, Pausable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;

    enum State {
        Closed,
        Presale,
        PresaleTwo,
        PublicSale
    }

    Counters.Counter private _tokenIdCounter;

    string private _metadataEndpoint = "https://api.kungfungus.com/tokens/";

    State private _saleState;

    uint256 private _supplyTotal = 10101;

    uint256 private _supplyPresale = 1000;

    uint256 private _supplyPresaleTwo = 1000;

    uint256 private _mintCostPresale = 0.03 ether;

    uint256 private _mintCostPresaleTwo = 0.04 ether;

    uint256 private _mintCostPublicSale = 0.05 ether;

    uint256 private _mintedPresale = 0;

    uint256 private _mintedPresaleTwo = 0;

    uint256 private _maxTokensPerAddress = 20;

    mapping(address => uint256) public mintsPerAddress;

    constructor() ERC721("Kung Fungus", "KUNGFUNGUS") {
        _tokenIdCounter.increment();
    }

    function _baseURI() internal view override returns (string memory) {
        return _metadataEndpoint;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        mintsPerAddress[to] += 1;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function setMetadataEndpoint(string memory endpoint) public onlyOwner {
        _metadataEndpoint = endpoint;
    }

    function setTotalSupply(uint256 supply) public onlyOwner {
        _supplyTotal = supply;
    }

    function setPresaleSupply(uint256 supply) public onlyOwner {
        _supplyPresale = supply;
    }

    function setPresaleTwoSupply(uint256 supply) public onlyOwner {
        _supplyPresaleTwo = supply;
    }

    function setPublicSaleCost(uint256 cost) public onlyOwner {
        _mintCostPublicSale = cost;
    }

    function setPresaleCost(uint256 cost) public onlyOwner {
        _mintCostPresale = cost;
    }

    function setPresaleTwoCost(uint256 cost) public onlyOwner {
        _mintCostPresaleTwo = cost;
    }

    function setState(State state) public onlyOwner {
        _saleState = state;
    }

    function setMaxTokensPerAddress(uint256 value) public onlyOwner {
        _maxTokensPerAddress = value;
    }

    function reservedMint(address to, uint256 quantity) public onlyOwner {
        require(
            _tokenIdCounter.current() + quantity <= _supplyTotal,
            "Not enough NFTs left to mint"
        );

        for (uint256 i = 0; i < quantity; i++) {
            safeMint(to);
        }
    }

    function withdraw(address recipient, uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "Incorrect amount");

        payable(recipient).transfer(amount);
    }

    function mint(uint256 quantity) public payable {
        require(_saleState != State.Closed, "Sale is not open");

        require(
            _tokenIdCounter.current() - 1 + quantity <= _supplyTotal,
            "Not enough NFTs left to mint"
        );

        require(
            mintsPerAddress[msg.sender] + quantity <= _maxTokensPerAddress,
            "This address cannot mint more NFTs"
        );

        if (_saleState == State.PublicSale) {
            publicSaleMint(quantity);
        } else if (_saleState == State.PresaleTwo) {
            presaleTwoMint(quantity);
        } else if (_saleState == State.Presale) {
            presaleMint(quantity);
        }
    }

    function presaleMint(uint256 quantity) internal {
        require(_saleState == State.Presale, "Sale is not open");

        require(
            _mintedPresale + quantity <= _supplyPresale,
            "Not enough NFTs left to mint"
        );

        require(
            msg.value >= mintCost() * quantity,
            "Not sufficient Ether to mint this amount of NFTs"
        );

        for (uint256 i = 0; i < quantity; i++) {
            safeMint(msg.sender);
            _mintedPresale += 1;
        }
    }

    function presaleTwoMint(uint256 quantity) internal {
        require(_saleState == State.PresaleTwo, "Sale is not open");

        require(
            _mintedPresaleTwo + quantity <= _supplyPresaleTwo,
            "Not enough NFTs left to mint"
        );

        require(
            msg.value >= mintCost() * quantity,
            "Not sufficient Ether to mint this amount of NFTs"
        );

        for (uint256 i = 0; i < quantity; i++) {
            safeMint(msg.sender);
            _mintedPresaleTwo += 1;
        }
    }

    function publicSaleMint(uint256 quantity) internal {
        require(_saleState == State.PublicSale, "Sale is not open");

        require(
            _tokenIdCounter.current() - 1 + quantity <= _supplyTotal,
            "Not enough NFTs left to mint"
        );

        require(
            msg.value >= mintCost() * quantity,
            "Not sufficient Ether to mint this amount of NFTs"
        );

        for (uint256 i = 0; i < quantity; i++) {
            safeMint(msg.sender);
        }
    }

    function mintCost() public view returns (uint256) {
        if (_saleState == State.PublicSale) {
            return _mintCostPublicSale;
        } else if (_saleState == State.PresaleTwo) {
            return _mintCostPresaleTwo;
        } else {
            return _mintCostPresale;
        }
    }

    function getSupplyPresale() public view returns (uint256) {
        return _supplyPresale;
    }

    function getSupplyPresaleTwo() public view returns (uint256) {
        return _supplyPresaleTwo;
    }

    function getSupplyTotal() public view returns (uint256) {
        return _supplyTotal;
    }

    function getMintedPresale() public view returns (uint256) {
        return _mintedPresale;
    }

    function getMintedPresaleTwo() public view returns (uint256) {
        return _mintedPresaleTwo;
    }

    function getMintedTotal() public view returns (uint256) {
        return _tokenIdCounter.current() - 1;
    }

    function getMaxTokensPerAddress() public view returns (uint256) {
        return _maxTokensPerAddress;
    }

    function getCurrentState() public view returns (State) {
        return _saleState;
    }
}