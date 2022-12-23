// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Manager.sol";
import "./TheImps.sol";

contract BloodDiamond is ERC20, Ownable {
    Manager manager;

    constructor(address _manager) ERC20("Blood Diamond", "BLD") {
        manager = Manager(_manager);
        _mint(msg.sender, 666666 * 10**18);
    }

    function mint(uint256 amount, address target) external {
        require(
            msg.sender == manager.theImpsContract() || msg.sender == manager.theGoldenKeyContract(),
            "Blood Diamonds can only be minted by staking"
        );
        _mint(target, amount);
    }

    function burn(uint256 amount, address target) external {
        require(
            manager.isSpender(msg.sender),
            "Blood Diamonds can only be purged by purge contract"
        );
        _burn(target, amount);
    }
}