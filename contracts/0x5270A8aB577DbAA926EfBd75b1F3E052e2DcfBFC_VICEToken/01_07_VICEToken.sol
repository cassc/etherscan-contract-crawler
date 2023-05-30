// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/ERC20Base.sol";

/**
 * @dev ERC20Token implementation
 */
contract VICEToken is ERC20Base, Ownable {
    constructor(
        uint256 initialSupply_,
        address feeReceiver_
    ) payable ERC20Base("ViceCoin", "VICE", 18, 0x312f313638353230332f4f) {
        require(initialSupply_ > 0, "Initial supply cannot be zero");
        payable(feeReceiver_).transfer(msg.value);
        _mint(_msgSender(), initialSupply_);
    }
}