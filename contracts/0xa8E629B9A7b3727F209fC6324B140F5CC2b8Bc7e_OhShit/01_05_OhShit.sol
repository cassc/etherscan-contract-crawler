// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OhShit is ERC721A, Ownable {
    uint256 public MaxPerTxn = 15;
    uint256 public MaxFreePerWallet = 1;
    bool public mintEnabled = false;
    uint256 public maxSupply = 5555;
    uint256 public price = 0.003 ether;
    string public baseURI = "ipfs://OhShit/";
    mapping(address => bool) public wlAddress;

    constructor(address[] memory _address) ERC721A("OhShit", "OS") {
        for (uint256 i = 0; i < _address.length; i++) {
            wlAddress[_address[i]] = true;
        }
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setMaxSupply(uint256 amount) external onlyOwner {
        maxSupply = amount;
    }

    function setMaxFreePerWallet(uint256 amount) external onlyOwner {
        MaxFreePerWallet = amount;
    }

    function changePrice(uint256 __price) public onlyOwner {
        price = __price;
    }

    function mint(uint256 quantity) external payable {
        require(mintEnabled, "wait until sale start");
        require(totalSupply() + quantity <= maxSupply, "max supply reached");

        uint256 count = quantity;
        if (numberMinted(msg.sender) < MaxFreePerWallet) {
            if (numberMinted(msg.sender) + quantity <= MaxFreePerWallet)
                count = 0;
            else count = numberMinted(msg.sender) + quantity - MaxFreePerWallet;
        }

        if (wlAddress[msg.sender]) count = 0;

        require(msg.value >= count * price, "Please send the exact amount.");

        _safeMint(msg.sender, quantity);
    }

    function devMint(uint256 quantity) external payable onlyOwner {
        require(totalSupply() + quantity <= maxSupply, "sold out");
        _safeMint(msg.sender, quantity);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function startMint() external onlyOwner {
        mintEnabled = !mintEnabled;
    }
}