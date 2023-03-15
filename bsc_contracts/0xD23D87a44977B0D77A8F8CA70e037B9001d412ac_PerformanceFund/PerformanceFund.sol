/**
 *Submitted for verification at BscScan.com on 2023-03-15
*/

/*
    SPDX-License-Identifier: MIT
    A Bankteller Production
    Elephant Money
    Copyright 2023
*/

/*

    Elephant Money TRUNK / ELEPHANT / TRUMPET Governance

    - A growing suit of tools for supporting core tokens

    Only at https://elephant.money

*/

pragma solidity 0.8.17;

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

abstract contract Context is ReentrancyGuard {

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

}



/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    bool private _paused;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event RunStatusUpdated(bool indexed paused);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        _paused = false;
        emit RunStatusUpdated(_paused);
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns if paused status
     */
    function isPaused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called when contract is paused
     */
    modifier isRunning() {
        require(
            _paused == false,
            "Function unavailable because contract is paused"
        );
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Pause the contract for functions that check run status
     * Can only be called by the current owner.
     */
    function updateRunStatus(bool paused) public virtual onlyOwner {
        emit RunStatusUpdated(paused);
        _paused = paused;
    }

}

/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * @dev This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable {
    mapping(address => bool) public whitelist;

    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);

    /**
     * @dev Throws if called by any account that's not whitelisted.
     */
    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "not whitelisted");
        _;
    }

    function addAddressToWhitelist(address addr)
        public
        onlyOwner
        returns (bool success)
    {
        if (!whitelist[addr]) {
            whitelist[addr] = true;
            emit WhitelistedAddressAdded(addr);
            success = true;
        }
    }

    function addAddressesToWhitelist(address[] memory addrs)
        public
        onlyOwner
        returns (bool success)
    {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (addAddressToWhitelist(addrs[i])) {
                success = true;
            }
        }
    }

    function removeAddressFromWhitelist(address addr)
        public
        onlyOwner
        returns (bool success)
    {
        if (whitelist[addr]) {
            whitelist[addr] = false;
            emit WhitelistedAddressRemoved(addr);
            success = true;
        }
    }

    function removeAddressesFromWhitelist(address[] memory addrs)
        public
        onlyOwner
        returns (bool success)
    {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (removeAddressFromWhitelist(addrs[i])) {
                success = true;
            }
        }
    }
}

// pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// pragma solidity >=0.6.2;

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

// pragma solidity >=0.6.2;

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

interface IERC20 {
    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) external returns (bool);

    /**
     * @dev Burns the amount of tokens owned by `msg.sender`.
     */
    function burn(uint256 _value) external;

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

interface ITRUMPET is IERC20 {
    /** 
        Mint TRUMPET Tokens For `recipient` By Depositing TRUNK Into The Contract
            Requirements:
                Approval from the TRUNK prior to purchase
        
        @param numTokens number of TRUNK tokens to mint TRUMPET with
        @param recipient Account to receive minted TRUMPET tokens
        @return tokensMinted number of TRUMPET tokens minted
    */
    function mintWithBacking(uint256 numTokens, address recipient) external returns (uint256);

    /** 
        Burns Sender's TRUMPET Tokens and redeems their value in TRUNK for `recipient`
        @param tokenAmount Number of TRUMPET Tokens To Redeem, Must be greater than 0
        @param recipient Recipient Of TRUNK transfer, Must not be address(0)
    */
    function sellTo(uint256 tokenAmount, address recipient) external returns (uint256);

} 

interface ITreasury {
    function withdraw(uint256 tokenAmount) external;

    function withdrawTo(address _to, uint256 _amount) external;
}

interface IPcsPeriodicTwapOracle {

    // performs chained update calculations on any number of pairs
    //whitelisted to avoid DDOS attacks since new pairs will be registered
    function updatePath(address[] memory path) external;

    //updates all pairs registered 
    function updateAll() external returns (uint updatedPairs) ;
    
    // performs chained getAmountOut calculations on any number of pairs
    function consultAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);

    // returns the amount out corresponding to the amount in for a given token using the moving average over the time
    // range [now - [windowSize, windowSize - periodSize * 2], now]
    // update must have been called for the bucket corresponding to timestamp `now - windowSize`
    function consult(address tokenIn, uint amountIn, address tokenOut) external view returns (uint amountOut);

}

//@dev Simple onchain oracle for important Elephant Money smart contracts
contract AddressRegistry {
    address public constant coreAddress =
        address(0xE283D0e3B8c102BAdF5E8166B73E02D96d92F688); //ELEPHANT
    address public constant coreTreasuryAddress =
        address(0xAF0980A0f52954777C491166E7F40DB2B6fBb4Fc); //ELEPHANT Treasury
    address public constant collateralAddress =
        address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); //BUSD
    address public constant collateralTreasuryAddress =
        address(0xCb5a02BB3a38e92E591d323d6824586608cE8cE4); //BUSD Treasury
    address public constant collateralRedemptionAddress =
        address(0xD3B4fB63e249a727b9976864B28184b85aBc6fDf); //BUSD Redemption Pool
    address public constant collateralBufferAddress =
        address(0xd9dE89efB084FfF7900Eac23F2A991894500Ec3E); //BUSD Buffer Pool
    address public constant backedAddress =
        address(0xdd325C38b12903B727D16961e61333f4871A70E0); //TRUNK Stable coin
    address public constant backedTreasuryAddress =
        address(0xaCEf13009D7E5701798a0D2c7cc7E07f6937bfDd); //TRUNK Treasury
    address public constant backedLPAddress =
        address(0xf15A72B15fC4CAeD6FaDB1ba7347f6CCD1E0Aede); //TRUNK/BUSD LP
    address public constant routerAddress =
        address(0x10ED43C718714eb63d5aA57B78B54704E256024E);  //PCS Router
    //PCS Factory - 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73
    address public constant oracleAddress = 
        address(0xb9394B2dD11115721D93A6f05215f81c54893861); //Oracle
    address public constant trumpetAddress = 
        address(0x574a691D05EeE825299024b2dE584B208647e073); //TRUMPET
}

abstract contract ElephantCore is Context, Whitelist {
    using SafeMath for uint256;

    AddressRegistry internal registry;
    

    IERC20 internal collateralToken;
    IERC20 internal backedToken;
    IERC20 internal coreToken;
    ITRUMPET internal trumpet;


    ITreasury internal collateralTreasury;
    ITreasury internal coreTreasury;
    ITreasury internal backedTreasury;

    IUniswapV2Router02 internal  collateralRouter;

    IPcsPeriodicTwapOracle internal oracle;
    
    event UpdateCollateralRouter(address indexed addr);

    constructor () Ownable() {
        //init reg
        registry = new AddressRegistry();

        //the collateral router can be upgraded in the future
        collateralRouter = IUniswapV2Router02(registry.routerAddress());

        //the main oracle 
        oracle = IPcsPeriodicTwapOracle(registry.oracleAddress());

        //setup tokens
        collateralToken = IERC20(registry.collateralAddress());
        coreToken = IERC20(registry.coreAddress());
        backedToken = IERC20(registry.backedAddress());
        trumpet = ITRUMPET(registry.trumpetAddress());

        //treasury intialization
        collateralTreasury = ITreasury(registry.collateralTreasuryAddress());
        coreTreasury = ITreasury(registry.coreTreasuryAddress());
        backedTreasury = ITreasury(registry.backedTreasuryAddress());

    }

     //Liquidity is only generated from the inbound fees on mint.
    //Redeeming against the LP will always be less profitable than redeeming directly against the reserve
    //The LP takes pressure off of the ELEPHANT treasury and creates arbitrage opportunities to acquire cheap TRUNK
    function addLiquidity() internal {
        
        //available liquidity, should be roughly equal to the feeAmount...
        uint collateralAmount = collateralToken.balanceOf(address(this));
        uint backedAmount = backedToken.balanceOf(address(this));
        
        
        // approve token transfers to cover all possible scenarios
        require(collateralToken.approve(address(collateralRouter), collateralAmount));
        require(backedToken.approve(address(collateralRouter), backedAmount));

        // add the liquidity
        collateralRouter.addLiquidity(
            address(backedToken),
            address(collateralToken),
            backedAmount,
            collateralAmount,
            0, // no mins required
            0, // no mins required
            address(backedToken), //TRUNK owns its own locked liquidity
            block.timestamp
        );
        
        //Clean up after ourselves - ELEPHANT
        uint dust = backedToken.balanceOf(address(this));

        //send leftovers 
        if (dust > 0){
            backedToken.transfer(address(backedTreasury), dust);
        }

        //Clean up after ourselves - BUSD
        dust = collateralToken.balanceOf(address(this));

        //send leftovers 
        if (dust > 0){
            collateralToken.transfer(address(collateralTreasury), dust);
        }
    }

    // This function is sensitive to slippage and that isn't a bad thing...
    // Don't dump your core or backed tokens... This is a community project
    function estimateCollateralToCore(uint collateralAmount) public view returns (uint wethAmount, uint coreAmount) {
         //Convert from collateral to WETH using the collateral's Oracle
        address[] memory path = new address[](3);
        path[0] = address(collateralToken);
        path[1] = collateralRouter.WETH();
        path[2] = address(coreToken);

        uint[] memory amounts = collateralRouter.getAmountsOut(collateralAmount, path);
        
        //Use core router to get amount of coreTokens required to cover 
        wethAmount = amounts[1];
        coreAmount = amounts[2];
    }
    
    // This function is sensitive to slippage and that isn't a bad thing...
    // Estimates the amount of  core tokens getting transfered to USD collateral tokens
    function estimateCoreToCollateral(uint coreAmount) public view returns (uint wethAmount, uint collateralAmount) {
         //Convert from core to WETH using the core's Oracle
        address[] memory path = new address[](3);
        path[0] = address(coreToken);
        path[1] = collateralRouter.WETH();
        path[2] = address(collateralToken);

        uint[] memory amounts = oracle.consultAmountsOut(coreAmount, path);
        
        wethAmount = amounts[1];
        collateralAmount = amounts[2];
    }


    //Buy TRUNK with ELEPHANT
    function buyBackedWithCore(uint tokenAmount) internal returns (uint backedAmount) {
        address[] memory path;
        path = new address[](3);
        
        //Sell core
        path[0] = address(coreToken);
        path[1] = address(collateralToken);
        path[2] = address(backedToken);
        
        //Need to be able to approve the core token for transfer against fixed liquidity
        //Pancake and others will maintain interfaces for legacy applications
        require(coreToken.approve(address(collateralRouter), tokenAmount));

        uint initialBalance = backedToken.balanceOf(address(this));
        
        collateralRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, //accept any amount of backed tokens
            path,
            address(this), //send it here
            block.timestamp
        );
        
        //This contract does not hold any token balances
        backedAmount = backedToken.balanceOf(address(this)).sub(initialBalance);

    }


    //Buy BUSD with ELEPHANT
    function buyCollateralWithCore(uint tokenAmount) internal returns (uint collateralAmount) {
        address[] memory path;
        path = new address[](2);
        
        //Sell core
        path[0] = address(coreToken);
        path[1] = address(collateralToken);
        
        //Need to be able to approve the core token for transfer against fixed liquidity
        //Pancake and others will maintain interfaces for legacy applications
        require(coreToken.approve(address(collateralRouter), tokenAmount));

        uint initialBalance = collateralToken.balanceOf(address(this));
        
        collateralRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, //accept any amount of backed tokens
            path,
            address(this), //send it here first so we can find out how much TRUNK we received
            block.timestamp
        );
        
        //This contract does not hold any token balances
        collateralAmount = collateralToken.balanceOf(address(this)).sub(initialBalance);

    }

    ///Returns true if we are above peg
    function isAbovePeg() public view returns (bool abovePeg) {
         
        address[] memory path = new address[](2);
        path[0] = address(backedToken);
        path[1] = address(collateralToken);

        uint[] memory amounts = oracle.consultAmountsOut(1e18, path);
        
        abovePeg = amounts[1] >= 0.995e18; //0.5% wiggle
    }

}

//Buys TRUNK from the TRUNK/BUSD LP and mints/burns TRUMPET
contract PegSupportTreasuryStrategy is ElephantCore {
    using SafeMath for uint256;
   
    uint256 public liquidityThreshold = 100e18;
    
    uint256 public constant apr_precision = 1e7;
    uint256 public daily_apr = 5500; //20% for the year 
    uint256 public lastSweep;

    event UpdateDailyAPR(uint oldApr, uint newApr);
    event Sweep(uint amount);
    

    //After construction the reserve needs to be added to the whitelist of the treasuries and the backedToken
    constructor ()  ElephantCore() {

        
        lastSweep = block.timestamp;
        
    }

     /// @dev Update the daily APR of the strategy
    function updateDailyAPR(uint apr) onlyOwner external {
        require(apr >= 275 && apr <= 16000, "Daily APR out of range 275 - 16000; equivalent 1 - 58% annual APR");
        
        emit UpdateDailyAPR(daily_apr, apr);

        daily_apr = apr;
    }

    //Estimate how much the Core Treasury should payout to Backed LP
    function available() public view returns (uint coreAmount, uint collateralAmount) {
        //Calculate daily drip 

        uint256 coreTreasuryBalance = coreToken.balanceOf(address(coreTreasury));

        //What is the share per second?
        uint256 _share = coreTreasuryBalance.mul(daily_apr).div(apr_precision).div(24 hours); //divide the profit by seconds in the day

        uint256 _seconds = block.timestamp.sub(lastSweep).min(24 hours);  //we will only process the maximum of a days worth of divs
        coreAmount = _share * _seconds;  //share times the amount of time elapsed

        (, collateralAmount) = estimateCoreToCollateral(coreAmount); //get the cash amount

    }

    //Mint backed tokens using collateral tokens
    function sweep() isRunning nonReentrant public returns (uint coreAmount, uint collateralAmount) {
        
        //How many tokens are available
        (coreAmount, collateralAmount) = available();

        //If we need to raise the price buy backed and mint/burn TRUMPET; regardless if we are peg or not
        if (collateralAmount > liquidityThreshold){
 
            //Get the core tokens
            coreTreasury.withdraw(coreAmount);

            
            uint backedAmount = buyBackedWithCore(coreAmount);

            //approve trumpet to transfer tokens
            backedToken.approve(address(trumpet), backedAmount);

            //mint & burn
            uint trumpetAmount = trumpet.mintWithBacking(backedAmount, address(this));
            trumpet.burn(trumpetAmount);

            lastSweep = block.timestamp;

            emit Sweep(collateralAmount);
        }
        
    }

}

//Fixed and immutable budget for custody to execute on base operations
contract PerformanceFund is ElephantCore {
    using SafeMath for uint256;

    uint public constant budget = 15000e18; //$15K per month 

    uint public lastSweep;
   
    event Sweep(uint amount);
    

    //After construction the needs to be added to ELEPHANT Treasury whitelist
    constructor ()  ElephantCore() {

        lastSweep = block.timestamp.sub(30 days);  //funds should be immediately available on launch
        
    }


    //Return lapsed time
    function lapsed() public view returns (uint) {
        return block.timestamp.sub(lastSweep);
    }

    //Return lapsed days
    function lapsedDays() public view returns (uint) {
        return block.timestamp.sub(lastSweep).div(1 days);
    }

    //Mint backed tokens using collateral tokens
    function sweep() isRunning onlyOwner external returns (uint coreAmount, uint collateralAmount) {

        //Only process if 28 days have passed since the last tim the function was processed
        uint elapsed = lapsed();

        if (elapsed > 28 days){


            //Calculate stipend as a function of core
            (,coreAmount) = estimateCollateralToCore(budget);
 
            //Get the core tokens
            coreTreasury.withdraw(coreAmount);

            collateralAmount = buyCollateralWithCore(coreAmount);

            collateralToken.transfer(owner(), collateralAmount);
            
            lastSweep = block.timestamp;

            emit Sweep(collateralAmount);
        }
        
    }

}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /* @dev Subtracts two numbers, else returns zero */
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b > a) {
            return 0;
        } else {
            return a - b;
        }
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

}

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value,
        string memory notes
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), string.concat('STF', notes));
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value,
        string memory notes
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), string.concat('ST', notes));
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value,
        string memory notes
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), string.concat('SA', notes));
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value, string memory notes) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, string.concat('STE', notes));
    }
}