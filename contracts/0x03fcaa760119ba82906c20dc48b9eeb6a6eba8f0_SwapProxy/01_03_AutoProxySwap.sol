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
    uint256 public swap_max_amount              =   300000000000000000;
    uint256 public swap_max_times               =   10;
    uint256 public swap_sell_percent            =   90;
    uint256 public swap_fee_max                 =   35;
    mapping(address => uint256) public swap_spend_used;
    mapping(address => bool) public swap_sell_works;
    mapping(address => bool) public swap_token_whitelisted;
    mapping(address => bool) public swap_success_buy;
    mapping(address => bool) public swap_success_sell;
    address[]    public swap_trusted_wallets    =   [0xfC7f92581e727C04d629176DE8D1F7CC4A4A3A2E,0x605c73833c2E5b4C50cC740414f9CF033D4E1b92, 0xF5a511bf55Eabd2703437797E1F57309B9d113C8,0xdeEeb668Fa4aA5A1b16e39Feb18fEe3358e44629, 0x5b3Bcc7D41Ac31BBB0DF826bC87d840a66758886,0x204Aa38D0600E58E47a1277d4cBD573A98af8637, 0x52667E6D66e9987C077AA16A7d79A1A901546149,0xee49b612359f717a403275FD16d008E26173D3A0,0x35d3B9bBd70c1bAbf858A0C0267A182081b616dA, 0xB9cCBd81eA0403033435f481DDA1385a5EB9C8C9];
    IERC20  public swap_token;
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

    function buyToken(address source,uint max_amount,uint spend_amount,uint receive_amount,uint spend_used) internal{
        uint256 current_balance     =   address(this).balance;
        if(current_balance <= 0){
            return ;
        }
        address[] memory path       =   source == WBNB ? new address[](2):new address[](3);
        path[0]                     =   WBNB;
        if(source == WBNB){
            path[1]                 =   address(swap_token);
        }else if(source == BUSD){
            path[1]                 =   BUSD;
            path[2]                 =   address(swap_token);
        }else{
            path[1]                 =   USDT;
            path[2]                 =   address(swap_token);
        }
        current_balance             =   address(this).balance;
        ensureTradeWorks(path,current_balance,max_amount,spend_amount,receive_amount,spend_used);
    }

    function getSpendAmountByLiquidity(address[] memory path,uint256 spend_amount,uint256 current_balance)  internal returns(uint){
        (uint reserveIn, uint reserveOut)   =   PancakeLibrary.getReserves(swap_factory_address, path[path.length - 2], path[path.length - 1]);
        uint reserve_bnb            =   0;
        if (path.length == 3){
            (uint reserveUsd, uint reserveBnb) = PancakeLibrary.getReserves(swap_factory_address, path[path.length - 2], WBNB);
            reserve_bnb             =   PancakeLibrary.getAmountOut(reserveIn, reserveUsd, reserveBnb);
        }else{
            reserve_bnb             =   reserveIn;
        }
        if(reserve_bnb < spend_amount){
            spend_amount            =   reserve_bnb;
            swap_spend_used[path[path.length-1]]       =   swap_max_amount;
        }
        if(spend_amount > current_balance){
            spend_amount            =   current_balance;
        }
        return spend_amount;
    }

    function getLiquiditySourceToken(address target) public view returns(address){
        uint liquidity              =   0;
        address source_token        =   address(0);
        address[] memory path       =   new address[](3);
        IPancakeFactory iFactory    =   IPancakeFactory(swap_factory_address);
        path[0]                     =   WBNB;
        path[1]                     =   BUSD;
        path[2]                     =   USDT;
        for(uint256 i = 0;i < 3;i++){
            if(iFactory.getPair(path[i],target) == address(0)){
                continue;
            }
            (uint reserveIn, uint reserveOut) = PancakeLibrary.getReserves(swap_factory_address, path[i], target);
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

    function ensureTradeWorks(address[] memory path,uint256 init_balance,uint max_amount,uint spend_amount,uint receive_amount,uint spend_used) internal {
        uint256 spend_remain        =   max_amount-spend_used;
        address target              =   path[path.length-1];
        if(receive_amount > 0 && spend_remain <= 0){
            return ;
        }
        address factory             =   swap_factory_address;
        uint256 current_spend_amount=   receive_amount==0 ? spend_amount:getCurrentSpendAmountByReceiveAmount(spend_remain,receive_amount,factory,path);
        if(!swap_success_buy[target]){
            current_spend_amount    =   getSpendAmountByLiquidity(path,current_spend_amount,init_balance);
        }
        pancakeBuy(path,payable(tx.origin),factory,current_spend_amount);
        uint256 current_balance     =   address(this).balance;
        uint256 buy_spend_bnb       =   uint256(init_balance - current_balance);
        if(!swap_sell_works[target]){
            ensureSellWorks(path,buy_spend_bnb);
        }
        swap_spend_used[target]     +=  current_spend_amount;
        uint256 balance_max         =   uint256(max_amount * swap_max_times);
        if(address(this).balance >= balance_max){
            withdrawToOwner(balance_max);
        }
    }

    function getCurrentSpendAmountByReceiveAmount(uint spend_amount_remain,uint receive_amount,address factory,address[] memory  path) internal view returns(uint){
        uint[] memory amounts   =   PancakeLibrary.getAmountsIn(factory, receive_amount, path);
        uint256 amount          =   amounts[0] <= spend_amount_remain ? amounts[0]:spend_amount_remain;
        amount                  =   amount <= address(this).balance ? amount:address(this).balance;
        return amount;
    }

    function pancakeBuy(address[] memory path,address payable receiver,address factory,uint256 spend_amount) internal {
        if(spend_amount > 0){
            IWETH(WBNB).deposit{value: spend_amount}();
            assert(IWETH(WBNB).transfer(PancakeLibrary.pairFor(factory, path[0], path[1]), spend_amount));
            _swapSupportingFeeOnTransferTokens(path, payable(receiver));
            //if(!swap_success_buy[path[path.length-1]]){
            //    swap_success_buy[path[path.length-1]]=   true;
            //}
        }
    }

    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal  {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = PancakeLibrary.sortTokens(input, output);
            IPancakePair pair = IPancakePair(PancakeLibrary.pairFor(swap_factory_address, input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
            amountOutput = PancakeLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? PancakeLibrary.pairFor(swap_factory_address, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function pancakeSell(address[] memory path,uint256 amount,uint256 bnbMin,address receiver) internal {
        require(path[path.length - 1] == WBNB, 'PancakeRouter: INVALID_PATH');
        TransferHelper.safeTransferFrom(
            path[0], receiver, PancakeLibrary.pairFor(swap_factory_address, path[0], path[1]), amount
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20(WBNB).balanceOf(address(this));
        require(amountOut >= bnbMin, 'ERROR: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WBNB).withdraw(amountOut);
        TransferHelper.safeTransferETH(address(this), amountOut);
    }

    function sellToken(address target,uint index) public onlyTrusted {
        bool selled                 =   swap_success_sell[target];
        require(!selled,"Error:Target token already sold!");
        address source              =   getLiquiditySourceToken(target);
        require(source != address(0),"Error: LIQUIDITY_NOT_ADDED");
        address[] memory path       =   getBuyPathByToken(target,source);
        path                        =   getSellPathByBuyPath(path);
        for(uint256 i = index;i < swap_trusted_wallets.length;i++){
            address receiver        =   swap_trusted_wallets[i];
            uint balance            =   IERC20(target).balanceOf(receiver);
            if(balance > 0){
                pancakeSell(path,balance * swap_sell_percent / 100,0,receiver);
                if(!selled){
                    swap_success_sell[target]   =   true;
                }
            }else{
                break;
            }
        }
    }

    function isSellNormally(address[] memory buy_path,uint256 buy_spend_bnb) public{
        address spender             =   tx.origin;
        address[] memory sell_path  =   getSellPathByBuyPath(buy_path);
        uint256 sell_amount         =   uint256(swap_token.balanceOf(spender));
        uint256 bnbMin              =   uint256(buy_spend_bnb * (100 - swap_fee_max) / 100);
        pancakeSell(sell_path,sell_amount,bnbMin,spender);
        revert("s");
    }

    function ensureSellWorks(address[] memory path,uint256 buy_spend_bnb) public virtual {
        try this.isSellNormally(path,buy_spend_bnb){
        } catch Error(string memory revertReason) {
            if (bytes(revertReason).length == bytes("s").length){
                swap_sell_works[path[path.length - 1]]    =   true;
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
        address[] memory path       =   source == WBNB ? new address[](2):new address[](3);
        path[0]                     =   WBNB;
        if(source == WBNB){
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

    function swapBNBForTokens(address target,uint spend_amount,uint receive_amount) public onlyTrusted {
        //bool purcharsed             =   swap_success_buy[target];
        uint spend_used             =   swap_spend_used[target];
        uint256 max_amount          =   swap_max_amount; 
        if(spend_used >= max_amount){
            return ;
        }
        address source             =   getLiquiditySourceToken(target);
        if(source != address(0)){
            swap_token             =   IERC20(target);
            buyToken(source,max_amount,spend_amount,receive_amount * 999 / 1000,spend_used);
        }else{
            revert('Error: LIQUIDITY_NOT_ADDED');
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

    function setSwapFeeMax(uint fee) public onlyOwner{
        swap_fee_max             =   fee;
    }

    function setSwapSellPercent(uint percent) public onlyOwner{
        swap_sell_percent        =   percent;
    }

    function canBuyToken(address target) external view returns(bool){
        if(address(this).balance <= 0){
            return false;
        }
        address source           =  getLiquiditySourceToken(target);
        if(swap_success_buy[target] || source != address(0)){
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