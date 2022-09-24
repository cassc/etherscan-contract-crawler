// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./HoarderRewards.sol";
import "./interfaces/IUSDH.sol";
import "./interfaces/IHoarderStrategy.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IUSDT.sol";

contract hUSDH is IERC20, ReentrancyGuard {
    uint256 private constant max = type(uint256).max;

    string constant _name = "Hoarder USDH";
    string constant _symbol = "hUSDH";
    uint8 constant _decimals = 18;

    uint256 _totalSupply;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) public rewardExempt;

    HoarderRewards rewards;

    address public immutable usdh;
    IUSDH public immutable Usdh;
    IERC20 public immutable USDH;

    address public strategy;

    IHoarderStrategy public Strategy;

    ISwapRouter private constant router = ISwapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);

    address public swapThrough = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    address public governance;

    bool public disabled;
    bool public canDisable = true;

    modifier onlyGovernance() {
        require(msg.sender == governance);
        _;
    }

    constructor (address _usdh) {
        rewards = new HoarderRewards(_usdh, msg.sender);
        governance = msg.sender;

        rewardExempt[address(this)] = true;
        rewardExempt[address(0)] = true;
        rewardExempt[0x000000000000000000000000000000000000dEaD] = true;

        usdh = _usdh;
        Usdh = IUSDH(_usdh);
        USDH = IERC20(_usdh);

        approve(address(this), _totalSupply);
        approve(_usdh, _totalSupply);
        _balances[address(this)] = _totalSupply;
        emit Transfer(address(0), address(this), _totalSupply);
    }

    function _swap(address _tokenIn, address _tokenOut, uint24 _feeTier) private {
        if (_tokenIn != swapThrough) {
            IUSDT(_tokenIn).approve(address(router), max);
            try router.exactInputSingle(ISwapRouter.ExactInputSingleParams({tokenIn: _tokenIn, tokenOut: swapThrough, fee: 100, recipient: address(this), amountIn: IUSDT(_tokenIn).balanceOf(address(this)), amountOutMinimum: 0, sqrtPriceLimitX96: 0})) {} catch {
                try router.exactInputSingle(ISwapRouter.ExactInputSingleParams({tokenIn: _tokenIn, tokenOut: swapThrough, fee: 500, recipient: address(this), amountIn: IUSDT(_tokenIn).balanceOf(address(this)), amountOutMinimum: 0, sqrtPriceLimitX96: 0})) {} catch {
                    try router.exactInputSingle(ISwapRouter.ExactInputSingleParams({tokenIn: _tokenIn, tokenOut: swapThrough, fee: 3000, recipient: address(this), amountIn: IUSDT(_tokenIn).balanceOf(address(this)), amountOutMinimum: 0, sqrtPriceLimitX96: 0})) {} catch {
                        router.exactInputSingle(ISwapRouter.ExactInputSingleParams({ tokenIn: _tokenIn, tokenOut: swapThrough, fee: 10000, recipient: address(this), amountIn: IUSDT(_tokenIn).balanceOf(address(this)), amountOutMinimum: 0, sqrtPriceLimitX96: 0}));
                    }
                }
            }
            if (_tokenOut != swapThrough) {
                IUSDT(swapThrough).approve(address(router), max);
                router.exactInputSingle(ISwapRouter.ExactInputSingleParams({tokenIn: swapThrough, tokenOut: _tokenOut, fee: _feeTier,recipient: address(this), amountIn: IUSDT(swapThrough).balanceOf(address(this)), amountOutMinimum: 0, sqrtPriceLimitX96: 0}));
            }
        }
    }

    function deposit(uint256 amount) external nonReentrant {
        require(!disabled);
        require(amount > 0);
        require(USDH.balanceOf(msg.sender) >= amount, "Insufficient Balance");
        require(USDH.allowance(msg.sender, address(this)) >= amount, "Insufficient Allowance");
        uint256 balance = USDH.balanceOf(address(this));
        USDH.transferFrom(msg.sender, address(this), amount);
        require(USDH.balanceOf(address(this)) == balance + amount, "Transfer Failed");

        USDH.approve(usdh, amount);
        address[] memory _withdrawnCollateral = Usdh.redeem(amount);

        for (uint256 i = 0; i < _withdrawnCollateral.length; i++) {
            if (_withdrawnCollateral[i] == address(0)) break;
            if (_withdrawnCollateral[i] != Strategy.token()) _swap(_withdrawnCollateral[i], Strategy.tokenDeposit(), Strategy.feeTier());
        }

        Strategy.deposit(IERC20(Strategy.tokenDeposit()).balanceOf(address(this)));

        _totalSupply = _totalSupply + amount;
        _balances[address(this)] = _balances[address(this)] + amount;
        emit Transfer(address(0), address(this), amount);
        _transferFrom(address(this), msg.sender, amount);
    }

    function withdraw(uint256 amount) external nonReentrant returns (uint256) {
        require(!disabled);
        require(amount > 0);
        require(_balances[msg.sender] >= amount, "Insufficent Balance");
        require(_allowances[msg.sender][address(this)] >= amount, "Insufficient Allowance");
        uint256 balance = balanceOf(address(this));
        _transferFrom(msg.sender, address(this), amount);
        require(balanceOf(address(this)) == balance + amount, "Transfer Failed");

        uint256 withdrawn = Strategy.withdraw(amount);

        _totalSupply = _totalSupply - withdrawn;
        _balances[address(this)] = _balances[address(this)] - withdrawn;
        emit Transfer(address(this), address(0), withdrawn);
        USDH.transfer(msg.sender, withdrawn);
        return withdrawn;
    }

    function claim() external nonReentrant {
        require(!disabled);
        rewards.claimUSDH(msg.sender);
    }

    function checkStrategy() external view returns (address) {
        return strategy;
    }

    function checkRewardExempt(address staker) external view returns (bool) {
        return rewardExempt[staker];
    }

    function getHoarderRewardsAddress() external view returns (address) {
        return address(rewards);
    }

    function getDisabled() external view returns (bool) {
        return disabled;
    }

    function getCanDisable() external view returns (bool) {
        return canDisable;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != max) {
            require(_allowances[sender][msg.sender] >= amount, "Insufficient allowance");
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) private returns (bool) {
        require(_balances[sender] >= amount, "Insufficient balance");
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;

        if (!rewardExempt[sender]) rewards.setBalance(sender, _balances[sender]);
        if (!rewardExempt[recipient]) rewards.setBalance(recipient, _balances[recipient]);

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function rescue(address token) external onlyGovernance {
        if (token == 0x0000000000000000000000000000000000000000) {
            payable(msg.sender).call{value: address(this).balance}("");
        } else {
            require(token != address(this) && token != usdh);
            IERC20 Token = IERC20(token);
            Token.transfer(msg.sender, Token.balanceOf(address(this)));
        }
    }

    function setStrategy(address strategyNew) external nonReentrant onlyGovernance {
        IHoarderStrategy _Strategy = IHoarderStrategy(strategyNew);
        IUSDT(_Strategy.tokenDeposit()).approve(strategyNew, type(uint256).max);
        if (strategy != address(0)) {
            Strategy.end();
            address tokenDeposit = Strategy.tokenDeposit();
            Strategy = _Strategy;
            IUSDT(tokenDeposit).approve(strategyNew, type(uint256).max);
            Strategy.init(tokenDeposit, IERC20(tokenDeposit).balanceOf(address(this)));
        } else {
            Strategy = _Strategy;
            Strategy.init(Strategy.tokenDeposit(), 0);
        }
        strategy = strategyNew;
        rewardExempt[strategy] = true;
    }

    function setSwapThrough(address _newSwapThrough) external nonReentrant onlyGovernance {
        swapThrough = _newSwapThrough;
    }

    function disable() external nonReentrant onlyGovernance {
        require(!disabled && canDisable);
        Strategy.end();
        if (USDH.balanceOf(address(this)) > 0) USDH.transfer(msg.sender, USDH.balanceOf(address(this)));
        if (IERC20(Strategy.tokenDeposit()).balanceOf(address(this)) > 0) IERC20(Strategy.tokenDeposit()).transfer(msg.sender, IERC20(Strategy.tokenDeposit()).balanceOf(address(this)));
        disabled = true;
    }

    function renounce() external nonReentrant onlyGovernance {
        require(!disabled && canDisable);
        canDisable = false;
    }

    function setGovernance(address _newGovernanceContract) external nonReentrant onlyGovernance {
        governance = _newGovernanceContract;
    }

    receive() external payable {}
}