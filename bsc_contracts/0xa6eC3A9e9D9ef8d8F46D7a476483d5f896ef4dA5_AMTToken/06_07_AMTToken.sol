//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import 'hardhat/console.sol';

contract AMTToken is ERC20, Ownable {
    uint256 public subscriptionPrice;
    uint256 public burnAllOutput;
    uint256 public surplusNum;
    uint256 public burnNowNum = 0;
    uint256 public surplusLimit;
    uint256 private _unitIncrease;

//交易挂单合约
    constructor() public ERC20("AMT", "AMT") {
        _setupDecimals(8);
        _mint(msg.sender, 2 * 10000 * 10000 * 10 ** uint256(decimals()));
        subscriptionPrice = 1 * 10 ** uint256(decimals());
        _unitIncrease = 260000;
        burnAllOutput = 195000000 * 10 ** uint256(decimals());
        surplusNum = burnAllOutput;
        surplusLimit = 21000000 * 10 ** uint256(decimals());
        _transfer(owner(), address(this), burnAllOutput);

    }
    //燃烧产出合约
    //燃烧升值合约
    function burn(uint256 amount) public onlyOwner {
        require(balanceOf(address(this)) >= amount, 'burn amount exceeds balance');
        require(surplusLimit <= surplusNum, 'Combustion capping');
        if(surplusLimit > (surplusNum.sub(amount)))
        {
            amount = surplusNum.sub(surplusLimit);
        }
        _burn(address(this), amount);
        surplusNum = surplusNum.sub(amount);
        burnNowNum = burnNowNum.add(amount);
        if(burnNowNum >= 1000 * 10 ** uint256(decimals())){
            subscriptionPrice = subscriptionPrice.add(_unitIncrease.mul(burnNowNum.div(1000 * 10 ** uint256(decimals()))));
            burnNowNum = burnNowNum.sub(burnNowNum.div(1000 * 10 ** uint256(decimals())) * 1000 * 10 ** uint256(decimals()));
        }
    }
    //领取收益合约
    function getContractBalance() public view returns(uint256){
        return balanceOf(address(this));
    }

}