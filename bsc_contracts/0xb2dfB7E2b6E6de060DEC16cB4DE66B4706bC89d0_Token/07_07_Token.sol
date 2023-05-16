/* SPDX-License-Identifier: UNLICENSED */

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Token is Ownable, IERC20, IERC20Metadata {
    struct Fees {
        uint256 buy;
        uint256 sell;
    }

    struct FeesDistribution {
        uint256 burns;
        uint256 dev;
    }

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public isDex;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    uint256 public PRECISION = 10000;

    address public BURNS;
    IUniswapV2Router02 public ROUTER;
    address public GROWTH;

    uint256 public liqAddedOn = 0;

    Fees public fees = Fees({buy: 300, sell: 300});
    FeesDistribution public permFees =
        FeesDistribution({burns: 3333, dev: 6667});

    Fees public tempFeesOne = Fees({buy: 3000, sell: 3000});
    uint256 public timeTempFeesOne = 180;

    Fees public tempFeesTwo = Fees({buy: 1000, sell: 1000});
    uint256 public timeTempFeesTwo = 360;
    FeesDistribution public tempFees = FeesDistribution({burns: 0, dev: 10000});

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initSupply,
        address burns,
        address router,
        address growth
    ) {
        _name = name_;
        _symbol = symbol_;

        BURNS = burns;
        ROUTER = IUniswapV2Router02(router);
        GROWTH = growth;

        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[msg.sender] = true;

        isDex[router] = true;

        _mint(msg.sender, initSupply);
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

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _routeTransfer(owner, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _routeTransfer(from, to, amount);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function addLiquidity(uint256 amount) public payable onlyOwner {
        require(liqAddedOn == 0, "LIQ: Already added liquidity.");
        liqAddedOn = block.timestamp;
        _transferExcluded(msg.sender, address(this), amount);
        _approve(address(this), address(ROUTER), type(uint256).max);
        ROUTER.addLiquidityETH{value: msg.value}(
            address(this),
            amount,
            0,
            0,
            msg.sender,
            block.timestamp
        );
    }

    function approveOnRouter() public onlyOwner {
        _approve(address(this), address(ROUTER), type(uint256).max);
    }

    function _routeTransfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        if (isExcludedFromFee[from] || isExcludedFromFee[to])
            _transferExcluded(from, to, amount);
        else _transferNoneExcluded(from, to, amount);
    }

    function getCurrentFees()
        public
        view
        returns (Fees memory, FeesDistribution memory)
    {
        if (block.timestamp < liqAddedOn + timeTempFeesOne)
            return (tempFeesOne, tempFees);
        if (block.timestamp < liqAddedOn + timeTempFeesTwo)
            return (tempFeesTwo, tempFees);
        return (fees, permFees);
    }

    function _transferNoneExcluded(
        address from,
        address to,
        uint256 amount
    ) internal {
        _balances[from] -= amount;

        uint256 feeValue = 0;
        (
            Fees memory currFees,
            FeesDistribution memory currFeeDist
        ) = getCurrentFees();

        if (isDex[from]) {
            feeValue = (amount * currFees.buy) / PRECISION;
        } else if (isDex[to]) {
            feeValue = (amount * currFees.sell) / PRECISION;
        }

        if (feeValue > 0) {
            if (currFeeDist.burns > 0) {
                address[] memory path = new address[](3);
                path[0] = address(this);
                path[1] = ROUTER.WETH();
                path[2] = BURNS;

                ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    (feeValue * currFeeDist.burns) / PRECISION,
                    0,
                    path,
                    GROWTH,
                    block.timestamp
                );
            }

            if (currFeeDist.dev > 0) {
                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = ROUTER.WETH();

                ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    (feeValue * currFeeDist.dev) / PRECISION,
                    0,
                    path,
                    GROWTH,
                    block.timestamp
                );
            }
        }

        uint256 receivedValue = amount - feeValue;

        _balances[to] += receivedValue;
        emit Transfer(from, to, receivedValue);
    }

    function _transferExcluded(
        address from,
        address to,
        uint256 amount
    ) internal {
        _balances[from] -= amount;
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
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
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function updateIsExcludedFromFee(
        address user,
        bool value
    ) public onlyOwner {
        isExcludedFromFee[user] = value;
    }

    function updateIsDex(address user, bool value) public onlyOwner {
        isDex[user] = value;
    }

    function updatePrecision(uint256 value) public onlyOwner {
        PRECISION = value;
    }

    function updateBurns(address value) public onlyOwner {
        BURNS = value;
    }

    function updateRouter(address value) public onlyOwner {
        ROUTER = IUniswapV2Router02(value);
    }

    function updateGrowth(address value) public onlyOwner {
        GROWTH = value;
    }

    function updateFees(uint256 buy, uint256 sell) public onlyOwner {
        fees = Fees({buy: buy, sell: sell});
    }

    function updatePermFees(uint256 burns, uint256 dev) public onlyOwner {
        permFees = FeesDistribution({burns: burns, dev: dev});
    }

    function updateTempFeesOne(uint256 buy, uint256 sell) public onlyOwner {
        tempFeesOne = Fees({buy: buy, sell: sell});
    }

    function updateTimeTempFeesOne(uint256 value) public onlyOwner {
        timeTempFeesOne = value;
    }

    function updateTempFeesTwo(uint256 buy, uint256 sell) public onlyOwner {
        tempFeesTwo = Fees({buy: buy, sell: sell});
    }

    function updateTimeTempFeesTwo(uint256 value) public onlyOwner {
        timeTempFeesTwo = value;
    }

    function updateTempFees(uint256 burns, uint256 dev) public onlyOwner {
        tempFees = FeesDistribution({burns: burns, dev: dev});
    }
}