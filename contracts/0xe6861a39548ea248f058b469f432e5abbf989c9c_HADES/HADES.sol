/**
 *Submitted for verification at Etherscan.io on 2023-06-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor() {
        _transferOwnership(msg.sender);
    }

    
    function owner() public view virtual returns (address) {
        return _owner;
    }

   
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

   
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

   
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniswapV2Router {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}



contract HADES is Ownable {
    mapping(address => uint256) public _balances;

    mapping(address => mapping(address => uint256)) public _allowances;

    uint256 public _totalSupply;

    string public _name;
    string public _symbol;
    uint8 _decimals;

    // 
    address public pairAddress;
    bool public swapping;

    uint256 public maxWalletAmount;

    uint256 public buyFee;

    uint256 public sellFee;

    IUniswapV2Router public router;

    mapping(address => bool) public feeWhiteList;
    mapping(address => bool) public maxWalletWhiteList;

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);

    
    
    constructor() {
        _name = "HADES";
        _symbol = "HADES";
        _decimals = 18;
        _mint(msg.sender, (100_000_000 * 10 ** decimals()));


        maxWalletAmount = 2_000_000 * 10 ** decimals();




        feeWhiteList[msg.sender] = true;
        feeWhiteList[address(this)] = true;

        maxWalletWhiteList[msg.sender] = true;
        maxWalletWhiteList[address(this)] = true;
        router = IUniswapV2Router(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        pairAddress = IUniswapV2Factory(router.factory()).createPair(
            address(this),
            router.WETH()
        );
        maxWalletWhiteList[pairAddress] = true;

        _approve(msg.sender, address(router), type(uint256).max);
        _approve(address(this), address(router), type(uint256).max);

    }


   
    function name() public view virtual  returns (string memory) {
        return _name;
    }


    function symbol() public view virtual  returns (string memory) {
        return _symbol;
    }

   
    function decimals() public view virtual  returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual  returns (uint256) {
        return _totalSupply;
    }

   
    function balanceOf(address account) public view virtual  returns (uint256) {
        return _balances[account];
    }

 
    function transfer(address recipient, uint256 amount) public virtual  returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual  returns (uint256) {
        return _allowances[owner][spender];
    }

    function updatePairAddress(address _pairAddress) public onlyOwner {
        pairAddress = _pairAddress;
    }

    

    function updateMaxWalletAmount(uint256 _maxWalletAmount) public onlyOwner {
        maxWalletAmount = _maxWalletAmount;
    }

    function updateFees(uint256 _buyFee, uint256 _sellFee) public onlyOwner {
        require(_buyFee <=3334);
        require(_sellFee <=3334);
        buyFee = _buyFee;
        sellFee = _sellFee;
    }

    function updateFeeWhiteList(address user, bool value) public onlyOwner {
        feeWhiteList[user] = value;
    }

    function updateMaxWalletWhiteList(address user, bool value) public onlyOwner {
        maxWalletWhiteList[user] = value;
    }

 
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual  returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }

  
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

 
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }


    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        bool takeFee = true;

        if (feeWhiteList[sender] || feeWhiteList[recipient]) {
            takeFee = false;
        }
        if (buyFee + sellFee == 0) {
            takeFee = false;
        }
        uint256 fees = 0;

        if (takeFee) {
             if (recipient == pairAddress) {
                fees = (amount * sellFee) / 10000;
            }
            else if (sender == pairAddress) {
                fees = (amount*buyFee) / 10000;
            }
        }

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        if (fees > 0) {
            amount = amount - fees;
            _balances[address(this)] += fees;
            emit Transfer(sender, (address(this)), fees);

        }
        _balances[recipient] += amount;

        if (!maxWalletWhiteList[recipient]) {
            require(balanceOf(recipient) <= maxWalletAmount);
        }

        emit Transfer(sender, recipient, amount);

    }

 
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");


        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

    }

   
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");


        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function swapFee() public {
        swapping = true;
        uint256 contractBalance = _balances[address(this)];
        if (contractBalance == 0) {
            return;
        }

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            contractBalance,
            0,
            path,
            owner(),
            (block.timestamp)
        );
    swapping = false;


    }
}