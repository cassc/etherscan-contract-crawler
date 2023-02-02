//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import 'hardhat/console.sol';
import './Payable.sol';

contract AMTToken is ERC20, Ownable,Payable {
    uint256 public subscriptionPrice;
    uint256 public burnAllOutput;
    uint256 public surplusNum;
    uint256 public burnNowNum = 0;
    uint256 public surplusLimit;
    uint256 private _unitIncrease;
    uint256 private _priceBase;
    mapping(address => bool) public swapPairs;
    uint256 public swapFee = 10;
//    uint256 public swapSaleFee = 10;
    mapping(address => bool) public excludedFee;

    //交易挂单合约
    constructor() public ERC20("AMT", "AMT") {
        _setupDecimals(8);
        _mint(msg.sender, 2 * 10000 * 10000 * 10 ** uint256(decimals()));
        subscriptionPrice = 1 * 10 ** uint256(decimals());
        _unitIncrease = 260000;
        _priceBase = 1000 * 10 ** uint256(decimals());
        burnAllOutput = 195000000 * 10 ** uint256(decimals());
        surplusNum = burnAllOutput;
        surplusLimit = 21000000 * 10 ** uint256(decimals());
        _transfer(owner(), address(this), burnAllOutput);

    }
    //燃烧产出合约
    function burn(uint256 amount) public onlyOwner {
        require(balanceOf(address(this)) >= amount, 'burn amount exceeds balance');
        require(surplusLimit <= surplusNum, 'Combustion capping');
        _customBurn(amount);
    }

    //燃烧升值合约
    function _customBurn(uint256 amount) private returns (bool) {

        if(surplusLimit > (surplusNum.sub(amount)))
        {
            amount = surplusNum.sub(surplusLimit);
        }
        if(amount <= 0)
        {
            return true;
        }
        _burn(address(this), amount);
        surplusNum = surplusNum.sub(amount);
        burnNowNum = burnNowNum.add(amount);
        if(burnNowNum >= _priceBase){
            subscriptionPrice = subscriptionPrice.add(_unitIncrease.mul(burnNowNum.div(_priceBase)));
            burnNowNum = burnNowNum.sub(burnNowNum.div(_priceBase) * _priceBase);
        }
        return true;
    }

    function getContractBalance() public view returns(uint256){
        return balanceOf(address(this));
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _customTransfer(_msgSender(), recipient, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        amount = _customTransfer(sender, recipient, amount);
        _approve(sender, _msgSender(), allowance(sender, _msgSender()).sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    //领取收益合约
    function _customTransfer(address sender, address recipient, uint256 amount) private returns (uint256) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if ((swapPairs[sender] && !excludedFee[recipient]) || (swapPairs[recipient] && !excludedFee[sender])) {
            uint256 profit = amount.mul(swapFee).div(100);
//            if (sender == msg.sender) {
//                profit = amount.mul(swapSaleFee).div(100);
//            }
//            if (recipient == msg.sender) {
//                profit = amount.mul(swapBuyFee).div(100);
//            }

            _customBurn(profit);
            amount = amount.sub(profit);
        }
        _transfer(sender, recipient, amount);
        return amount;
    }

    function setSwapBuyFee(uint256 fee) public onlyOwner {
        swapFee = fee;
    }
//    function setSwapSaleFee(uint256 fee) public onlyOwner {
//        swapSaleFee = fee;
//    }
    function addSwapPair(address pairAddress) public onlyOwner {
        swapPairs[pairAddress] = true;
    }
    function appendExcludedFee(address account) public onlyOwner {
        excludedFee[account] = true;
    }

    function removeSwapPair(address pairAddress) public onlyOwner {
        swapPairs[pairAddress] = false;
    }

}