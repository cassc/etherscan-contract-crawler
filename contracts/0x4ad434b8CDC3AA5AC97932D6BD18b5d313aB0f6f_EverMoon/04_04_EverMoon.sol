// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// https://twitter.com/EverMoonERC
// https://t.me/EverMoonERC

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address UNISWAP_V2_PAIR);
}

contract EverMoon is IERC20, Ownable {
    /* -------------------------------------------------------------------------- */
    /*                                   events                                   */
    /* -------------------------------------------------------------------------- */
    event Reflect(uint256 amountReflected, uint256 newTotalProportion);

    /* -------------------------------------------------------------------------- */
    /*                                  constants                                 */
    /* -------------------------------------------------------------------------- */
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;

    uint256 constant MAX_FEE = 10;

    /* -------------------------------------------------------------------------- */
    /*                                   states                                   */
    /* -------------------------------------------------------------------------- */
    IUniswapV2Router02 public constant UNISWAP_V2_ROUTER =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public immutable UNISWAP_V2_PAIR;

    struct Fee {
        uint8 reflection;
        uint8 marketing;
        uint8 lp;
        uint8 buyback;
        uint8 burn;
        uint128 total;
    }

    string _name = "EverMoon";
    string _symbol = "EVERMOON";

    uint256 _totalSupply = 1_000_000_000 ether;
    uint256 public _maxTxAmount = _totalSupply * 2 / 100;

    /* rOwned = ratio of tokens owned relative to circulating supply (NOT total supply, since circulating <= total) */
    mapping(address => uint256) public _rOwned;
    uint256 public _totalProportion = _totalSupply;

    mapping(address => mapping(address => uint256)) _allowances;

    bool public limitsEnabled = true;
    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isTxLimitExempt;

    Fee public buyFee = Fee({reflection: 1, marketing: 1, lp: 1, buyback: 1, burn: 1, total: 5});
    Fee public sellFee = Fee({reflection: 1, marketing: 1, lp: 1, buyback: 1, burn: 1, total: 5});

    address private marketingFeeReceiver;
    address private lpFeeReceiver;
    address private buybackFeeReceiver;

    bool public claimingFees = true;
    uint256 public swapThreshold = (_totalSupply * 2) / 1000;
    bool inSwap;
    mapping(address => bool) public blacklists;

    /* -------------------------------------------------------------------------- */
    /*                                  modifiers                                 */
    /* -------------------------------------------------------------------------- */
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    /* -------------------------------------------------------------------------- */
    /*                                 constructor                                */
    /* -------------------------------------------------------------------------- */
    constructor() {
        // create uniswap pair
        address _uniswapPair =
            IUniswapV2Factory(UNISWAP_V2_ROUTER.factory()).createPair(address(this), UNISWAP_V2_ROUTER.WETH());
        UNISWAP_V2_PAIR = _uniswapPair;

        _allowances[address(this)][address(UNISWAP_V2_ROUTER)] = type(uint256).max;
        _allowances[address(this)][tx.origin] = type(uint256).max;

        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[address(UNISWAP_V2_ROUTER)] = true;
        isTxLimitExempt[_uniswapPair] = true;
        isTxLimitExempt[tx.origin] = true;
        isFeeExempt[tx.origin] = true;

        marketingFeeReceiver = 0xeEA122Ad5f9c02fa3Bec08115E7CDb4D65142C81;
        lpFeeReceiver = 0x31D650bdE669fFcd5A7E1745D6E8306c8100E520;
        buybackFeeReceiver = 0xF07B6322A5eF6297F10eDE3dbc6ce0612dA9875D;

        _rOwned[tx.origin] = _totalSupply;
        emit Transfer(address(0), tx.origin, _totalSupply);
    }

    receive() external payable {}

    /* -------------------------------------------------------------------------- */
    /*                                    ERC20                                   */
    /* -------------------------------------------------------------------------- */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            require(_allowances[sender][msg.sender] >= amount, "ERC20: insufficient allowance");
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    /* -------------------------------------------------------------------------- */
    /*                                    views                                   */
    /* -------------------------------------------------------------------------- */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function tokensToProportion(uint256 tokens) public view returns (uint256) {
        return tokens * _totalProportion / _totalSupply;
    }

    function tokenFromReflection(uint256 proportion) public view returns (uint256) {
        return proportion * _totalSupply / _totalProportion;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - balanceOf(DEAD) - balanceOf(ZERO);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   owners                                   */
    /* -------------------------------------------------------------------------- */
    function clearStuckBalance() external onlyOwner {
        (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    function clearStuckToken() external onlyOwner {
        _transferFrom(address(this), msg.sender, balanceOf(address(this)));
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        claimingFees = _enabled;
        swapThreshold = _amount;
    }

    function changeFees(
        uint8 reflectionFeeBuy,
        uint8 marketingFeeBuy,
        uint8 lpFeeBuy,
        uint8 buybackFeeBuy,
        uint8 burnFeeBuy,
        uint8 reflectionFeeSell,
        uint8 marketingFeeSell,
        uint8 lpFeeSell,
        uint8 buybackFeeSell,
        uint8 burnFeeSell
    ) external onlyOwner {
        uint128 __totalBuyFee = reflectionFeeBuy + marketingFeeBuy + lpFeeBuy + buybackFeeBuy + burnFeeBuy;
        uint128 __totalSellFee = reflectionFeeSell + marketingFeeSell + lpFeeSell + buybackFeeSell + burnFeeSell;

        require(__totalBuyFee <= MAX_FEE, "Buy fees too high");
        require(__totalSellFee <= MAX_FEE, "Sell fees too high");

        buyFee = Fee({
            reflection: reflectionFeeBuy,
            marketing: reflectionFeeBuy,
            lp: reflectionFeeBuy,
            buyback: reflectionFeeBuy,
            burn: burnFeeBuy,
            total: __totalBuyFee
        });

        sellFee = Fee({
            reflection: reflectionFeeSell,
            marketing: reflectionFeeSell,
            lp: reflectionFeeSell,
            buyback: reflectionFeeSell,
            burn: burnFeeSell,
            total: __totalSellFee
        });
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setFeeReceivers(address m_, address lp_, address b_) external onlyOwner {
        marketingFeeReceiver = m_;
        lpFeeReceiver = lp_;
        buybackFeeReceiver = b_;
    }

    function setMaxTxBasisPoint(uint256 p_) external onlyOwner {
        _maxTxAmount = _totalSupply * p_ / 10000;
    }

    function setLimitsEnabled(bool e_) external onlyOwner {
        limitsEnabled = e_;
    }

    function blacklist(address _address, bool _isBlacklisting) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   private                                  */
    /* -------------------------------------------------------------------------- */
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(!blacklists[recipient] && !blacklists[sender], "Blacklisted");

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (limitsEnabled && !isTxLimitExempt[sender] && !isTxLimitExempt[recipient]) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        if (_shouldSwapBack()) {
            _swapBack();
        }

        uint256 proportionAmount = tokensToProportion(amount);
        require(_rOwned[sender] >= proportionAmount, "Insufficient Balance");
        _rOwned[sender] = _rOwned[sender] - proportionAmount;

        uint256 proportionReceived = _shouldTakeFee(sender, recipient)
            ? _takeFeeInProportions(sender == UNISWAP_V2_PAIR ? true : false, sender, proportionAmount)
            : proportionAmount;
        _rOwned[recipient] = _rOwned[recipient] + proportionReceived;

        emit Transfer(sender, recipient, tokenFromReflection(proportionReceived));
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        uint256 proportionAmount = tokensToProportion(amount);
        require(_rOwned[sender] >= proportionAmount, "Insufficient Balance");
        _rOwned[sender] = _rOwned[sender] - proportionAmount;
        _rOwned[recipient] = _rOwned[recipient] + proportionAmount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _takeFeeInProportions(bool buying, address sender, uint256 proportionAmount) internal returns (uint256) {
        Fee memory __buyFee = buyFee;
        Fee memory __sellFee = sellFee;

        uint256 proportionFeeAmount =
            buying == true ? proportionAmount * __buyFee.total / 100 : proportionAmount * __sellFee.total / 100;

        // reflect
        uint256 proportionReflected = buying == true
            ? proportionFeeAmount * __buyFee.reflection / __buyFee.total
            : proportionFeeAmount * __sellFee.reflection / __sellFee.total;

        _totalProportion = _totalProportion - proportionReflected;

        // take fees
        uint256 _proportionToContract = proportionFeeAmount - proportionReflected;
        if (_proportionToContract > 0) {
            _rOwned[address(this)] = _rOwned[address(this)] + _proportionToContract;

            emit Transfer(sender, address(this), tokenFromReflection(_proportionToContract));
        }
        emit Reflect(proportionReflected, _totalProportion);
        return proportionAmount - proportionFeeAmount;
    }

    function _shouldSwapBack() internal view returns (bool) {
        return msg.sender != UNISWAP_V2_PAIR && !inSwap && claimingFees && balanceOf(address(this)) >= swapThreshold;
    }

    function _swapBack() internal swapping {
        Fee memory __sellFee = sellFee;

        uint256 __swapThreshold = swapThreshold;
        uint256 amountToBurn = __swapThreshold * __sellFee.burn / __sellFee.total;
        uint256 amountToSwap = __swapThreshold - amountToBurn;
        approve(address(UNISWAP_V2_ROUTER), amountToSwap);

        // burn
        _transferFrom(address(this), DEAD, amountToBurn);

        // swap
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UNISWAP_V2_ROUTER.WETH();

        UNISWAP_V2_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap, 0, path, address(this), block.timestamp
        );

        uint256 amountETH = address(this).balance;

        uint256 totalSwapFee = __sellFee.total - __sellFee.reflection - __sellFee.burn;
        uint256 amountETHMarketing = amountETH * __sellFee.marketing / totalSwapFee;
        uint256 amountETHLP = amountETH * __sellFee.lp / totalSwapFee;
        uint256 amountETHBuyback = amountETH * __sellFee.buyback / totalSwapFee;

        // send
        (bool tmpSuccess,) = payable(marketingFeeReceiver).call{value: amountETHMarketing}("");
        (tmpSuccess,) = payable(lpFeeReceiver).call{value: amountETHLP}("");
        (tmpSuccess,) = payable(buybackFeeReceiver).call{value: amountETHBuyback}("");
    }

    function _shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }
}