// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PepeWallet is ERC20, Ownable {
    mapping (address => bool) private _isExcludedFromFee;
    address private _teamAddress;
    uint256 private _taxFee = 2; // 2%

    constructor() ERC20("Pepe Wallet", "PEWALL") {
        _mint(msg.sender, 10000000000 * (10 ** decimals()));
        _teamAddress = msg.sender; // Set the initial team address to the contract deployer
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_teamAddress] = true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if (_isExcludedFromFee[_msgSender()]) {
            _transfer(_msgSender(), recipient, amount);
        } else {
            uint256 taxAmount = amount * _taxFee / 100;
            uint256 transferAmount = amount - taxAmount;
            _transfer(_msgSender(), recipient, transferAmount);
            _transfer(_msgSender(), _teamAddress, taxAmount);
        }
        return true;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setTeamAddress(address teamAddress_) public onlyOwner {
        _isExcludedFromFee[_teamAddress] = false;
        _teamAddress = teamAddress_;
        _isExcludedFromFee[_teamAddress] = true;
    }

}