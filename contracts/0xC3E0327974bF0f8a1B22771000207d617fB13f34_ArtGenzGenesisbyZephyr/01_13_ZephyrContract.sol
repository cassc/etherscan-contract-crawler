//*      ___           ___                         ___           ___           ___           ___                    ___           ___           ___           ___           ___                       ___                                                       ___           ___           ___         ___                       ___     
//*     /\  \         /\  \                       /\__\         /\__\         /\  \         /\__\                  /\__\         /\__\         /\  \         /\__\         /\__\                     /\__\                  _____                              /\__\         /\__\         /\  \       /\  \                     /\  \    
//*    /::\  \       /::\  \         ___         /:/ _/_       /:/ _/_        \:\  \       /::|  |                /:/ _/_       /:/ _/_        \:\  \       /:/ _/_       /:/ _/_       ___         /:/ _/_                /::\  \         ___                /::|  |       /:/ _/_       /::\  \      \:\  \         ___       /::\  \   
//*   /:/\:\  \     /:/\:\__\       /\__\       /:/ /\  \     /:/ /\__\        \:\  \     /:/:|  |               /:/ /\  \     /:/ /\__\        \:\  \     /:/ /\__\     /:/ /\  \     /\__\       /:/ /\  \              /:/\:\  \       /|  |              /:/:|  |      /:/ /\__\     /:/\:\__\      \:\  \       /|  |     /:/\:\__\  
//*  /:/ /::\  \   /:/ /:/  /      /:/  /      /:/ /::\  \   /:/ /:/ _/_   _____\:\  \   /:/|:|  |__            /:/ /::\  \   /:/ /:/ _/_   _____\:\  \   /:/ /:/ _/_   /:/ /::\  \   /:/__/      /:/ /::\  \            /:/ /::\__\     |:|  |             /:/|:|  |__   /:/ /:/ _/_   /:/ /:/  /  ___ /::\  \     |:|  |    /:/ /:/  /  
//* /:/_/:/\:\__\ /:/_/:/__/___   /:/__/      /:/__\/\:\__\ /:/_/:/ /\__\ /::::::::\__\ /:/ |:| /\__\          /:/__\/\:\__\ /:/_/:/ /\__\ /::::::::\__\ /:/_/:/ /\__\ /:/_/:/\:\__\ /::\  \     /:/_/:/\:\__\          /:/_/:/\:|__|    |:|  |            /:/ |:| /\__\ /:/_/:/ /\__\ /:/_/:/  /  /\  /:/\:\__\    |:|  |   /:/_/:/__/___
//* \:\/:/  \/__/ \:\/:::::/  /  /::\  \      \:\  \ /:/  / \:\/:/ /:/  / \:\~~\~~\/__/ \/__|:|/:/  /          \:\  \ /:/  / \:\/:/ /:/  / \:\~~\~~\/__/ \:\/:/ /:/  / \:\/:/ /:/  / \/\:\  \__  \:\/:/ /:/  /          \:\/:/ /:/  /  __|:|__|            \/__|:|/:/  / \:\/:/ /:/  / \:\/:/  /   \:\/:/  \/__/  __|:|__|   \:\/:::::/  /
//*  \::/__/       \::/~~/~~~~  /:/\:\  \      \:\  /:/  /   \::/_/:/  /   \:\  \           |:/:/  /            \:\  /:/  /   \::/_/:/  /   \:\  \        \::/_/:/  /   \::/ /:/  /   ~~\:\/\__\  \::/ /:/  /            \::/_/:/  /  /::::\  \                |:/:/  /   \::/_/:/  /   \::/__/     \::/__/      /::::\  \    \::/~~/~~~~ 
//*   \:\  \        \:\~~\      \/__\:\  \      \:\/:/  /     \:\/:/  /     \:\  \          |::/  /              \:\/:/  /     \:\/:/  /     \:\  \        \:\/:/  /     \/_/:/  /       \::/  /   \/_/:/  /              \:\/:/  /   ~~~~\:\  \               |::/  /     \:\/:/  /     \:\  \      \:\  \      ~~~~\:\  \    \:\~~\     
//*    \:\__\        \:\__\          \:\__\      \::/  /       \::/  /       \:\__\         |:/  /                \::/  /       \::/  /       \:\__\        \::/  /        /:/  /        /:/  /      /:/  /                \::/  /         \:\__\              |:/  /       \::/  /       \:\__\      \:\__\          \:\__\    \:\__\    
//*     \/__/         \/__/           \/__/       \/__/         \/__/         \/__/         |/__/                  \/__/         \/__/         \/__/         \/__/         \/__/         \/__/       \/__/                  \/__/           \/__/              |/__/         \/__/         \/__/       \/__/           \/__/     \/__/    
//*

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

contract ArtGenzGenesisbyZephyr is ERC721A, Ownable {
    using Strings for uint256;
    
    uint public maxSupply = 333;
    uint public mintPrice = 0.008 ether;
    uint public maxMintPerTx = 5;
    uint public maxFreeMintPerWallet = 0;
    bool public salesStarted = false;
    bool public reveal =false;

    mapping(address => uint) private _accountToFreeMint;
    string private uriPrefix;
    string private uriSuffix = ".json";
    string public hiddenURL;

    constructor() ERC721A("ArtGenz Genesis by Zephyr", "Zephyr") {
    }

    function mint(uint amount) external payable {
        require(totalSupply() < maxSupply, "sold out");
        require(salesStarted, "sales is not active");
        require(amount > 0, "invalid amount");
        require(amount <= maxMintPerTx, "max tokens per tx reached");
        require(msg.value >= amount * mintPrice, "invalid mint price");
        require(amount + totalSupply() <= maxSupply, "amount exceeds max supply");

        _safeMint(msg.sender, amount);
    }

    function freeMint(uint amount) external {
        require(totalSupply() < maxSupply, "sold out");
        require(salesStarted, "sales is not active");
        require(amount > 0, "invalid amount");
        require(amount <= maxMintPerTx, "max tokens per tx reached");
        require(amount + _accountToFreeMint[msg.sender] <= maxFreeMintPerWallet, "amount exceeds max free mint per wallet");

        _accountToFreeMint[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function batchMint(address[] calldata addresses, uint[] calldata amounts) external onlyOwner {
        require(addresses.length == amounts.length, "addresses and amounts doesn't match");

        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], amounts[i]);
        }
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
    
    function startSales() external onlyOwner {
        salesStarted = true;
    }

    function stopSales() external onlyOwner {
        salesStarted = false;
    }

    function setMaxSupply(uint z) external onlyOwner {
        maxSupply = z;
    }

    function setMintPrice(uint z) external onlyOwner {
        mintPrice = z;
    }

    function setMaxFreeMintPerWallet(uint z) external onlyOwner {
        maxFreeMintPerWallet = z;
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
    
        if ( reveal == false)
    {
        return hiddenURL;
    }
    
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString() ,uriSuffix))
        : "";
    }

    function setUriPrefix(string memory _uriPrefix) external onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setHiddenUri(string memory _uriPrefix) external onlyOwner {
        hiddenURL = _uriPrefix;
    }

    function _baseURI() internal view  override returns (string memory) {
        return uriPrefix;
    }

    function setRevealed() external onlyOwner{
        reveal = !reveal;
    }
 
    function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}