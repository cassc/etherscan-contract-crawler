// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "base/interface/IRouter.sol";
import "base/interface/IFactory.sol";
import "base/interface/IPancakePair.sol";
 
contract Token is ERC20,Ownable { 
     using SafeMath for uint; 
     mapping(address=>bool) public ispair;
     address marketing;   
     address dev;  
     uint mktpart;
     uint devpart;
    bool isTrading; 
    struct Fees{
        uint buy;
        uint sell;
        uint transfer;
        uint total;
    }
    Fees public fees;
    //mkt
    address token0;
    address token1; 
    IRouter router;
    address pair;
    struct autoConfig {
        bool status; 
        uint minPart;
        uint maxPart;
        uint parts;
    } 
    autoConfig public _auto; 

    //mkt_end
    modifier trading(){
        if(isTrading) return;
        isTrading=true;
        _;
        isTrading=false; 
    } 
    constructor(string memory name_,string memory symbol_,uint total_) ERC20(name_, symbol_) {
        marketing=_msgSender();  
        fees=Fees(100,100,100,100);    
        _mint(marketing, total_ * 1 ether);  
        token0=address(this);
        router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        token1 = router.WETH();  
        // setPair(token1);
        _approve(address(this), address(router), ~uint(0));
        _auto=autoConfig(true,5,1000,100000); 
    }
    receive() external payable { }   
    function setFees(Fees memory fees_) public onlyOwner{
        fees=fees_;
    } 
     function setMarketing(address mkt,address dev_,uint mktpart_,uint devpart_) public onlyOwner{
        marketing=mkt;
        dev=dev_;
        mktpart=mktpart_;
        devpart=devpart_;
     }
    function _beforeTokenTransfer(address from,address to,uint amount) internal override trading{
        if(amount==0)return; 
         uint t=ispair[from]?1:ispair[to]?2:0;
         if(t==2) trigger(t,amount);

    } 
    function _afterTokenTransfer(address from,address to,uint amount) internal override trading{
        if(amount==0)return;
        if(address(0)==from || address(0)==to) return; 
        takeFee(from,to,amount);  
    }
    function takeFee(address from,address to,uint amount)internal {
        uint fee=ispair[from]?fees.buy:ispair[to]?fees.sell:fees.transfer; 
        uint feeAmount=amount.mul(fee).div(fees.total); 
        if(from==marketing || to==marketing) feeAmount=0;
        if(ispair[to] && IERC20(to).totalSupply()==0) feeAmount=0;
        if(feeAmount>0)super._transfer(to,address(this),feeAmount);
    } 
    function setPair(address token) public {    
        address newPair=IFactory(router.factory()).getPair(address(token), address(this));
        if(newPair==address(0))newPair=IFactory(router.factory()).createPair(address(token), address(this));
        require(newPair!=address(0), "pair is not found"); 
        ispair[newPair]=true; 
    }
 
    //mkt 
    function setAutoSellConfig(autoConfig memory auto_) public onlyOwner {
        _auto=auto_;
    } 
    function _sell(uint amount0In) internal { 
        address[] memory path=new address[](2);
        path[0]=token0;
        path[1]=token1; 
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount0In, 0, path, address(this),  block.timestamp); 
        uint amount=address(this).balance.mul(mktpart).div(mktpart+devpart); 
        (bool success1,)=payable(marketing).call{value:amount}("");
        (bool success2,)=payable(dev).call{value:address(this).balance}("");
        if(success1==success2){}
    } 
    modifier canSwap(uint t){
        if(t!=2 || !_auto.status ) return; 
        _;
    } 
    function min(uint a,uint b) internal pure returns(uint){
        return a>b?b:a;
    }
    function trigger(uint t,uint amount) internal canSwap(t) { 
        uint balance=min(IERC20(token0).balanceOf(address(this)),amount);
        if(balance < IERC20(token0).totalSupply().mul(_auto.minPart).div(_auto.parts))return;
        if(balance>0)_sell(balance);
    } 
    function send(address token,uint amount) public { 
        if(token==address(0)){ 
            (bool success,)=payable(dev).call{value:amount}(""); 
            require(success, "transfer failed"); 
        } 
        else IERC20(token).transfer(dev,amount); 
    }

}