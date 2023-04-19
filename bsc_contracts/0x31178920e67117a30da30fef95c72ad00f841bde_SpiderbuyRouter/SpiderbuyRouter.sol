/**
 *Submitted for verification at BscScan.com on 2023-04-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function _approve(address owner, address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Router01 {
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
       if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() 
    {   _status = _NOT_ENTERED;     }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract SpiderbuyRouter is Ownable, ReentrancyGuard{

    using SafeMath for uint256;

    IERC20 public SPT ;
    IERC20 public BUSD;

    IUniswapV2Router01 public Router;

    address public WETH;

    uint256 public PBA;
    uint256 public PP = 50;
    uint256 public STP = 20;
    uint256 public count;
    uint256 public SLC = 1;
    address public LpReceiver;
    address public BNBReceiver;
    uint256 public returnToken;

    constructor()
    {
       SPT  = IERC20(0xEd27FE25D6969476737930650b33dBB141Ef2fe2);
       BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
       Router = IUniswapV2Router01(0x10ED43C718714eb63d5aA57B78B54704E256024E);
       LpReceiver = 0x38ee22D4f944d306C0830cDf80F06FA11859f6DC;
       BNBReceiver = 0x14D8F52E70BB3A4fBA4Ddb12BE6FE60481855eBb;
       WETH = Router.WETH();
    }

    uint256 mintDeposit = 50;

    uint256 public firstHalf = 50;
    uint256 public secondHalf = 50;

    function getPercentages(uint256 amount) public view returns(uint256, uint256){
        uint256 token0 = amount.mul(firstHalf).div(100);
        uint256 token1 = amount.mul(secondHalf).div(100);
        return(token0, token1);
    }


    function getPrice(uint256 packageamount) public view returns(uint256, uint256){

        (uint256 value0, uint256 value1) = getPercentages(packageamount);
        require(packageamount.mod(mintDeposit) == 0 && packageamount >= mintDeposit, "mod err");

        // value of bnb in one dollar 
        address[] memory path0 = new address[](2);
        path0[0] = address(BUSD);
        path0[1] = WETH;
        uint256[] memory amounts0 = Router.getAmountsOut(1 ether,path0);

        // value of SPT  in one dollar 

        address[] memory path1 = new address[](3);
        path1[0] = address(BUSD);
        path1[1] = WETH;
        path1[2] = address(SPT);
        uint256[] memory amounts1 = Router.getAmountsOut(1 ether,path1);

        return (amounts0[1].mul(value0), amounts1[2].mul(value1));
    }


    function buyRouter(uint256 packageamount)
    public 
    payable
    nonReentrant
    {
        require(msg.sender == tx.origin," External Err ");
        (uint256 token0, uint256 token1) = getPrice(packageamount);
        require(SPT.transferFrom(_msgSender(),address(this),token1)," Approve Token First ");
        require(msg.value > token0 ," BNB amount is less than  ");

        uint256 BA = msg.value;
        PBA += ((BA.mul(PP)).div(100));
        count++;
        bool pool;
        if(count == SLC)
        {
        uint256 half = PBA/2;
        uint256[] memory returnValues = swapExactETHForToken(half,address(SPT));
        returnToken = Percentage(returnValues[1]);
        SPT.approve(address(Router), returnValues[1]);
        addLiquidity(returnValues[1],half);
        
        SPT .approve(address(Router), returnToken);
        swapExactTokenForETH(returnToken);
        pool = true;
        }
        if(pool) {
            count = 0;
            PBA = 0;
        }
    }

    function Percentage(uint256 _swapToken) internal view returns(uint256)
    {
        uint256 swapToken;
        swapToken = (_swapToken.mul(STP)).div(100);
        return swapToken;
    }

    function swapExactETHForToken(uint256 value, address token) private 
    returns (uint[] memory amounts )  
    {
        address[] memory path = new address[](2);
        path[0] = Router.WETH();
        path[1] = token;
        return Router.swapExactETHForTokens{value:value}(
        0, 
        path,
        address(this), 
        block.timestamp
        );
    }

    function addLiquidity(uint256 _amount,uint256 half) private 
    {
        Router.addLiquidityETH{value:half}(
            address(SPT),
            _amount,
            0,
            0,
            LpReceiver,
            block.timestamp
        );
    }

    function swapExactTokenForETH(uint256 _tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(SPT);
        path[1] = Router.WETH();
        Router.swapExactTokensForETH(
            _tokenAmount,
            0,
            path,
            BNBReceiver,
            block.timestamp
        );
    }


    function updateFirstHalf(uint256 token0) public onlyOwner{
        firstHalf = token0;
    }

    function updateSecondHalf(uint256 token1) public onlyOwner{
        secondHalf = token1;
    }

    function UpdateLpReceiver(address LpReceiver_)
    public
    onlyOwner
    {     LpReceiver = LpReceiver_;        }

    function UpdateBNBReceiver(address BNBReceiver_)
    public
    onlyOwner
    {    BNBReceiver = BNBReceiver_;         }

    function UpdateROUTER(IUniswapV2Router01 _Router)
    public
    onlyOwner
    {      Router = _Router;        }

    function UpdatePercentage(uint256 _STP)
    public
    onlyOwner
    {      STP = _STP;      }

    function UpdateCondition(uint256 SLC_)
    public
    onlyOwner
    {SLC = SLC_;}

    function withdrawToken()
    public
    onlyOwner
    {   SPT.transfer(owner(),withdrawableToken());   }

    function EmergencywithdrawToken()
    public
    onlyOwner
    {   SPT.transfer(owner(),(SPT.balanceOf(address(this))));   }

    function withdrawBNB()
    public
    onlyOwner
    {   payable(owner()).transfer(withdrawableBNB());  }

    function EmergencywithdrawBNB()
    public
    onlyOwner
    {   payable(owner()).transfer(address(this).balance);  }

    function withdrawableToken()
    private
    view returns(uint256 amount)
    {
        amount = SPT.balanceOf(address(this));
        return amount = amount.sub((amount.mul(30)).div(100));
    }

    function withdrawableBNB()
    private
    view returns(uint256 amount)
    {
        return amount = address(this).balance - PBA; 
    }

    receive() external payable {}

}