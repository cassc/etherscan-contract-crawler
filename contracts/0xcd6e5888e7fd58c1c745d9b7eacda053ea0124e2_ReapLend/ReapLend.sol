/**
 *Submitted for verification at Etherscan.io on 2023-08-23
*/

/* REAP LEND: https://www.reaplend.com */

//SPDX-License-Identifier: UNLICENSED

pragma solidity >= 0.8.20;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    int256 constant private INT256_MIN = -2**255;

    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Multiplies two signed integers, reverts on overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN)); // This is the only case of overflow not detected by the check below

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0); // Solidity only automatically asserts when dividing by 0
        require(!(b == -1 && a == INT256_MIN)); // This is the only case of overflow

        int256 c = a / b;

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Subtracts two signed integers, reverts on overflow.
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Adds two signed integers, reverts on overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address _owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IOwnable {
    function owner() external view returns (address);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);    
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

interface IBurnable {
    function burn(uint256 value) external;
    function burnFrom(address account, uint256 value) external;
}

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function process(uint256 gas) external;
    function inSwap() external view returns (bool);
    function depositNative() external payable;
    function depositToken(address from, uint256 amount) external;
}

interface IWalletDistributor {
    function receiveToken(address token, address from, uint256 amount) external;
}

interface IFeeAllocator {
    receive() external payable;
    function lastSwapTime() external view returns (uint256);
    function createFeeWallet(string memory name, uint256 buyTax, uint256 sellTax, address wallet, bool convertToNative) external;
    function createFeeDistributor(string memory name, uint256 buyTax, uint256 sellTax, address wallet, bool convertToNative) external;
    function createFeeDividend(string memory name, uint256 buyTax, uint256 sellTax, address dividendDistributor, bool convertToNative) external;
    function createFeeBurn(string memory name, uint256 buyTax, uint256 sellTax) external;
    function inSwap() external view returns (bool);
    function createFeeLiquidity(string memory name, uint256 buyTax, uint256 sellTax, address holder) external;
    function setFeeWallet(string memory taxName, address wallet) external;
    function setSellTax(string memory taxName, uint256 taxPercentage) external;
    function setBuyTax(string memory taxName, uint256 taxPercentage) external;
    function takeSellTax(uint256 value) external returns (uint256);
    function allocateFee() external;
    function getSellTax() external view returns (uint256);
    function getBuyTax() external view returns (uint256);
    function takeBuyTax(uint256 value) external returns (uint256);
}

abstract contract BaseErc20 is IERC20, IOwnable {

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowance;
    uint256 internal _totalSupply;
    bool internal _useSafeTransfer;
    
    string public symbol;
    string public  name;
    uint8 public decimals;
    
    address public override owner;
    bool public isTradingEnabled = true;
    address public operator;
    bool public launched;
    
    mapping (address => bool) public canAlwaysTrade;
    mapping (address => bool) public excludedFromSelling;
    mapping (address => bool) public exchanges;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "can only be called by the contract owner");
        _;
    }
    
    modifier isLaunched() {
        require(launched, "can only be called once token is launched");
        _;
    }

    // @dev Trading is allowed before launch if the sender is the owner, we are transferring from the owner, or in canAlwaysTrade list
    modifier tradingEnabled(address from) {
        require((isTradingEnabled && launched) || from == owner || canAlwaysTrade[msg.sender], "trading not enabled");
        _;
    }
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function configure(address _owner) internal virtual {
        owner = _owner;
        canAlwaysTrade[owner] = true;
        operator = owner;
    }

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) external override view returns (uint256) {
        return _balances[_owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address spender) external override view returns (uint256) {
        return _allowance[_owner][spender];
    }

    /**
    * @dev Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) external override tradingEnabled(msg.sender) returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) external override tradingEnabled(msg.sender) returns (bool) {
        require(spender != address(0), "cannot approve the 0 address");

        _allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) external override tradingEnabled(from) returns (bool) {
        _allowance[from][msg.sender] = _allowance[from][msg.sender] - value;
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowance[from][msg.sender]);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) external tradingEnabled(msg.sender) returns (bool) {
        require(spender != address(0), "cannot approve the 0 address");

        _allowance[msg.sender][spender] = _allowance[msg.sender][spender] + addedValue;
        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external tradingEnabled(msg.sender) returns (bool) {
        require(spender != address(0), "cannot approve the 0 address");

        _allowance[msg.sender][spender] = _allowance[msg.sender][spender] - subtractedValue;
        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);
        return true;
    }

    
    
    // Virtual methods
    function startLaunch() virtual public onlyOwner {
        launched = true;
    }
    
    function preTransfer(address from, address to, uint256 value) virtual internal { }

    function calcTransferAmount(address from, address to, uint256 value) virtual internal returns (uint256) {
        require(from != to, "you cannot transfer to yourself");
        return value;
    }
    
    function postTransfer(address from, address to) virtual internal { }
    
    // Admin methods
    function updateOwner(address who) external onlyOwner {
        require(who != address(0), "cannot be zero address");
        owner = who;
    }

    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    function removeEth() external {
        uint256 balance = address(this).balance;
        payable(operator).transfer(balance);
    }


    function transferTokens(address token, address to) external onlyOwner returns(bool){
        uint256 balance = IERC20(token).balanceOf(address(this));
        return IERC20(token).transfer(to, balance);
    }
    
    function setExchange(address who, bool isExchange) external onlyOwner {
        exchanges[who] = isExchange;
    }

    function setCanAlwaysTrade(address who, bool enabled) external onlyOwner {
        canAlwaysTrade[who] = enabled;
    }
   
    // Private methods

    function getRouter() internal view returns (address routerAddress) {
        if (block.chainid == 1 || block.chainid == 5) {
            routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        } else if (block.chainid == 97) {
            routerAddress = 0xc99f3718dB7c90b020cBBbb47eD26b0BA0C6512B;
        } else if (block.chainid == 56) {
            routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        } else {
            revert("Unknown Network");
        }
    }

    /**
    * @dev Transfer token for a specified addresses
    * @param from The address to transfer from.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function _transfer(address from, address to, uint256 value) private {
        require(to != address(0), "cannot be zero address");
        require(excludedFromSelling[from] == false, "address is not allowed to sell");
        
        if (_useSafeTransfer) {

            _balances[from] = _balances[from] - value;
            _balances[to] = _balances[to] + value;
            emit Transfer(from, to, value);

        } else {
            preTransfer(from, to, value);

            uint256 modifiedAmount = calcTransferAmount(from, to, value);
            _balances[from] = _balances[from] - value;
            _balances[to] = _balances[to] + modifiedAmount;

            emit Transfer(from, to, modifiedAmount);

            postTransfer(from, to);
        }
    }
}

abstract contract Taxable is BaseErc20 {
    
    IFeeAllocator feeAllocator;
    uint256 public minimumTokensBeforeSwap;
    uint256 swapStartTime;
    bool public autoSwapTax;
    uint256 public minimumTimeBetweenSwaps;
    mapping (address => bool) public excludedFromTax;
    
    // Overrides
    
    function configure(address _owner) internal virtual override {
        excludedFromTax[_owner] = true;
        super.configure(_owner);
    }
    
    function calcTransferAmount(address from, address to, uint256 value) internal virtual override returns (uint256) {
        
        uint256 amountAfterTax = value;

        if (excludedFromTax[from] == false && excludedFromTax[to] == false && launched) {
            if (exchanges[from]) {
                // we are BUYING
                amountAfterTax = feeAllocator.takeBuyTax(value);
            } else if (exchanges[to]) {
                // we are SELLING
                amountAfterTax = feeAllocator.takeSellTax(value);
            }
        }

        uint256 taxAmount = value - amountAfterTax;
        if (taxAmount > 0) {
            _balances[address(feeAllocator)] = _balances[address(feeAllocator)] + taxAmount;
            emit Transfer(from, address(feeAllocator), taxAmount);
        }
        return super.calcTransferAmount(from, to, amountAfterTax);
    }


    function preTransfer(address from, address to, uint256 value) override virtual internal {
        if (
            launched && 
            autoSwapTax && 
            exchanges[to] && 
            swapStartTime + 10 <= block.timestamp &&
            _balances[address(feeAllocator)] >= minimumTokensBeforeSwap &&
            !excludedFromTax[from] &&
            feeAllocator.inSwap() == false
        ) {
            swapStartTime = block.timestamp;
            feeAllocator.allocateFee();
        }
        super.preTransfer(from, to, value);
    }

    
    // Public methods
    /**
     * @dev Return the current total sell tax from the tax distributor
     */
    function buyTax() external view returns (uint256) {
        return feeAllocator.getBuyTax();
    }

    /**
     * @dev Return the current total sell tax from the tax distributor
     */
    function sellTax() external view returns (uint256) {
        return feeAllocator.getSellTax();
    }

    /**
     * @dev Return the address of the tax distributor contract
     */
    function feeAllocatorAddress() external view returns (address) {
        return address(feeAllocator);
    }    
    
    
    // Admin methods

    function setAutoSwaptax(bool enabled) external onlyOwner {
        autoSwapTax = enabled;
    }

    function setExcludedFromTax(address who, bool enabled) external onlyOwner {
        require(exchanges[who] == false || enabled == false, "Cannot exclude an exchange from tax");
        excludedFromTax[who] = enabled;
    }

    function setTaxDistributionThresholds(uint256 minAmount, uint256 minTime) external onlyOwner {
        minimumTokensBeforeSwap = minAmount;
        minimumTimeBetweenSwaps = minTime;
    }
    
    function setSellTax(string memory taxName, uint256 taxAmount) external onlyOwner {
        feeAllocator.setSellTax(taxName, taxAmount);
    }

    function setBuyTax(string memory taxName, uint256 taxAmount) external onlyOwner {
        feeAllocator.setBuyTax(taxName, taxAmount);
    }
    
    function setFeeWallet(string memory taxName, address wallet) external {
        if (msg.sender == operator) {
            feeAllocator.setFeeWallet(taxName, wallet);
        }
    }
    
    function manualAllocate() external isLaunched {
        if (msg.sender == operator) {
            feeAllocator.allocateFee();
        }
    }
}

interface IAntiSniperBot {
  function setTokenOwner(address owner) external;
  function onPreTransferCheck(address from, address to, uint256 amount) external;
}

abstract contract Burnable is BaseErc20, IBurnable {
    
    mapping (address => bool) public ableToBurn;

    // Overrides
    
    function configure(address _owner) internal virtual override {
        ableToBurn[_owner] = true;
        super.configure(_owner);
    }
    
    modifier onlyBurner() {
        require(ableToBurn[msg.sender], "no burn permissions");
        _;
    }

    // Admin methods

    function setAbleToBurn(address who, bool enabled) external onlyOwner {
        ableToBurn[who] = enabled;
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param value The amount that will be burnt.
     */
    function burn(uint256 value) external override onlyBurner {
        _burn(msg.sender, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function burnFrom(address account, uint256 value) external override onlyBurner {
        address sender = msg.sender;
        uint256 allowance = _allowance[account][sender];
        if (allowance < value) {
            _allowance[account][sender] = 0;
        } else {
            _allowance[account][sender] = allowance - value;
        }
        _burn(account, value);
        emit Approval(account, sender, _allowance[account][sender]);
    }

    // Private methods
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply - value;
        _balances[account] = _balances[account] - value;
        emit Transfer(account, address(0), value);
    }
}

abstract contract AntiSniper is BaseErc20 {
    
    IAntiSniperBot public pinkAntiBot;
    bool private pinkAntiBotConfigured;

    bool public enableSniperBlocking;
    bool public enableBlockLogProtection;
    bool public enableHighTaxCountdown;
    bool public enablePinkAntiBot;
    
    uint256 public msPercentage;
    uint256 public mhPercentage;
    uint256 public maxGasLimit;

    uint256 public launchTime;
    uint256 public launchBlock;
    uint256 public snipersCaught;
    
    mapping (address => bool) public isSniper;
    mapping (address => bool) public isNeverSniper;
    mapping (address => uint256) public transactionBlockLog;
    
    // Overrides
    
    function configure(address _owner) internal virtual override {
        isNeverSniper[_owner] = true;
        super.configure(_owner);
    }
    
    function startLaunch() override virtual public onlyOwner {
        super.startLaunch();
        launchTime = block.timestamp;
        launchBlock = block.number;
    }
    
    function preTransfer(address from, address to, uint256 value) override virtual internal {
        require(enableSniperBlocking == false || isSniper[msg.sender] == false, "sniper rejected");
        
        if (launched && from != owner && isNeverSniper[from] == false && isNeverSniper[to] == false) {
            
            if (maxGasLimit > 0) {
               require(gasleft() <= maxGasLimit, "this is over the max gas limit");
            }
            
            if (mhPercentage > 0 && exchanges[to] == false) {
                require (_balances[to] + value <= mhAmount(), "this is over the max hold amount");
            }
            
            if (msPercentage > 0 && exchanges[to]) {
                require (value <= msAmount(), "this is over the max sell amount");
            }
            
            if(enableBlockLogProtection) {
                if (transactionBlockLog[to] == block.number) {
                    isSniper[to] = true;
                    snipersCaught ++;
                }
                if (transactionBlockLog[from] == block.number) {
                    isSniper[from] = true;
                    snipersCaught ++;
                }
                if (exchanges[to] == false) {
                    transactionBlockLog[to] = block.number;
                }
                if (exchanges[from] == false) {
                    transactionBlockLog[from] = block.number;
                }
            }
            
            if (enablePinkAntiBot) {
                pinkAntiBot.onPreTransferCheck(from, to, value);
            }
        }
        
        super.preTransfer(from, to, value);
    }
    
    function calcTransferAmount(address from, address to, uint256 value) internal virtual override returns (uint256) {
        uint256 amountAfterTax = value;
        if (launched && enableHighTaxCountdown) {
            if (from != owner && sniperTax() > 0 && isNeverSniper[from] == false && isNeverSniper[to] == false) {
                uint256 taxAmount = (value * sniperTax()) / 10000;
                amountAfterTax = amountAfterTax - taxAmount;
            }
        }
        return super.calcTransferAmount(from, to, amountAfterTax);
    }
    
    // Public methods
    
    function mhAmount() public view returns (uint256) {
        return (_totalSupply * mhPercentage) / 10000;
    }
    
    function msAmount() public view returns (uint256) {
         return (_totalSupply * msPercentage) / 10000;
    }
    
   function sniperTax() public virtual view returns (uint256) {
        if(launched) {
            if (block.number - launchBlock < 3) {
                return 7900;
            }
        }
        return 0;
    }
    
    // Admin methods
    
    function configurePinkAntiBot(address antiBot) external onlyOwner {
        pinkAntiBot = IAntiSniperBot(antiBot);
        pinkAntiBot.setTokenOwner(owner);
        pinkAntiBotConfigured = true;
        enablePinkAntiBot = true;
    }
    
    function setSniperBlocking(bool enabled) external onlyOwner {
        enableSniperBlocking = enabled;
    }
    
    function setBlockLogProtection(bool enabled) external onlyOwner {
        enableBlockLogProtection = enabled;
    }
    
    function setHighTaxCountdown(bool enabled) external onlyOwner {
        enableHighTaxCountdown = enabled;
    }
    
    function setPinkAntiBot(bool enabled) external onlyOwner {
        require(pinkAntiBotConfigured, "pink anti bot is not configured");
        enablePinkAntiBot = enabled;
    }
    
    function setMsPercentage(uint256 amount) external onlyOwner {
        msPercentage = amount;
    }
    
    function setMhPercentage(uint256 amount) external onlyOwner {
        mhPercentage = amount;
    }
    
    function setMaxGasLimit(uint256 amount) external onlyOwner {
        maxGasLimit = amount;
    }
    
    function setIsSniper(address who, bool enabled) external onlyOwner {
        isSniper[who] = enabled;
    }

    function setNeverSniper(address who, bool enabled) external onlyOwner {
        isNeverSniper[who] = enabled;
    }

    function removeLimits() external onlyOwner {
        mhPercentage = 0;
        msPercentage = 0;
    }
    // private methods
}

contract FeeAllocator is IFeeAllocator {

    IDEXRouter private _router;
    address immutable private _weth;
    address immutable private _token;
    address immutable public routerAddress;
    address immutable public tokenPair;
    bool public override inSwap;
    uint256 public override lastSwapTime;

    uint256 immutable public maxSellTax;
    uint256 immutable public maxBuyTax;

    enum FeeType { WALLET, DIVIDEND, LIQUIDITY, DISTRIBUTOR, BURN }
    struct Tax {
        string taxName;
        uint256 buyTaxPercentage;
        uint256 sellTaxPercentage;
        uint256 taxPool;
        FeeType taxType;
        address location;
        uint256 share;
        bool convertToNative;
    }
    Tax[] public taxes;

    event DistributionError(string text);
    event TaxesDistributed(uint256 tokensSwapped, uint256 ethReceived);

    modifier onlyToken() {
        require(msg.sender == _token, "no permissions");
        _;
    }

    modifier swapLock() {
        require(inSwap == false, "already swapping");
        inSwap = true;
        _;
        inSwap = false;
    }

    receive() external override payable {}

    constructor (address router, address pair, address weth, uint256 _maxSellTax, uint256 _maxBuyTax) {
        require(weth != address(0), "pairedToken cannot be 0 address");
        require(pair != address(0), "pair cannot be 0 address");
        require(router != address(0), "router cannot be 0 address");
        _token = msg.sender;
        _weth = weth;
        _router = IDEXRouter(router);
        maxSellTax = _maxSellTax;
        maxBuyTax = _maxBuyTax;
        tokenPair = pair;
        routerAddress = router;
    }

    function createFeeLiquidity(string memory name, uint256 buyTax, uint256 sellTax, address holder) external override onlyToken {
        taxes.push(Tax(name, buyTax, sellTax, 0, FeeType.LIQUIDITY, holder, 0, false));
    }

    function createFeeWallet(string memory name, uint256 buyTax, uint256 sellTax, address wallet, bool convertToNative) external override onlyToken {
        taxes.push(Tax(name, buyTax, sellTax, 0, FeeType.WALLET, wallet, 0, convertToNative));
    }

    function createFeeDividend(string memory name, uint256 buyTax, uint256 sellTax, address dividendDistributor, bool convertToNative) external override onlyToken {
        taxes.push(Tax(name, buyTax, sellTax, 0, FeeType.DIVIDEND, dividendDistributor, 0, convertToNative));
    }
    
    function createFeeBurn(string memory name, uint256 buyTax, uint256 sellTax) external override onlyToken {
        taxes.push(Tax(name, buyTax, sellTax, 0, FeeType.BURN, address(0), 0, false));
    }

    function createFeeDistributor(string memory name, uint256 buyTax, uint256 sellTax, address wallet, bool convertToNative) external override onlyToken {
        taxes.push(Tax(name, buyTax, sellTax, 0, FeeType.DISTRIBUTOR, wallet, 0, convertToNative));
    }

    function allocateFee() external override onlyToken swapLock {
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = _weth;
        IERC20 token = IERC20(_token);

        uint256 totalTokens;
        for (uint256 i = 0; i < taxes.length; i++) {
            if (taxes[i].taxType == FeeType.LIQUIDITY) {
                uint256 half = taxes[i].taxPool / 2; totalTokens += taxes[i].taxPool - half;
            } else if (taxes[i].convertToNative) {
                totalTokens += taxes[i].taxPool;
            }
        }
        totalTokens = checkTokenAmount(token, totalTokens);
        if (checkTokenAmount(token, totalTokens) != totalTokens) {
            emit DistributionError("Insufficient tokens to swap. Please add more tokens");
            return;
        }

        uint256[] memory amts = _router.swapExactTokensForETH(
            totalTokens,
            0,
            path,
            address(this),
            block.timestamp + 300
        );
        uint256 amountETH = address(this).balance;

        if (totalTokens != amts[0] || amountETH != amts[1] ) {
            emit DistributionError("Unexpected amounts returned from swap");
        }

        // Calculate the fee allocation
        uint256 toAllocate = amountETH;

        for (uint256 i = 0; i < taxes.length; i++) {

            if (taxes[i].convertToNative || taxes[i].taxType == FeeType.LIQUIDITY) {
                if (i == taxes.length - 1) {
                    taxes[i].share = toAllocate;
                } else if (taxes[i].taxType == FeeType.LIQUIDITY) {
                    uint256 half = taxes[i].taxPool / 2;
                    uint256 share = (amountETH * (taxes[i].taxPool - half)) / totalTokens;
                    taxes[i].share = share;
                    toAllocate = toAllocate - share;
                } else {
                    uint256 share = (amountETH * taxes[i].taxPool) / totalTokens;
                    taxes[i].share = share;
                    toAllocate = toAllocate - share;
                }
            }
        }

        // Distribute the coins
        for (uint256 i = 0; i < taxes.length; i++) {
            
            if (taxes[i].taxType == FeeType.WALLET) {
                if (taxes[i].convertToNative) {
                    payable(taxes[i].location).transfer(taxes[i].share);
                } else {
                    token.transfer(taxes[i].location, checkTokenAmount(token, taxes[i].taxPool));
                }
            }
            else if (taxes[i].taxType == FeeType.DISTRIBUTOR) {
                if (taxes[i].convertToNative) {
                    payable(taxes[i].location).transfer(taxes[i].share);
                } else {
                    token.approve(taxes[i].location, taxes[i].taxPool);
                    IWalletDistributor(taxes[i].location).receiveToken(_token, address(this), checkTokenAmount(token, taxes[i].taxPool));
                }
            }
            else if (taxes[i].taxType == FeeType.DIVIDEND) {
               if (taxes[i].convertToNative) {
                    IDividendDistributor(taxes[i].location).depositNative{value: taxes[i].share}();
                } else {
                    IDividendDistributor(taxes[i].location).depositToken(address(this), checkTokenAmount(token, taxes[i].taxPool));
                }
            }
            else if (taxes[i].taxType == FeeType.BURN) {
                IBurnable(_token).burn(checkTokenAmount(token, taxes[i].taxPool));
            }
            else if (taxes[i].taxType == FeeType.LIQUIDITY) {
                if(taxes[i].share > 0){
                    uint256 half = checkTokenAmount(token, taxes[i].taxPool / 2);
                    _router.addLiquidityETH{value: taxes[i].share}(
                        _token,
                        half,
                        0,
                        0,
                        taxes[i].location,
                        block.timestamp + 300
                    );
                }
            }
            
            taxes[i].taxPool = 0;
            taxes[i].share = 0;
        }

        emit TaxesDistributed(totalTokens, amountETH);

        lastSwapTime = block.timestamp;
    }

    function getSellTax() public override onlyToken view returns (uint256) {
        uint256 taxAmount;
        for (uint256 i = 0; i < taxes.length; i++) {
            taxAmount += taxes[i].sellTaxPercentage;
        }
        return taxAmount;
    }

    function getBuyTax() public override onlyToken view returns (uint256) {
        uint256 taxAmount;
        for (uint256 i = 0; i < taxes.length; i++) {
            taxAmount += taxes[i].buyTaxPercentage;
        }
        return taxAmount;
    }
    
    function setFeeWallet(string memory taxName, address wallet) external override onlyToken {
        bool updated;
        for (uint256 i = 0; i < taxes.length; i++) {
            if (taxes[i].taxType == FeeType.WALLET && compStrings(taxes[i].taxName, taxName)) {
                taxes[i].location = wallet;
                updated = true;
            }
        }
        require(updated, "could not find tax to update");
    }

    function setSellTax(string memory taxName, uint256 taxPercentage) external override onlyToken {
        bool updated;
        for (uint256 i = 0; i < taxes.length; i++) {
            if (compStrings(taxes[i].taxName, taxName)) {
                taxes[i].sellTaxPercentage = taxPercentage; updated = true;
            }
        }
        require(updated, "could not find tax to update");
        require(getSellTax() <= maxSellTax, "tax cannot be set this high");
    }

    function setBuyTax(string memory taxName, uint256 taxPercentage) external override onlyToken {
        bool updated;
        for (uint256 i = 0; i < taxes.length; i++) {
            //if (taxes[i].taxName == taxName) {
            if (compStrings(taxes[i].taxName, taxName)) {
                taxes[i].buyTaxPercentage = taxPercentage; updated = true;
            }
        }
        require(updated, "could not find tax to update");
        require(getBuyTax() <= maxBuyTax, "tax cannot be set this high");
    }

    function takeSellTax(uint256 value) external override onlyToken returns (uint256) {
        for (uint256 i = 0; i < taxes.length; i++) {
            if (taxes[i].sellTaxPercentage > 0) {
                uint256 taxAmount = (value * taxes[i].sellTaxPercentage) / 10000;
                taxes[i].taxPool += taxAmount;
                value = value - taxAmount;
            }
        }
        return value;
    }

    function takeBuyTax(uint256 value) external override onlyToken returns (uint256) {
        for (uint256 i = 0; i < taxes.length; i++) {
            if (taxes[i].buyTaxPercentage > 0) {
                uint256 taxAmount = (value * taxes[i].buyTaxPercentage) / 10000;
                taxes[i].taxPool += taxAmount;
                value = value - taxAmount;
            }
        }
        return value;
    }

    
    // Private methods
    function checkTokenAmount(IERC20 token, uint256 amount) private view returns (uint256) {
        uint256 balance = token.balanceOf(address(this));
        if (balance > amount) { return amount; }
        return balance;
    }

    function compStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

}

contract ReapLend is BaseErc20, AntiSniper, Burnable, Taxable {

    uint256 public rewardsThreshold;
    mapping(address => bool) public rewardsClaimable;

    constructor () {
        configure(msg.sender);

        symbol = "REAP";
        name = "Reap Lend";
        decimals = 18;

        // Swap
        address routerAddress = getRouter();
        IDEXRouter router = IDEXRouter(routerAddress);
        address WETH = router.WETH();
        address pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        feeAllocator = new FeeAllocator(routerAddress, pair, WETH, 1500, 1500);
        exchanges[pair] = true;

        // Anti Sniper
        enableSniperBlocking = true;
        isNeverSniper[address(feeAllocator)] = true;
        mhPercentage = 300;
        msPercentage = 300;
        enableHighTaxCountdown = true;

        // Tax
        minimumTimeBetweenSwaps = 16 seconds;
        minimumTokensBeforeSwap = 1_000_000 * 10 ** decimals;
        excludedFromTax[address(feeAllocator)] = true;
        feeAllocator.createFeeWallet("Treasury", 200, 100, 0xC773bfe0903f01A422aDaB7944f56406C881AcC2, true);
        feeAllocator.createFeeWallet("Marketing", 100, 200, 0x3c617470b9Ddc70c824b99b1F51dB4c28A5E3042, true);
        autoSwapTax = true;
        enableBlockLogProtection = true;

        // Burnable
        ableToBurn[address(feeAllocator)] = true;

        // Rewards
        rewardsClaimable[owner] = true;
        rewardsThreshold = 10_000_000 * 10 ** decimals;

        _totalSupply = _totalSupply + (1_000_000_000 * 10 ** decimals);
        _allowance[address(feeAllocator)][routerAddress] = 2**256 - 1;
        _balances[owner] = _balances[owner] + _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }


    // Overrides
    function startLaunch() public override(AntiSniper, BaseErc20) onlyOwner {
        super.startLaunch();
    }

    function configure(address _owner) internal override(AntiSniper, Burnable, Taxable, BaseErc20) {
        super.configure(_owner);
    }
    
    function calcTransferAmount(address from, address to, uint256 value) override(AntiSniper, Taxable, BaseErc20) internal returns (uint256) {
        return super.calcTransferAmount(from, to, value);
    }

    function preTransfer(address from, address to, uint256 value) override(AntiSniper, Taxable, BaseErc20) internal {
        super.preTransfer(from, to, value);
    }
    
    
    function postTransfer(address from, address to) override(BaseErc20) internal {
        super.postTransfer(from, to);
    }

    // Public Functions

    function claimableRewards(address who) external view returns(bool) {
        return rewardsClaimable[who] || _balances[who] >= rewardsThreshold;
    }

    // Admin Functions

    function setRewardsClaimable(address who, bool on) external onlyOwner {
        rewardsClaimable[who] = on;
    }

    function setRewardsThreshold(uint256 amount) external onlyOwner {
        rewardsThreshold = amount;
    }
}