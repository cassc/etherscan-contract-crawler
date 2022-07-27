// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

error BeforeMint();
error MintReachedMaxSupply();
error MintReachedSaleSupply();
error MintReachedWhitelistSaleSupply();
error MintReachedWaitlistSaleSupply();
error MintNotWhitelisted();
error MintNotWaitlisted();
error MintValueIsMissing();

contract MediaDAOFriendsNagoya is ERC721A('MediaDAO Friends Nagoya', 'MDFN'), Ownable {
    enum Phase {
        BeforeMint,
        WhitelistMint,
        WaitlistMint,
        PublicMint
    }
    address public constant withdrawAddress = 0x76EFeCA40b573C3E6e9b0c1D00C97252Bcf29AAb;
    uint256 public constant maxSupply = 1241;

    mapping(address => bool) public whitelist;
    mapping(address => bool) public waitlist;
    mapping(address => uint256) public whitelistMinted;
    mapping(address => uint256) public waitlistMinted;
    mapping(address => uint256) public minted;

    uint256 public mintCost = 0.04 ether;
    uint256 public waitlistMintCost = 0.04 ether;
    uint256 public whitelistMintCost = 0.03 ether;
    uint256 public saleSupply = 10;
    uint256 public whitelistSaleSupply = 2;
    uint256 public waitlistSaleSupply = 2;
    Phase public phase = Phase.BeforeMint;

    string public baseURI = 'ipfs://QmaXPk575oZfyBZnq5u81dxMuqvLwwjmPyGzZ2ycdqrQz9/';
    string public metadataExtentions = '.json';

    constructor() {
        _safeMint(withdrawAddress, 130);
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

    function waitlistMint(uint256 quantity) external payable {
        if (phase != Phase.WaitlistMint) revert BeforeMint();
        if (totalSupply() + quantity > maxSupply) revert MintReachedMaxSupply();
        if (!waitlist[_msgSender()]) revert MintNotWaitlisted();
        if (waitlistMinted[_msgSender()] + quantity > waitlistSaleSupply) revert MintReachedWaitlistSaleSupply();
        if (msg.sender != owner())
            if (msg.value < waitlistMintCost * quantity) revert MintValueIsMissing();
        waitlistMinted[_msgSender()] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function whitelistMint(uint256 quantity) external payable {
        if (phase != Phase.WhitelistMint) revert BeforeMint();
        if (totalSupply() + quantity > maxSupply) revert MintReachedMaxSupply();
        if (!whitelist[_msgSender()]) revert MintNotWhitelisted();
        if (whitelistMinted[_msgSender()] + quantity > whitelistSaleSupply) revert MintReachedWhitelistSaleSupply();
        if (msg.sender != owner())
            if (msg.value < whitelistMintCost * quantity) revert MintValueIsMissing();
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

    function setWhitelistMintCost(uint256 _newCost) public onlyOwner {
        whitelistMintCost = _newCost;
    }

    function setWaitlistMintCost(uint256 _newCost) public onlyOwner {
        waitlistMintCost = _newCost;
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

    function setWaitlist(address[] memory addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            waitlist[addresses[i]] = true;
        }
    }

    function removeWaitlist(address[] memory addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            waitlist[addresses[i]] = false;
        }
    }

    function setPhase(Phase _newPhase) public onlyOwner {
        phase = _newPhase;
    }

    function setSaleSupply(uint256 _newSaleSupply) public onlyOwner {
        saleSupply = _newSaleSupply;
    }

    function setWhitelistSaleSupply(uint256 _newWhitelistSaleSupply) public onlyOwner {
        whitelistSaleSupply = _newWhitelistSaleSupply;
    }

    function setWaitlistSaleSupply(uint256 _waitlistSaleSupply) public onlyOwner {
        waitlistSaleSupply = _waitlistSaleSupply;
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