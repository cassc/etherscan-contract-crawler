/**
 *Submitted for verification at Etherscan.io on 2023-08-24
*/

// SPDX-License-Identifier: MIT
/*
Genesis Block (2009): The first block of the Bitcoin blockchain, 
known as the "genesis block,"was mined by Satoshi Nakamoto in January 2009. 
This marked the beginning of the Bitcoin network.

https://t.me/Genesisblock_2009

https://twitter.com/Genesisblock_9

http://genesisblock2009.com
**/

pragma solidity ^0.8.10;

library SafeMath {
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IDexFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IDexRouter {
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
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IERC20Extended {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address _owner,
        address spender
    ) external view returns (uint256);

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
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
        _owner = payable(address(0));
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

// main contract
contract GENESISBLOCK is IERC20Extended, Ownable {
    using SafeMath for uint256;

    string private constant _name = "Genesis Block";
    string private constant _symbol = "BITCOIN";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 21_000_000 * 10 ** _decimals;

    address private constant DEAD = address(0xdead);
    address private constant ZERO = address(0);
    IDexRouter public router;
    address public pair;
    address public autoLiquidityReceiver;
    address private marketingFeeReceiver;
    address private devFeeReceiver;

    uint256 liquidityFeePercent = 0;
    uint256 marketingFeePercent = 50;
    uint256 devFeePercent = 50;

    uint256 public totalBuyFee = 30;
    uint256 public totalSellFee = 40;
    uint256 public feeDenominator = 100;
    uint256 public maxWalletAmount = (_totalSupply * 2) / 100;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isLimitExmpt;

    bool public trading;
    bool public swapEnabled;
    uint256 public swapThreshold = (_totalSupply * 1) / 100;
    uint256 public launchedAt;
    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    event AutoLiquify(uint256 amountEth, uint256 amountToken);

    constructor() {
        address router_ = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        autoLiquidityReceiver = msg.sender;
        marketingFeeReceiver = msg.sender;
        devFeeReceiver = msg.sender;

        router = IDexRouter(router_);
        pair = IDexFactory(router.factory()).createPair(
            address(this),
            router.WETH()
        );

        isFeeExempt[msg.sender] = true;
        isFeeExempt[autoLiquidityReceiver] = true;
        isFeeExempt[marketingFeeReceiver] = true;
        isFeeExempt[devFeeReceiver] = true;

        isLimitExmpt[msg.sender] = true;
        isLimitExmpt[address(this)] = true;
        isLimitExmpt[address(router)] = true;
        isLimitExmpt[pair] = true;
        isLimitExmpt[autoLiquidityReceiver] = true;
        isLimitExmpt[marketingFeeReceiver] = true;
        isLimitExmpt[devFeeReceiver] = true;

        _allowances[address(this)][address(router)] = _totalSupply;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(
        address holder,
        address spender
    ) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) external override returns (bool) {
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
        if (!isFeeExempt[sender] && !isFeeExempt[recipient]) {
            // trading disable till launch
            if (!trading) {
                require(
                    pair != sender && pair != recipient,
                    "trading is disable"
                );
            }
        }
        if (!isLimitExmpt[recipient]) {
            require(
                balanceOf(recipient).add(amount) <= maxWalletAmount,
                "Max wallet limit exceeds"
            );
        }

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (shouldSwapBack()) {
            swapBack();
        }

        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );

        uint256 amountReceived;
        if (
            isFeeExempt[sender] ||
            isFeeExempt[recipient] ||
            (sender != pair && recipient != pair)
        ) {
            amountReceived = amount;
        } else {
            uint256 feeAmount;
            if (sender == pair) {
                feeAmount = amount.mul(totalBuyFee).div(feeDenominator);
                amountReceived = amount.sub(feeAmount);
                takeFee(sender, feeAmount);
            } else {
                feeAmount = amount.mul(totalSellFee).div(feeDenominator);
                amountReceived = amount.sub(feeAmount);
                takeFee(sender, feeAmount);
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

    function takeFee(address sender, uint256 feeAmount) internal {
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            swapEnabled &&
            _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 amountToLiquify = swapThreshold
            .mul(liquidityFeePercent)
            .div(feeDenominator)
            .div(2);

        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);
        _allowances[address(this)][address(router)] = _totalSupply;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountEth = address(this).balance.sub(balanceBefore);

        uint256 totalEthFee = marketingFeePercent.add(devFeePercent).add(
            liquidityFeePercent.div(2)
        );

        uint256 amountEthLiquidity = amountEth
            .mul(liquidityFeePercent)
            .div(totalEthFee)
            .div(2);
        uint256 amountEthMarketing = amountEth.mul(marketingFeePercent).div(
            totalEthFee
        );
        uint256 amountEthDev = amountEth.mul(devFeePercent).div(totalEthFee);

        if (amountEthMarketing > 0) {
            payable(marketingFeeReceiver).transfer(amountEthMarketing);
        }
        if (amountEthDev > 0) {
            payable(devFeeReceiver).transfer(amountEthDev);
        }

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountEthLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountEthLiquidity, amountToLiquify);
        }
    }

    function enableTrading() external onlyOwner {
        require(!trading, "Already enabled");
        trading = true;
        swapEnabled = true;
        launchedAt = block.timestamp;
    }

    function removeStuckTokens(
        address receiver,
        address token,
        uint256 amount
    ) external onlyOwner {
        IERC20Extended(token).transfer(receiver, amount);
    }

    function removeStuckEth(
        address receiver,
        uint256 amount
    ) external onlyOwner {
        payable(receiver).transfer(amount);
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsLimitExempt(address holder, bool exempt) external onlyOwner {
        isLimitExmpt[holder] = exempt;
    }

    function setMaxWalletlimit(uint256 _maxWalletAmount) external onlyOwner {
        maxWalletAmount = _maxWalletAmount;
    }

    function setFeesPercent(
        uint256 _liquidityFee,
        uint256 _marketingFee,
        uint256 _devFee,
        uint256 _feeDenominator
    ) public onlyOwner {
        liquidityFeePercent = _liquidityFee;
        marketingFeePercent = _marketingFee;
        devFeePercent = _devFee;
        feeDenominator = _feeDenominator;
        uint256 totalFeePercent = liquidityFeePercent.add(marketingFeePercent).add(devFeePercent);
        require(
            totalFeePercent == feeDenominator,
            "Must be equal"
        );
    }

    function setFees(
        uint256 _buyFee,
        uint256 _sellFee
    ) public onlyOwner {
        totalBuyFee = _buyFee;
        totalSellFee = _sellFee;
        require(
            totalSellFee <= feeDenominator.mul(80).div(100) &&
                totalBuyFee <= feeDenominator.mul(80).div(100),
            "Can't be greater than 80%"
        );
    }

    function setFeeReceivers(
        address _autoLiquidityReceiver,
        address _marketingFeeReceiver,
        address _devFeeReceiver
    ) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        devFeeReceiver = _devFeeReceiver;
    }

    function setSwapBackSettings(
        bool _enabled,
        uint256 _amount
    ) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }
}