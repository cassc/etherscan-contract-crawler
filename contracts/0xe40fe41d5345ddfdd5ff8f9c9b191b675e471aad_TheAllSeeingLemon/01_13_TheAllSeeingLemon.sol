// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";

contract TheAllSeeingLemon is ERC721A, Ownable, ReentrancyGuard {
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant RESERVE_SUPPLY = 200;
    uint256 public constant MAX_PER_WALLET = 2;

    uint256 public price = 0.00 ether;
    string private _baseTokenURI;
    
    bool public paused = true;
    bool public reserveMinted = false;

    constructor(string memory initialBaseURI)
        ERC721A("The All Seeing Lemon", "TASL")
    {
        setBaseURI(initialBaseURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function togglePause() external onlyOwner{
        paused = !paused;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Cannot be called by a contract.");
        _;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function mint(uint256 _quantity) external payable callerIsUser nonReentrant {
        require(!paused, "This mint is not active.");

        require(_quantity > 0, "You can't mint 0 lemons.");
        require(
            (totalSupply() + _quantity + RESERVE_SUPPLY) <= MAX_SUPPLY,
            "We're out of lemons!"
        );
        require(
            (numberMinted(msg.sender) + _quantity) <= MAX_PER_WALLET,
            "You've maxed out on lemons for this wallet."
        );
        if (msg.sender != owner()) {
            require(
                msg.value >= price * _quantity,
                "Not enough ETH for these lemons."
            );
        }

        _safeMint(msg.sender, _quantity);
    }

    function reserveMint() external onlyOwner {
        require(!reserveMinted, "Team already minted");

        _safeMint(msg.sender, RESERVE_SUPPLY);
        reserveMinted = true;
    }

    function withdraw() external payable onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed.");
    }
}