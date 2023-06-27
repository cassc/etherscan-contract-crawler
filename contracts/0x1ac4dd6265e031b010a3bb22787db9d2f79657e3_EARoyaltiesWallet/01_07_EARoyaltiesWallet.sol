// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EARoyaltiesWallet is PaymentSplitter, Ownable {
    
    string public name = "EA Royalties Wallet";
    uint[] private _shares = [25, 25, 25, 25, 25, 25, 50];
    address[] private _team = [
        0xF16A786004F2E763b3e754c2245105f1e7AcA767,
        0x58B029B606D1d1311680813cCe39c4770f2f241C,
        0x7eDE5189FffC950f5A692B22C0311479D9B1bcF0,
        0xE139e34C1714a93701b7BCB2F7C0D174cdc1E2C6,
        0x0502EF00b5194d6899d96d027B0fb27A195F96b3,
        0xDA7d1A4C705B257ca18b8e820bff31b8a8CecD79,
        0xC4b8aa60b802F17dFA6BD8ef821365Ed1c3F9BbF
    ];

    constructor () PaymentSplitter(_team, _shares) payable {}
        
    function totalBalance() public view returns(uint) {
        return address(this).balance;
    }
        
    function totalReceived() public view returns(uint) {
        return totalBalance() + totalReleased();
    }
    
    function balanceOf(address _account) public view returns(uint) {
        return totalReceived() * shares(_account) / totalShares() - released(_account);
    }
    
    function release(address payable account) public override onlyOwner {
        super.release(account);
    }
    
    function withdraw() public {
        require(balanceOf(msg.sender) > 0, "No funds to withdraw");
        super.release(payable(msg.sender));
    }
    
}