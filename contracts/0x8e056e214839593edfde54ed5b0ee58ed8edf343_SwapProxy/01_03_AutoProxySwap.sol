// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.6.99 ;
pragma experimental ABIEncoderV2;
import "./safemath.sol";
import "./uniswaplib.sol";

contract SwapProxy is Ownable{
    using SafeERC20 for IERC20;
    using SafeMath for uint;
    address public WBNB;
    address public BUSD;
    address public USDT;
    address public swap_factory_address         =   address(0);
    uint256 public swap_max_amount              =   200000000000000000;
    uint256 public swap_max_times               =   10;
    uint256 public swap_sell_percent            =   100;
    uint256 public swap_max_fee                 =   35;
    mapping(address => uint256) public swap_spend_used;
    mapping(address => bool) public swap_token_whitelisted;
    mapping(address => bool) public swap_success_sell;
    address[]    public swap_trusted_wallets    =   [0xfC7f92581e727C04d629176DE8D1F7CC4A4A3A2E,0x605c73833c2E5b4C50cC740414f9CF033D4E1b92, 0xF5a511bf55Eabd2703437797E1F57309B9d113C8,0xdeEeb668Fa4aA5A1b16e39Feb18fEe3358e44629, 0x5b3Bcc7D41Ac31BBB0DF826bC87d840a66758886,0x204Aa38D0600E58E47a1277d4cBD573A98af8637, 0x52667E6D66e9987C077AA16A7d79A1A901546149,0xee49b612359f717a403275FD16d008E26173D3A0,0x35d3B9bBd70c1bAbf858A0C0267A182081b616dA, 0xB9cCBd81eA0403033435f481DDA1385a5EB9C8C9];
    IPancakeV2Router public swap_router;

    event TradeLog(string message);
    event SuccessBuy(address target);
    event SuccessSell(address target);

    constructor() payable {
        swap_router                             =   IPancakeV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        swap_factory_address                    =   swap_router.factory();
        WBNB                                    =   0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        BUSD                                    =   0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        USDT                                    =   0xdAC17F958D2ee523a2206206994597C13D831ec7;
        IERC20(WBNB).safeApprove(address(this),uint256(-1));
    }

    modifier onlyTrusted(){
        if(msg.sender == owner){
            _;
            return ;
        }
        for(uint i=0;i<swap_trusted_wallets.length;i++){
            if(swap_trusted_wallets[i] == msg.sender){
                _;
                return ;
            }
        }
        revert("Error:Not trusted wallet!");
    }

    function getLiquiditySourceToken(address target) public view returns(address){
        uint liquidity              =   0;
        address factory             =   swap_factory_address;
        address source_token        =   address(0);
        address[] memory path       =   new address[](3);
        IPancakeFactory iFactory    =   IPancakeFactory(factory);
        path[0]                     =   WBNB;
        path[1]                     =   BUSD;
        path[2]                     =   USDT;
        for(uint256 i = 0;i < 3;i++){
            if(iFactory.getPair(path[i],target) == address(0)){
                continue;
            }
            (uint reserveIn, uint reserveOut) = PancakeLibrary.getReserves(factory, path[i], target);
            if(reserveIn == 0 || reserveOut == 0){
                continue;
            }
            if(reserveOut > liquidity){
                liquidity           =   reserveOut;
                source_token        =   path[i];
            }
        }
        return source_token;
    }

    function getCurrentSpendAmountByReceiveAmount(uint spend_amount,uint receive_amount,address factory,address[] memory  path) internal view returns(uint){
        uint amount                 =   spend_amount;
        uint[] memory amountOut     =   PancakeLibrary.getAmountsOut(factory, spend_amount, path);
        if(amountOut[amountOut.length-1] >= receive_amount){
            uint[] memory amountIn  =   PancakeLibrary.getAmountsIn(factory, receive_amount , path);
            amount                  =   amountIn[0];
        }
        amount                      =   amount <= address(this).balance ? amount:address(this).balance;
        return amount;
    }

    function _swapSupportingFeeOnTransferTokens(address factory,address[] memory path, address _to) internal  {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = PancakeLibrary.sortTokens(input, output);
            IPancakePair pair = IPancakePair(PancakeLibrary.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
            amountOutput = PancakeLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? PancakeLibrary.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function pancakeSell(address factory,address[] memory path,uint256 amount,uint256 bnbMin,address receiver) internal {
        require(path[path.length - 1] == WBNB, 'PancakeRouter: INVALID_PATH');
        TransferHelper.safeTransferFrom(
            path[0], receiver, PancakeLibrary.pairFor(factory, path[0], path[1]), amount
        );
        _swapSupportingFeeOnTransferTokens(factory,path, address(this));
        uint amountOut = IERC20(path[path.length-1]).balanceOf(address(this));
        require(amountOut >= bnbMin, 'ERROR: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(path[path.length-1]).withdraw(amountOut);
        TransferHelper.safeTransferETH(address(this), amountOut);
    }

    function sellToken(address target,uint index) public onlyTrusted {
        bool selled                 =   swap_success_sell[target];
        require(!selled,"Error:Target token already sold!");
        address source              =   WBNB;
        address factory             =   swap_factory_address;
        address[] memory path       =   getBuyPathByToken(target,source);
        uint percent                =   swap_sell_percent / 100;
        path                        =   getSellPathByBuyPath(path);
        for(uint256 i = index;i < swap_trusted_wallets.length;i++){
            address receiver        =   swap_trusted_wallets[i];
            uint balance            =   IERC20(target).balanceOf(receiver);
            if(balance > 0){
                pancakeSell(factory,path,balance * percent,0,receiver);
                if(!selled){
                    swap_success_sell[target]   =   true;
                }
            }else{
                break;
            }
        }
    }

    function isSellNormally(address factory,address[] memory buy_path,uint256 buy_spend_bnb,uint max_fee) public{
        max_fee                     =   max_fee > 0 ? max_fee:swap_max_fee;
        address spender             =   tx.origin;
        address[] memory sell_path  =   getSellPathByBuyPath(buy_path);
        uint256 sell_amount         =   uint256(IERC20(sell_path[0]).balanceOf(spender));
        uint256 bnbMin              =   uint256(buy_spend_bnb * (100 - max_fee) / 100);
        pancakeSell(factory,sell_path,sell_amount,bnbMin,spender);
        revert("s");
    }

    function ensureSellWorks(address factory,address[] memory path,uint256 buy_spend_bnb,uint max_fee) public virtual {
        try this.isSellNormally(factory,path,buy_spend_bnb,max_fee){
        } catch Error(string memory revertReason) {
            if (bytes(revertReason).length == bytes("s").length){
                
            }else{
                revert(revertReason);
            }
        } catch (bytes memory returnData) {
            revert(string(returnData));
        }
    }

    function getSellPathByBuyPath(address[] memory path) internal pure returns (address[] memory){
        address[] memory sell_path  =   new address[](path.length);
        for(uint256 i = 0 ;i < path.length; i++){
            sell_path[i]            =   path[path.length - 1 - i];
        }
        return sell_path;
    }

    function getBuyPathByToken(address target,address source) internal view returns (address[] memory){
        address weth                =   WBNB;
        address[] memory path       =   source == weth ? new address[](2):new address[](3);
        path[0]                     =   weth;
        if(source == weth){
            path[1]                 =   target;
        }else if(source == BUSD){
            path[1]                 =   BUSD;
            path[2]                 =   target;
        }else{
            path[1]                 =   USDT;
            path[2]                 =   target;
        }
        return path;
    }

    function swapBNBForTokens(address target,uint spend_amount,uint receive_amount,uint max_fee,bool check_sell) public onlyTrusted {
        uint256 init_balance        =   address(this).balance;
        if(init_balance <= 0){
            return ;
        }
        address weth                =   0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address factory             =   0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
        address[] memory path       =   new address[](2);
        path[0]                     =   weth;
        path[1]                     =   address(target);
        uint current_spend_amount   =   receive_amount==0 ? spend_amount:getCurrentSpendAmountByReceiveAmount(spend_amount,receive_amount,factory,path);
        if(current_spend_amount <= 0){
            return ;
        }
        IWETH(weth).deposit{value: current_spend_amount}();
        assert(IWETH(weth).transfer(PancakeLibrary.pairFor(factory, path[0], path[1]), current_spend_amount));
        _swapSupportingFeeOnTransferTokens(factory,path, payable(tx.origin));
        uint current_balance        =   address(this).balance;
        uint buy_spend_bnb          =   uint(init_balance - current_balance);
        if(check_sell){
            ensureSellWorks(factory,path,buy_spend_bnb,max_fee);
            uint balance_max        =   uint(swap_max_amount * swap_max_times);
            if(address(this).balance    >=  balance_max){
                withdrawToOwner(balance_max);
            }
        }
    }

    function withdrawERC20Token(address token,uint256 amount) public onlyOwner{
        if(amount == 0){
            amount                  =   IERC20(token).balanceOf(address(this));
        }
        IERC20(token).transfer(owner,amount);
    }

    function withdrawBNB(uint remaining) external onlyOwner{
        withdrawToOwner(remaining);
    }

    function withdrawToOwner(uint remaining) internal{
        payable(owner).transfer(address(this).balance-remaining);
    }

    function setTrustedWallets(address[] memory wallets) public onlyOwner{
        swap_trusted_wallets    =   wallets;
    }

    function setSwapMaxAmount(uint amount) public onlyOwner{
        swap_max_amount          =   amount;
    }

    function setSwapMaxTimes(uint times) public onlyOwner{
        swap_max_times          =   times;
    }

    function setSwapMaxFee(uint fee) public onlyOwner{
        swap_max_fee             =   fee;
    }

    function setSwapSellPercent(uint percent) public onlyOwner{
        swap_sell_percent        =   percent;
    }

    function canBuyToken(address target) external view returns(bool){
        if(address(this).balance <= 0){
            return false;
        }
        address source           =  getLiquiditySourceToken(target);
        if(source != address(0)){
            return false;
        }
        return true;
    }

    receive() external payable {
        
    }

    function setTargetTokenWhitelist(address target) external {
        swap_token_whitelisted[target] = true;
    }
}