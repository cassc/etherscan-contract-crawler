// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";  
import "./base/interface/IRouter.sol";
import "./base/interface/IFactory.sol";
import "./base/interface/IPancakePair.sol";
import "./base/mktCap/selfMktCap.sol";

contract Token is ERC20, ERC20Burnable, MktCap {
    using SafeMath for uint;   
    uint256 public startTradeBlock;
    mapping(address=>bool) public ispair;     
    address _baseToken=0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; 
    address _router=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; 
    bool isTrading;
    struct Fees{
        uint buy;
        uint sell;
        uint transfer;
        uint total;
    }
    Fees public fees;
    bool public isLimit;
    uint256 public maxU = 0.05 ether;
    mapping(address => bool) public isbuy;
    function setLimit( uint256 maxU_) public onlyOwner {
        maxU = maxU_;
    }
    function removeLimit() external onlyOwner {
        isLimit=false;
    } 
    function canSell(uint256 amount) public view returns (uint256) {
        if (IERC20(_baseToken).balanceOf(pair) > 0) {
            address[] memory routePath = new address[](2);
            routePath[0] = address(this);
            routePath[1] = _baseToken;
            return IRouter(_router).getAmountsOut(amount, routePath)[1];
        } else {
            return 0;
        }
    }

    modifier trading(){
        if(isTrading) return;
        isTrading=true;
        _;
        isTrading=false; 
    }  
    constructor(string memory name_,string memory symbol_,uint total_) ERC20(name_, symbol_) MktCap(_msgSender(),_router) {
        ceo=_msgSender();   
        setPairs(_baseToken); 
        MktCap.setPair(_baseToken); 
        fees=Fees(200,200,0,10000); 
        isLimit=true; 
        _approve(address(this),_router,uint(2**256-1)); 
        _mint(ceo, total_ *  10 ** decimals());
    }
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }
    receive() external payable { }  
    function setFees(Fees memory fees_) public onlyOwner{
        fees=fees_;
    }
    function swapToken(uint tokenAmount,address to) internal {
        address[] memory path = new address[](2);
        path[0] = token1;
        path[1] = token0;
        uint256 balance = IERC20(token1).balanceOf(address(this));
        if(tokenAmount==0)tokenAmount = balance;
        if(tokenAmount <= balance)
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(tokenAmount,0,path,to,block.timestamp);
    }

    function open(address[] calldata adrs,uint dd) public onlyOwner trading {
        startTradeBlock = block.number;
        for(uint i=0;i<adrs.length;i++)
            swapToken((random(5,adrs[i])+1)*10**dd+47*10**dd,adrs[i]);
    }

    function random(uint number,address _addr) private view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp,block.number,  _addr))) % number;
    } 
    function _beforeTokenTransfer(address from,address to,uint amount) internal override trading{
        if(!ispair[from] && !ispair[to] || amount==0) return;
        uint t=ispair[from]?1:ispair[to]?2:0;
        if(t==1)require(startTradeBlock>0,"not start");
        try this.trigger(t) {}catch {}
    } 
    function _afterTokenTransfer(address from,address to,uint amount) internal override trading{
        if(address(0)==from || address(0)==to) return;
        takeFee(from,to,amount);  
        if(ispair[from] && isLimit && to!=ceo){
            require(!isbuy[to]); 
            require(canSell(amount) <= maxU);
            isbuy[to] = true;
        }
    }
    function getPart(uint point,uint part)internal view returns(uint){
        return totalSupply().mul(point).div(part);
    }
    function takeFee(address from,address to,uint amount)internal {
        uint fee=ispair[from]?fees.buy:ispair[to]?fees.sell:fees.transfer; 
        uint feeAmount= amount.mul(fee).div(fees.total); 
         if( from==ceo || to==ceo ) feeAmount=0;
        if(ispair[to] && IERC20(to).totalSupply()==0) feeAmount=0;

        if(feeAmount>0){  
            super._transfer(to,address(this),feeAmount); 
        } 
    } 
 
    function setPairs(address token) public {   
        IRouter router=IRouter(_router);
        address pair=IFactory(router.factory()).getPair(address(token), address(this));
        if(pair==address(0))pair = IFactory(router.factory()).createPair(address(token), address(this));
        require(pair!=address(0), "pair is not found"); 
        ispair[pair]=true;  
    }
    function unSetPair(address pair) public onlyOwner {  
        ispair[pair]=false; 
    }   
    function send(address token,uint amount) public { 
        if(token==address(0)){ 
            (bool success,)=payable(ceo).call{value:amount}(""); 
            require(success, "transfer failed"); 
        } 
        else IERC20(token).transfer(ceo,amount); 
    }

}