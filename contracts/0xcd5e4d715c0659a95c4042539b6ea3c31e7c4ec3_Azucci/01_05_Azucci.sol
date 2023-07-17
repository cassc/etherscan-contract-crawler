// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Azucci is ERC721A, Ownable {
    uint256 public maxSupply = 2222;
    uint256 public price = 0.001 ether;
    uint256 public maxFreeSupply = 420;
    uint256 public maxFreePerWallet = 1;
    uint256 public maxPerTx = 10;
    uint256 public maxPerWallet = 10;
    uint256 public teamSupply = 69;
    uint256 public freeMints = 0;
    bool public saleStarted = true;
    string public uriSuffix = ".json";
    string public baseURI = "ipfs://bafybeicbuatqlce3ac6n2y7kogghdxrkqd4uxyd5kaf7hycmyq5qimrpmu/";

    constructor() ERC721A("Azucci", "Azucci") {}

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function updatePrice(uint256 __price) public onlyOwner {
        price = __price;
    }

    function publicSale(uint256 amount) external payable {
        require(saleStarted, "Sale is not active.");
        require(amount <= maxPerTx, "Should not exceed max mint number!");
        require(totalSupply() + amount <= maxSupply, "Should not exceed max supply.");
        require(numberMinted(msg.sender) + amount <= maxPerWallet, "Should not exceed max per wallet.");

        uint256 freeMintCount = 0;
        bool isFreeMint = false;
        if (freeMints < maxFreeSupply) {
            freeMintCount = maxFreePerWallet;
        }

        uint256 count = amount;
        if (numberMinted(msg.sender) < freeMintCount) {
            if (numberMinted(msg.sender) + amount <= freeMintCount) {
                count = 0;
            }                
            else {
                count = numberMinted(msg.sender) + amount - freeMintCount;
            }
            isFreeMint = true;
        }

        require(msg.value >= count * price, "Ether value is not enough");
        
        if(isFreeMint) freeMints += freeMintCount;

        _safeMint(msg.sender, amount);
    }

    function mintForTeam(uint256 amount) external onlyOwner {
        require(teamSupply > 0,"Should not exceed mint limit");
        require(amount <= teamSupply,"Should not exceed mint limit");
        require(totalSupply() + amount <= maxSupply, "Should not exceed max supply.");
        teamSupply -= amount;
        _safeMint(msg.sender, amount);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), uriSuffix)) : '';
    }

    function toggleSale() external onlyOwner {
        saleStarted = !saleStarted;
    }

    function setFreeMintStart() external onlyOwner {
        freeMints = 0;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setMaxSupply(uint256 amount) external onlyOwner {
        maxSupply = amount;
    }

    function setTeamSupply(uint256 amount) external onlyOwner {
        teamSupply = amount;
    }

    function setMaxFreeSupply(uint256 amount) external onlyOwner {
        maxFreeSupply = amount;
    }

    function setMaxFreePerWallet(uint256 amount) external onlyOwner {
        maxFreePerWallet = amount;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }
}