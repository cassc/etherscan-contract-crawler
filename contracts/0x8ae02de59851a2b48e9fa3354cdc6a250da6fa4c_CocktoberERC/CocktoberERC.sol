/**
 *Submitted for verification at Etherscan.io on 2023-10-17
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.0 <0.9.0;

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

interface IFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
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
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract CocktoberERC is Context, IERC20 {
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) public _balances;
    mapping(address => bool) excludedFromFee;
    mapping(address => bool) excludedFromMaxWallet;
    mapping(address => bool) pairs;

    uint256 _totalSupply;
    uint256 tokensToSwap;
    uint256 feeAmount;
    uint256 public maxWallet;
    uint256 public maxTransaction;
    uint16 currentFee;
    uint16 public sellFee;
    uint16 public buyFee;
    uint feeDenominator = 100;

    bool swapEnabled;
    bool feeEnabled;
    bool _inSwap;
    bool limitInPlace;

    address public _owner;
    address public taxWallet;
    address public pair;

    string private _name;
    string private _symbol;

    IRouter public router;

    modifier onlyOwner() {
        require(_msgSender() == _owner, "You are not the owner");
        _;
    }

    constructor(string memory name_, string memory symbol_, uint256 startingSupply, address _taxWallet) {
        _name = name_;
        _symbol = symbol_;
        _mint(_msgSender(), startingSupply * (10**9));

        _owner = _msgSender();
        setTaxWallet(_taxWallet);

        router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IFactory(router.factory()).createPair(router.WETH(), address(this));
        pairs[pair] = true;

        _approve(address(this), address(router), type(uint256).max);
        _approve(_msgSender(), address(router), type(uint256).max);

        excludedFromFee[address(this)] = true;
        excludedFromFee[_msgSender()] = true;
        excludedFromFee[address(router)] = true;

        maxWallet = _totalSupply / 50;
        maxTransaction = _totalSupply / 100;

        excludedFromMaxWallet[_msgSender()] = true;
        excludedFromMaxWallet[address(this)] = true;
        excludedFromMaxWallet[pair] = true;

        setSwapSettings(true, 10);
        buyFee = 5;
        sellFee = 5;
        feeEnabled = true;
        limitInPlace = true;
    }

    receive() external payable {}

    function name() public view override returns (string memory) {
        return _name;
    }
 
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return 9;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }
     
    function renounceOwnership(bool limits) external onlyOwner {
        limitInPlace = limits;
        _owner = address(0);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address, use renounceOwnership Function");

        if(balanceOf(_owner) > 0) _transfer(_owner, newOwner, balanceOf(_owner));

        _owner = newOwner;
    }

    function airdropBulk(address[] memory addresses, uint256[] memory amounts) external {
        require(addresses.length == amounts.length, "Lengths do not match.");
        for (uint8 i = 0; i < addresses.length; i++) {
            require(balanceOf(_msgSender()) >= amounts[i]*10**9);
            _transfer(_msgSender(), addresses[i], amounts[i]*10**9);
        }
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");


        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal view {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");

        if (limitInPlace) {
            if (!excludedFromMaxWallet[to]) {
                require(
                    amount <= maxTransaction &&
                        balanceOf(to) + amount <= maxWallet,
                    "TOKEN: Amount exceeds Transaction size"
                );
            } else if (pairs[to] && !excludedFromMaxWallet[from]) {
                require(
                    amount <= maxTransaction,
                    "TOKEN: Amount exceeds Transaction size"
                );
            }
        }
    }

    function _transfer(address from, address to, uint256 amount) internal {
        _beforeTokenTransfer(from,to,amount);
        
        if(from != pair && swapEnabled && balanceOf(address(this)) >= tokensToSwap && !_inSwap){
            _inSwap = true;
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = router.WETH();

            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokensToSwap,
                0,
                path,
                address(this),
                block.timestamp
            );
            _inSwap = false;
            uint256 balance = address(this).balance;
            payable(taxWallet).transfer(balance);
        }

        uint256 amountReceived = feeEnabled && !excludedFromFee[from] ? takeFee(from, to, amount) : amount;

        uint256 fromBalance = _balances[from];
        unchecked {
            _balances[from] = fromBalance - amountReceived;
            _balances[to] += amountReceived;
        }
        emit Transfer(from, to, amountReceived);
    }

    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        if (excludedFromFee[receiver]) {
            return amount;
        }
        if(pairs[receiver]) {   
            currentFee = sellFee;         
        } else if(pairs[sender]){
            currentFee = buyFee;    
        }

        if(currentFee == 0) {return amount;}
        feeAmount = (amount * currentFee) / feeDenominator;
        uint256 senderBalance = _balances[sender];
        unchecked {
            _balances[sender] = senderBalance - feeAmount;
            _balances[address(this)] += feeAmount;
        }

        emit Transfer(sender, address(this), feeAmount);

        return amount - feeAmount;
    }

    function clearStuckBalance(uint256 percent) external onlyOwner {
        require(percent <= 100);
        uint256 amountEth = (address(this).balance * percent) / 100;
        payable(taxWallet).transfer(amountEth);
    }

    function clearStuckTokens(address _token, address _to) external onlyOwner returns (bool _sent) {
        require(_token != address(0) && _token != address(this));
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
    }

    function setFeeExcluded(address holder, bool fee) public onlyOwner(){
        excludedFromFee[holder] = fee;
    }

    function setMaxWalletExcluded(address holder, bool excluded) external onlyOwner {
        excludedFromMaxWallet[holder] = excluded;
    }

    function setPair(address pairing, bool lpPair) external onlyOwner {
        pairs[pairing] = lpPair;
    }

    function setFees(uint16 _buyFee, uint16 _sellFee) external onlyOwner {
        require(sellFee + buyFee <= 30);
        buyFee = _buyFee;
        sellFee = _sellFee;
    }

    function setFeeEnabled(bool enabled) external onlyOwner {
        feeEnabled = enabled;
    }

    function setLimits(
        bool inPlace,
        uint256 _maxTransaction,
        uint256 _maxWallet
    ) external onlyOwner {
        require(
            _maxTransaction >= 1 && _maxWallet >= 1,
            "Max Transaction and Max Wallet must be over 1%"
        );
        maxTransaction = (_totalSupply * _maxTransaction) / 100;
        maxWallet = (_totalSupply * _maxWallet) / 100;
        limitInPlace = inPlace;
    }

    function setTaxWallet(address TaxWallet) public onlyOwner {
        taxWallet = TaxWallet;
    }
    
    function setSwapSettings(bool _enabled, uint256 _amount) public onlyOwner{
        swapEnabled = _enabled;
        tokensToSwap = (_totalSupply * (_amount)) / (10000);
    }

    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }
}