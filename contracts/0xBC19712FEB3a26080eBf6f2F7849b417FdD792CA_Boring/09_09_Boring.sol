// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Boring is ERC20Burnable, Ownable{

    using SafeERC20 for IERC20;

    IERC20 public bor;
    uint public ratio;
    bool public switchOn = true;

    constructor(address _bor, uint _ratio) ERC20("BoringDAO", "BORING") {
        bor = IERC20(_bor);
        ratio = _ratio;
        // for people who transfer bor to borContract address
        // https://etherscan.io/token/0x3c9d6c1C73b31c837832c72E04D3152f051fc1A9?a=0x3c9d6c1C73b31c837832c72E04D3152f051fc1A9
        // https://bscscan.com/token/0x92d7756c60dcfd4c689290e8a9f4d263b3b32241?a=0x92d7756c60dcfd4c689290e8a9f4d263b3b32241
        _mint(msg.sender, 29770922242336919137*_ratio);
    }

    function setSwitchOn(bool _switchOn) public onlyOwner {
        require(switchOn != _switchOn, "dont need change switchon");
        switchOn = _switchOn;
    }

    function toBoring(uint borAmount) public {
        uint boringAmount = borAmount*ratio;
        _mint(msg.sender, boringAmount);
        bor.safeTransferFrom(msg.sender, address(this), borAmount);
        emit ToBoring(msg.sender, borAmount, boringAmount); 
    }

    function toBor(uint boringAmount) public onlySwitchOn {
        require(balanceOf(msg.sender) >= boringAmount, "Boring:Not enough boring");
        require(bor.balanceOf(address(this)) * ratio >= boringAmount, "Boring:Not enough bor");
        burn(boringAmount);
        uint borAmount = boringAmount / ratio;
        bor.transfer(msg.sender, borAmount);
        emit ToBor(msg.sender, borAmount, boringAmount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        super._beforeTokenTransfer(from, to, amount);
        require(to != address(this), "ERC20: transfer to the token contract address");
     }

    modifier onlySwitchOn {
        require(switchOn == true, "only switchOn true");
        _;
    }

    event ToBoring(address account, uint borAmount, uint boringAmount);
    event ToBor(address account, uint borAmount, uint boringAmount);

}