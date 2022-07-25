// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AmadeusVault is Ownable {

    struct Price {
        uint256 export;
        uint256 IPFS;
        uint256 contractWithoutRoyalty;
    }

    Price private price;

    address private vaultAddr;
    
    event Recharge(string indexed collectionID, uint256 indexed rechargeType);

    constructor(address _vaultAddr) {
        price = Price(0.2 ether, 0.05 ether ,1 ether);
        vaultAddr = _vaultAddr;
    }

    function setVaultAddress(address _vaultAddr) external onlyOwner {
        vaultAddr = _vaultAddr;
    }

    function addRechargeToken(Price calldata _price) external onlyOwner {
        price = _price;
    }

    function recharge(string calldata collectionID, uint256 rechargeType) public payable {
        uint256 totalPrice = getPriceByType(rechargeType);
        require(msg.value == totalPrice, "Incorrect Value.");
        emit Recharge(collectionID, rechargeType);
    }

    function getPriceByType(uint256 rechargeType) public view returns(uint256) {
        require(rechargeType < 8, "Type Not Valid");
        uint256 totalPrice = 0;
        if (rechargeType & 0x1 == 1) {
            totalPrice += price.export;
        }
        if (rechargeType & 0x2 == 2) {
            totalPrice += price.IPFS;
        }
        if (rechargeType & 0x4 == 4) {
            totalPrice += price.contractWithoutRoyalty;
        }
        return totalPrice;
    }

}