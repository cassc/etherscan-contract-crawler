// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract KNKContract is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    uint256 public constant MAX_SUPPLY = 6666;
    uint256 public constant MAX_PER_WALLET = 6;
    uint256 public constant WHITELIST_PRICE = 90000000000000000; // Equivalent to 0.09 ether
    uint256 public constant PUBLIC_PRICE = 200000000000000000; // Equivalent to 0.2 ether

    enum ContractPhase { PRE_SALE, WHITELIST_SALE, PUBLIC_SALE, POST_SALE }
    string private __baseURI = "";
    ContractPhase private _contractPhase = ContractPhase.PRE_SALE;
    mapping(address => bool) private _whiteList;
    Counters.Counter private amountMinted;

    constructor() ERC721("KiwisnKangaroos", "KNK") {
    }

    function _baseURI() override internal view returns (string memory) {
        return __baseURI;
    }

    /// @notice Lets the owner of the contract update the baseURI of the tokens, this will be used to reveal the tokens after launch
    function setBaseURI(string memory uri) public onlyOwner {
        __baseURI = uri;
    }

    /// @notice Gets the current phase of the contract (whitelist only, public sale, etc)
    function getContractPhase() public view returns (ContractPhase) {
        return _contractPhase;
    }

    /// @notice Lets the owner set the current phase of the contract
    function setContractPhase(uint newStatus) public onlyOwner {
        _contractPhase = ContractPhase(newStatus);
    }

    /// @notice Checks if an address is on the whitelist
    function isOnWhiteList(address newAddress) public view returns (bool) {
        return _whiteList[newAddress];
    }

    /// @notice Lets the owner add an address to the whitelist
    function addToWhiteList(address newAddress) public onlyOwner {
        _whiteList[newAddress] = true;
    }

    /// @notice Lets the owner add multiple addresses to the whitelist
    function addMultipleToWhiteList(address[] memory newAddresses) public onlyOwner {
        for (uint i = 0; i < newAddresses.length; i++) {
            _whiteList[newAddresses[i]] = true;
        }
    }

    /// @notice Lets the owner remove an address to the whitelist
    function removeFromWhiteList(address newAddress) public onlyOwner {
        _whiteList[newAddress] = false;
    }

    /// @notice Get the total amount of tokens minted
    function totalMinted() public view returns (uint) {
        return amountMinted.current();
    }

    /// @notice Public method to mint tokens, tokens can only be minted during the whitelist sale phase (for 0.09ETH) or the public sale phase (for 0.2ETH). Addresses can only mint up to 6 tokens for themselves, and the total amount of tokens is limited to 6666  
    function mintTokens(uint amount) public payable {
        require(_contractPhase != ContractPhase.PRE_SALE, "Can't mint during presale");

        require((_contractPhase != ContractPhase.WHITELIST_SALE) || _whiteList[msg.sender], "Can't mint if not on whitelist");
        require((_contractPhase != ContractPhase.WHITELIST_SALE) || (msg.value == (WHITELIST_PRICE * amount)), "incorrect amount of eth sent");

        require((_contractPhase != ContractPhase.PUBLIC_SALE) || (msg.value == (PUBLIC_PRICE * amount)), "incorrect amount of eth sent");

        require(_contractPhase != ContractPhase.POST_SALE, "Can't mint after sale");

        require(amount > 0 && amount <= MAX_PER_WALLET, "Trying to mint too many or 0 tokens");
        require((balanceOf(msg.sender) + amount) <= MAX_PER_WALLET, "Exceeded limit on tokens per wallet");
        require((amountMinted.current() + amount) <= MAX_SUPPLY, "Token supply exceeded");

        for (uint i = 0; i < amount; i++) {
            _safeMint(msg.sender, amountMinted.current());
            amountMinted.increment();
        }
    }

    /// @notice Lets the owner mint tokens on behalf of other users
    function adminMintTokens(uint amount, address addr) public onlyOwner {
        require((amountMinted.current() + amount) <= MAX_SUPPLY, "Token supply exceeded");

        for (uint i = 0; i < amount; i++) {
            _safeMint(addr, amountMinted.current());
            amountMinted.increment();
        }
    }

    /// @notice Lets the owner withdraw all the eth in the contract
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}