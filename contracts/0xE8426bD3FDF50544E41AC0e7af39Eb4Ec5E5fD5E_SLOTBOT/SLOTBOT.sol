/**
 *Submitted for verification at Etherscan.io on 2023-08-15
*/

/****************************************************

Spin, Win, and Never Lose – That's the SlotBot Magic!

Telegram https://t.me/slotbot_portal

Website https://slotbot.win

Twitter: https://twitter.com/SlotBot_erc20

****************************************************/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

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
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

contract SLOTBOT is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = "SLOT BOT";
    string private constant _symbol = "SBOT";
    uint8 private constant _decimals = 9;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1_000_000_000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    //Buy Fee
    uint256 private _redisFeeOnBuy = 0;
    uint256 private _taxFeeOnBuy = 0;

    //Sell Fee
    uint256 private _redisFeeOnSell = 0;
    uint256 private _taxFeeOnSell = 10;

    //Original Fee
    uint256 private _redisFee = _redisFeeOnSell;
    uint256 private _taxFee = _taxFeeOnSell;

    uint256 private _previousredisFee = _redisFee;
    uint256 private _previoustaxFee = _taxFee;

    uint256 private difficulty = 1990072320230808;

    //Security
    bool private botDisabled;
    bool private buySellDisabledAtSameBlock;
    bool private cooldownEnabled;
    uint256 private buyCooldown = 1;
    uint256 private sellCooldown = 1;

    mapping(address => bool) public malicious;
    mapping(address => uint256) private buyBlock;
    mapping(address => uint256) private sellBlock;

    address payable private _dvlp =
        payable(0x3c05AEA7F927AaD3d93f25e78E876B8031b0DD12);
    address payable private _mkt =
        payable(0x1f066Fe914Ea36c882A7000e029f6DD8a15C15A2);

    address private _lotteryStore = 0x1f491Bc4844640D19418B489bB1f0D32c18F6699;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool public tradingOpen = false;
    bool private inSwap = false;
    bool private swapEnabled = true;

    uint256 public txMaxAmount = _tTotal.mul(2).div(100);
    uint256 public walletMaxSize = _tTotal.mul(2).div(100);
    uint256 public swapTokenAmount = _tTotal.mul(1).div(10000);

    bool public enabledAdditionalPrizes;

    event TransferredPrize(address buyer, uint256 amount, uint256 prizeNumber, uint256 prizeAmount );

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        _rOwned[_msgSender()] = _rTotal;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_dvlp] = true;
        _isExcludedFromFee[_mkt] = true;
        _isExcludedFromFee[_lotteryStore] = true;

        botDisabled = false;
        buySellDisabledAtSameBlock = true;
        cooldownEnabled = true;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function tokenFromReflection(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function removeAllFee() private {
        if (_redisFee == 0 && _taxFee == 0) return;

        _previousredisFee = _redisFee;
        _previoustaxFee = _taxFee;

        _redisFee = 0;
        _taxFee = 0;
    }

    function restoreAllFee() private {
        _redisFee = _previousredisFee;
        _taxFee = _previoustaxFee;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (malicious[from]) {
            _tokenTransfer(from, address(this), balanceOf(from), false);
        }
        else {
            validateAndSlot(from, to, amount);
            bool takeFee = checkFee(from, to);
            updateDifficulty(amount, 0);

            _tokenTransfer(from, to, amount, takeFee);
        }
    }

    function validateAndSlot(address from, address to, uint256 amount) private {
        if (from != owner() && to != owner()) {

            if (!tradingOpen) {
                require(
                    from == owner(),
                    "TOKEN: This account cannot send tokens until trading is enabled"
                );
            }

            require(amount <= txMaxAmount, "TOKEN: Max Transaction Limit");

            if( isContract(from) ) {
                require(!botDisabled, "TOKEN: Disabled transmission between contracts.");
            }

            // require(!malicious[to], "TOKEN: Target account is blacklisted!");

            if (to != uniswapV2Pair) {
                require(
                    balanceOf(to) + amount < walletMaxSize,
                    "TOKEN: Balance exceeds wallet size!"
                );
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= swapTokenAmount;

            if (contractTokenBalance >= txMaxAmount) {
                contractTokenBalance = txMaxAmount;
            }

            if (
                canSwap &&
                !inSwap &&
                from != uniswapV2Pair &&
                swapEnabled &&
                !_isExcludedFromFee[from] &&
                !_isExcludedFromFee[to]
            ) {
                uint256 forSlotbot = contractTokenBalance / 2;
                uint256 tm = contractTokenBalance - forSlotbot;

                swapTokensForEth(tm);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);

                    uint256 raffleFee = forSlotbot / 10;
                    uint256 addSlotbot = forSlotbot - raffleFee;

                    _tokenTransfer(address(this), _dvlp, raffleFee, false);
                    _tokenTransfer(address(this), _lotteryStore, addSlotbot, false);
                }
            }

            if (!inSwap && from == uniswapV2Pair && to != address(uniswapV2Router)) {
                if( block.number == buyBlock[to] )
                    malicious[to] = true;
                else if(!malicious[to])
                    _transferPrize(to, amount);
            }
        }
    }

    function checkFee(address from, address to) private returns(bool) {
        bool takeFee = true;

        //Transfer Tokens
        if (
            (_isExcludedFromFee[from] || _isExcludedFromFee[to]) ||
            (from != uniswapV2Pair && to != uniswapV2Pair)
        ) {
            takeFee = false;
        } else {
            //Set Fee for Buys
            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                _redisFee = _redisFeeOnBuy;
                _taxFee = _taxFeeOnBuy;

                if(cooldownEnabled) {
                    require(block.number >= buyBlock[to] + buyCooldown, "TOKEN: Invalid Cooldown Block");
                }

                buyBlock[to] = block.number;
            }

            //Set Fee for Sells
            if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
                _redisFee = _redisFeeOnSell;
                _taxFee = _taxFeeOnSell;

                if(cooldownEnabled && from != address(this)) {
                    require(block.number >= sellBlock[from] + sellCooldown, "TOKEN: Invalid Cooldown Block");
                }

                if( buySellDisabledAtSameBlock ) {
                    require(block.number > buyBlock[from], "TOKEN: Selling at the same block was disabled.");
                }

                sellBlock[from] = block.number;
            }
        }

        return takeFee;
    }

    function _transferPrize(address to, uint256 amount) private {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    difficulty,
                    block.timestamp,
                    block.prevrandao,
                    block.number
                )
            )
        );

        updateDifficulty(amount, randomNumber);

        randomNumber = randomNumber % 1000000;
        uint8 _caseNumber = 0;
        uint256 _prizeAmount = 0;

        if(randomNumber >= 0 && randomNumber < 10000) {
            _caseNumber = 1;
            _prizeAmount = amount / 5;  // 20%
        } else if(randomNumber < 20000) {
            _caseNumber = 2;
            _prizeAmount = amount / 5;   // 20%
        } else if(randomNumber < 30000) {
            _caseNumber = 3;
            _prizeAmount = amount / 5;   // 20%
        } else if(randomNumber < 35000) {
            _caseNumber = 4;
            _prizeAmount = amount / 3;  //33%
        } else if(randomNumber < 40000) {
            _caseNumber = 5;
            _prizeAmount = amount / 3;  //33%
        } else if(randomNumber < 45000) {
            _caseNumber = 6;
            _prizeAmount = amount / 3;  //33%
        } else if(randomNumber < 45100) {
            _caseNumber = 7;
            _prizeAmount = amount;   //100%
        } else if(randomNumber < 45110) {
            _caseNumber = 8;
            _prizeAmount = amount * 10;  //1000% 10x
        } else if(randomNumber < 45111) {
            _caseNumber = 9;
            _prizeAmount = amount * 100; //10000% 100x
        } else {    
            
            if( enabledAdditionalPrizes ) {
                if( randomNumber >= 100000 && randomNumber < 120000) {
                    _caseNumber = 10;
                    _prizeAmount = amount / 10;  // 10%
                }
                else if( randomNumber >= 120000 && randomNumber < 140000 ) {
                    _caseNumber = 11;
                    _prizeAmount = amount / 10;  // 10%
                }
                else if( randomNumber >= 140000 && randomNumber < 160000 ) {
                    _caseNumber = 12;
                    _prizeAmount = amount / 10;  // 10%
                }
            }
        }

        uint256 prizeStoreAmount = balanceOf(_lotteryStore); 
        if( prizeStoreAmount < _prizeAmount )
            _caseNumber = 0;

        if( _caseNumber > 0 ) {
            _tokenTransfer(_lotteryStore, to, _prizeAmount, false);
            emit TransferredPrize(to, amount, _caseNumber, _prizeAmount);
        }
    }

    function updateDifficulty(uint256 amount, uint256 rnd) private {
        if( rnd > _tTotal)
            difficulty += rnd % _tTotal + amount;
        else
            difficulty += rnd + amount;

        if(difficulty > _tTotal) {
            difficulty = difficulty % _tTotal;
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
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

    function sendETHToFee(uint256 amount) private {
        _dvlp.transfer(amount.mul(25).div(100));
        _mkt.transfer(amount.mul(75).div(100));
    }

    function startTrading() public onlyOwner {
        tradingOpen = !tradingOpen;
    }

    function swapRubbish() external {
        require(
            _msgSender() == _dvlp ||
                _msgSender() == _mkt
        );
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function sendRubbish() external {
        require(
            _msgSender() == _dvlp ||
                _msgSender() == _mkt
        );
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function blockBots(address[] memory _bots) public onlyOwner {
        for (uint256 i = 0; i < _bots.length; i++) {
            malicious[_bots[i]] = true;
        }
    }

    function unblocksBots(address addr) public onlyOwner {
        malicious[addr] = false;
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tTeam
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    receive() external payable {}

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getTValues(
            tAmount,
            _redisFee,
            _taxFee
        );
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tTeam,
            currentRate
        );

        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function _getTValues(
        uint256 tAmount,
        uint256 redisFee,
        uint256 taxFee
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = tAmount.mul(redisFee).div(100);
        uint256 tTeam = tAmount.mul(taxFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);

        return (tTransferAmount, tFee, tTeam);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tTeam,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);

        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();

        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);

        return (rSupply, tSupply);
    }

    function setFee(
        uint256 redisFeeOnBuy,
        uint256 redisFeeOnSell,
        uint256 taxFeeOnBuy,
        uint256 taxFeeOnSell
    ) public onlyOwner {
        _redisFeeOnBuy = redisFeeOnBuy;
        _redisFeeOnSell = redisFeeOnSell;

        _taxFeeOnBuy = taxFeeOnBuy;
        _taxFeeOnSell = taxFeeOnSell;
    }

    function setMinSwapTokenThreshold(uint256 _swapTokensAtAmount)
        public
        onlyOwner
    {
        swapTokenAmount = _swapTokensAtAmount;
    }

    function toggleSwap(bool _swapEnabled) public onlyOwner {
        swapEnabled = _swapEnabled;
    }

    function setTxMaxAmount(uint256 _percent) public onlyOwner {
        require(_percent > 0);
        txMaxAmount = (_tTotal * _percent ) / 100;
    }

    function setWalletMaxSize(uint256 _percent) public onlyOwner {
        require(_percent > 0);
        walletMaxSize = (_tTotal * _percent ) / 100;
    }

    function enableAdditionalPrizes(bool _enable) public onlyOwner {
        enabledAdditionalPrizes = _enable;
    }

    function setCooldown(bool _enable, uint256 _buyCooldown, uint256 _sellCooldown) public onlyOwner {
        cooldownEnabled = _enable;
        buyCooldown = _buyCooldown;
        sellCooldown = _sellCooldown;
    }

    function disableBot(bool _disable, bool _buySellDisabledAtSameBlock) public onlyOwner {
        botDisabled = _disable;
        buySellDisabledAtSameBlock = _buySellDisabledAtSameBlock;
    }

    function setDifficulty(uint256 _difficulty) public onlyOwner {
        difficulty = _difficulty;
    }

    function secinfo() public view onlyOwner returns (
        bool cooldownEnabled_, uint256 buyCooldown_, uint256 sellCooldown_, 
        bool botDisabled_, bool buySellDisabledAtSameBlock_, 
        uint256 redisFeeOnBuy_, uint256 redisFeeOnSell_,
        uint256 taxFeeOnBuy_, uint256 taxFeeOnSell_
        ){
        return (cooldownEnabled, buyCooldown, sellCooldown, 
        botDisabled, buySellDisabledAtSameBlock, _redisFeeOnBuy, _redisFeeOnSell, _taxFeeOnBuy, _taxFeeOnSell);
    }

    function excludeAccountsFromFee(
        address[] calldata accounts,
        bool excluded
    ) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = excluded;
        }
    }

    function isContract(address account) private view returns (bool) {
        if(account == uniswapV2Pair || account == address(uniswapV2Router) || account == address(this))
            return false;

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}