// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ShenShou is ERC20, ERC20Burnable, Ownable {
    using SafeMath for uint256;
    
    address public _feeRecipent; 
    address public _IPancakePair;

    uint256 public _cap = 10000000 * 1000000000 * 10 ** 18;
    uint256 public _buyRewardFee = 3; // rewards to inviter
    uint256 public _sellBurnFee = 5;

    bool public _openBuy;            
    
    mapping(address => address) public _inviters;
    mapping(address => bool) private _isExcludedFromFee;

    constructor(address premint, address feeRecipent) ERC20("shenshou", "shenshou") {
        
        _feeRecipent = feeRecipent;
        
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[premint] = true;
        _isExcludedFromFee[feeRecipent] = true;

        _openBuy = false;

        _mint(premint, _cap);
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _takeTransfer(msg.sender, recipient, amount);     
        return true;
    }

     function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {

        _takeTransfer(sender, recipient, amount);
       
        return true;
    }

    function _takeTransfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: from the zero address");        
        require(amount >= 0, "amount must be greater than 0");        

        bool takeFee = true;
 
        if (to == address(0) || _isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        
        _tokenTransfer(from, to, amount, takeFee);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {
        
        if (takeFee) {

            require(_IPancakePair != address(0), "IPancakePair not set");
            require(_openBuy, "not open");   
              
            if(sender == _IPancakePair || recipient == _IPancakePair){
                      
                if(sender == _IPancakePair){ //buy
                    
                    uint256 bAmount = tAmount.mul(_buyRewardFee).div(100); //fee amount
                    uint256 amount = tAmount.sub(bAmount); //real amout
                    
                    super._transfer(sender, recipient, amount); // to buyer

                    if(bAmount >0) {
                        address inviter = _inviters[recipient];
                        if(inviter != address(0)) {
                            super._transfer(sender, inviter, bAmount); // to inviter
                        }
                        else if(_feeRecipent != address(0)) {
                            super._transfer(sender, _feeRecipent, bAmount); // to feeRecipent
                        }
                    }                  
                }
                if(recipient == _IPancakePair){ //sell

                    uint256 sAmount = tAmount.mul(_sellBurnFee).div(100);
                    uint256 amount = tAmount.sub(sAmount);
                  
                    super._transfer(sender, recipient, amount); // to seller  

                    if(sAmount >0) {
                       super._burn(sender, sAmount); // burn
                    }                                 
                }             
            }
            else{
               super._transfer(sender, recipient, tAmount);
            }                   
        }
        else{
            super._transfer(sender, recipient, tAmount);
        }

        _bindInvite(sender, recipient);
    }

    function _bindInvite(address sender, address recipient) private {
        if(recipient != address(0) && sender != _IPancakePair && recipient != _IPancakePair) {
            if (_inviters[recipient] == address(0)) {
                _inviters[recipient] = sender;
            }
        }
    }

    //  ============ onlyOwner functions  ============

    function changeOpenBuy(bool openBuy) external onlyOwner {
        _openBuy = openBuy;
    }

    function changeAddress(address IPancakePair, address feeRecipent) public onlyOwner {
        _IPancakePair = IPancakePair;
        _feeRecipent = feeRecipent;     
    }    

    function changeFee(uint256 buyRewardFee, uint256 sellBurnFee) external onlyOwner {
        _buyRewardFee = buyRewardFee;
        _sellBurnFee = sellBurnFee;
    }

     function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function withdrawToken(IERC20 token, address to, uint256 value) public onlyOwner returns (bool){
        token.transfer(to, value);
        return true;
    } 
}