// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract WorldOfPumpKins is ERC721, Ownable {
    using Strings for uint256;

    string baseExtension = ".json";
    string public baseUri;
    string hiddenUri;
    uint256 public totalSupply = 8888;
    uint256 public supply;

    uint256 public mintCost = 0.02 ether;
    uint256 public presaleMintCost = 0.01 ether;

    uint256 public reservedMintLeft = 100;

    bool public isPaused = true;
    bool public isPresale = true;
    bool public isRevealed;

    mapping(address => bool) public hasMintedOnPresale;

    modifier isNotPaused() {
        require(!isPaused, "Contract is paused");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        string memory _hiddenUri
    ) ERC721(name_, symbol_) {
        hiddenUri = _hiddenUri;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Query for nonexistent token");
        if (isRevealed) {
            return
                string(
                    abi.encodePacked(baseUri, tokenId.toString(), baseExtension)
                );
        } else {
            return hiddenUri;
        }
    }

    // public
    function mint(uint256 amount) public payable isNotPaused {
        require(
            amount + supply <= totalSupply - reservedMintLeft,
            "Mint amount exceeds allowed"
        );
        if (isPresale) {
            require(
                !hasMintedOnPresale[msg.sender],
                "Already minted during presale"
            );
            require(amount <= 5, "Amount exceeds mint limit");
            require(
                msg.value == presaleMintCost * amount,
                "Wrong transaction value"
            );
            hasMintedOnPresale[msg.sender] = true;
        } else {
            require(msg.value == mintCost * amount, "Wrong transaction value");
            require(amount <= 10, "Amount exceeds mint limit");
        }
        for (uint256 i = 0; i < amount; i++) {
            supply++;
            _mint(msg.sender, supply);
        }
    }

    //admin
    function adminMint(uint256 amount) public onlyOwner {
        require(reservedMintLeft - amount >= 0, "Can't mint more than 100");
        for (uint256 i = 0; i < amount; i++) {
            supply++;
            _mint(msg.sender, supply);
        }
    }

    function changePause() public onlyOwner {
        isPaused = !isPaused;
    }

    function endPresale() public onlyOwner {
        isPresale = false;
    }

    function reveal(string memory uri) public onlyOwner {
        require(!isRevealed, "Already revealed");
        isRevealed = true;
        baseUri = uri;
    }

    function withdraw(address payable to, uint256 amount) public onlyOwner {
        to.transfer(amount);
    }
}