// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DegenMoodSwings is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    uint256 price;
    uint256 _maxSupply;
    uint256 maxMintAmountPerTx;
    uint256 maxMintAmountPerWallet;
    uint256 maxFree;
    uint256 maxperAddressFreeLimit;

    string baseURL = ""; // base uri for meta data
    string ExtensionURL = ".json";

    bool paused = false; // by default contract is paused

    mapping(address => uint256) public addressFreeMintedBalance; // to keep track of free minted balance per address

    constructor(
        uint256 _price,
        uint256 __maxSupply,
        string memory _initBaseURI,
        uint256 _maxMintAmountPerTx,
        uint256 _maxMintAmountPerWallet,
        uint256 _maxFree,
        uint256 _maxperAddressFreeLimit
    ) ERC721A("Degen Mood Swings", "DMS") {
        baseURL = _initBaseURI; // setting cloud ipfs address
        price = _price; // setting price of token
        _maxSupply = __maxSupply;   // setting max supply of token
        maxMintAmountPerTx = _maxMintAmountPerTx; // setting max mint amount per tx
        maxMintAmountPerWallet = _maxMintAmountPerWallet; // setting max mint amount per wallet
        maxFree = _maxFree; // setting max free mint amount per address
        maxperAddressFreeLimit = _maxperAddressFreeLimit; // setting max free mint amount per address
    }

    // ================== Mint Function =======================

    function mint(uint256 _mintAmount) public payable nonReentrant {
        require(!paused, "The contract is paused!"); // check if contract is paused
        // check if mint amount is greater than max mint amount per tx
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx ,
            "Invalid mint amount!"
        ); 
        // check if mint amount is greater than max supply
        require(
            totalSupply() + _mintAmount <= _maxSupply,
            "Max supply exceeded!"
        );
        // check if address has sufficient balance to mint
        require(
            msg.value >= price * _mintAmount,
            "You dont have enough funds!"
        );
        // check if address has already minted max amount
        require(
            balanceOf(msg.sender) + _mintAmount <= maxMintAmountPerWallet,
            "Max mint per wallet exceeded!"
        );
        _safeMint(msg.sender, _mintAmount);
    }

    function MintFree(uint256 _mintAmount) public payable nonReentrant {
        uint256 s = totalSupply();
        uint256 addressFreeMintedCount = addressFreeMintedBalance[msg.sender]; // get free minted balance of address
        require(!paused, "The contract is paused!"); // check if contract is paused
        // check if mint amount is greater than max free mint amount per tx
        require(
            addressFreeMintedCount + _mintAmount <= maxperAddressFreeLimit,
            "max NFT per address exceeded"
        );
        require(_mintAmount > 0, "Cant mint 0");
        require(s + _mintAmount <= maxFree, "Cant go over supply");
        for (uint256 i = 0; i < _mintAmount; ++i) {
            addressFreeMintedBalance[msg.sender]++; // increment free minted balance of token address
        }
        _safeMint(msg.sender, _mintAmount);
        delete s;
        delete addressFreeMintedCount;
    }

    // ================== (Owner Only) ===============

    function pause(bool state) public onlyOwner {
        paused = state;
    }

    function safeMint(address to, uint256 quantity) public onlyOwner {
        _safeMint(to, quantity);
    }

    function setbaseURL(string memory uri) public onlyOwner {
        baseURL = uri;
    }

    function setExtensionURL(string memory uri) public onlyOwner {
        ExtensionURL = uri;
    }

    function setCostPrice(uint256 _cost) public onlyOwner {
        price = _cost;
    }

    function setSupply(uint256 supply) public onlyOwner {
        _maxSupply = supply;
    }

    // ================================ Withdraw Function ====================

    function withdraw() public onlyOwner nonReentrant {
        uint256 CurrentContractBalance = address(this).balance;
        (bool success, ) = payable(owner()).call{value: CurrentContractBalance}("");
        require(success, "Withdraw failed!");
    }
    
    // =================== (View Only) ====================

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        ExtensionURL
                    )
                )
                : "";
    }

    function cost() public view returns (uint256) {
        return price;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURL;
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }
}