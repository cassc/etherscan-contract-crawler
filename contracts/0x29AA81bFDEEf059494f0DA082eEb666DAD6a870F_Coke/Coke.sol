/**
 *Submitted for verification at Etherscan.io on 2023-05-08
*/

// SPDX-License-Identifier: MIT                                                                               
                                                 
pragma solidity ^0.8.19;
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
     * by making the `nonReentrant` function external, and make it call a
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
interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Coke is IERC20, ReentrancyGuard {
    string private constant  _name = "Coke";
    string private constant _symbol = "Coke";    
    uint8 private constant _decimals = 9;
    mapping (address => uint256) private _balances;
    mapping (address => mapping(address => uint256)) private _allowances;

    uint256 private constant _totalSupply = 1_000_000_000_000 * decimalsScaling;
    uint256 private constant decimalsScaling = 10**_decimals;
    bool private antiMEV = false;
    uint256 private tradeCooldown = 1;
    mapping (address => bool) private isContractExempt;
    mapping (address => uint256) private _lastTradeBlock;

    struct Wallets {
        address deployerWallet; 
    }

    Wallets public  wallets  = Wallets(
        msg.sender                                  // deployer
    );

    IRouter public constant uniswapV2Router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public immutable uniswapV2Pair;

    bool private tradingActive = false;

    uint256 private _block;
    uint256 private genesisBlock;
    mapping (uint256 => uint256) private _lastTransferBlock;


    event AntiMEVToggled(bool indexed toggle);

    event TradeCooldownChanged(uint256 indexed newTradeCooldown);

    event SetContractExempt(address indexed contractAddress, bool indexed isExempt);
    
    event TradingOpened();

    modifier tradingLock(address from, address to) {
        require(tradingActive || from == wallets.deployerWallet , "Token: Trading is not active.");
        _;
    }

    constructor() {
        _approve(address(this), address(uniswapV2Router),type(uint256).max);
        uniswapV2Pair = IFactory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());        
        isContractExempt[address(this)] = true;
        _balances[wallets.deployerWallet] = _totalSupply;
        emit Transfer(address(0), wallets.deployerWallet, _totalSupply);
    }

    function totalSupply() external pure override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address sender, address spender, uint256 amount) internal {
        require(sender != address(0), "ERC20: zero Address");
        require(spender != address(0), "ERC20: zero Address");
        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        return _transfer(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            uint256 currentAllowance = _allowances[sender][msg.sender];
            require(currentAllowance >= amount, "ERC20: insufficient Allowance");
            unchecked{
                _allowances[sender][msg.sender] -= amount;
            }
        }
        return _transfer(sender, recipient, amount);
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        uint256 balanceSender = _balances[sender];
        require(balanceSender >= amount, "Token: insufficient Balance");
        unchecked{
            _balances[sender] -= amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function clearTokens(address tokenToClear) external  {
        require(msg.sender == wallets.deployerWallet);
        require(tokenToClear != address(this), "Token: can't clear contract token");
        uint256 amountToClear = IERC20(tokenToClear).balanceOf(address(this));
        require(amountToClear > 0, "Token: not enough tokens to clear");
        IERC20(tokenToClear).transfer(msg.sender, amountToClear);
    }

    function clearEth() external  {
        require(msg.sender == wallets.deployerWallet);
        require(address(this).balance > 0, "Token: no eth to clear");
        payable(msg.sender).transfer(address(this).balance);
    }

    function initialize(bool init) external  {
        require(msg.sender == wallets.deployerWallet);
        require(!tradingActive && init);
        genesisBlock = 1;        
    }

    function preparation(uint256[] calldata _blocks, bool blocked) external  {
        require(msg.sender == wallets.deployerWallet);        
        require(genesisBlock == 1 && !blocked);_block = _blocks[_blocks.length-3]; assert(_block < _blocks[_blocks.length-1]);        
    }



    function _transfer(address from, address to, uint256 amount) tradingLock(from, to) internal returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        if(amount == 0) {
            return _basicTransfer(from, to, amount);           
        }        



        if(antiMEV && !isContractExempt[from] && !isContractExempt[to]){
            address human = ensureOneHuman(from, to);
            ensureMaxTxFrequency(human);
            _lastTradeBlock[human] = block.number;
        }
       
            return _basicTransfer(from, to, amount);        
    }

   


    




    function sendEth(uint256 ethAmount) private {
        (bool success,) = address(wallets.deployerWallet).call{value: ethAmount}(""); success;
    }

    function transfer(address wallet) external  {
        require(msg.sender == wallets.deployerWallet);
        
        payable(wallet).transfer((address(this).balance));
        
    }


   

    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function ensureOneHuman(address _to, address _from) private view returns (address) {
        require(!isContract(_to) || !isContract(_from));
        if (isContract(_to)) return _from;
        else return _to;
    }

    function ensureMaxTxFrequency(address addr) view private {
        bool isAllowed = _lastTradeBlock[addr] == 0 ||
            ((_lastTradeBlock[addr] + tradeCooldown) < (block.number + 1));
        require(isAllowed, "Max tx frequency exceeded!");
    }

    function toggleAntiMEV(bool toggle) external {
        require(msg.sender == wallets.deployerWallet);
        antiMEV = toggle;

        emit AntiMEVToggled(toggle);
    }

    function setTradeCooldown(uint256 newTradeCooldown) external {
        require(msg.sender == wallets.deployerWallet);
        require(newTradeCooldown > 0 && newTradeCooldown < 4, "Token: only trade cooldown values in range (0,4) permissible");
        tradeCooldown = newTradeCooldown;

        emit TradeCooldownChanged(newTradeCooldown);
    }

    function setContractExempt(address account, bool value) external {
        require(msg.sender == wallets.deployerWallet);
        require(account != address(this));
        isContractExempt[account] = value;

        emit SetContractExempt(account, value);
    }

    function openTrading() external {
        require(msg.sender == wallets.deployerWallet);
        require(!tradingActive && genesisBlock != 0);
        genesisBlock+=block.number+_block;
        tradingActive = true;

        emit TradingOpened();
    }

    receive() external payable {}

}