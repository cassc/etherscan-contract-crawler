/**
 *Submitted for verification at BscScan.com on 2023-02-19
*/

/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

interface IChainlink {
  function latestAnswer() external view returns (int256);
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // for lp
   
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);    
    function decimals() external view returns (uint8);   
}

interface IFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}
 

contract PriceOracle {
    uint256 constant F = 1e18;
    address owner;
 
    /////////////////////////  change for release  //////////////////////// 
    address constant public SWAP_FACTORY = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;  //change for release
    address constant public STAKING_POOL = 0xEe165c9333cd53aa1dc6383fEa5A918Cfb4a350c;   //change for release

    address constant public DZHT  =  0x5B90eE203101F7546e5714B1fa8B516D3F187CE2 ;  //change for release
    address constant public LONG  =  0x0A01677fb607b593F4A753F8504A680C20930F21 ;  //change for release
 
    ///////////////////////////////////////////////////////////////////////// 

    //https://docs.chain.link/docs/binance-smart-chain-addresses/
    // bsc main chainlink oracle
    address constant CL_USDT = 0xB97Ad0E74fa7d920791E90258A6E2085088b4320;
    address constant CL_BNB = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
    address constant CL_BTC = 	0x264990fbd0A4796A3E3d8E37C4d5F87a3aCa5Ebf;
    address constant CL_ETH =  0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
    address constant CL_FIL = 0xE5dbFD9003bFf9dF5feB2f4F445Ca00fb121fb83;
    
    //bsc main
    address constant USDT =  0x55d398326f99059fF775485246999027B3197955 ;   
    address constant BNB =   0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c ;   
    address constant BTC =   0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c ;   
    address constant ETH  =  0x2170Ed0880ac9A755fd29B2688956BD959F933F8 ;   
    address constant FIL  =  0x0D8Ce2A99Bb6e3B7Db580eD848240e4a0F9aE153 ; 
 
    address public LONG_USDT ;
    address public DZHT_USDT ;
    address public BTC_DZHT ;
    address public FIL_DZHT ;
    address public ETH_DZHT ;
    address public BNB_DZHT ;
  
    function tvl() public view returns (uint256){
     return IERC20(USDT).balanceOf(STAKING_POOL) * oracle_price(CL_USDT) * 1e10 + 
             IERC20(BNB).balanceOf(STAKING_POOL) * oracle_price(CL_BNB) * 1e10 + 
             IERC20(BTC).balanceOf(STAKING_POOL) * oracle_price(CL_BTC) * 1e10+ 
             IERC20(ETH).balanceOf(STAKING_POOL) * oracle_price(CL_ETH) * 1e10 + 
             IERC20(LONG).balanceOf(STAKING_POOL) * long_price() +
             usdt_balance(LONG_USDT) *oracle_price(CL_USDT) * 1e10 * 2 +
             usdt_balance(DZHT_USDT) *oracle_price(CL_USDT) * 1e10 * 2 +
             dzht_balance(BTC_DZHT) * dzht_price()  * 2 +
             dzht_balance(FIL_DZHT) * dzht_price()  * 2 +
             dzht_balance(ETH_DZHT) * dzht_price()  * 2 +
             dzht_balance(BNB_DZHT) * dzht_price()  * 2 ;
    }

    constructor() public {
        owner = msg.sender;
    } 

    function update() public {
        IFactory factory = IFactory(SWAP_FACTORY);
        LONG_USDT = factory.getPair(LONG, USDT);
        DZHT_USDT = factory.getPair(DZHT, USDT);
        BTC_DZHT  = factory.getPair(BTC, DZHT );
        FIL_DZHT  = factory.getPair(FIL, DZHT );
        ETH_DZHT  = factory.getPair(ETH, DZHT );
        BNB_DZHT  = factory.getPair(BNB, DZHT );     
     }
    

    function usdt_balance( address _lptoken) public view returns (uint256){
        uint token_balance;
        uint256 usd_balance;

        IERC20 pair = IERC20(_lptoken);
        if (pair.token0() == USDT) 
            (usd_balance, token_balance, ) = pair.getReserves();     
        else
            (token_balance, usd_balance , ) = pair.getReserves();           

        return usd_balance;
    }  

    function dzht_balance( address _lptoken) public view returns (uint256){
        uint token_balance;
        uint256 dzht_balance1;

        IERC20 pair = IERC20(_lptoken);
        if (pair.token0() == DZHT) 
            (dzht_balance1, token_balance, ) = pair.getReserves();     
        else
            (token_balance, dzht_balance1 , ) = pair.getReserves();           
            
        return dzht_balance1;
    } 

    // X-USDT OR USDT-X  , return x price
    function amm_price( address _lptoken) public view returns (uint256){
        uint token_balance;
        uint256 usd_balance;
        uint token_decimal;
        address token;

        IERC20 pair = IERC20(_lptoken);
        if (pair.token0() == USDT) {
            (usd_balance, token_balance, ) = pair.getReserves(); 
            token = pair.token1();
        }
        else{
            (token_balance, usd_balance , ) = pair.getReserves();
            token = pair.token0();
        }
        token_decimal = IERC20(token).decimals();
        token_decimal = 10 ** token_decimal;
        uint256 price = usd_balance * token_decimal / token_balance;
        return price;
    }     
   
 
    function long_price() public  view returns (uint256){
        return amm_price(LONG_USDT);
    }

    function dzht_price() public  view returns (uint256){
        return amm_price(DZHT_USDT);
    }

    // return 26 78993591 = 26u
    function oracle_price(address _oracle_address) public view returns (uint256) {
        return uint256(IChainlink(_oracle_address).latestAnswer());
    }
}