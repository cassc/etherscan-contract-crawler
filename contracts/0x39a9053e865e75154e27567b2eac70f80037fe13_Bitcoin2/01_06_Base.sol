// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Bitcoin2 is ERC20, Ownable {
    mapping(address => bool) public feeExempt;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 private _maxSupply = 36000000 * (10 ** uint256(decimals()));
    uint256 private _fee = 1; // Set the fee to 1%

    constructor() ERC20("Bitcoin 2.0", "Bitcoin 2.0") {
        _mint(msg.sender, _maxSupply);
    }

    function addFeeExempt(address _address) public onlyOwner {
        feeExempt[_address] = true;
    }

    function removeFeeExempt(address _address) public onlyOwner {
        feeExempt[_address] = false;
    }
    
    function renounceContractOwnership() public onlyOwner {
        renounceOwnership();
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        uint256 feeAmount;
        if(!feeExempt[sender]) {
            feeAmount = amount * _fee / 100;
        }
        uint256 transferAmount = amount - feeAmount;
        super._transfer(sender, recipient, transferAmount);
        if(feeAmount > 0) {
            super._transfer(sender, deadAddress, feeAmount);
        }
    }
}