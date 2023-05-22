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
}

interface IStakePool {
    function fundUSDT(uint256 amount) external;
}

contract DLMToken is ERC20, Ownable {
    using SafeMath for uint256;

    IDEXRouter public dexRouter;
    IStakePool public stakePool;
    AutoSwap autoSwap;
    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public disabled;
    mapping (address => bool) public minter;
    address public baseToken;
    address public basePair;
    address public dbToken;
    address public marketingFeeReceiver;

    uint8 transferCount;
    bool public enabledSwap;
    bool inSwap; 
    
    struct FeeRatio{
        uint256 foundation;
        uint256 stakePool;
        uint256 swapDB;
        uint256 total;
    }
    
    FeeRatio public fees;

    modifier swapping() {
        inSwap = true;
        _; 
        inSwap = false; 
    }

    constructor () ERC20("DLM Token","DLM") {
        _mint(msg.sender,10000000e18);
        dexRouter = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        baseToken = 0x55d398326f99059fF775485246999027B3197955;
        marketingFeeReceiver = 0xef77f747bBEd3fd817b4F752A770646cBdBCefB0;

        dbToken=0xe4f4A00AF530776fd94FEA807e473857102F8737;
        
        basePair = IDEXFactory(dexRouter.factory()).createPair(baseToken, address(this));
        autoSwap=new AutoSwap(baseToken);

        isFeeExempt[msg.sender] = true;
        isFeeExempt[dbToken]=true;
        isFeeExempt[address(0xdEaD)]=true;
        
        fees=FeeRatio({
            foundation:30,
            stakePool:20,
            swapDB:30,
            total:80
        });
    }

    function multiSetFeeExempt(address[] memory users,bool flag) external onlyOwner {
        for(uint i;i<users.length;i++){
            isFeeExempt[users[i]]=flag;
        }
    }
    
    function _transfer(address from,address to,uint256 amount) internal override {
        if(inSwap||isFeeExempt[from]||isFeeExempt[to]){
           return super._transfer(from, to, amount);
        }

        if(disabled[from]||disabled[to]){
            revert("wallet disabled");
        }
        
        if(from!=basePair&&to!=basePair){
            process();
            return super._transfer(from, to, amount);
        }

        require(enabledSwap,"swap disabled");

        uint256 fee=amount.mul(fees.total).div(1000);
        
        uint256 balance=amount.sub(fee);
        
        super._transfer(from,address(this),fee);

        transferCount++;
        
        if(from!=basePair&&transferCount>10){
            process();
            transferCount=0;
        }

        super._transfer(from, to, balance);
    }

    function setEnabledSwap() external  onlyOwner {
        enabledSwap=true;
    }

    function process() internal  swapping {
        uint256 balance=balanceOf(address(this));
        if(balance==0){
            return;
        }

        swapTokenAToTokenB(address(this),baseToken,balance,0,address(autoSwap));

        autoSwap.withdraw();
        uint256 totalAmount=IERC20(baseToken).balanceOf(address(this));
        IERC20(baseToken).transfer(marketingFeeReceiver,totalAmount.mul(fees.foundation).div(fees.total));

        uint256 fundUsdt=totalAmount.mul(fees.stakePool).div(fees.total);
        IERC20(baseToken).approve(address(stakePool), fundUsdt);
        stakePool.fundUSDT(fundUsdt);

        uint256 balanceUSDT=IERC20(baseToken).balanceOf(address(this));
        uint256 halfAmount=balanceUSDT.div(2);
        swapTokenAToTokenB(baseToken, dbToken, halfAmount, 0, address(this));
        
        uint256 balanceDB=IERC20(dbToken).balanceOf(address(this));
        IERC20(baseToken).approve(address(dexRouter), halfAmount);
        IERC20(dbToken).approve(address(dexRouter), balanceDB);
        dexRouter.addLiquidity(baseToken, dbToken, halfAmount, balanceDB, 0, 0, dbToken, block.timestamp);
    }

    function swapTokenAToTokenB(address tokenA,address tokenB,uint256 amountA,uint amountB,address to) internal {
        address[] memory path=new address[](2);
        path[0]=tokenA;
        path[1]=tokenB;
        IERC20(tokenA).approve(address(dexRouter), amountA);
        dexRouter.swapExactTokensForTokens(amountA, amountB, path, to, block.timestamp);   
    }
    
    function setFees(FeeRatio memory _fees) external onlyOwner {
        fees=_fees;
    }

    function disableWallet(address user,bool flag) external onlyOwner{
        disabled[user]=flag;
    }

    function setAddress(address _marketingFeeReceiver) external  onlyOwner {
        marketingFeeReceiver=_marketingFeeReceiver;
    }

    function batchDisableWallet(address [] calldata users,bool flag)external onlyOwner{
        for(uint i=0;i<users.length;i++){
            disabled[users[i]]=flag;
        }
    }

    function setStakePool(address _stakePool) external onlyOwner{
        stakePool=IStakePool(_stakePool);
        isFeeExempt[_stakePool]=true;
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