// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract LoveLain is ERC721A, Ownable {

    string public baseURI;
    uint256 public constant MAX_MINT_PER_ADDR = 3;
    uint256 public constant MAX_SUPPLY = 999;
    uint256 public PRICE = 0.003 ether;

    bool public saleIsActive = true;

    event Minted(address minter, uint256 amount);
    event BaseURIChanged(string newBaseURI);

    constructor(string memory initBaseURI) ERC721A("LetsLoveLain", "LoveLain") {
        baseURI = initBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 quantity) external payable {
        require(saleIsActive, "Not started yet");
        require(tx.origin == msg.sender, "No contract calls allowed");
        require(
            numberMinted(msg.sender) + quantity <= MAX_MINT_PER_ADDR,
            "Max mint per address."
        );
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Purchase would exceed max supply of tokens"
        );

        _safeMint(msg.sender, quantity);

        emit Minted(msg.sender, quantity);
    }


    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }


    function toggleSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    function setPRICE(uint256 _newPRRICE) public onlyOwner {
    PRICE = _newPRRICE;
    }

    function withdraw(address payable recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "U don't love Lain...");
    }
}