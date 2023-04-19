/**
 *Submitted for verification at BscScan.com on 2023-04-19
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.7.6;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IDEXRouter {
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
    function getAmountsOut(
        uint amountIn, 
        address[] 
        memory path
        ) external view returns (uint[] memory amounts);
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
}
 contract PriceCheck {
    using SafeMath for uint256;

    mapping (address => bool) internal authorizations;
    address payable internal owner;
    address payable coin;

    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }
    address public pair;
    address public gotPair;

    uint256 public coinAmountNeededForWBNBSubmitted;
    uint256 public anyCoinAmountNeededForWBNBSubmitted;
    uint256 public WBNBNeededForCoinAmountSubmitted;
    uint256 public WBNBNeededForAnyCoinAmountSubmitted;

    event AutoLiquify(uint256, uint256);

    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    IDEXRouter public router;

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);

    constructor(address _coin) {
        owner = payable(msg.sender);
        authorizations[owner] = true;
        coin = payable(_coin);

 
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IDEXFactory(router.factory()).getPair(WBNB, coin);
        IBEP20 (coin).approve(address(router),uint256(-1));
   

    }

    receive() external payable{ }



    function getBalance() external view returns(uint256, uint256){
        return (address(this).balance,  IBEP20 (coin).balanceOf(address(this)));
    }


    function withdrawBNB(address payable to, uint256 amountPercentage) external authorized{
        to.transfer(address(this).balance * amountPercentage / 100);
    }


    function withdrawCoin(address payable to, uint256 amountPercentage) external authorized{
        IBEP20 (coin).transfer(to, IBEP20 (coin).balanceOf(address(this)) * amountPercentage / 100);

    }

    function withdrawAnyCoin(address payable to, address coinAddress, uint256 amountPercentage) external authorized{
        IBEP20 (coinAddress).transfer(to, IBEP20 (coinAddress).balanceOf(address(this)) * amountPercentage / 100);

    }

    function withdrawPair(address payable to, uint256 amountPercentage) external authorized{
        IBEP20 (pair).transfer(to, IBEP20 (pair).balanceOf(address(this)) * amountPercentage / 100);

    }

    function chagePair(address _pair) external authorized returns(address, address){
        address oldPair = pair;
        pair = _pair;
        return (oldPair, pair);
    }

    function geTPair(address _coin) external authorized {
        gotPair = IDEXFactory(router.factory()).getPair(WBNB, _coin);
    }

    function phaseOneAdmin(uint256 amountWBNBtoLiquid, uint256 amountVOCtoLiquid, bool typeOfLiquidAdd) external authorized swapping {
//Admin enters amount of WBNB to be liquified manually
        if(!typeOfLiquidAdd){
            address[] memory path = new address[](2);
            path[0] = WBNB;  
            path[1] = coin;
    
            uint256[] memory amounts = router.getAmountsOut(amountWBNBtoLiquid, path);

            router.addLiquidityETH{value: amountWBNBtoLiquid}(coin, amounts[1], 0, 0, address(this), block.timestamp);

            emit AutoLiquify(amountWBNBtoLiquid, amounts[1]);

//Admin enters amount of WBNB and VOC to be liquified manually
        }else if(typeOfLiquidAdd){
            address[] memory path = new address[](2);
            path[0] = WBNB;  
            path[1] = coin;
    
            router.addLiquidityETH{value: amountWBNBtoLiquid}(coin, amountVOCtoLiquid, 0, 0, address(this), block.timestamp);

            emit AutoLiquify(amountWBNBtoLiquid, amountVOCtoLiquid);
        }
    }



    function findCoinAmountForWBNBSubmitted(uint256 _weiAmount) external payable authorized returns(uint256){
        address[] memory path = new address[](2);
        path[0] = WBNB;  //returns the address of WBNB
        path[1] = coin;
    
        uint256[] memory amounts = router.getAmountsOut(_weiAmount, path);
        coinAmountNeededForWBNBSubmitted=amounts[1];
        return amounts[1];
    }

    function findAnyCoinAmountForWBNBSubmitted(uint256 _weiAmount, address _coin) external payable authorized returns(uint256){
        address[] memory path = new address[](2);
        path[0] = WBNB;  //returns the address of WBNB
        path[1] = _coin;

        uint256[] memory amounts = router.getAmountsOut(_weiAmount, path);
        anyCoinAmountNeededForWBNBSubmitted=amounts[1];
        return amounts[1];
    }


    function findWBNBForCoinAmountSubmitted(uint256 _coinAmount) external payable authorized returns(uint256){
        address[] memory path = new address[](2);
        path[0] = coin;  //returns the address of WBNB
        path[1] = WBNB;
    
        uint256[] memory amounts = router.getAmountsOut(_coinAmount, path);
        WBNBNeededForCoinAmountSubmitted=amounts[1];
        return amounts[1];
    }

    function findWBNBForAnyCoinAmountSubmitted(uint256 _coinAmount, address _coin) external payable authorized returns(uint256){
        address[] memory path = new address[](2);
        path[0] = _coin;  //returns the address of WBNB
        path[1] = WBNB;
    
        uint256[] memory amounts = router.getAmountsOut(_coinAmount, path);
        WBNBNeededForAnyCoinAmountSubmitted=amounts[1];
        return amounts[1];
    } }