// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

error BeforeMint();
error MintReachedMaxSupply();
error MintReachedSaleSupply();
error MintReachedMaxMintSupply();
error MintReachedWhitelistSaleSupply();

contract maplen is ERC721A('maplen', 'MPL'), Ownable {
    enum Phase {
        BeforeMint,
        WLMint,
        PublicMint
    }
    uint256 public constant maxSupply = 10000;

    mapping(address => uint256) public whitelist;
    mapping(address => uint256) public whitelistMinted;

    Phase public phase = Phase.BeforeMint;

    string public baseURI = 'ipfs://QmNNraBuAxSsWY2SgjPZPWCqXzwiWrn6YiLvA46DP1gKfb/';
    string public metadataExtentions = '.json';
    uint256 public maxMintSupply = 15;

    constructor() {
        whitelistMinted[0x2d58a89D33C32eBE38e21E358D6F9C3803Fc2473] += 1;
        _safeMint(0x2d58a89D33C32eBE38e21E358D6F9C3803Fc2473, 1);
    }

    function mint(uint256 quantity) external {
        if (phase != Phase.PublicMint) revert BeforeMint();
        if (totalSupply() + quantity > maxSupply) revert MintReachedMaxSupply();
        if (whitelist[_msgSender()] == 0) revert MintReachedWhitelistSaleSupply();
        if (quantity > maxMintSupply) revert MintReachedMaxMintSupply();
        _safeMint(_msgSender(), quantity);
    }

    function whitelistMint(uint256 quantity) external {
        if (phase != Phase.WLMint) revert BeforeMint();
        if (totalSupply() + quantity > maxSupply) revert MintReachedMaxSupply();
        if (whitelistMinted[_msgSender()] + quantity > whitelist[_msgSender()]) revert MintReachedWhitelistSaleSupply();
        whitelistMinted[_msgSender()] += quantity;
        _safeMint(_msgSender(), quantity);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setWhitelist(address[] memory addresses, uint256[] memory saleSupplies) public onlyOwner {
        require(addresses.length == saleSupplies.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = saleSupplies[i];
        }
    }

    function setPhase(Phase _newPhase) public onlyOwner {
        phase = _newPhase;
    }

    function setMaxMintSupply(uint256 _newMaxMintSupply) public onlyOwner {
        maxMintSupply = _newMaxMintSupply;
    }

    function setMetadataExtentions(string memory _newMetadataExtentions) public onlyOwner {
        metadataExtentions = _newMetadataExtentions;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), metadataExtentions));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}