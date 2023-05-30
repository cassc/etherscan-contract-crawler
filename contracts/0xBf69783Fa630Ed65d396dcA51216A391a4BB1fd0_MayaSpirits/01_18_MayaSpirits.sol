// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {DefaultOperatorFilterer, OperatorFilterer} from "DefaultOperatorFilterer.sol";

contract MayaSpirits is ERC721, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    using Strings for uint256;

    mapping(address => bool) public allowlisted;
    mapping(address => uint256) public AmountClaimedWalletAllowlist;
    mapping(address => uint256) public AmountClaimedWalletPublic;

    uint256 public constant MAX_SUPPLY = 6000;
    uint256 public constant MAX_MINT_AMOUNT_WALLET = 5;
    uint256 public constant MINT_PRICE_ALLOWLIST = 0.1 ether; 
    uint256 public constant MINT_PRICE_PUBLIC = 0.15 ether; 
    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadata;

    string private baseURI;
    uint256 public _minted = 0;

    bool public AllowlistMintActive = false;
    bool public PublicMintActive = false;
    bool public revealed = false;



    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {
    }

    function AllowlistMint(uint256 amount) public payable nonReentrant {
        require(AllowlistMintActive, "The Allowlist Sale is not enabled!");
        require(isAllowlisted(msg.sender), "Not a part of Allowlist");
        require(
            msg.value == amount * MINT_PRICE_ALLOWLIST,
            "Invalid funds provided"
        );
        require(
            amount > 0 && amount <= MAX_MINT_AMOUNT_WALLET,
            "Must mint between the min and max."
        );
        require(_minted + amount <= MAX_SUPPLY, "Exceed max supply");
        require(
            AmountClaimedWalletAllowlist[msg.sender] + amount <= MAX_MINT_AMOUNT_WALLET,
            "Already minted Max Mints Allowlist"
        );
        AmountClaimedWalletAllowlist[msg.sender] += amount;
        for (uint256 i = 0; i < amount; i++) {
            _minted ++;
            uint256 mintIndex = _minted ;
            _safeMint(msg.sender, mintIndex);
        }
    }

    function PublicMint(uint256 amount) public payable nonReentrant {
        require(PublicMintActive, "The Public Sale is not enabled!");
        require(
            msg.value == amount * MINT_PRICE_PUBLIC,
            "Invalid funds provided"
        );
        require(
            amount > 0 && amount <= MAX_MINT_AMOUNT_WALLET,
            "Must mint between the min and max."
        );
        require(_minted + amount <= MAX_SUPPLY, "Exceed max supply");
        require(
            AmountClaimedWalletPublic[msg.sender] + amount <= MAX_MINT_AMOUNT_WALLET,
            "Already minted Max Mints Public"
        );
        AmountClaimedWalletPublic[msg.sender] += amount;
        for (uint256 i = 0; i < amount; i++) {
            _minted ++;
            uint256 mintIndex = _minted;
            _safeMint(msg.sender, mintIndex);
        }
    }

    function teamMint(uint256 amount) external onlyOwner {
        require(_minted + amount <= MAX_SUPPLY, "Max supply exceeded!");
        for (uint256 i = 0; i < amount; i++) {
            _minted ++;
            uint256 mintIndex = _minted;
            _safeMint(msg.sender, mintIndex);
        }
    }

    function setAllowlistMint(bool _state) public onlyOwner {
        AllowlistMintActive = _state;
    }

    function setPublicMint(bool _state) public onlyOwner {
        PublicMintActive = _state;
    }

    function addToAllowlist(address _addr) public onlyOwner {
        allowlisted[_addr] = true;
    }

    function addArrayToAllowlist(address[] memory _addrs) public onlyOwner {
        for (uint256 i = 0; i < _addrs.length; i++)
            allowlisted[_addrs[i]] = true;
    }

    function removeFromAllowlist(address _addr) public onlyOwner {
        allowlisted[_addr] = false;
    }

    function isAllowlisted(address _addr) public view returns (bool) {
        return allowlisted[_addr];
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (revealed == false) {
            return hiddenMetadata;
        }
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }


    function setHiddenMetadata(string memory _hiddenmetadata) public onlyOwner {
        hiddenMetadata = _hiddenmetadata;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }


  function withdrawMoney() external onlyOwner {
        Address.sendValue(payable(owner()), address(this).balance);
    }
     function withdrawMoneyTo(address payoutAddress) external onlyOwner {
    (bool success, ) = payoutAddress.call{value: address(this).balance}("");
        require(success, "WITHDRAW FAILED!");
    }
}