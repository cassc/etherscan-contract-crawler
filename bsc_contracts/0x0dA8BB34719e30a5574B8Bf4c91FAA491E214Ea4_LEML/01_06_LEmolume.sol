// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LEML is ERC20, Ownable {
    address private _bank;
    uint256 public totalSupplyLimit = 300000000 * 10**18;

    bool public isTransferable = false;

    constructor() ERC20("Locked Emolume", "LEML") {}

    function mint(address to, uint256 amount) public returns (bool) {
        require(
            msg.sender == owner() || msg.sender == _bank,
            "Owner can call this method"
        );
        require(
            totalSupply() + amount < totalSupplyLimit,
            "Total Supply exceeded"
        );
        _mint(to, amount);
        return true;
    }

    function burn(address account, uint256 amount) public returns (bool) {
        require(
            msg.sender == owner() || msg.sender == _bank,
            "Owner can call this method"
        );
        _burn(account, amount);
        return true;
    }

    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        require(isTransferable, "Token are not Transferable yet.");
        return transfer(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        require(isTransferable, "Token are not Transferable yet.");
        return transferFrom(from, to, amount);
    }

    function pauseTransfer() public onlyOwner {
        isTransferable = false;
    }

    function resumeTransfer() public onlyOwner {
        isTransferable = true;
    }

    function updateBank(address newBank) public onlyOwner {
        _bank = newBank;
    }

    function getBank() public view returns (address) {
        return _bank;
    }
}