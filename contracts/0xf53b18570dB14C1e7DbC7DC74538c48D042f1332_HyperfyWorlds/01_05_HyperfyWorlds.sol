// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HyperfyWorlds is ERC721A, Ownable {
    
    uint256 private phase;

    uint256 private maxSupply;
    uint256 private supply;
    uint256 private price;
    
    uint256 private reserve = 500;

    string private uri;

    constructor(address _owner, string memory newURI) ERC721A("Hyperfy Worlds", "WORLD") {
        setURI(newURI);
        transferOwnership(_owner);
    }

    function advance() external onlyOwner {   
        if (phase == 0) {
            phase = 1;
            maxSupply = 1000;
            price = 60e15;
        } else if (phase == 1) {
            phase = 2;
            maxSupply = 9500;
            price = 90e15;
        }
    }

    function mint(uint256 amount) external payable {
        require(phase > 0, "Sale is not yet activated");
        require(amount + supply <= maxSupply, "Amount exceeds max supply");
        require(amount * price == msg.value, "Amount does not match price");
        
        supply += amount;

        _mint(msg.sender, amount);
    }

    function send(address recipient, uint256 amount) external onlyOwner {
        require(amount <= reserve, "Not enough reserve");
        
        reserve -= amount;

        _mint(recipient, amount);
    }

    function airdrop(address[] calldata recipients) external onlyOwner {
        require(recipients.length <= reserve, "Not enough reserve");

        reserve -= recipients.length;

        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], 1);
        }
    }

    function withdraw(address addr, uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Not enough ETH");
        
        payable(addr).transfer(amount);
    }

    function setURI(string memory newURI) public onlyOwner {
        uri = newURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return uri;
    }

    function getInfo() public view returns (uint256, uint256, uint256, uint256, uint256) {
        return (phase, price, supply, maxSupply, reserve);
    }

}