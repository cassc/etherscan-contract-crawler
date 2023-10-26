// SPDX-License-Identifier: MIT

// Holy Bread - $BREAD
//
// Ancient Recipe, Modern Rebase
//
// https://holybread.xyz/
// https://twitter.com/HolyBreadCoin
// https://t.me/BreadPortal

pragma solidity ^0.8.19;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Bread is IERC20, Ownable {
    using SafeMath for uint256;

    /* -------------------------------------------------------------------------- */
    /*                                   events                                   */
    /* -------------------------------------------------------------------------- */
    event RequestRebase(bool increaseSupply, uint256 amount);
    event Rebase(uint256 indexed time, uint256 totalSupply);
    event RemovedLimits();
    event Log(string message, uint256 value);
    event ErrorCaught(string reason);

    /* -------------------------------------------------------------------------- */
    /*                                  constants                                 */
    /* -------------------------------------------------------------------------- */
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;
    uint256 constant NOMINAL_TAX = 3;
    uint256 constant MINIMAL_TAX = 1;

    uint256 private constant MAX_SUPPLY = ~uint128(0);
    uint256 private constant MIN_SUPPLY = 1 ether;
    uint256 public constant INITIAL_BREADS_SUPPLY = 100_000 ether;
    uint256 public DELTA_SUPPLY = INITIAL_BREADS_SUPPLY;

    // TOTAL_CRUMBS is a multiple of INITIAL_BREADS_SUPPLY so that _crumbsPerBread is an integer.
    // Use the highest value that fits in a uint256 for max granularity.
    uint256 public constant TOTAL_CRUMBS = type(uint256).max - (type(uint256).max % INITIAL_BREADS_SUPPLY);
    uint256 constant public zero = uint256(0);

    /* -------------------------------------------------------------------------- */
    /*                                   states                                   */
    /* -------------------------------------------------------------------------- */

    address public SWAP_ROUTER_ADR = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 public SWAP_ROUTER;
    address public immutable SWAP_PAIR;

    uint256 public _totalSupply;
    uint256 public _crumbsPerBread;
    uint256 private crumbsSwapThreshold = (TOTAL_CRUMBS / 100000 * 25);

    address private oracleWallet;
    uint256 public vatBuy;
    uint256 public vatSell;

    bool public limitRebase = true;
    bool public limitRebasePct = true;
    bool public giveBread = false;
    bool public swapEnabled = false;
    bool public enableUpdateTax = true;
    bool public syncLP = true;
    bool inSwap;
    uint256 private lastRebaseTime = 0;
    uint256 private limitRebaseRate = 10;
    uint256 private limitDebaseRate = 5;
    uint256 private limitDayRebase = 100;
    uint256 private limitDayDebase = 65;
    uint256 private limitNightRebase = 60;
    uint256 private limitNightDebase = 65;
    uint256 private transactionCount = 0;
    uint256 public txToSwitchTax;

    uint256 public buyToRebase = 0;
    uint256 public sellToRebase = 0;

    string _name = "Holy Bread";
    string _symbol = "BREAD";

    bool public dayMode = true;

    mapping(address => uint256) public _crumbBalances;
    mapping (address => mapping (address => uint256)) public _allowedBreads;
    mapping (address => bool) public isWhitelisted;

    /* -------------------------------------------------------------------------- */
    /*                                  modifiers                                 */
    /* -------------------------------------------------------------------------- */
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleWallet, "Not oracle");
        _;
    }

	constructor(address _oracle, address _bw) {
        // create uniswap pair
        SWAP_ROUTER = IUniswapV2Router02(SWAP_ROUTER_ADR);
        address _uniswapPair =
            IUniswapV2Factory(SWAP_ROUTER.factory()).createPair(address(this), SWAP_ROUTER.WETH());
        SWAP_PAIR = _uniswapPair;

        _allowedBreads[address(this)][address(SWAP_ROUTER)] = type(uint256).max;
        _allowedBreads[address(this)][msg.sender] = type(uint256).max;
        _allowedBreads[address(msg.sender)][address(SWAP_ROUTER)] = type(uint256).max;

        oracleWallet = _oracle;
        vatBuy = 20;
        vatSell = 20;
        txToSwitchTax = 15;

        isWhitelisted[msg.sender] = true;
        isWhitelisted[address(this)] = true;
        isWhitelisted[SWAP_ROUTER_ADR] = true;
        isWhitelisted[oracleWallet] = true;
        isWhitelisted[ZERO] = true;
        isWhitelisted[DEAD] = true;

        _totalSupply = INITIAL_BREADS_SUPPLY;
        _crumbsPerBread = TOTAL_CRUMBS.div(_totalSupply);

        _crumbBalances[_bw] = TOTAL_CRUMBS.div(100).mul(50);
        _crumbBalances[msg.sender] = TOTAL_CRUMBS.div(100).mul(50);

        emit Transfer(address(0), _bw, balanceOf(_bw));
        emit Transfer(address(0), msg.sender, balanceOf(msg.sender));
	}

    /* -------------------------------------------------------------------------- */
    /*                                    views                                   */
    /* -------------------------------------------------------------------------- */
    function totalSupply() public view returns (uint256) {
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

    function balanceOf(address holder) public view returns (uint256) {
        return _crumbBalances[holder].div(_crumbsPerBread);
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

    function setSwapBackSettings(bool _enabled, uint256 _pt) external onlyOwner {
        swapEnabled = _enabled;
        crumbsSwapThreshold = (TOTAL_CRUMBS * _pt) / 100000;
    }

    function enableBreadExchange() external onlyOwner {
        require(!giveBread, "Token launched");
        giveBread = true;
        swapEnabled = true;
    }

    function whitelistWallet(address _address, bool _isWhitelisted) external onlyOwner {
        isWhitelisted[_address] = _isWhitelisted;
    }

    function setTxToSwitchTax(uint256 _c) external  onlyOwner {
        txToSwitchTax = _c;
    }

    function setToFinalTax() external onlyOwner {
        enableUpdateTax = false;
        vatBuy = NOMINAL_TAX;
        vatSell = NOMINAL_TAX;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   oracle                                   */
    /* -------------------------------------------------------------------------- */
    function switchMode() external onlyOracle {
        dayMode = !dayMode;
    }

    function setRebaseLimit(bool _l) external  onlyOracle {
        limitRebase = _l;
    }

    function setRebaseLimit(bool _l, bool _p) external  onlyOracle {
        limitRebase = _l;
        limitRebasePct = _p;
    }

    function setSyncLP(bool _s) external  onlyOracle {
        syncLP = _s;
    }

    function setRebaseLimitRate(uint256 _r, uint256 _dr, uint256 _nr) external  onlyOracle {
        limitRebaseRate = _r;
        limitDayRebase = _dr;
        limitNightRebase = _nr;
    }

    function setDebaseLimitRate(uint256 _r, uint256 _dd, uint256 _nd) external  onlyOracle {
        limitDebaseRate = _r;
        limitDayDebase = _dd;
        limitNightDebase = _nd;
    }

    function setToMinimalTax() external onlyOracle {
        enableUpdateTax = false;
        vatBuy = MINIMAL_TAX;
        vatSell = MINIMAL_TAX;
    }

    function canRebase() public view returns (bool) {
        return sellToRebase != buyToRebase;
    }

    function rebase() external onlyOracle {
        uint256 currentTime = block.timestamp;
        uint256 newSupply = _totalSupply;
        uint256 rebaseDelta = 0;
        bool increaseSupply = false;
        if (sellToRebase > buyToRebase){
            rebaseDelta = sellToRebase - buyToRebase;
        } else if (buyToRebase > sellToRebase) {
            rebaseDelta = buyToRebase - sellToRebase;
            increaseSupply = true;
        } else {
            emit Log("same amount, no need to rebase", 0);
            return;
        }
        if (!dayMode) {
            increaseSupply = !increaseSupply;
        }

        if (currentTime >= lastRebaseTime + 1 days) {
            lastRebaseTime = currentTime;
            DELTA_SUPPLY = newSupply;
        }

        if (increaseSupply) {
            if (limitRebasePct) {
                if (dayMode) {
                    if (rebaseDelta > DELTA_SUPPLY.mul(limitDayRebase).div(1000)) {
                        rebaseDelta = DELTA_SUPPLY.mul(limitDayRebase).div(1000);
                    }
                } else {
                    if (rebaseDelta > DELTA_SUPPLY.mul(limitNightRebase).div(1000)) {
                        rebaseDelta = DELTA_SUPPLY.mul(limitNightRebase).div(1000);
                    }
                }
            }
            if (limitRebase && _totalSupply.add(rebaseDelta) > DELTA_SUPPLY.mul(limitRebaseRate)){
                newSupply = DELTA_SUPPLY.mul(limitRebaseRate);
            } else {
                newSupply = _totalSupply.add(rebaseDelta);
            }
        } else { 
            if (limitRebasePct) {
                if (dayMode) {
                    if (rebaseDelta > DELTA_SUPPLY.mul(limitDayDebase).div(1000)) {
                        rebaseDelta = DELTA_SUPPLY.mul(limitDayDebase).div(1000);
                    }
                } else {
                    if (rebaseDelta > DELTA_SUPPLY.mul(limitNightDebase).div(1000)) {
                        rebaseDelta = DELTA_SUPPLY.mul(limitNightDebase).div(1000);
                    }
                }
            }
            if (limitRebase && _totalSupply.sub(rebaseDelta) < DELTA_SUPPLY.div(limitDebaseRate)){
                newSupply = DELTA_SUPPLY.div(limitDebaseRate);
            } else {
                newSupply = _totalSupply.sub(rebaseDelta);
            }
        }

        if (newSupply > MAX_SUPPLY) {
            newSupply = MAX_SUPPLY;
        }

        if (newSupply < MIN_SUPPLY) {
            newSupply = MIN_SUPPLY;
        }

        _totalSupply = newSupply;
        _crumbsPerBread = TOTAL_CRUMBS.div(_totalSupply);
        sellToRebase = 0;
        buyToRebase = 0;

        if (syncLP){
            lpSync();
        }

        emit Rebase(currentTime, _totalSupply);
    }
    

    /* -------------------------------------------------------------------------- */
    /*                                   private                                  */
    /* -------------------------------------------------------------------------- */
    function updateTaxes() internal {
        if (vatSell > NOMINAL_TAX) {
            transactionCount += 1;
        }
        if (transactionCount == txToSwitchTax) {
            vatBuy = 10;
            vatSell = 10;
        } else if (transactionCount == txToSwitchTax.mul(2)) {
            vatBuy = 5;
            vatSell = 5;
        } else if (transactionCount >= txToSwitchTax.mul(3) && vatSell > NOMINAL_TAX) {
            vatBuy = NOMINAL_TAX;
            vatSell = NOMINAL_TAX;
            enableUpdateTax = false;
            emit RemovedLimits();
        }
    }

    function lpSync() internal {
        IUniswapV2Pair _pair = IUniswapV2Pair(SWAP_PAIR);
        try _pair.sync() {} catch {}
    }

    /* -------------------------------------------------------------------------- */
    /*                                    ERC20                                   */
    /* -------------------------------------------------------------------------- */
    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function allowance(address owner_, address spender) public view returns (uint256) {
        return _allowedBreads[owner_][spender];
    }
    function approve(address spender, uint256 value) public returns (bool) {
        _allowedBreads[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _allowedBreads[msg.sender][spender] = _allowedBreads[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedBreads[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 oldValue = _allowedBreads[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedBreads[msg.sender][spender] = 0;
        } else {
            _allowedBreads[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedBreads[msg.sender][spender]);
        return true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowedBreads[sender][msg.sender] != type(uint256).max) {
            require(_allowedBreads[sender][msg.sender] >= amount, "ERC20: insufficient allowance");
            _allowedBreads[sender][msg.sender] = _allowedBreads[sender][msg.sender] - amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(sender != DEAD, "Please use a good address");
        require(sender != ZERO, "Please use a good address");

        uint256 crumbAmount = amount.mul(_crumbsPerBread);
        require(_crumbBalances[sender] >= crumbAmount, "Insufficient Balance");

        if(!inSwap && !isWhitelisted[sender] && !isWhitelisted[recipient]){
            require(giveBread, "Trading not live");
            if (_shouldSwapBack(recipient)){
                try this.swapBack(){} catch {}
            }

            uint256 vatAmount = 0;
            if(sender == SWAP_PAIR){
                emit RequestRebase(true, amount);
                buyToRebase += amount;
                vatAmount = crumbAmount.mul(vatBuy).div(100);
            }
            else if (recipient == SWAP_PAIR) {
                emit RequestRebase(false, amount);
                sellToRebase += amount;
                vatAmount = crumbAmount.mul(vatSell).div(100);
            }

            if(vatAmount > 0){
                _crumbBalances[sender] -= vatAmount;
                _crumbBalances[address(this)] += vatAmount;
                emit Transfer(sender, address(this), vatAmount.div(_crumbsPerBread));
                crumbAmount -= vatAmount;

                if (enableUpdateTax) {
                    updateTaxes();
                }
            }
        }

        _crumbBalances[sender] = _crumbBalances[sender].sub(crumbAmount);
        _crumbBalances[recipient] = _crumbBalances[recipient].add(crumbAmount);

        emit Log("Amount transfered", crumbAmount.div(_crumbsPerBread));

        emit Transfer(sender, recipient, crumbAmount.div(_crumbsPerBread));

        return true;
    }

    function _shouldSwapBack(address recipient) internal view returns (bool) {
        return recipient == SWAP_PAIR && !inSwap && swapEnabled && balanceOf(address(this)) >= crumbsSwapThreshold.div(_crumbsPerBread);
    }

    function swapBack() public swapping {
        uint256 contractBalance = balanceOf(address(this));
        if(contractBalance == 0){
            return;
        }

        if(contractBalance > crumbsSwapThreshold.div(_crumbsPerBread).mul(20)){
            contractBalance = crumbsSwapThreshold.div(_crumbsPerBread).mul(20);
        }

        swapTokensForETH(contractBalance);
    }

    function swapTokensForETH(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(SWAP_ROUTER.WETH());

        SWAP_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(oracleWallet),
            block.timestamp
        );
    }

    receive() external payable {}
}