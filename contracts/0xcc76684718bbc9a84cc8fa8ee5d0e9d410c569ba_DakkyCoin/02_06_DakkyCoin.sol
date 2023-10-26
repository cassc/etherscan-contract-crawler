// SPDX-License-Identifier: MIT

//      .___       __    __           _________        .__        
//    __| _/____  |  | _|  | _____.__.\_   ___ \  ____ |__| ____  
//   / __ |\__  \ |  |/ /  |/ <   |  |/    \  \/ /  _ \|  |/    \ 
//  / /_/ | / __ \|    <|    < \___  |\     \___(  <_> )  |   |  \
//  \____ |(____  /__|_ \__|_ \/ ____| \______  /\____/|__|___|  /
//       \/     \/     \/    \/\/             \/               \/ 
//          August 2023                      by dakky.eth

pragma solidity ^0.8.21;

import "ERC20.sol";
import "Ownable.sol";

contract DakkyCoin is ERC20, Ownable {
    uint256 private _maxSupply;
    uint256 public initialSupply = 0;
    uint256 public maxSupply = 100000;
    uint256 public price = 0.001 ether;
    bool public publicSaleOpen = false;

    constructor() ERC20("DakkyCoin", "DAKKY") {}

    function mint(address account, uint256 amount) public payable {
        require(publicSaleOpen, "Sale not yet started!");
        require(maxSupply >= initialSupply, "Max supply must be greater or equal to initial supply");
        require(msg.value == price * amount, "Needs to send more ETH!");
        uint256 totalSupplyAfterMint = totalSupply() + amount;
        require(totalSupplyAfterMint <= maxSupply, "Max supply reached or minting more than remaining");
        _mint(account, amount);
    }

    function getMaxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function setMaxSupply(uint256 _supply) public onlyOwner() {
        require(_supply <= 100000, "Error: New max supply cant be higher than original!");
        maxSupply = _supply;
    }

    function toggleSale() public onlyOwner() {
        publicSaleOpen = !publicSaleOpen;
    }

    function withdraw() external onlyOwner {
        uint _balance = address(this).balance;
        payable(owner()).transfer(_balance); // Owner
    }

    function setPrice(uint256 _price) public onlyOwner() {
        require(_price >= 0.001 ether, "Error: New price cant be lower than original!");
        price = _price;
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
}