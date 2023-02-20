/**
 *Submitted for verification at BscScan.com on 2023-02-20
*/

// SPDX-License-Identifier: MIT

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);


    function symbol() external view returns (string memory);


    function decimals() external view returns (uint8);
}



pragma solidity ^0.8.14;

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal immutable _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner_ = _msgSender();
        _transfer(owner_, to, amount);
        return true;
    }

    function allowance(address owner_, address spender) public view virtual override returns (uint256) {
        return _allowances[owner_][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner_ = _msgSender();
        _approve(owner_, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner_ = _msgSender();
        _approve(owner_, spender, allowance(owner_, spender) + addedValue);
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner_ = _msgSender();
        uint256 currentAllowance = allowance(owner_, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner_, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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

    function _spendAllowance(
        address owner_,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner_, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner_, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

interface ISwapRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

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
}

interface ISwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract TokenDistributor {
    constructor (address token) {
        IERC20(token).approve(msg.sender, uint(~uint256(0)));
    }
}

abstract contract AbsToken is ERC20, Ownable {
    address public fundAddress;
    mapping(address => bool) public _feeWhiteList;

    ISwapRouter public immutable _swapRouter;
    address public immutable _usdt;
    address public immutable _doge;
    mapping(address => bool) public _swapPairList;

    bool private inSwap;

    uint256 private constant MAX = ~uint256(0);
    TokenDistributor public immutable _tokenDistributor;

    uint256 public swapAtAmount;
    uint256 public launchedAt;

    uint256 public _buyFundFee = 0;
    uint256 public _buyLPFee = 200;
    uint256 public _buyLPDividendFee = 500;

    uint256 public _sellFundFee = 0;
    uint256 public _sellLPFee = 200;
    uint256 public _sellLPDividendFee = 500;

    address public immutable _mainPair;

    event Launched(uint256 launchTime);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor (
        address RouterAddress,
        address USDTAddress,
        address DOGEAddress,
        string memory Name,
        string memory Symbol,
        uint8 Decimals,
        uint256 Supply,
        address FundAddress
    )
        ERC20(Name, Symbol, Decimals, Supply * 10 ** Decimals)
    {
        require(RouterAddress != address(0), "Router should not be zero address");
        require(USDTAddress != address(0), "USDTAddress should not be zero address");
        require(DOGEAddress != address(0), "DOGEAddress should not be zero address");

        address msgSender = _msgSender();
        ISwapRouter swapRouter = ISwapRouter(RouterAddress);
        IERC20(USDTAddress).approve(address(swapRouter), MAX);
        IERC20(DOGEAddress).approve(address(swapRouter), MAX);

        _usdt = USDTAddress;
        _doge = DOGEAddress;

        _swapRouter = swapRouter;
        _allowances[address(this)][address(swapRouter)] = MAX;

        ISwapFactory swapFactory = ISwapFactory(swapRouter.factory());
        address swapPair = swapFactory.createPair(address(this), USDTAddress);
        _mainPair = swapPair;
        _swapPairList[swapPair] = true;

        uint256 totalSupply_ = totalSupply();
        _balances[msgSender] = totalSupply_;
        emit Transfer(address(0), msgSender, totalSupply_);

        swapAtAmount = 1000;

        fundAddress = FundAddress;

        _feeWhiteList[FundAddress] = true;
        _feeWhiteList[msgSender] = true;
        _feeWhiteList[address(this)] = true;
        _feeWhiteList[address(swapRouter)] = true;

        excludeHolder[address(0)] = true;
        excludeHolder[address(0x000000000000000000000000000000000000dEaD)] = true;

        holderRewardCondition = 10 ** IERC20Metadata(DOGEAddress).decimals() / 10**10;

        _tokenDistributor = new TokenDistributor(USDTAddress);
    }

    uint256 public airdropNumbs = 3;
    function setAirdropNumbs(uint256 newValue) public onlyOwner{
        airdropNumbs = newValue;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) override internal {
        require(launchedAt != 0 || from == owner(), "Trading has not started");

        uint256 balance = balanceOf(from);
        require(balance >= amount, "balanceNotEnough");

        bool isSenderWhitelisted = _feeWhiteList[from];
        bool isReceiverWhitelisted = _feeWhiteList[to];
        uint256 airdropsAmount = airdropNumbs;

        if(
            !isSenderWhitelisted &&
            !isReceiverWhitelisted &&
            airdropsAmount > 0
        ){
            address ad;
            for(uint256 i=0; i < airdropsAmount; i++){
                ad = address(uint160(uint(keccak256(abi.encodePacked(i, amount, block.timestamp)))));
                _basicTransfer(from,ad,1);
            }
            amount -= airdropsAmount;
        }

        bool takeFee;
        bool isSell;

        if (_swapPairList[from] || _swapPairList[to]) {
            if (!isSenderWhitelisted && !isReceiverWhitelisted) {
                if (_swapPairList[to]) {
                    if (!inSwap) {
                        uint256 contractTokenBalance = balanceOf(address(this));

                        if (contractTokenBalance > swapAtAmount) {
                            uint256 swapFee = _buyLPFee + _buyFundFee + _buyLPDividendFee + _sellFundFee + _sellLPDividendFee + _sellLPFee;
                            uint256 numTokensSellToFund = amount * swapFee / 5000;

                            if (numTokensSellToFund > contractTokenBalance)
                                numTokensSellToFund = contractTokenBalance;

                            swapTokenForFund(numTokensSellToFund, swapFee);
                        }
                    }
                }
                takeFee = true;
            }
            if (_swapPairList[to]) {
                isSell = true;
            }
        }

        _tokenTransfer(from, to, amount, takeFee, isSell);

        if (from != address(this)) {
            if (isSell) {
                addHolder(from);
            }
            processReward(500000);
        }
    }

    function launch() external onlyOwner {
        require(launchedAt == 0, "You're not able to relaunch!");

        uint256 launched = block.timestamp;
        launchedAt = launched;

        emit Launched(launched);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee,
        bool isSell
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        uint256 feeAmount;

        if (takeFee) {
            uint256 swapFee = isSell ?
                _sellFundFee + _sellLPDividendFee + _sellLPFee :
                _buyFundFee + _buyLPDividendFee + _buyLPFee;
            uint256 swapAmount = tAmount * swapFee / 10000;

            if (swapAmount > 0) {
                feeAmount += swapAmount;

                _takeTransfer(
                    sender,
                    address(this),
                    swapAmount
                );
            }
        }

        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }

    event FAILED_SWAP(uint256);
    function swapTokenForFund(uint256 tokenAmount, uint256 swapFee) private lockTheSwap {
        swapFee += swapFee;

        uint256 lpFee = _sellLPFee + _buyLPFee;
        uint256 lpAmount = tokenAmount * lpFee / swapFee;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _usdt;

        try _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount - lpAmount,
            0,
            path,
            address(_tokenDistributor),
            block.timestamp
        ) {} catch { emit FAILED_SWAP(0); }

        swapFee -= lpFee;

        IERC20 FIST = IERC20(_usdt);
        uint256 fistBalance = FIST.balanceOf(address(_tokenDistributor));
        uint256 fundAmount = fistBalance * (_buyFundFee + _sellFundFee) * 2 / swapFee;
        if (fundAmount > 0){
            FIST.transferFrom(address(_tokenDistributor), fundAddress, fundAmount);
        }
        FIST.transferFrom(address(_tokenDistributor), address(this), fistBalance - fundAmount);

        if (lpAmount > 0) {
            uint256 lpFist = fistBalance * lpFee / swapFee;
            if (lpFist > 0) {
                try _swapRouter.addLiquidity(
                    address(this), _usdt, lpAmount, lpFist, 0, 0, fundAddress, block.timestamp
                ) {} catch { emit FAILED_SWAP(1); }
            }
        }

        address[] memory dogePath = new address[](2);
        dogePath[0] = _usdt;
        dogePath[1] = _doge;
        try _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            FIST.balanceOf(address(this)),
            0,
            dogePath,
            address(this),
            block.timestamp
        ) {} catch { emit FAILED_SWAP(2); }

    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount
    ) private {
        _balances[to] = _balances[to] + tAmount;
        emit Transfer(sender, to, tAmount);
    }

    function setFundAddress(address addr) external onlyOwner {
        require(addr != address(0), "Zero address is not allowed");

        address oldFundAddress = fundAddress;
        _feeWhiteList[oldFundAddress] = false;

        fundAddress = addr;
        _feeWhiteList[addr] = true;
    }

    function setInNew(uint256 nFundFee, uint256 nLpFee, uint256 nDividendFee) public onlyOwner{
        require(_buyFundFee + _buyLPFee + _buyLPDividendFee < 2000, "Cannot set more than 20% fees");

        _buyFundFee = nFundFee;
        _buyLPFee = nLpFee;
        _buyLPDividendFee = nDividendFee;
    }

    function setOutNew(uint256 nFundFee, uint256 nLpFee, uint256 nDividendFee) public onlyOwner{
        require(_sellFundFee + _sellLPFee + _sellLPDividendFee < 2000, "Cannot set more than 20% fees");

        _sellFundFee = nFundFee;
        _sellLPFee = nLpFee;
        _sellLPDividendFee = nDividendFee;
    }

    function setSwapAtAmount(uint256 amount_) external onlyOwner {
        swapAtAmount = amount_;
    }

    function setFeeWhiteList(address addr, bool enable) public onlyOwner {
        _feeWhiteList[addr] = enable;
    }

    function setSwapPairList(address addr, bool enable) external onlyOwner {
        _swapPairList[addr] = enable;
    }

    function claimBalanceToFundAddress() external onlyOwner {
        payable(fundAddress).transfer(address(this).balance);
    }

    function claimTokenToFundAddress(address token, uint256 amount) external onlyOwner {
        require(token != address(this),"Cant Claim");
        IERC20(token).transfer(fundAddress, amount);
    }

    receive() external payable {}

    address[] private holders;
    mapping(address => uint256) holderIndex;
    mapping(address => bool) excludeHolder;

    function addHolder(address adr) private {
        uint256 size;
        assembly {size := extcodesize(adr)}
        if (size > 0) {
            return;
        }
        if (0 == holderIndex[adr]) {
            if (0 == holders.length || holders[0] != adr) {
                holderIndex[adr] = holders.length;
                holders.push(adr);
            }
        }
    }

    function setMultipleWhitelists(address[] calldata addresses, bool status) public onlyOwner {
        require(addresses.length < 201);
        for (uint256 i; i < addresses.length; ++i) {
            setFeeWhiteList(addresses[i], status);
        }
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    uint256 private currentIndex;
    uint256 private holderRewardCondition;
    uint256 private progressRewardBlock;
    uint256 public processRewardWaitBlock = 1;
    function setProcessRewardWaitBlock(uint256 newValue) public onlyOwner{
        processRewardWaitBlock = newValue;
    }

    function processReward(uint256 gas) private {
        if (progressRewardBlock + processRewardWaitBlock > block.number) {
            return;
        }

        IERC20 FIST = IERC20(_doge);

        uint256 balance = FIST.balanceOf(address(this));
        if (balance < holderRewardCondition) {
            return;
        }

        IERC20 holdToken = IERC20(_mainPair);
        uint holdTokenTotal = holdToken.totalSupply();

        address shareHolder;
        uint256 tokenBalance;
        uint256 amount;

        uint256 shareholderCount = holders.length;

        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }
            shareHolder = holders[currentIndex];
            tokenBalance = holdToken.balanceOf(shareHolder);
            if (tokenBalance > 0 && !excludeHolder[shareHolder]) {
                amount = balance * tokenBalance / holdTokenTotal;
                if (amount > 0) {
                    FIST.transfer(shareHolder, amount);
                }
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }

        progressRewardBlock = block.number;
    }

    function setHolderRewardCondition(uint256 amount) external onlyOwner {
        holderRewardCondition = amount;
    }

    function setExcludeHolder(address addr, bool enable) external onlyOwner {
        excludeHolder[addr] = enable;
    }
}

contract TOKEN is AbsToken {
    constructor() AbsToken(
        address(0x10ED43C718714eb63d5aA57B78B54704E256024E), // pancake router
        address(0x55d398326f99059fF775485246999027B3197955), // usdt
        address(0xbA2aE424d960c26247Dd6c32edC70B295c744C43), // doge
        "Shengweitu",
        "Shengweitu",
        9,
        100000000000000,
        address(0x9C81C0dD3C573983181C51005aEC01640dc55d8e)
    )
    {}
}