// contracts/LSAirdrop.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LSAirdrop {

    address guardianAddress;

    constructor(address _guardianAddress) {
        guardianAddress = _guardianAddress;
    }

    function airdrop(address coinAddress, address[] memory recepients, uint256[] memory amounts) public {
        require(msg.sender == guardianAddress, "unapproved sender");
        require(recepients.length == amounts.length, "Unmatched lengths");
        ERC20 coin = ERC20(coinAddress);

        for (uint256 i = 0; i < recepients.length; i++) {    
            coin.transfer(recepients[i], amounts[i]);
        }
    }
}