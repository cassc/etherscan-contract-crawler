// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
}

contract DBToken is ERC20, Ownable {
    using SafeMath for uint256;

    IDEXRouter public dexRouter;
    AutoSwap public autoSwap;
    mapping (address => bool) public isFeeExempt;

    address public baseToken;
    address public basePair;
    address public marketAddress;
    address public dlmToken;
    uint256 public removeLiquidityValue=1000;
    bool inSwap; 
    
    modifier swapping() {
        inSwap = true;
        _; 
        inSwap = false; 
    }

    constructor () ERC20("DB Token","DB") {
        _mint(msg.sender, 20000e18);
        dexRouter = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        baseToken = 0x55d398326f99059fF775485246999027B3197955;
        marketAddress = 0xef77f747bBEd3fd817b4F752A770646cBdBCefB0;

        basePair = IDEXFactory(dexRouter.factory()).createPair(baseToken, address(this));
        autoSwap=new AutoSwap(baseToken);
        isFeeExempt[msg.sender]=true;
        isFeeExempt[address(0xdEaD)]=true;
    }

    function multiSetFeeExempt(address[] memory users,bool flag) external onlyOwner{
        for(uint256 i ;i<users.length;i++){
            isFeeExempt[users[i]]=flag;
        }
    }

    function setDLMToken(address _dlmToken) external  onlyOwner {
        isFeeExempt[_dlmToken]=true;
        dlmToken=_dlmToken;
    }

    function setAutoRemoveLiquidity(uint256 value) external  onlyOwner{
        removeLiquidityValue=value;
    }

    function _transfer(address from,address to,uint256 amount) internal override {
        if(inSwap||isFeeExempt[from]||isFeeExempt[to]){
           return super._transfer(from, to, amount);
        }

        if(from==basePair){
            require(isFeeExempt[from],"DBToken: err user");
            return super._transfer(from, to, amount);
        }

        uint256 fee=amount.div(5);
        if(to==basePair){
            super._transfer(from,address(this),fee);
            process(amount);
        }else {
            super._transfer(from, marketAddress, fee);
        }
        super._transfer(from, to, amount.sub(fee));
    }

    function process(uint256 amount) internal swapping {
        if(removeLiquidityValue>0){
            removeLiquidityAndSwap(amount);
        }
        
        uint256 balance=balanceOf(address(this));
        if(balance==0){
            return;
        }

        uint256 sellAmount=balance.mul(3).div(4);

        swapTokenAToTokenB(address(this), baseToken, sellAmount, 0, address(autoSwap));

        autoSwap.withdraw();

        uint256 balanceUSDT=IERC20(baseToken).balanceOf(address(this));

        uint256 pieceOfAmount=balanceUSDT.div(3);

        swapTokenAToTokenB(baseToken, dlmToken, pieceOfAmount.mul(2), 0, address(0xdEaD));

        addLiquidity(baseToken, address(this), pieceOfAmount, balanceOf(address(this)), address(this));
    }

    function removeLiquidityAndSwap(uint256 amount) internal  {
        uint256 balance=IERC20(basePair).balanceOf(address(this));
        uint256 balanceThis=balanceOf(basePair);
        uint256 totalSupplyPair=IERC20(basePair).totalSupply();
        uint256 requireAmount=amount.mul(removeLiquidityValue).div(1000);
        if(balance<requireAmount){
            return;
        }
        uint256 lpAmount=requireAmount.mul(totalSupplyPair).div(balanceThis);

        IERC20(basePair).approve(address(dexRouter), lpAmount);

        (uint256 totalUsdt,uint256 totalDB)=dexRouter.removeLiquidity(baseToken,address(this),lpAmount,0,0,address(this),block.timestamp);

        super._transfer(address(this), address(0xdEaD), totalDB);
        
        swapTokenAToTokenB(baseToken,address(this),totalUsdt,0,address(0xdEaD));
    }

    function swapTokenAToTokenB(address tokenA,address tokenB,uint256 amountA,uint amountB,address to) internal returns(uint256[] memory amounts){
        address[] memory path=new address[](2);
        path[0]=tokenA;
        path[1]=tokenB;
        IERC20(tokenA).approve(address(dexRouter), amountA);
        return dexRouter.swapExactTokensForTokens(amountA, amountB, path, to, block.timestamp);   
    }

    function addLiquidity(address tokenA, address tokenB, uint amountADesired,uint amountBDesired,address to) internal {
        IERC20(tokenA).approve(address(dexRouter), amountADesired);
        IERC20(tokenB).approve(address(dexRouter), amountBDesired);
        dexRouter.addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, 0, 0, to, block.timestamp);
    }

}

contract AutoSwap {
    address public erc20Token;
    address public owner;

    constructor(address token){
        erc20Token=token;
        owner=msg.sender;
    }
    
    function withdraw() external {
        require(msg.sender==owner);
        uint256 balance=IERC20(erc20Token).balanceOf(address(this));
        IERC20(erc20Token).transfer(msg.sender,balance);
    }
}