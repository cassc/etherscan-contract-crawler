// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract MagoMintPayment is Ownable {
    uint256 private constant MAX_SUPPLY = 300;
    uint256 public constant PRIVATE_PRICE = 0.55 ether;

    uint256 public publicPrice;
    uint256 public totalSupply = 0;
    bool public presale = true;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public purchasedQuantity;

    constructor() {}

    function publicPurchase(uint256 _amount) public payable {
        require(!presale, "presale is active");
        require(totalSupply + _amount < MAX_SUPPLY, "MAXSUPPLY over");
        require(msg.value == _amount * publicPrice, "not correct funds");
        purchasedQuantity[msg.sender] += _amount;
        totalSupply += _amount;
    }

    function prePurchase(uint256 _amount) public payable {
        require(presale, "presale is not active");
        require(totalSupply + _amount < MAX_SUPPLY, "MAXSUPPLY over");
        require(msg.value == _amount * PRIVATE_PRICE, "not correct funds");
        purchasedQuantity[msg.sender] += _amount;
        totalSupply += _amount;
    }

    function freePurchase() public {
        require(whitelist[msg.sender], "Already claimed max");
        whitelist[msg.sender] = false;
        purchasedQuantity[msg.sender] += 1;
        totalSupply += 1;
    }

    function setWhitelist(address[] calldata _addresses) public onlyOwner {
        for(uint index=0; index<_addresses.length; index++) {
            whitelist[_addresses[index]] = true;
        }
    }

    function setPublicPrice(uint256 _publicPrice) public onlyOwner {
        publicPrice = _publicPrice;
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(0xeC2C16A4aBD441ef48e1b48D644330302F010923), address(this).balance);
    }

    function setPublic() public onlyOwner {
        presale = false;
    }
}