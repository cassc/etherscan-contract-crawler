//SPDX-License-Identifier: UNLICENSED
pragma solidity <=0.8.17;
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "hardhat/console.sol";
contract MCShibaInu is
    ERC20("MC Shiba Inu", "MCSHIBA"),
    ERC20Burnable,
    Ownable
{
    uint256 private cap = 10_000_000_000 * 10**uint256(18);
    constructor() {
        console.log("owner: %s maxcap: %s", msg.sender, cap);
        _mint(msg.sender, cap);
        transferOwnership(msg.sender);
    }
}