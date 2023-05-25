// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract WithdrawFairly is Ownable {
    using SafeMath for uint256;

    struct Part {
        address salesWallet;
        address royaltiesWallet;
        uint256 salePart;
        uint256 royaltiesPart;
    }

    Part[] public parts;
    address[] public tokenAddress;

    constructor(){
        parts.push(Part(0xb224811F71c803af1762CC6AEfd995edbfAFBD42, 0x647b14eC32Cd079D4156241c990Cc73540FFad5b, 2000, 3500)); // miinded
        parts.push(Part(0xAA3F3ed871aB321002d823D466D6E2d5e05E4aB2, 0xAA3F3ed871aB321002d823D466D6E2d5e05E4aB2, 2000, 1625)); // pudgy 1
        parts.push(Part(0x70031E2B0F221da3b72b305292219d7DCD1300Df, 0x70031E2B0F221da3b72b305292219d7DCD1300Df, 2000, 1625)); // pudgy 2
        parts.push(Part(0x462A7C08f7f6Dd914F913CD82b4d5f16D1aa350c, 0x462A7C08f7f6Dd914F913CD82b4d5f16D1aa350c, 2000, 1625)); // pudgy 3
        parts.push(Part(0xFe5573C66273313034F7fF6050c54b5402553716, 0xFe5573C66273313034F7fF6050c54b5402553716, 2000, 1625)); // pudgy 4

        tokenAddress.push(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // USDC
        tokenAddress.push(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // WETH
        tokenAddress.push(0x6B175474E89094C44Da98b954EedeAC495271d0F); // DAI
    }

    function withdrawSalesPart() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Sales Balance = 0");

        for(uint8 i = 0; i < parts.length; i++){
            if(parts[i].salePart > 0){
                _withdraw(parts[i].salesWallet, balance.mul(parts[i].salePart).div(10000));
            }
        }

        _withdraw(owner(), address(this).balance);
    }

    function withdrawRoyalties() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Contract Balance = 0");

        for(uint8 i = 0; i < parts.length; i++){
            if(parts[i].royaltiesPart > 0){
                _withdraw(parts[i].royaltiesWallet, balance.mul(parts[i].royaltiesPart).div(10000));
            }
        }

        _withdraw(owner(), address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function withdrawRoyaltiesTokens() public onlyOwner {
        for(uint256 j = 0; j < tokenAddress.length; j++){
            if(tokenAddress[j] == address(0)){
                continue;
            }
            uint256 balance = IERC20(tokenAddress[j]).balanceOf(address(this));
            for(uint256 i = 0; i < parts.length; i++){
                if(parts[i].royaltiesPart > 0 && balance > 0){
                    IERC20(tokenAddress[j]).transfer(parts[i].royaltiesWallet, balance.mul(parts[i].royaltiesPart).div(10000));
                }
            }
        }
    }

    function addERC20Address(address _contract) public onlyOwner{
        tokenAddress.push(_contract);
    }
    function removeERC20Address(address _contract) public onlyOwner{
        for(uint256 i = 0; i < tokenAddress.length;i++){
            if(tokenAddress[i] == _contract){
                tokenAddress[i] = address(0);
            }
        }
    }

    receive() external payable {}

}