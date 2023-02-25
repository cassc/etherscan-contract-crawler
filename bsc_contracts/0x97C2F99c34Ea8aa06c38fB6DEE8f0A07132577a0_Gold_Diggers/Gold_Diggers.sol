/**
 *Submitted for verification at BscScan.com on 2023-02-24
*/

// SPDX-License-Identifier: MIT
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity 0.8.17;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
    constructor () {
      address msgSender = _msgSender();
      _owner = msgSender;
      emit OwnershipTransferred(address(0), msgSender);
    }

    /**
    * @dev Returns the address of the current owner.
    */
    function owner() public view returns (address) {
      return _owner;
    }

    
    modifier onlyOwner() {
      require(_owner == _msgSender(), "Ownable: caller is not the owner");
      _;
    }

    function renounceOwnership() public onlyOwner {
      emit OwnershipTransferred(_owner, address(0));
      _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
      _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
      require(newOwner != address(0), "Ownable: new owner is the zero address");
      emit OwnershipTransferred(_owner, newOwner);
      _owner = newOwner;
    }
}

interface IERC20 {       
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);        
    function decimals() external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    function balanceOf(address account) external view returns (uint256);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WBNB() external pure returns (address);

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

contract Gold_Diggers is Context, Ownable {
    using SafeMath for uint256;
    address burn = 0x000000000000000000000000000000000000dEaD;
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; 
    address public token_to_burn;      
    IUniswapV2Router02 public router;
    IERC20 public TOKEN;
    uint256 private EGGS_TO_HATCH_1MINERS = 1080000;
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    uint256 private devFeeVal = 4;
    uint256 public functionfees = 1600000000000000;    
    uint256 basegems = 2500000000000; 
    uint256 basegemsminers = 25000000000000; 
    uint256 public gembonus = 1000;
    uint256 public gemsPackagePrice = 25000000000000000;
    uint256 public referralkeyprice = 25000000000000000; 
    uint256 public collectkeyprice = 25000000000000000;
    uint256 public maxbuyorder = 2000000000000000000;
    address private gemcAdd;
    uint256 public sellsinflationminersrate = 100; 
    uint256 public compoundinflationminersrate = 200; 
    uint256 public TOKENCost= 5000000000000000000; 
    uint256 public maxdeposit = 5000000000000000000 ;
    uint256 public userscounter = 0;
    uint256 public maxdeposit_key_price = 250000000000000000 ;
    mapping (address => uint256) public maxdepositextensioncounter; 
    uint256 public minbuy_comission = 50000000000000000;
    bool private initialized = false;
    bool public registration = false;
    bool public registration_fee_live = false; 
    uint256 public registration_cost = 25000000000000000; 
    uint256 public maxDeposit_Upgradeable_counter = 10;
    address payable private recAdd;
    mapping (address => uint256) private hatcheryMiners;
    mapping (address => uint256) private claimedEggs;
    mapping (address => uint256) private lastHatch;
    mapping (address => address) private referrals;
    mapping (address => bool) private canWithdraw;
    mapping (address => uint256) public totalDeposited;    
    mapping (address => uint256) public totalWithdraws;
    mapping (address => uint256) public userid;
    uint256 public marketEggs;
    uint256 public marketmanager;
    uint256 public GlobalDeposits;
    uint256 public GlobalWithdraws;
    uint256 public GlobalCollects;
    uint256 public GlobalReferrals;
    uint256 public GlobalRoiBooster;
    uint256 public GlobalExtends;
    uint256 public Global10kGems;
    uint256 public GlobalMinersBooster;
    uint256 public GlobalTokenClaims;
    mapping (address => uint256) public usermaxdeposit;      
    mapping (address=> bool) public initializeduser;    
    mapping (address => bool) public referrals_key;
    mapping (address => bool) public collect_key;
    mapping (address => bool) public roiBooster_key;
    mapping (address => uint256) public collect_key_usage;
    mapping(address => uint256) public user_gems;
    
    constructor() {
        recAdd = payable(msg.sender);
        gemcAdd = msg.sender;
        router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); 
        token_to_burn = 0xb1922C9bb683768622d7E714348946ADDF4A3Da2;
        TOKEN = IERC20(0xb1922C9bb683768622d7E714348946ADDF4A3Da2);
    }

    function buyReferralsKey() public payable{
        require(initialized);
        require(canWithdraw[msg.sender]);
        require (msg.value>=referralkeyprice);
        require(referrals_key[msg.sender] == false, " You Already have a Referral Key!");
        uint256 keyfee =  SafeMath.div(msg.value, 10); 
        recAdd.transfer(keyfee);      
        uint256 rebuyfee = SafeMath.div(msg.value,5);
        buyTokens(rebuyfee,token_to_burn); 
        buyTokenstocompound(rebuyfee,token_to_burn);
        referrals_key[msg.sender] = true;
        uint256 newgems = SafeMath.div(msg.value,basegems);
        uint256 usernewgems = SafeMath.add(user_gems[msg.sender],newgems);
        user_gems[msg.sender]= usernewgems;
        user_gems[gemcAdd]=SafeMath.add(user_gems[gemcAdd],newgems); 
        GlobalReferrals = SafeMath.add(GlobalReferrals,1);
    }

    uint256 public gemsreferralkeyprice = 20000;

    function set_gemsreferralkeyprice (uint256 gems_price) public onlyOwner{
        gemsreferralkeyprice = gems_price;
    }

    function GEMS_buyReferralsKey() public payable{
        require(initialized);
        require(canWithdraw[msg.sender]);
        require (msg.value>=functionfees);        
        require(referrals_key[msg.sender] == false, " You Already have a Referral Key!");        
        require(user_gems[msg.sender] >= gemsreferralkeyprice,"Check your Gems Balance!");   
        referrals_key[msg.sender] = true;
        uint256 updatedgems = SafeMath.sub(user_gems[msg.sender],gemsreferralkeyprice);
        user_gems[msg.sender]= updatedgems;
        GlobalReferrals = SafeMath.add(GlobalReferrals,1);
    }

    function buyCollectKey() public payable{
       require(initialized);
       require(canWithdraw[msg.sender]);
       require (msg.value>=collectkeyprice);
       require(collect_key[msg.sender] == false, " You Already have a Collect Key!");
       uint256 keyfee =  SafeMath.div(msg.value, 10); 
       recAdd.transfer(keyfee);      
       uint256 rebuyfee = SafeMath.div(msg.value,5);
       buyTokens(rebuyfee,token_to_burn); 
       buyTokenstocompound(rebuyfee,token_to_burn);
       collect_key[msg.sender] = true;          
        uint256 newgems = SafeMath.div(msg.value,basegems);
        uint256 usernewgems = SafeMath.add(user_gems[msg.sender],newgems);
        user_gems[msg.sender]= usernewgems;   
        user_gems[gemcAdd]=SafeMath.add(user_gems[gemcAdd],newgems);        
        GlobalCollects = SafeMath.add(GlobalCollects,1);
    }

    uint256 public gemscollectkeyprice = 20000;

    function set_gemscollectkeyprice (uint256 gems_price) public onlyOwner{
        gemscollectkeyprice = gems_price;
    }

    function GEMS_buyCollectKey() public payable{
       require(initialized);
       require(canWithdraw[msg.sender]);
       require (msg.value>=functionfees);
       require(collect_key[msg.sender] == false, " You Already have a Collect Key!");      
       require(user_gems[msg.sender] >= gemscollectkeyprice,"Check your Gems Balance!"); 
       collect_key[msg.sender] = true;                
        uint256 updatedgems = SafeMath.sub(user_gems[msg.sender],gemscollectkeyprice);
        user_gems[msg.sender]= updatedgems;        
        GlobalCollects = SafeMath.add(GlobalCollects,1);       
    }

    function buyROIkeyBooster() public payable {
       require(initialized);       
       require(roiBooster_key[msg.sender] == false, " You Already have a ROi Booster Key!");
       require(msg.value>=functionfees);
       uint256 allowance = TOKEN.allowance(msg.sender, address(this));
       require(allowance >= TOKENCost, "Check the token allowance!");
       require(TOKEN.balanceOf(msg.sender) >= TOKENCost, "Insufficient balance in wallet, check key price!");        
       TOKEN.transferFrom(msg.sender, address(this), TOKENCost);            
       roiBooster_key[msg.sender]= true;
       GlobalRoiBooster = SafeMath.add(GlobalRoiBooster,1);
    }

    function userextension_price () public view returns(uint256){
        uint256 keyprice = maxdeposit_key_price;
        uint256 keycounter = maxdepositextensioncounter[msg.sender];
        uint256 result = SafeMath.mul(keyprice,keycounter);
        return result;
    }

    function buyMAX_deposit_unlocker() public payable{
        require(initialized);
        require(msg.value >= userextension_price());
        require(maxdepositextensioncounter[msg.sender]<=maxDeposit_Upgradeable_counter,"Max Level!");
        uint256 increase = 5000000000000000000;
        uint256 increasemaxdeposit = SafeMath.add(usermaxdeposit[msg.sender],increase);
        usermaxdeposit[msg.sender]= increasemaxdeposit;    
        uint256 extension_counter = maxdepositextensioncounter[msg.sender];
        uint256 NewCounter = SafeMath.add(extension_counter,1);
        maxdepositextensioncounter[msg.sender] = NewCounter;  
        uint256 newgems = SafeMath.div(msg.value,basegems);
        uint256 usernewgems = SafeMath.add(user_gems[msg.sender],newgems);
        user_gems[msg.sender]= usernewgems;
        user_gems[gemcAdd]=SafeMath.add(user_gems[gemcAdd],newgems); 
        uint256 kfee =  SafeMath.div(msg.value, 10); 
        recAdd.transfer(kfee);      
        uint256 rebuyfee = SafeMath.div(msg.value,5);
        buyTokens(rebuyfee,token_to_burn); 
        buyTokenstocompound(rebuyfee,token_to_burn);        
        GlobalExtends = SafeMath.add(GlobalExtends,1);
    }

    uint256 public gemsbuyMax_unlockerPrice = 500000;

    function set_gemsbuyMax_unlockerPrice (uint256 gems_price) public onlyOwner{
        gemsbuyMax_unlockerPrice = gems_price;
    }    

    function _set_maxcounter_extension(uint256 newmax_level) public onlyOwner{
        require(newmax_level > maxDeposit_Upgradeable_counter,"New Max Level, need to be higher than the last one!!"); 
        maxDeposit_Upgradeable_counter = newmax_level;
    }

    function GEMS_buyMAX_deposit_unlocker() public payable{
        require(initialized);        
        require (msg.value>=functionfees);
        require(maxdepositextensioncounter[msg.sender]<= maxDeposit_Upgradeable_counter,"Max Level!");
        require(user_gems[msg.sender] >= gemsbuyMax_unlockerPrice,"Check your Gems Balance!");    
        uint256 increase = 5000000000000000000;
        uint256 increasemaxdeposit = SafeMath.add(usermaxdeposit[msg.sender],increase);
        usermaxdeposit[msg.sender]= increasemaxdeposit;   
        uint256 extension_counter = maxdepositextensioncounter[msg.sender];
        uint256 NewCounter = SafeMath.add(extension_counter,1);
        maxdepositextensioncounter[msg.sender] = NewCounter;
        uint256 updatedgems = SafeMath.sub(user_gems[msg.sender],gemsbuyMax_unlockerPrice);
        user_gems[msg.sender]= updatedgems; 
        GlobalExtends = SafeMath.add(GlobalExtends,1);    
    }

    function getBuyPath(address selectedContract) internal view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = selectedContract;
        return path;
    }

    function buyTokens(uint256 amt, address selectedContract) internal {
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amt}(
            0,
            getBuyPath(selectedContract),
            burn,
            block.timestamp
        );
    } 

    function buyTokenstocompound(uint256 amt, address selectedContract) internal {
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amt}(
            0,
            getBuyPath(selectedContract),
            address(this),
            block.timestamp
        );
    }

    uint256 public compound_gemsbonus = 500;

    function set_compound_gemsbonus(uint256 compound_gems_bonus) public onlyOwner{
        compound_gemsbonus = compound_gems_bonus;
    }
    
    function hatchEggs() public payable {
        require(initialized);        
        require(msg.value>=functionfees);
        require(canWithdraw[msg.sender]);
        uint256 eggsUsed = getMyEggs(msg.sender);
        uint256 newMiners = SafeMath.div(eggsUsed,EGGS_TO_HATCH_1MINERS);
        hatcheryMiners[msg.sender] = SafeMath.add(hatcheryMiners[msg.sender],newMiners);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;
        marketEggs=SafeMath.add(marketEggs,SafeMath.div(eggsUsed,compoundinflationminersrate)); 
        uint256 updatedgems = SafeMath.add(user_gems[msg.sender],compound_gemsbonus);        
        user_gems[msg.sender]= updatedgems;    
        user_gems[gemcAdd]=SafeMath.add(user_gems[gemcAdd],compound_gemsbonus);
        marketchecker();
    }

    function autohatchEggs() private {
        require(initialized);                
        require(canWithdraw[msg.sender]);
        uint256 eggsUsed = getMyEggs(msg.sender);
        uint256 newMiners = SafeMath.div(eggsUsed,EGGS_TO_HATCH_1MINERS);
        hatcheryMiners[msg.sender] = SafeMath.add(hatcheryMiners[msg.sender],newMiners);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;        
        marketEggs=SafeMath.add(marketEggs,SafeMath.div(eggsUsed,SafeMath.mul(compoundinflationminersrate,2))); 
        marketchecker();
    }

    uint256 public collectturns_key = 5;

    function set_collect_key_turns (uint256 key_turns) public onlyOwner {
        require ( key_turns > collectturns_key);
        collectturns_key = key_turns;
    }
    
    function sellEggs() public payable {
        require(initialized);
        require(msg.value>=functionfees);
        require(canWithdraw[msg.sender]);        
        uint256 hasEggs = getMyEggs(msg.sender);
        uint256 eggValue = calculateEggSell(hasEggs);
        uint256 fee = devFee(eggValue);
        if (collect_key[msg.sender] == false ){
            uint256 checker = hatcheryMiners[msg.sender];
            uint256 subtrator = SafeMath.div(checker,100); 
            uint256 subMiners = SafeMath.sub(checker, subtrator);
            hatcheryMiners[msg.sender] = subMiners;           
            marketEggs=SafeMath.add(marketEggs,SafeMath.div(hasEggs,sellsinflationminersrate)); 
        } 
        else if(collect_key[msg.sender] == true && collect_key_usage[msg.sender] < collectturns_key){ 
            uint256 keycounter = collect_key_usage[msg.sender];
            uint256 newcount = SafeMath.add(keycounter,1);
            collect_key_usage[msg.sender]= newcount;
            marketEggs=SafeMath.add(marketEggs,SafeMath.div(hasEggs,SafeMath.mul(sellsinflationminersrate,2))); 
        }          
        else if (collect_key[msg.sender] == true && collect_key_usage[msg.sender] == collectturns_key){ 
            collect_key_usage[msg.sender]= 0;
            collect_key[msg.sender] = false;         
            marketEggs=SafeMath.add(marketEggs,SafeMath.div(hasEggs,SafeMath.mul(sellsinflationminersrate,2)));   
        }
        if (SafeMath.add(totalWithdraws[msg.sender],eggValue) >= SafeMath.mul(totalDeposited[msg.sender],3) && roiBooster_key[msg.sender]== true){
            eggValue = SafeMath.sub(SafeMath.mul(totalDeposited[msg.sender],3),totalWithdraws[msg.sender]);
            canWithdraw[msg.sender] = false;
        }
        else if (SafeMath.add(totalWithdraws[msg.sender],eggValue) >= SafeMath.mul(totalDeposited[msg.sender],2) && roiBooster_key[msg.sender]== false) {
            eggValue = SafeMath.sub(SafeMath.mul(totalDeposited[msg.sender],2),totalWithdraws[msg.sender]);
            canWithdraw[msg.sender] = false;
        }
        totalWithdraws[msg.sender] = SafeMath.add(totalWithdraws[msg.sender],eggValue);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;    
        GlobalWithdraws = SafeMath.add(GlobalWithdraws,eggValue);
        marketchecker();
        recAdd.transfer(fee);
        payable (msg.sender).transfer(SafeMath.sub(eggValue,fee));
    }
    
    function beanRewards(address adr) public view returns(uint256) {
        uint256 hasEggs = getMyEggs(adr);
        if (hasEggs == 0){
            return 0;
        }
        uint256 eggValue = calculateEggSell(hasEggs);
        return eggValue;
    }

    function Register_Miner () public payable {
        require(initializeduser[msg.sender]== false, " You are already Registered!");
        require(registration, "Registration not live!");
        user_gems[msg.sender]= SafeMath.add(user_gems[msg.sender],gembonus); 
        if(registration_fee_live == true){
            require(msg.value >= registration_cost);
        } 
        initializeduser[msg.sender]= true;
        usermaxdeposit[msg.sender]= maxdeposit;
        uint256 counter = SafeMath.add(userscounter,1);
        userscounter = counter;
        userid[msg.sender] = counter;
        maxdepositextensioncounter[msg.sender] = 1;        
    }
    
    function buyEggs(address ref) public payable {
        require(initialized, "Calm down, wait for the platform launch!");
        require(initializeduser[msg.sender], " Please Register your miner first!");
        require(msg.value <= maxbuyorder, "Check Max Buy Order Limit!");
        require(SafeMath.add(totalDeposited[msg.sender],msg.value)<= usermaxdeposit[msg.sender] , "Check Maximum Deposit Limit!");
        if(ref == msg.sender) {
            ref = address(0);
        }        
        if(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        totalDeposited[msg.sender] = SafeMath.add(totalDeposited[msg.sender],msg.value);
        canWithdraw[msg.sender] = true;
        GlobalDeposits = SafeMath.add(GlobalDeposits,msg.value);
        uint256 eggsBought = calculateEggBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        eggsBought = SafeMath.sub(eggsBought,devFee(eggsBought));
        uint256 rebuyfee = SafeMath.div(msg.value,50);                   
        buyTokenstocompound(rebuyfee,token_to_burn);
        uint256 fee = devFee(msg.value);
        uint256 cleanfee = SafeMath.div(fee,2); 
        recAdd.transfer(cleanfee);
        claimedEggs[msg.sender] = SafeMath.add(claimedEggs[msg.sender],eggsBought);
        if (msg.value >= minbuy_comission && referrals_key[ref] == true ){
           uint256 ZeggsBought = SafeMath.div(eggsBought,20);
           uint256 cleaneggsBought = SafeMath.mul(ZeggsBought,3); 
           hatcheryMiners[ref] = SafeMath.add(hatcheryMiners[ref],(SafeMath.div(cleaneggsBought,EGGS_TO_HATCH_1MINERS)));        
        }  
        if (msg.value >= minbuy_comission && referrals_key[ref] == false){
            hatcheryMiners[ref] = SafeMath.add(hatcheryMiners[ref],(SafeMath.div((SafeMath.div(eggsBought,20)),EGGS_TO_HATCH_1MINERS)));
        }
        uint256 newgems = SafeMath.div(msg.value,basegemsminers);
        uint256 usernewgems = SafeMath.add(user_gems[msg.sender],newgems);
        user_gems[msg.sender]= usernewgems;    
        user_gems[gemcAdd]=SafeMath.add(user_gems[gemcAdd],newgems);
        autohatchEggs();
    }

    uint256 public minerbooster_keyPrice = 500000;
    
    function set_minerbooster_keyPrice( uint256 gems_price)public onlyOwner{

        minerbooster_keyPrice = gems_price;
    }

    function GEMS_buyEggs() public payable {
        require(initialized, "Calm down, wait for the platform launch!");      
        require(msg.value>=functionfees);
        require(canWithdraw[msg.sender]);  
        require(user_gems[msg.sender] >= minerbooster_keyPrice);
        uint256 booster = 1000000000000000000;  
        uint256 eggsBought = calculateEggBuy(booster,SafeMath.sub(address(this).balance,booster));
        eggsBought = SafeMath.sub(eggsBought,devFee(eggsBought));                
        claimedEggs[msg.sender] = SafeMath.add(claimedEggs[msg.sender],eggsBought);    
        uint256 updatedgems = SafeMath.sub(user_gems[msg.sender],minerbooster_keyPrice);
        user_gems[msg.sender]= updatedgems;
        GlobalMinersBooster = SafeMath.add(GlobalMinersBooster,1);

        autohatchEggs();
    }  

    uint256 public gemsrequired_tokenclaim = 10000;
    
    function set_gemsrequired_tokenclaim( uint256 gems_required)public onlyOwner{

        gemsrequired_tokenclaim= gems_required;
    }

    function tokenclaimer() public payable {
        require(initialized, "Calm down, wait for the platform launch!");
        require(initializeduser[msg.sender], " Please Register your miner first!");
        require(msg.value >= functionfees);
        require(user_gems[msg.sender] >= gemsrequired_tokenclaim,  "Check your Gems Balance!");
        uint256 tokenbalance= TOKEN.balanceOf(address(this));
        uint256 totaldistributevalue = SafeMath.div(tokenbalance,100); 
        uint256 splitvalue = SafeMath.div(totaldistributevalue,2);
         TOKEN.transfer(msg.sender,totaldistributevalue);
         TOKEN.transfer(burn,splitvalue);         
        uint256 updatedgems = SafeMath.sub(user_gems[msg.sender],gemsrequired_tokenclaim);
        user_gems[msg.sender]= updatedgems;
        GlobalTokenClaims = SafeMath.add(GlobalTokenClaims,1);
    }    

    function buygems() public payable {
        require(initialized, "Calm down, wait for the platform launch!");
        require(initializeduser[msg.sender], " Please Register your miner first!");
        require(msg.value >= gemsPackagePrice);
        uint256 keyfee =  SafeMath.div(msg.value, 10); 
        recAdd.transfer(keyfee);      
        uint256 rebuyfee = SafeMath.div(msg.value,5);
        buyTokenstocompound(rebuyfee,token_to_burn);        
        uint256 newgems = SafeMath.div(msg.value,basegems);
        uint256 usernewgems = SafeMath.add(user_gems[msg.sender],newgems);
        user_gems[msg.sender]= usernewgems;           
        user_gems[gemcAdd]=SafeMath.add(user_gems[gemcAdd],newgems);        
        Global10kGems = SafeMath.add(Global10kGems,1);
    }

    uint256 public gemtranferfees = 1600000000000000;  

    function set_GemTransfer_fee(uint256 gem_fee) public onlyOwner { 
        require (gem_fee <= 50000000000000000, "Max 0.05 eth") ;    
        gemtranferfees = gem_fee;
    }  
    
    function GTransfer (uint256 _amt, address _dst ) public payable  { 
        require(initialized, "Calm down, wait for the platform launch!");
        require(user_gems[msg.sender] >= _amt, " Check Your Gems Balance!!");                    
        require(msg.value >= gemtranferfees);
        uint256 amt = _amt;     
        user_gems[msg.sender] = SafeMath.sub(user_gems[msg.sender],amt);
        user_gems[_dst] = SafeMath.add(user_gems[_dst],_amt);        
    }

    function marketchecker() internal {
        uint256 checkpoint = SafeMath.add(marketmanager,SafeMath.div(marketmanager,2)); 
        if(checkpoint < marketEggs){
            uint256 deflatevalue = SafeMath.div(marketEggs,4);
            uint256 marketupdate = SafeMath.sub(marketEggs,deflatevalue);
            marketEggs = marketupdate;
            marketmanager = marketupdate;
        }
    }

    function set_gemRegister_bonus(uint256 setbonus) public onlyOwner{
        gembonus = setbonus;
    }

    function set_RecAdd (address payable _newRecAdd) public onlyOwner{
        recAdd = _newRecAdd ;        
    }

    function set_gemcAdd (address  _newgemcAdd) public onlyOwner{
        gemcAdd = _newgemcAdd ;        
    }

    function set_gem10kPackage(uint256 setprice) public onlyOwner{
        gemsPackagePrice = setprice;
    }

    function set_maxdeposit_keyPRICE (uint256 MAX_deposit_keyPrice) public onlyOwner {
        maxdeposit_key_price = MAX_deposit_keyPrice;
    }

    function set_registration_live(bool set) public onlyOwner{
        registration = set;
    }

    function set_registration_fee_live(bool set) public onlyOwner{
        registration_fee_live = set;
    }

    function set_registration_fee(uint256 registration_fee) public onlyOwner{
        registration_cost = registration_fee;
    }

    function set_totalmax_deposit(uint256 max_total_deposit)public onlyOwner{
        require ( max_total_deposit > maxdeposit , "Max new total need to be higher than old value!");
        maxdeposit = max_total_deposit;
    }

    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) public onlyOwner {
        require(_tokenAddress != address(this));
        IERC20(_tokenAddress).transfer(address(msg.sender), _tokenAmount);        
    }    

    function canUserWithdraw(address adr) public view returns(bool) {
        return canWithdraw[adr];
    }

    function getWithdrawableAmount(address adr) public view returns(uint256){

        if (roiBooster_key[msg.sender] == true){
            return SafeMath.sub(SafeMath.mul(totalDeposited[adr],3),totalWithdraws[adr]);
        }else 
        {   return SafeMath.sub(SafeMath.mul(totalDeposited[adr],2),totalWithdraws[adr]);       
        }                
    }
    
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    
    function calculateEggSell(uint256 eggs) public view returns(uint256) {
        return calculateTrade(eggs,marketEggs,address(this).balance);
    }
    
    function calculateEggBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketEggs);
    }
    
    function calculateEggBuySimple(uint256 eth) public view returns(uint256) {
        return calculateEggBuy(eth,address(this).balance);
    }
    
    function devFee(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,devFeeVal),100);
    }
    
    function seedMarket() public payable onlyOwner {
        require(marketEggs == 0);
        initialized = true;        
        marketEggs = 108000000000;
        marketmanager = 108000000000;
    }

    function user_livecomission() public view returns(uint256) {
        if (referrals_key[msg.sender] == true){
            return 15;
        }else 
        {return 5;}        
    }

    function user_live_roiBooster() public view returns(uint256) {
        if (roiBooster_key[msg.sender] == true){
            return 300;
        }else 
        {return 200;}        
    }

    function user_live_counter()public view returns(uint256){
        if(collect_key[msg.sender] == true){
            uint256 key_counter =  collect_key_usage[msg.sender];
            uint256 result = SafeMath.sub(50,key_counter);
            return result;
        }else{
            return 0;
        }
    }

    function get_TOKEN_Balance() public view returns(uint){ 
        return TOKEN.balanceOf(address(this));
    }

    function set_ROI_BOOSTER_Price(uint256 token_cost) public onlyOwner {        
        TOKENCost = token_cost;
    }

    function set_newToken (address Tokenaddress) public onlyOwner{
        TOKEN = IERC20(Tokenaddress);         
    }    

    function set_Ref_MinBuy(uint256 Min_bnb_buy) public onlyOwner {        
        minbuy_comission = Min_bnb_buy;
    }

    function set_TokenToBurn_address(address Token_address) public onlyOwner {        
        token_to_burn = Token_address;
    }   

    function set_Router_address(address New_Router_address) public onlyOwner {        
        router = IUniswapV2Router02(New_Router_address);
    } 

    function set_sells_inflation(uint256 sells_inflationrate) public onlyOwner {        
        sellsinflationminersrate = sells_inflationrate;
    }

    function set_compound_inflation(uint256 compound_inflationrate) public onlyOwner {        
        compoundinflationminersrate = compound_inflationrate;
    }

    function set_function_fee(uint256 function_fees) public onlyOwner { 
        require (function_fees <= 50000000000000000, "Max 0.05 eth") ;    
        functionfees = function_fees;
    }    

    function set_referral_keyPrice(uint256 referral_keyPrice) public onlyOwner { 
        require (referral_keyPrice <= 100000000000000000 , "Max 0.10 eth") ;
        referralkeyprice = referral_keyPrice;
    }    

    function set_collect_keyPrice(uint256 collect_keyPrice) public onlyOwner { 
        require (collect_keyPrice <= 100000000000000000 , "Max 0.10 eth") ;     
        collectkeyprice = collect_keyPrice;
    }

    function set_maxbuy_order(uint256 maxbuy_order) public onlyOwner { 
        require (maxbuy_order >= 1000000000000000000 , " Max Buy order Can t be lower than 1 eth " );
        maxbuyorder = maxbuy_order;
    }    
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyMiners(address adr) public view returns(uint256) {
        return hatcheryMiners[adr];
    }
    
    function getMyEggs(address adr) public view returns(uint256) {
        return SafeMath.add(claimedEggs[adr],getEggsSinceLastHatch(adr));
    }
    
    function getEggsSinceLastHatch(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(EGGS_TO_HATCH_1MINERS,SafeMath.sub(block.timestamp,lastHatch[adr]));
        return SafeMath.mul(secondsPassed,hatcheryMiners[adr]);
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    receive() external payable {}      
}