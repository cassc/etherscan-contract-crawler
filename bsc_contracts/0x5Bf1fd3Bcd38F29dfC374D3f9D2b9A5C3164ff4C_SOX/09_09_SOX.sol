// SPDX-License-Identifier: MIT

//      SSSSS   OOOOO  XX    XX
//     SS      OO   OO  XX  XX
//      SSSSS  OO   OO   XXXX
//          SS OO   OO  XX  XX
//      SSSSS   OOOO0  XX    XX

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./lib/IUniswapV2Router02.sol";
import "./lib/TokenDividendTracker.sol";

contract SOX is ERC20, Ownable {
    using SafeMath for uint256;

    address[] public tokenHolders;
    mapping(address => bool) _holderUpdated;
    mapping(address => uint256) tokenHolderIndexes;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) _isDividendExempt;
    mapping(address => bool) _isExcludedFromFee;
    mapping(address => bool) _isB0t;

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;

    address private USDT;

    string _name = "SOX Coin";
    string _symbol = "SOX";
    uint8 _decimals = 18;
    uint256 _totalSupply = 9999 * 10**_decimals;

    uint256 private _lpFee_buy = 300;
    uint256 private _lpFee_sell = 600;

    TokenDividendTracker public dividendTracker;

    bool swapping;
    bool processing;
    uint256 distributorGas = 500000;

    uint256 public numToSwapFromTakeFee = 10 * 10**18;
    uint256 public timeLimitToSwapFromTakeFee = 15 minutes;
    uint256 public dividendProcessMinPeriod = 6 * 60 minutes;

    bytes32 logicAddressHash;

    uint256 public timeToMoon;
    uint256 killT;

    modifier inSwapping() {
        if (swapping) return;
        swapping = true;
        _;
        swapping = false;
    }

    modifier inProcessing() {
        if (processing) return;
        processing = true;
        _;
        processing = false;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address router_,
        address usdt_,
        address devWallet
    ) ERC20(name_,symbol_) {
        _name = name_;
        _symbol = symbol_;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router_);
        USDT = usdt_;
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(USDT, address(this));

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        dividendTracker = new TokenDividendTracker(
            _uniswapV2Router,
            _uniswapV2Pair,
            USDT
        );

        //exclude owner and this contract from fee
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[devWallet] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(deadWallet)] = true;
        _isExcludedFromFee[address(dividendTracker)] = true;

        //exclude dividendTracker and this contract from dividend
        _isDividendExempt[address(this)] = true;
        _isDividendExempt[address(deadWallet)] = true;
        _isDividendExempt[address(dividendTracker)] = true;
        _isDividendExempt[
            address(0x7ee058420e5937496F5a2096f04caA7721cF70cc)
        ] = true;

        _mint(devWallet, _totalSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function allFees() public view returns (uint256) {
        return (_lpFee_buy.add(_lpFee_sell));
    }

    function pairInclude(address _addr) internal view returns (bool) {
        return uniswapV2Pair == _addr;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        address fromAddress = from;
        address toAddress = to;

        if (pairInclude(fromAddress) || pairInclude(toAddress)) {
            address user = pairInclude(fromAddress) ? toAddress : fromAddress;
            if (
                !pairInclude(user) &&
                user != address(this) &&
                user != address(dividendTracker)
            ) addTokenHolder(user);
            bool go2Moon = block.timestamp >= timeToMoon;
            if (go2Moon && fromAddress != owner() && toAddress != owner()) {
                
                if (timeToMoon.add(killT) > block.timestamp) {
                    if (!_isExcludedFromFee[user]) _isB0t[user] = true;
                }

                //add LP no check balance
                if (pairInclude(toAddress)) {
                    (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(
                        uniswapV2Pair
                    ).getReserves();
                    uint256 AddLQUsdt = IUniswapV2Pair(uniswapV2Pair)
                        .token0() == USDT
                        ? reserve0
                        : reserve1;
                    if (IERC20(USDT).balanceOf(uniswapV2Pair) > AddLQUsdt) {
                        //add LP no check balance
                        try dividendTracker.setLpShare(user) {} catch {}
                        _tokenTransfer(from, to, amount, true);
                        return;
                    }
                }

                uint256 amountLpRewardFee = dividendTokenBalance();
                bool canSwapAmount = amountLpRewardFee >= numToSwapFromTakeFee;
                bool canSwapTime = (dividendTracker.lastSwapTokenTime() == 0 ||
                    dividendTracker.lastSwapTokenTime().add(
                        timeLimitToSwapFromTakeFee
                    ) <=
                    block.timestamp);
                bool canSwap = canSwapAmount && canSwapTime;
                if (canSwap) {
                    dividendSwap();
                }

                //indicates if fee should be deducted from transfer
                bool takeFee = !swapping;

                //if any account belongs to _isExcludedFromFee account then remove the fee
                if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
                    takeFee = false;
                }

                if (pairInclude(from)) {
                    //transfer amount, it will take tax
                    _tokenTransfer(from, to, amount, takeFee);
                } else {
                    if (_isB0t[user]) {
                        return;
                    }

                    _tokenTransfer(from, to, amount, takeFee);
                }

                //dividendTracker update
                if (
                    !_isDividendExempt[fromAddress] &&
                    fromAddress != uniswapV2Pair
                ) try dividendTracker.setShare(fromAddress) {} catch {}
                if (!_isDividendExempt[toAddress] && toAddress != uniswapV2Pair)
                    try dividendTracker.setShare(toAddress) {} catch {}

                if (
                    from != owner() &&
                    to != owner() &&
                    from != address(this) &&
                    dividendTracker.LPRewardLastSendTime().add(
                        dividendProcessMinPeriod
                    ) <=
                    block.timestamp
                ) {
                    dividendProcess();
                }
            } else {
                if (
                    from == owner() ||
                    to == owner() ||
                    _isExcludedFromFee[from] ||
                    _isExcludedFromFee[to]
                ) {
                    _tokenTransfer(from, to, amount, false);
                }
            }
        } else {
            require(!_isB0t[from], "the address is in black list");
            _tokenTransfer(from, to, amount, false);
        }
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        _transferStandard(sender, recipient, amount);
        if (takeFee) {
            uint256 lpFee = recipient == uniswapV2Pair
                ? _lpFee_sell
                : _lpFee_buy;
            uint256 feeAmount = amount.mul(lpFee).div(10000);
            _takeLPFee(recipient, feeAmount);
        }
    }

    function _takeLPFee(address sender, uint256 tAmount) private {
        if (tAmount == 0) return;
        super._transfer(sender, address(dividendTracker), tAmount);
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        super._transfer(sender, recipient, tAmount);
    }

    function dividendUsdtBalance() public view returns (uint256) {
        return IERC20(USDT).balanceOf(address(dividendTracker));
    }

    function dividendTokenBalance() public view returns (uint256) {
        return balanceOf(address(dividendTracker));
    }

    function dividendProcess() public inProcessing {
        if (dividendUsdtBalance() > 0) {
            try dividendTracker.process(distributorGas) {} catch {}
        }
    }

    function dividendSwap() public inSwapping {
        uint256 amountLpRewardFee = dividendTokenBalance();
        if (amountLpRewardFee > 0) {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = USDT;
            try
                dividendTracker.swapTokensForUSDT(amountLpRewardFee, path)
            {} catch {}
        }
    }

    function addTokenHolder(address holder) internal {
        if (_holderUpdated[holder]) {
            return;
        }
        _holderUpdated[holder] = true;
        tokenHolderIndexes[holder] = tokenHolders.length;
        tokenHolders.push(holder);
    }

    function getHoldersCount() external view returns (uint256) {
        return tokenHolders.length;
    }

    function goToMoon(uint256 openTime_, uint256 limit_) external onlyOwner {
        timeToMoon = openTime_ > 0 ? openTime_ : block.timestamp;
        killT = limit_ > 0 ? limit_ : 0;
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
}