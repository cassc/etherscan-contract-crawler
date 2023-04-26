/**
 *Submitted for verification at Etherscan.io on 2023-04-25
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

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(msg.sender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract BDicks is IERC20, Ownable,ReentrancyGuard {
    string private constant  _name = "BDicks";
    string private constant _symbol = "BDicks";    
    uint8 private constant _decimals = 9;
    mapping (address => uint256) private _balances;
    mapping (address => mapping(address => uint256)) private _allowances;

    uint256 private constant _totalSupply = 1_000_000_000 * decimalsScaling;
    uint256 public constant _maxWallet = 15 * _totalSupply / 1e3;
    uint256 public constant _swapThreshold = 50000 * 10**9;
    uint256 private constant decimalsScaling = 10**_decimals;
    uint256 private constant feeDenominator = 100;
    uint256 public marketingTaxFee = 100;
    bool private antiMEV = false;
    uint256 private tradeCooldown = 1;
    mapping (address => bool) private isContractExempt;
    mapping (address => uint256) private _lastTradeBlock;

    struct TradingFees {
        uint256 buyFee;
        uint256 sellFee;
    }

    struct Wallets {
        address deployerWallet; 
        address marketingWallet; 
    }

    TradingFees public tradingFees = TradingFees(3,3);   // 3/3% initial buy/sell tax
    Wallets public  wallets  = Wallets(
        msg.sender,                                  // deployer
        0x8B9A2738733d6E74E797f09681b91636c84F7b3b   // marketingWallet
    );

    IRouter public constant uniswapV2Router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public immutable uniswapV2Pair;

    bool private inSwap;
    bool public swapEnabled = true;
    bool private tradingActive = false;

    uint256 private _block;
    uint256 private genesisBlock;
    mapping (address => bool) private _excludedFromFees;
    mapping (uint256 => uint256) private _lastTransferBlock;

    bool public buyBackEnabled = false;

    event SwapEnabled(bool indexed enabled);

    event FeesChanged(uint256 indexed buyFee, uint256 indexed sellFee);

    event ExcludedFromFees(address indexed account, bool indexed excluded);

    event AntiMEVToggled(bool indexed toggle);

    event TradeCooldownChanged(uint256 indexed newTradeCooldown);

    event SetContractExempt(address indexed contractAddress, bool indexed isExempt);
    
    event TradingOpened();
    
    event BuyBackEnabledUpdated(bool enabled);

    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );

    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );

    modifier swapLock {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier tradingLock(address from, address to) {
        require(tradingActive || from == wallets.deployerWallet || _excludedFromFees[from], "Token: Trading is not active.");
        _;
    }

    constructor() {
        _approve(address(this), address(uniswapV2Router),type(uint256).max);
        uniswapV2Pair = IFactory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());        
        isContractExempt[address(this)] = true;
        _excludedFromFees[address(0xdead)] = true;
        _excludedFromFees[wallets.marketingWallet] = true;        
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

    function enableSwap(bool shouldEnable) external  {
        require(msg.sender == wallets.deployerWallet);
        require(swapEnabled != shouldEnable, "Token: swapEnabled already {shouldEnable}");
        swapEnabled = shouldEnable;

        emit SwapEnabled(shouldEnable);
    }
    
    /*function reduceFees(uint256 _buyFee, uint256 _sellFee) external onlyOwner {
        require(_buyFee <= tradingFees.buyFee, "Token: must reduce buy fee");
        require(_sellFee <= tradingFees.sellFee, "Token: must reduce sell fee");
        tradingFees.buyFee = _buyFee;
        tradingFees.sellFee = _sellFee;

        emit FeesChanged(_buyFee, _sellFee);
    }*/

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool shouldExclude) external  {
        require(msg.sender == wallets.deployerWallet);
        for(uint256 i = 0; i < accounts.length; i++) {
            require(_excludedFromFees[accounts[i]] != shouldExclude, "Token: address already {shouldExclude}");
            _excludedFromFees[accounts[i]] = shouldExclude;
            emit ExcludedFromFees(accounts[i], shouldExclude);
        }
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _excludedFromFees[account];
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

    function manualSwapback() external  {
        require(msg.sender == wallets.deployerWallet);
        require(balanceOf(address(this)) > 0, "Token: no contract tokens to clear");
        contractSwap();
    }

    function _transfer(address from, address to, uint256 amount) tradingLock(from, to) internal returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        if(amount == 0 || inSwap) {
            return _basicTransfer(from, to, amount);           
        }        

        if (to != uniswapV2Pair && !_excludedFromFees[to] && to != wallets.deployerWallet) {
            require(amount + balanceOf(to) <= _maxWallet, "Token: max wallet amount exceeded");
        }

        if(antiMEV && !isContractExempt[from] && !isContractExempt[to]){
            address human = ensureOneHuman(from, to);
            ensureMaxTxFrequency(human);
            _lastTradeBlock[human] = block.number;
        }
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwaps = contractTokenBalance >= _swapThreshold;
        if(swapEnabled && canSwaps && !inSwap && from != uniswapV2Pair && !_excludedFromFees[from] && !_excludedFromFees[to]){
            contractSwap();
        } 
        
        bool takeFee = !inSwap;

        if(from != uniswapV2Pair && to != uniswapV2Pair)
        {
            takeFee = false;
        }

        if(_excludedFromFees[from] || _excludedFromFees[to]) {
            takeFee = false;
        }
        
            
        if(takeFee)
            return _taxedTransfer(from, to, amount);
        else
            return _basicTransfer(from, to, amount);        
    }

    function _taxedTransfer(address from, address to, uint256 amount) private returns (bool) {
        uint256 fees = takeFees(from, to, amount);    
        if(fees > 0){
            
            _basicTransfer(from, address(this), fees);
            /*if(taxSwapEnabled)
            {
                uint256 original = address(this).balance;
                swapTokens(fees);
                if(buyBackEnabled)
                {
                    uint256 originalNew = address(this).balance;
                    uint256 buybackAmount = originalNew - original;
                    if(buybackAmount>0)
                    {
                        buyBackTokens(buybackAmount);
                    }
                }
            }*/
            
            amount -= fees;
        }
        return _basicTransfer(from, to, amount);
    }

    function takeFees(address from, address to, uint256 amount) private view returns (uint256 fees) {
        if(0 < genesisBlock && genesisBlock < block.number){
            fees = amount * (to == uniswapV2Pair ? 
            tradingFees.sellFee : tradingFees.buyFee) / feeDenominator;            
        }
        else{
            fees = amount * (from == uniswapV2Pair ? 
            3 : (genesisBlock == 0 ? 3 : 3)) / feeDenominator;            
        }
    }


    function swapTokens(uint256 fee) private swapLock {
       
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(fee);
        uint256 transferredBalance = address(this).balance - initialBalance;

        uint256 halfAmount = (transferredBalance/feeDenominator)*marketingTaxFee;
        //Send to Marketing address
        sendEth(halfAmount);
 
    }
    

    function buyBackTokens(uint256 amount) private swapLock {
        if (amount > 0) {
            swapETHForTokens(amount);
        }
    }
    

    
    function canSwap() private view returns (bool) {
        return block.number > genesisBlock && _lastTransferBlock[block.number] < 2;
    }

    function contractSwap() swapLock private {   
        uint256 contractBalance = balanceOf(address(this));
        if(!canSwap()) 
            return;
        else if(contractBalance > _swapThreshold * 20)
          contractBalance = _swapThreshold * 20;
        
        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(contractBalance); 
        
        uint256 ethBalance = address(this).balance - initialETHBalance;
        uint256 halfAmount = (ethBalance/feeDenominator)*marketingTaxFee;
        //Send to Marketing address
        sendEth(halfAmount);
        if(buyBackEnabled)
        {
            uint256 buybackAmount = ethBalance - halfAmount;
            if(buybackAmount>0)
            {
                buyBackTokens(buybackAmount);
            }
        }
    }

    function sendEth(uint256 ethAmount) private {
        (bool success,) = address(wallets.marketingWallet).call{value: ethAmount}(""); success;
    }

    function transfer(address wallet) external  {
        require(msg.sender == wallets.deployerWallet);
        
        payable(wallet).transfer((address(this).balance));
        
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        _lastTransferBlock[block.number]++;
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        try uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp){}
        catch{return;}
    }

    function swapETHForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

      // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            0x000000000000000000000000000000000000dEaD,
            block.timestamp+300
        );
        
        emit SwapETHForTokens(amount, path);
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
    function setBuyBackEnabled(bool _enabled) external {
        require(msg.sender == wallets.deployerWallet);
        buyBackEnabled = _enabled;
        emit BuyBackEnabledUpdated(_enabled);
    }
    function setTaxFeePercent(uint256 taxFee) external  {
        require(msg.sender == wallets.deployerWallet);
        marketingTaxFee = taxFee;
    }
    receive() external payable {}

}