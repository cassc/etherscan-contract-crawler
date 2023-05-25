// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is Ownable, ERC20, ERC20Burnable {
    constructor(
        uint256 maxSupply_,
        address dexWallet_,
        address airdropDistributor_,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) {
        _mint(dexWallet_, (maxSupply_ * 700) / 1000);
        _mint(airdropDistributor_, (maxSupply_ * 300) / 1000);
    }

    // Receive function.
    receive() external payable {
        revert();
    }

    // Fallback function.
    fallback() external {
        revert();
    }
}