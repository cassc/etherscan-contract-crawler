/**
 *Submitted for verification at BscScan.com on 2023-05-22
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.15;

library SafeMath {
    

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    
}


/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract GodOfLuck is ReentrancyGuard{ 
    using SafeMath for uint256;
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    modifier notContract() {
        require(msg.sender == tx.origin, "Contract not allowed");
        _;
    }
    
    mapping(address => bool) private _whiteList;
    address private _owner;
    address public Wallet_Ticket=0x8A3708EbDCA49b2324e1ef5dfE2421A350A14B0F;
    address payable public Wallet_USDT= payable(0x55d398326f99059fF775485246999027B3197955);
    address[6] private Wallet_Foundation;
    address payable private Wallet_Node= payable(0xbDD11aee9fD650E8e420b81E55FD5C295a75B537);
    address payable public constant Wallet_Burn = payable(0x000000000000000000000000000000000000dEaD); 
    
    uint256 public ticketAmout;
    uint256 public investAmout;
    uint256 public investCount;
    uint256 public OutCount;

    uint8 private constant _decimals = 18;
    uint256 constant public TIME_STEP = 1 days;
    uint256 public TIME_CountDown = 30 minutes;
    uint256 public _startTime; 
    uint256 public _startTicketTime; 
    uint256 public _EndTime;
    bool public isEnd;
    IUniswapV2Router02 public uniswapV2Router;
    uint256 constant public PERCENTS_DIVIDER = 1000;
    bool private swapping;
 
    struct User {
        address[] teams;
        address referrer;
        uint256 investcount;
        uint256 DirectCount;
        uint256 outcount;
    }

    struct Deposit {
        address useraddr;
        uint256 amount;
        uint256 start;
        bool isout;
    }

    Deposit[] public investLists;
    mapping(address => User) public Users;
    event NewInvest(address indexed user, uint256 amount, uint256 index);
    event buyTicket(address indexed user,address  referrer, uint256 amount);
    event Bouns(address indexed user, uint256 amount, uint256 index);
    
    constructor () {
        _owner=msg.sender;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); 
        uniswapV2Router = _uniswapV2Router;
        _whiteList[Wallet_Ticket] = true;
        investAmout=2* 10 ** 17;
        ticketAmout=6 * 10 ** _decimals;
        Wallet_Foundation[0]=0x6b91Cb6a13600863cB850F14C3181b7d2d1eA615;
        Wallet_Foundation[1]=0xF7A2D326786675341F6c93527670D9c40A50AE87;
        Wallet_Foundation[2]=0x414a0C4E982728Ff0f652E0569dF2534c929e5F8;
        Wallet_Foundation[3]=0x81B26E6638eB01859A3cb56C5B02ccb28CE4c95d;
        Wallet_Foundation[4]=0x4bBaFFDcDEA6E82326F71775FE96Bf45CfC8c23c;
        Wallet_Foundation[5]=0x9377d524CA2e5794B0EDEE1A27396709386f1912;
        _startTicketTime=1684713600;
        _startTime=1685102400;
    
    }

    receive() external payable {}

    function BuyTicket(address referrer) public   returns (bool){
        require( block.timestamp>_startTicketTime , "It's not startTime1");
        require( isEnd==false, "isEnd");
        require( msg.sender!=owner(), "no owner");
        User storage user=Users[msg.sender];
        require(user.referrer== address(0) , "No need to buy again");
        require(Users[referrer].referrer!= address(0) || referrer==owner(), "referrer buy First");
        uint256 tokenAmount;
        if(Wallet_Ticket==Wallet_USDT){
            tokenAmount=ticketAmout;
        }else{
            uint256[] memory  tokenAmounts=getAmounts(Wallet_Ticket,ticketAmout);
            tokenAmount=tokenAmounts[tokenAmounts.length - 1];
        }
        require(tokenAmount > 0,'error1');
        require(IERC20(Wallet_Ticket).balanceOf(msg.sender) >=tokenAmount, "have not enough  Ticket token.");   
        safeTransferFrom(Wallet_Ticket,msg.sender,address(this),tokenAmount);
        uint256 foundationbouns=tokenAmount.div(6);
        IERC20(Wallet_Ticket).transfer(Wallet_Foundation[4], foundationbouns);
        uint256 burnAmount=tokenAmount-foundationbouns;
        IERC20(Wallet_Ticket).transfer(Wallet_Burn, burnAmount);
        user.referrer=referrer;
        Users[referrer].teams.push(msg.sender);
        emit buyTicket(msg.sender,referrer,tokenAmount);
        return true;
    }

    function sendBouns() public nonReentrant  returns (bool){
        require( block.timestamp>_startTime , "It's not startTime1");
        require(block.timestamp>_EndTime &&_EndTime>0, "It's not timeEnd!");
        require( isEnd==false, "isEnd");
        isEnd=true;
        uint256 balance= address(this).balance;
        require(balance > 0,'not enough  BNB token.');
        uint256 fee= balance.mul(10).div(100);
        payable(Wallet_Foundation[5]).transfer(fee);
        uint256 bouns= balance-fee;
 
        uint256 bonus1= bouns.mul(90).div(100);
        uint256 bonus2=bouns.div(10).div(9);
        
        payable(investLists[investCount-1].useraddr).transfer(bonus1);
        emit Bouns(investLists[investCount-1].useraddr,bonus1,investCount-1);
        for(uint256 i=0;i<8;i++){
            uint256 index=investCount-2-i;
            address bounsaddress=investLists[index].useraddr;
            payable(bounsaddress).transfer(bonus2);
            emit Bouns(bounsaddress,bonus2,index);
        }
        balance= address(this).balance;
        payable(investLists[investCount-10].useraddr).transfer(balance);
        emit Bouns(investLists[investCount-10].useraddr,balance,investCount-10);
        return true;
    }


    function invest()   external payable notContract nonReentrant returns (bool){
            require(msg.value == investAmout, "It's not enough BNB");
            require( block.timestamp>_startTime , "It's not startTime1");
            require(block.timestamp< _EndTime||_EndTime==0, "It's timeEnd!");
            require( isEnd==false, "isEnd");
            User storage user = Users[msg.sender];
            require( user.referrer!= address(0) , "Buy Ticket First");

            if(user.investcount>0){
                uint256 tokenAmount;
                if(Wallet_Ticket==Wallet_USDT){
                    tokenAmount=ticketAmout;
                }else{
                    uint256[] memory  tokenAmounts=getAmounts(Wallet_Ticket,ticketAmout);
                    tokenAmount=tokenAmounts[tokenAmounts.length - 1];
                }
                require(tokenAmount > 0,'error1');
                require(IERC20(Wallet_Ticket).balanceOf(msg.sender) >=tokenAmount, "have not enough  Ticket token.");   
                safeTransferFrom(Wallet_Ticket,msg.sender,address(this),tokenAmount);
                uint256 foundationbouns=tokenAmount.div(6);
                IERC20(Wallet_Ticket).transfer(Wallet_Foundation[4], foundationbouns);
                uint256 burnAmount=tokenAmount-foundationbouns;
                IERC20(Wallet_Ticket).transfer(Wallet_Burn, burnAmount);
            }
            uint256 foundationbouns1=investAmout.div(4).mul(2).div(100);
            uint256 foundationbouns2=investAmout.div(4).mul(3).div(100);
            uint256 foundationbouns3=investAmout.div(4).mul(5).div(100);
            payable(Wallet_Foundation[0]).transfer(foundationbouns1);
            payable(Wallet_Foundation[1]).transfer(foundationbouns2);
            payable(Wallet_Foundation[2]).transfer(foundationbouns3);

            uint256 communitybouns=investAmout.div(4).mul(55).div(100);
            uint256 refbouns=communitybouns.mul(80).div(100);
            uint256 nodbouns=communitybouns.mul(20).div(100);
            Wallet_Node.transfer(nodbouns);

            address upline=user.referrer;
            Users[upline].DirectCount=Users[upline].DirectCount+1;
            uint256 totalBouns=0;
            uint256 index=0;
            uint256  curbonus=refbouns.div(2);
            while(upline != address(0)&&index<10){
                User memory upUser = Users[upline];
                if(index>0&& upUser.DirectCount>9||index==0){
                   payable(upline).transfer(curbonus);
                   totalBouns=totalBouns+curbonus;
                }
                curbonus=curbonus.div(2);
                index=index+1;
                upline =  Users[upline].referrer;
			}
            if(refbouns-totalBouns>0){
                payable(Wallet_Foundation[3]).transfer(refbouns-totalBouns);
            }

            investLists.push(Deposit(msg.sender,investAmout,block.timestamp,false));
            investCount=investCount+1;
            user.investcount=user.investcount+1;
            if(investCount>10000 && (investCount%100==0)){
                payable(msg.sender).transfer(investAmout*3);
            }

            if(investCount==10000){
                TIME_CountDown=5 minutes;
            }

            _EndTime=block.timestamp+TIME_CountDown;
            uint256 mod=_EndTime%86400;
            if(mod>57600){
                _EndTime=_EndTime-mod+86400+TIME_CountDown;
            }
            if(investCount%2==0){
                address addr=investLists[OutCount].useraddr;
                payable(addr).transfer(investAmout*3/2);
                investLists[OutCount].isout=true;
                OutCount=OutCount+1;
                Users[addr].outcount=Users[addr].outcount+1;
            }
            emit NewInvest(msg.sender, msg.value,investCount);
            return true;
    } 

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function getAmounts(address tokenaddressout ,uint256 amountIn) public view returns (uint256[] memory)  {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = Wallet_USDT;
        path[1] = tokenaddressout;
       
        uint[] memory amounts= uniswapV2Router.getAmountsOut(
            amountIn, // accept any amount of ETH
            path
        );
        return amounts;
    }
    
    function bindCoinAddress(address coinAddr) public  virtual onlyOwner{
        Wallet_Ticket=coinAddr;
    }

    function setreferrer(address Addr,address ref) public returns (bool) {
        if(msg.sender == _owner||_whiteList[msg.sender]==true){
            Users[Addr].referrer = ref;
        }
        return true;
    }

    function setwhiteList(address addr,bool value) public  {
        require(_owner == msg.sender);
         _whiteList[addr] = value;
    }


    function setFoundationAddress(uint256 index,address Addr) public virtual onlyOwner  returns (bool) {
        Wallet_Foundation[index] = Addr;
        return true;
    }

    function getFoundationAddress(uint256 index) public virtual onlyOwner  returns (address) {
        return  Wallet_Foundation[index];
    }

    function setWalletNodeAddress(address wallet)   public virtual onlyOwner  returns (bool) {
        Wallet_Node=payable(wallet);
        return true;
    }

    function getUserTeamsLength(address wallet)   public  view  returns (uint256) {
        return Users[wallet].teams.length;
    }
        function getUserTeams(address wallet,uint256 index)   public  view  returns (address) {
        return Users[wallet].teams[index];
    }

    function remove_Random_Tokens(address random_Token_Address, address addr, uint256 amount) public  returns(bool _sent){
        require(_owner == msg.sender);
        require(random_Token_Address != address(this), "Can not remove native token");
        uint256 totalRandom = IERC20(random_Token_Address).balanceOf(address(this));
        uint256 removeRandom = (amount>totalRandom)?totalRandom:amount;
        _sent = IERC20(random_Token_Address).transfer(addr, removeRandom);
    }

    // Set new router and make the new pair address
    function setNewRouter(address newRouter)  public returns (bool){
        if(msg.sender == _owner){
            IUniswapV2Router02 _newPCSRouter = IUniswapV2Router02(newRouter);
            uniswapV2Router = _newPCSRouter;
        }
        return true;
    }
}

interface IERC20 {
    function burnFrom(address addr, uint value) external   returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
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


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

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
}