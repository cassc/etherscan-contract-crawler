// SPDX-License-Identifier: MIT


pragma solidity ^0.8.17;

import "./SafeMath.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./IERC20Extended.sol";
import "./Auth.sol";

contract ShibaGandalfWizardPumpCoin1337 is IERC20Extended, Auth {
    using SafeMath for uint256;

    uint256 public maxTokenHold = 133333333 * 10**18;

    mapping(address => bool) public isExcludedFromMaxHold;
    mapping(address => bool) public isTaxExempt;

    // Time when the liquidity can be released
    uint256 public liquidityReleaseTime;

    // State of the liquidity lock
    bool public liquidityLocked = false;

    string public constant _name = "ShibaGandalfChadPumpCoin1337";
    string public constant _symbol = "SGWPC1337";
    uint256 public constant _totalSupply = 13333333337 * 10**18;
    uint8 private constant _decimals = 18;

    IUniswapV2Router02 public router;
    IUniswapV2Factory public factory;
    address public pair;
    address public marketingWallet;

    uint256 public buyTax = 30; // 3%
    uint256 public sellTax = 30; // 3%
    uint256 public constant feeDenominator = 1000;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(
        address factory_,
        address router_,
        address _marketingWallet
    ) payable Auth(msg.sender) {
        router = IUniswapV2Router02(router_);
        factory = IUniswapV2Factory(factory_);
        marketingWallet = _marketingWallet;

        pair = factory.createPair(address(this), router.WETH());

        // Exclude important addresses from the max hold limit
        isExcludedFromMaxHold[msg.sender] = true; // Deployer
        isExcludedFromMaxHold[address(this)] = true; // Contract itself
        isExcludedFromMaxHold[marketingWallet] = true; // Marketing wallet
        isExcludedFromMaxHold[pair] = true; // Uniswap pair
        isExcludedFromMaxHold[router_] = true; // Uniswap router

        // Initialize tax exemption
        isTaxExempt[msg.sender] = true; // Deployer
        isTaxExempt[router_] = true; // Uniswap router
        isTaxExempt[pair] = true; // Uniswap pair
        isTaxExempt[address(this)] = true; // Contract itself
        isTaxExempt[marketingWallet] = true; // Marketing wallet

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

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

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transfer(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(
            amount,
            "Insufficient Allowance"
        );

        return _transfer(sender, recipient, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );

        // If recipient is not excluded, check that they will not exceed the max hold amount
        if (!isExcludedFromMaxHold[recipient]) {
            require(
                _balances[recipient].add(amount) <= maxTokenHold,
                "Recipient would hold too many tokens"
            );
        }

        uint256 taxAmount = 0;
        if (!isTaxExempt[sender] && !isTaxExempt[recipient]) {
            taxAmount = amount.mul(sender == pair ? buyTax : sellTax).div(
                feeDenominator
            );
        }

        uint256 amountReceived = amount.sub(taxAmount);

        _balances[marketingWallet] = _balances[marketingWallet].add(taxAmount);
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, marketingWallet, taxAmount);
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function setTaxExemptStatus(address account, bool _status)
        external
        authorized
    {
        isTaxExempt[account] = _status;
    }
}