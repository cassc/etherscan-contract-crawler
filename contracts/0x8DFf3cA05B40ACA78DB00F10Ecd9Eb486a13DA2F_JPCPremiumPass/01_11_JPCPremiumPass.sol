// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

error BeforeMint();
error MintReachedMaxSupply();
error MintReachedSaleSupply();
error MintReachedWhitelistSaleSupply();
error MintNotWhitelisted();
error MintValueIsMissing();

contract JPCPremiumPass is ERC721A('PREMIUM PASS', 'JNM'), Ownable {
    enum Phase {
        BeforeMint,
        WLMint,
        PublicMint
    }
    address public constant withdrawAddress = 0x7F429dc5FFDa5374bb09a1Ba390FfebdeA4797a4;
    uint256 public constant maxSupply = 1000;

    mapping(address => bool) public whitelist;
    mapping(address => uint256) public whitelistMinted;
    mapping(address => uint256) public minted;

    uint256 public mintCost = 0.03 ether;
    uint256 public witelistMintCost = 0.01 ether;
    uint256 public saleSupply = 5;
    uint256 public whitelistSaleSupply = 2;
    Phase public phase = Phase.BeforeMint;

    string public baseURI = 'ipfs://QmQ6ULwGuy2C4LC1cecjsci9arBQgpksNtJnHR8oegkkDL/';
    string public metadataExtentions = '.json';

    constructor() {
        _safeMint(withdrawAddress, 100);
    }

    function mint(uint256 quantity) external payable {
        if (phase != Phase.PublicMint) revert BeforeMint();
        if (totalSupply() + quantity > maxSupply) revert MintReachedMaxSupply();
        if (minted[_msgSender()] + quantity > saleSupply) revert MintReachedSaleSupply();
        if (msg.sender != owner())
            if (msg.value < mintCost * quantity) revert MintValueIsMissing();
        minted[_msgSender()] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function whitelistMint(uint256 quantity) external payable {
        if (phase != Phase.WLMint) revert BeforeMint();
        if (totalSupply() + quantity > maxSupply) revert MintReachedMaxSupply();
        if (!whitelist[_msgSender()]) revert MintNotWhitelisted();
        if (whitelistMinted[_msgSender()] + quantity > whitelistSaleSupply) revert MintReachedWhitelistSaleSupply();
        if (msg.sender != owner())
            if (msg.value < witelistMintCost * quantity) revert MintValueIsMissing();
        whitelistMinted[_msgSender()] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}('');
        require(os);
    }

    function setMintCost(uint256 _newCost) public onlyOwner {
        mintCost = _newCost;
    }

    function setWitelistMintCost(uint256 _newCost) public onlyOwner {
        witelistMintCost = _newCost;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setWhitelist(address[] memory addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = true;
        }
    }

    function removeWhitelist(address[] memory addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = false;
        }
    }

    function setPhase(Phase _newPhase) public onlyOwner {
        phase = _newPhase;
    }

    function setSaleSupply(uint256 _newSaleSupply) public onlyOwner {
        saleSupply = _newSaleSupply;
    }

    function setWhitelistSaleSupply(uint256 _newWitelistSaleSupply) public onlyOwner {
        whitelistSaleSupply = _newWitelistSaleSupply;
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