// SPDX-License-Identifier: MIT
/*
███╗   ██╗ █████╗ ██╗   ██╗ ██████╗ ██╗  ██╗████████╗██╗   ██╗    ██████╗ ██╗   ██╗██████╗ ███████╗     ██████╗██╗     ██╗   ██╗██████╗ 
████╗  ██║██╔══██╗██║   ██║██╔════╝ ██║  ██║╚══██╔══╝╚██╗ ██╔╝    ██╔══██╗██║   ██║██╔══██╗██╔════╝    ██╔════╝██║     ██║   ██║██╔══██╗
██╔██╗ ██║███████║██║   ██║██║  ███╗███████║   ██║    ╚████╔╝     ██████╔╝██║   ██║██████╔╝███████╗    ██║     ██║     ██║   ██║██████╔╝
██║╚██╗██║██╔══██║██║   ██║██║   ██║██╔══██║   ██║     ╚██╔╝      ██╔═══╝ ██║   ██║██╔═══╝ ╚════██║    ██║     ██║     ██║   ██║██╔══██╗
██║ ╚████║██║  ██║╚██████╔╝╚██████╔╝██║  ██║   ██║      ██║       ██║     ╚██████╔╝██║     ███████║    ╚██████╗███████╗╚██████╔╝██████╔╝
╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝   ╚═╝      ╚═╝       ╚═╝      ╚═════╝ ╚═╝     ╚══════╝     ╚═════╝╚══════╝ ╚═════╝ ╚═════╝ 
@title Naughty Pups Club
*/

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";


contract NPUPS is Ownable, ERC721A, ReentrancyGuard {
    uint256 public immutable MAX_SUPPLY = 10000;
    uint256 public constant PRICE = 0 ether;
    uint256 private maxPublicTx = 2;
    uint256 private amountForPublic = 2;
    uint256 public amountForTeam = 300;

    bool public _isActive = false;

    mapping(address => uint256) public _amountCounter;

    constructor(
        string memory name,
        string memory symbol
    ) ERC721A(name, symbol) {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // set if contract is active or not
    function setActive(bool isActive) external onlyOwner {
        _isActive = isActive;
    }

    // Internal for competitions + giveaways
    function internalMint(uint256 quantity, address to)
        external
        onlyOwner
        nonReentrant
    {
        require( _amountCounter[msg.sender] + quantity <= amountForTeam,"too many already minted for internal mint");
        require(totalSupply() + quantity <= MAX_SUPPLY,"would exceed max supply");
        _amountCounter[msg.sender] = _amountCounter[msg.sender] + quantity;
        _safeMint(to, quantity);
    }

    // metadata URI
    string private _baseTokenURI;

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setPublicTX(uint256 publicTX) external onlyOwner {
        maxPublicTx = publicTX;
    }

    function setAmtPUBLIC(uint256 amtPUBLIC) external onlyOwner {
        amountForPublic = amtPUBLIC;
    }

    //withdraw to owner wallet
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // public mint
    function publicSaleMint(uint256 quantity,address to)
        external
        payable
        nonReentrant
        callerIsUser
    {
        require(quantity > 0, "Please mint more than 0 tokens");
        require(_isActive, "Public sale has not begun yet");
        require(PRICE * quantity == msg.value, "Incorrect funds");
        require(quantity <= maxPublicTx, "Exceeds max per transaction");
        require(_amountCounter[msg.sender] + quantity <= amountForPublic,"Sorry, too many. Only 2 per wallet.");
        require(totalSupply() + quantity <= MAX_SUPPLY,"Would exceed max supply");
        _amountCounter[msg.sender] = _amountCounter[msg.sender] + quantity;
        _safeMint(to, quantity);
    }
}