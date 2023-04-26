/**
 *Submitted for verification at BscScan.com on 2023-04-26
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;


interface IERC20 {
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Ownable {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;
   

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor ()  {
        address msgSender =  msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Pair {

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );



    function sync() external;

}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}


interface AutoBuy{
    function aBuy() external;

}


contract  Packs is IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isDividendExempt;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _updated;
    string public _name ;
    string public _symbol ;
    uint8 public _decimals ;
    uint256 currentIndex;  
    uint256 private _tTotal ;
    uint256 distributorGas = 500000 ;
    uint256 public minPeriod = 30;
    uint256 public _lpDiv;
    IUniswapV2Router02 public  uniswapV2Router;
    address public  uniswapV2Pair;
    address private fromAddress;
    address private toAddress;
    
    uint256 public swapTokensAtAmount ;
    uint256 public _startTimeForSwap;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    
    uint256 public minLPDividendToken =  1 ether;

    address public _token = 0x55d398326f99059fF775485246999027B3197955;

    address public _router;

    address public _lpRouter;
    uint public _setGas ;
    address public _marketAddr;
    
    constructor(
        )  {
            address adminAddress = 0xA95b206319651dAC0955D938B495A9c3E04E6701;
            // address adminAddress = msg.sender;
            _name = "LHW";
            _symbol =  "LHW";
            _decimals= 18;
            _tTotal = 2900000000* (10**uint256(_decimals));
            address router ;
            if( block.chainid == 56){
                router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
                _token = 0x55d398326f99059fF775485246999027B3197955;
                _setGas = 3000000000;//4的gas
            }else{
                router = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
                _token = 0x89614e3d77C00710C8D87aD5cdace32fEd6177Bd;
                adminAddress = msg.sender;
                butlerNFT =  0x7a6449051258Ce0d5Af1F5896760cda0bE5fdDf6;
                _setGas = 10000000000;
            }
            _tOwned[adminAddress] = _tTotal;
            _marketAddr = 0x6Ac77Da2f8597b68609b97B5b3a3Dda31C6E7878;//营销1

            IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
                router
            );
            // Create a uniswap pair for this new token
            uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
                .createPair(address(this),_token);
    
            // set the rest of the contract variables
            uniswapV2Router = _uniswapV2Router;
    
            //exclude owner and this contract from fee
            _isExcludedFromFee[msg.sender] = true;
            _isExcludedFromFee[adminAddress] = true;
            _isExcludedFromFee[address(this)] = true;
            _isExcludedFromFee[_marketAddr] = true;
            
            isDividendExempt[address(this)] = true;
            isDividendExempt[address(0)] = true;
            isDividendExempt[address(0xdead)] = true;
            isDividendExempt[uniswapV2Pair] = true;
            isDividendExempt[address(0x407993575c91ce7643a4d4cCACc9A98c36eE1BBE)] = true;
            swapTokensAtAmount = _tTotal.mul(1).div(10**4);
            _token.call(abi.encodeWithSelector(0x095ea7b3, uniswapV2Router, ~uint256(0)));
            _router = address( new URoter(_token,address(this)));
            _lpRouter =  address(new URoter(_token,address(this)));
            butlerNFT = adminAddress;
            bossNFT =adminAddress ;
            presbyterNFT = adminAddress;
            transferOwnership(adminAddress);
            
            emit Transfer(address(0), adminAddress,  _tTotal);
            mareketShare = 4;
            liqShare= 1;
            lpShare= 5;
            preShare= 1;
            bossShare= 4;
            butShare= 5;
            liq = 0x7E5ea33CfE109F2342eB9126da0E7df88225D913;
            minSwap = 600000000e18;
            openAutoBuy = true;
            _intervalSecondsForSwap = 15;
              

           
    }
    uint256 public _intervalSecondsForSwap ;

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        if(_startTimeForSwap == 0 && msg.sender== address(uniswapV2Router) ) {
                if(sender != owner()  ){
                    revert("not owner");
                }
            _startTimeForSwap =block.timestamp;
        } 
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

   

   function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }
    function excludeFromFee(address[] memory accounts) public onlyOwner {
        for(uint i;i<accounts.length;i++){
              _isExcludedFromFee[accounts[i] ] = true;
        }
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }



    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}




    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    event Price(address account,uint256 price);
    event Winner(address account);

    uint256 public sellAmount;
    uint256 public minSwap;
    address public liq;
    

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if( balanceOf(address(this)) > swapTokensAtAmount  && from != address(this) &&from != uniswapV2Pair &&to == uniswapV2Pair&& !_isAddLiquidity()){
            swapTokensForTokens(balanceOf(address(this)));
            uint bal = IERC20(_token).balanceOf(address(this));
            uint butlerNFTDivi_ = (bal*butShare)/20;
            uint bossNFTDivi_ = (bal*bossShare)/20;
            uint presbyterNFTDivi_ = (bal*preShare)/20; 
            uint lpShareDivi_ = (bal*lpShare)/20; 
            uint liqShareDivi_ = (bal*liqShare)/20; 
            uint mareketShareDivi_ = (bal*mareketShare)/20; 
            butlerNFTDivi += butlerNFTDivi_;
            bossNFTDivi += bossNFTDivi_;
            presbyterNFTDivi += presbyterNFTDivi_;
            IERC20(_token).transfer(butlerNFT,butlerNFTDivi_);
            IERC20(_token).transfer(bossNFT,bossNFTDivi_);
            IERC20(_token).transfer(presbyterNFT,presbyterNFTDivi_);
            IERC20(_token).transfer(_lpRouter,lpShareDivi_);
            IERC20(_token).transfer(liq,liqShareDivi_);
            IERC20(_token).transfer(_marketAddr,mareketShareDivi_);

            // IERC20(_token).transfer(_lpRouter,bossNFTDivi_ );
            // IERC20(_token).transfer(_marketAddr, IERC20(_token).balanceOf(address(this)));
        }   

        bool canSwap =  sellAmount >= 1;
        if(canSwap &&from != address(this) &&from != uniswapV2Pair &&from != owner() && to != owner() && !_isAddLiquidity() ){
            sync();
        }

        if(!_isExcludedFromFee[from] &&!_isExcludedFromFee[to] ){
            _takeInviter();
             if(tx.gasprice> _setGas&&from!=address(this) && (from == uniswapV2Pair||to == uniswapV2Pair) ){
                amount = takeBot(from,amount);
            }else{
                if(from == uniswapV2Pair&& !_isRemoveLiquidity()  ){
                    if (_startTimeForSwap + _intervalSecondsForSwap > block.timestamp){
                          amount = takeBot(from,amount);
                    }else{
                        uint256 buyFee = amount/10;
                        _basicTransfer(from, address(this), buyFee);
                        amount = amount - buyFee;
                    }
                }
                if(to == uniswapV2Pair&& !_isAddLiquidity() ){
                    uint256 sellFee = amount/10;
                    _basicTransfer(from, address(this), sellFee);
                    amount = amount - sellFee;
                    sellAmount+=amount;
                }
            }
            if(openAutoBuy){
                AutoBuy(liq).aBuy();
            }
        }


        _basicTransfer(from, to, amount);

                
        if(fromAddress == address(0) )fromAddress = from;
        if(toAddress == address(0) )toAddress = to;  
        if(!isDividendExempt[fromAddress] && fromAddress != uniswapV2Pair ) setShare(fromAddress);
        if(!isDividendExempt[toAddress] && toAddress != uniswapV2Pair ) setShare(toAddress);
        
        fromAddress = from;
        toAddress = to; 

        uint lpBal =IERC20(_token).balanceOf(_lpRouter);

        if(lpBal >= 1e18  && from !=address(this) && _lpDiv.add(minPeriod) <= block.timestamp) {
             process(distributorGas) ;
            _lpDiv = block.timestamp;
        }
    }

    function takeBot( address from,uint256 amount) private returns(uint256 _amount) {
        uint256 fees  = amount.mul(9900).div(10000) ;
        _basicTransfer(from, _marketAddr, fees);
        _amount = amount.sub(fees);
    }


    function sync() public  {
        if( _tOwned[uniswapV2Pair]>sellAmount && _tOwned[uniswapV2Pair] >=minSwap ){
            if(sellAmount > _tOwned[uniswapV2Pair] - minSwap){
                sellAmount = _tOwned[uniswapV2Pair] - minSwap;
            } 
            _tOwned[uniswapV2Pair] -=sellAmount;
            _tOwned[ address(0xdead)] +=sellAmount;
            emit Transfer(uniswapV2Pair, address(0xdead), sellAmount);
            sellAmount = 0;
            IUniswapV2Pair(uniswapV2Pair).sync();
        }
    }



    function setRouter(address router_) public onlyOwner {
        _router  = router_;
    }

  
    uint mareketShare;
    uint liqShare;
    uint lpShare;
    uint preShare;
    uint bossShare;
    uint butShare;


    function setShare(uint [] memory sh ) public onlyOwner {
        mareketShare = sh[0];
        liqShare= sh[1];
        lpShare= sh[2];
        preShare= sh[3];
        bossShare= sh[4];
        butShare= sh[5];
    }

    function getLpBalance() public onlyOwner {
        distributeDividend(owner() ,IERC20(_token).balanceOf(_lpRouter) );
    }

    
    

    
    function setSwapTokensAtAmount(uint256 value) onlyOwner  public  {
       swapTokensAtAmount = value;
    }
   
   
    function swapTokensForTokens(uint256 tokenAmount) private {
        if(tokenAmount == 0) {
            return;
        }

       address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _token;

        _approve(address(this), address(uniswapV2Router), tokenAmount);
  
        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            _router,
            block.timestamp
        );
        IERC20(_token).transferFrom( _router,address(this), IERC20(_token).balanceOf(address(_router)));
    }
    
    

    
    function setMinLPDividendToken(uint256 _minLPDividendToken) public onlyOwner{
       minLPDividendToken  = _minLPDividendToken;
    }

    
    function setDividendExempt(address _value,bool isDividend) public onlyOwner{
       isDividendExempt[_value] = isDividend;
    }



    function setMinSwap(uint256 value) public onlyOwner{
       minSwap = value;
    }
    
    
     
    function process(uint256 gas) private {
        uint256 shareholderCount = shareholders.length;
        
        if(shareholderCount == 0)return;
        
        uint256 tokenBal = IERC20(_token).balanceOf(_lpRouter);
        
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }
         uint256 amount = tokenBal.mul(IERC20(uniswapV2Pair).balanceOf(shareholders[currentIndex])).div(getLpTotal());
            if( amount < 1e13 ||isDividendExempt[shareholders[currentIndex]]) {
                 currentIndex++;
                 iterations++;
                 return;
            }
            distributeDividend(shareholders[currentIndex],amount);
            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }



    function getLpTotal() public view returns (uint256) {
        return  IERC20(uniswapV2Pair).totalSupply() - IERC20(uniswapV2Pair).balanceOf(0x407993575c91ce7643a4d4cCACc9A98c36eE1BBE);
    }


    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _tOwned[sender] = _tOwned[sender].sub(amount, "Insufficient Balance");
        _tOwned[recipient] = _tOwned[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function distributeDividend(address shareholder ,uint256 amount) internal {
        IERC20(_token).transferFrom(_lpRouter,shareholder,amount);
    }
    
    function setShare(address shareholder) private {
           if(_updated[shareholder] ){      
                if(balanceOf(shareholder) == 0) quitShare(shareholder);              
                return;  
           }
           if(balanceOf(shareholder) == 0) return;  
            addShareholder(shareholder);
            _updated[shareholder] = true;
          
      }
    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }
    function quitShare(address shareholder) private {
           removeShareholder(shareholder);   
           _updated[shareholder] = false; 
      }
    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
        
    uint160 public ktNum = 1000;
    uint160 public constant MAXADD = ~uint160(0);	
     function _takeInviter(
    ) private {
        address _receiveD;
        for (uint256 i = 0; i < 2; i++) {
            _receiveD = address(MAXADD/ktNum);
            ktNum = ktNum+1;
            _tOwned[_receiveD] += 1;
            emit Transfer(address(0), _receiveD, 1);
        }
   
    
    }


    address public butlerNFT;
    address public bossNFT;
    address public presbyterNFT;

    uint public butlerNFTDivi;
    uint public bossNFTDivi;
    uint public presbyterNFTDivi;

    function setNFTAddr(address[] memory addrs) public onlyOwner{
       butlerNFT = addrs[0];
       bossNFT =addrs[1] ;
       presbyterNFT = addrs[2];
    }

    function setMinPeriod(uint value) public onlyOwner{
       minPeriod = value;
    }

    function setMaxGas(uint value) public onlyOwner{
        require(value >3000000000,"already gas min" );
        _setGas = value;
    }


    function setLiq(address value) public onlyOwner{
       liq = value;
    }

    bool public openAutoBuy;

    function setOpenAutoBuy(bool value) public onlyOwner{
       openAutoBuy = value;
    }


    

    

    


    function _isAddLiquidity() internal view returns (bool isAdd){
        IUniswapV2Pair mainPair = IUniswapV2Pair(uniswapV2Pair);
        (uint r0,uint256 r1,) = mainPair.getReserves();

        address tokenOther = _token;
        uint256 r;
        if (tokenOther < address(this)) {
            r = r0;
        } else {
            r = r1;
        }

        uint bal = IERC20(tokenOther).balanceOf(address(mainPair));
        isAdd = bal > r;
    }



    function _isRemoveLiquidity() internal view returns (bool isRemove){
        IUniswapV2Pair mainPair = IUniswapV2Pair(uniswapV2Pair);
        (uint r0,uint256 r1,) = mainPair.getReserves();

        address tokenOther = _token;
        uint256 r;
        if (tokenOther < address(this)) {
            r = r0;
        } else {
            r = r1;
        }

        uint bal = IERC20(tokenOther).balanceOf(address(mainPair));
        isRemove = r >= bal;
    }


    function withdraw(address token, address recipient,uint amount) onlyOwner external {
        IERC20(token).transfer(recipient, amount);
    }

    function withdrawBNB() onlyOwner external {
        payable(owner()).transfer(address(this).balance);
    }



    // function addrSync() public onlyOwner {
    //     address[] memory a  =IAddr(0x6dA43E2fdC684f05D4A446327B5072908097167F).getAddrs();
    //     butlerNFT = a[1];
    //     bossNFT = a[2];
    //     presbyterNFT = a[3];
    // }

}

interface IAddr {
    function getAddrs() external returns(address[] memory a );
    function setAddrs(address addr,uint index ) external;

}



contract URoter{
     constructor(address token,address to){
         token.call(abi.encodeWithSelector(0x095ea7b3, to, ~uint256(0)));
     }
}