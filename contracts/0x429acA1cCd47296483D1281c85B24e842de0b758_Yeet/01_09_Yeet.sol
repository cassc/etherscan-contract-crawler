// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./dependencies/SafeMath.sol";
import "./dependencies/Clones.sol";
import "./dependencies/Address.sol";

import "./dependencies/IUniswapV2Factory.sol";
import "./dependencies/IUniswapV2Router02.sol";
import "./dependencies/IERC20Extended.sol";
import "./dependencies/Auth.sol";
import "./dependencies/BaseToken.sol";

contract Yeet is IERC20Extended, Auth, BaseToken {
    using SafeMath for uint256;
    using Address for address;
    using Address for address payable;

    uint256 public constant VERSION = 2;

    event taxSwapped(uint256 amountIn, uint256 amountOut);

    address private constant DEAD = address(0xdead);
    address private constant ZERO = address(0);
    address public treasuryAddress;
    uint256 private gracePeriod = 5 minutes;
    uint256 private gracePeriodEnd;
    uint8 private constant _decimals = 18;

    string public constant _name = "Yeet";
    string public constant _symbol = "YEET";
    uint256 public constant _totalSupply = 420_069_000 * 10**18;

    IUniswapV2Router02 public router;
    IUniswapV2Factory public factory;
    address public pair;

    // [69,69,10000]
    uint256 public buyingFee = 69; // 0.69%
    uint256 public sellingFee = 69; // 0.69%
    uint256 public feeDenominator; // default: 10000

    bool public swapEnabled;
    uint256 public swapThreshold;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public isFeeExempt;

    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(
        address factory_,
        address router_,
        uint256[3] memory feeSettings_
    ) payable Auth(msg.sender) {
        gracePeriodEnd = block.timestamp + gracePeriod;

        _initializeFees(feeSettings_);

        swapEnabled = true;
        swapThreshold = _totalSupply / 100000; // 0.001% of total supply (4_200 YEET)
        factory = IUniswapV2Factory(factory_);
        router = IUniswapV2Router02(router_);
        pair = factory.createPair(address(this), router.WETH());

        isFeeExempt[msg.sender] = true;
        _allowances[address(this)][address(router)] = _totalSupply;
        _allowances[address(this)][address(pair)] = _totalSupply;
        treasuryAddress = msg.sender;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);

        emit TokenCreated(
            msg.sender,
            address(this),
            TokenType.antiBotStandard,
            VERSION
        );

    }

    function _initializeFees(uint256[3] memory feeSettings_) internal {
        _setFees(
            feeSettings_[0], // buyingFee
            feeSettings_[1], // sellingFee
            feeSettings_[2] // feeDenominator
        );
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
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
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
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
        if (_allowances[sender][msg.sender] != _totalSupply) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (shouldSwapToETH()) {
            swapToETH();
        }

        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );

        uint256 amountReceived = shouldTakeFee(sender)
            ? takeFee(sender, recipient, amount)
            : amount;

        if(shouldTakeFee(sender) && onGracePeriod()){
            // Holders Control during first hour
            if(recipient != pair && _balances[recipient].add(amount) >= (_totalSupply.mul(50).div(10000))){
                revert("You cannot hold more than 0.50% of the supply during the grace period");
            }
        }

        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender] && (sellingFee > 0 || buyingFee > 0);
    }

    function getTradingFee(bool selling) public view returns (uint256) {
        if(selling){
            if(onGracePeriod()){
                return 9000; // 90% of selling fee during grace period
            }
            return sellingFee;
        }
        return buyingFee;
    }

    function takeFee(
        address sender,
        address receiver,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTradingFee(receiver == pair)).div(
            feeDenominator
        );

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function shouldSwapToETH() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            swapEnabled &&
            !onGracePeriod() &&
            _balances[address(this)] >= swapThreshold;
    }

    function onGracePeriod() internal view returns (bool) {
        return block.timestamp < gracePeriodEnd;
    }

    function swapToETH() internal swapping {
        uint256 amountToSwap = swapThreshold;
        if(_balances[address(this)] > (100 * swapThreshold)){
            amountToSwap = swapThreshold * 50;
        }else {
            amountToSwap = _balances[address(this)];
        }

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance;
        payable(treasuryAddress).transfer(amountETH);
        emit taxSwapped(amountToSwap, amountETH);
    }

    function setFees(
        uint256 _buyFee,
        uint256 _sellFee,
        uint256 _feeDenominator
    ) public authorized {
        _setFees(
            _buyFee,
            _sellFee,
            _feeDenominator
        );
    }

    function _setFees(
        uint256 _buyFee,
        uint256 _sellFee,
        uint256 _feeDenominator
    ) internal {
        buyingFee = _buyFee;
        sellingFee = _sellFee;

        feeDenominator = _feeDenominator;
        require(_buyFee <= 300 && _sellFee <= 300, "Fee should be less than 3%");
        require(
            buyingFee <= feeDenominator / 4 && sellingFee <= feeDenominator / 4,
            "Total fee should not be greater than 1/4 of fee denominator"
        );
    }

    function setFeeExempt(address wallet_, bool exempt) external authorized {
        isFeeExempt[wallet_] = exempt;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount)
        external
        authorized
    {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setTreasuryAddress(address _treasuryAddress) external authorized {
        treasuryAddress = _treasuryAddress;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }
}