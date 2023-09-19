pragma solidity ^0.8.17;
//SPDX-License-Identifier: MIT

import "IERC20.sol";
import "Auth.sol";
import "SafeMath.sol";
import "IDEXRouter.sol";
import "IDEXFactory.sol";
import "OperaRevenue.sol";

//This Token was deployed using the Opera Protocol
//The Opera Protocol is a token deployer with the ability to deploy using borrowed initial liquidity
//This token can be configured at construction to have NO taxes or to HAVE taxes
//If the taxable variable (this cannot be updated after deployment) is true then this token is taxed
//If the borrowedLP variable (this cannot be updated after deployment) is true then the max tax is 10% buy / sell, otherwise the max can be 50% buy / sell
//Swap Threshold must be between 0.2% and 5% of supply, only if the token is taxable
//The Opera Dao will control the LP tokens for tokens that borrow Liquidity

contract OperaToken is IERC20, Auth {
    using SafeMath for uint256;

    string _name;
    string _symbol;
    string _telegram;
    string _website;

    uint8 constant _decimals = 9;

    uint256 public _totalSupply;

    uint256 public _maxWalletToken;
    uint256 public _swapThreshold;

    uint256 public _operaTax;
    uint256 public _marketingBuyTax;
    uint256 public _marketingSellTax;
    uint256 public _devBuyTax;
    uint256 public _devSellTax;
    uint256 public _liquidityBuyTax;
    uint256 public _liquiditySellTax;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) isFeeExempt;

    address public pair;
    address public routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public _devAddress;
    address public _marketingAddress;
    address public OperaRevenueAddress;
    address public OperaFactoryAddress;
    address public WETHAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IDEXRouter public router;

    bool inSwap;
    bool public taxable;
    bool public borrowedLP;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }
    event AutoLiquify(uint256 amountETH, uint256 amountCoin);

    constructor(
        string[] memory _stringData,
        address[] memory _addressData,
        uint256[] memory _intData,
        address rewardsAddress
    ) Auth(msg.sender) {
        require(_stringData.length == 4, "String List needs 4 string inputs");
        require(
            _addressData.length == 2,
            "Address List needs 2 address inputs"
        );
        require(_intData.length == 11, "Int List needs 11 int inputs");
        if (_intData[9] == 1) {
            taxable = true;
        }
        if (_intData[10] == 1 && _intData[9] == 1) {
            borrowedLP = true;
        }
        OperaRevenueAddress = rewardsAddress;
        OperaFactoryAddress = msg.sender;
        router = IDEXRouter(routerAddress);
        pair = IDEXFactory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );

        authorizations[routerAddress] = true;

        _name = _stringData[0];
        _symbol = _stringData[1];
        _telegram = _stringData[2];
        _website = _stringData[3];

        require(_intData[0] > 0 && _intData[0] < 999999999999999999);
        _totalSupply = _intData[0] * 10 ** _decimals;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);

        _maxWalletToken = (_totalSupply * _intData[1]) / 1000;
        if (taxable) {
            _devAddress = _addressData[0];
            _marketingAddress = _addressData[1];
            _swapThreshold = (_totalSupply * _intData[2]) / 1000;
            _marketingBuyTax = _intData[3];
            _marketingSellTax = _intData[4];
            _devBuyTax = _intData[5];
            _devSellTax = _intData[6];
            _liquidityBuyTax = _intData[7];
            _liquiditySellTax = _intData[8];
            if (borrowedLP) {
                if (getTotalTax() > 192) {
                    _operaTax = 20;
                } else {
                    _operaTax = 4;
                }
            } else {
                _operaTax = 2;
            }

            require(
                _swapThreshold <= (_totalSupply / 20) &&
                    _swapThreshold >= (_totalSupply / 500),
                "Swap Threshold must be less than 5% of total supply, or greater than 0.2%."
            );
            require(getSellTax() <= 500, "Sell tax can't be greater than 50%.");
            require(getBuyTax() <= 500, "Buy tax can't be greater than 50%.");
            require(
                _devAddress != address(0) && _marketingAddress != address(0),
                "Reciever wallets can't be Zero address."
            );
        }

        _allowances[address(this)][address(router)] = _totalSupply;

        require(
            _maxWalletToken >= (_totalSupply / 500),
            "Max Wallet must be greater than 0.2%."
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
        if (shouldTokenSwap(recipient)) {
            tokenSwap();
        }

        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        uint256 amountReceived = (taxable &&
            (recipient == pair || sender == pair))
            ? takeFee(sender, recipient, amount)
            : amount;

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
        if (recipient == OperaFactoryAddress) {
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
        return _liquidityBuyTax + _devBuyTax + _marketingBuyTax + _operaTax;
    }

    function getSellTax() public view returns (uint) {
        return _liquiditySellTax + _devSellTax + _marketingSellTax + _operaTax;
    }

    function getTotalTax() public view returns (uint) {
        return getSellTax() + getBuyTax();
    }

    function setTaxes(
        uint256 _marketingBuyPercent,
        uint256 _marketingSellPercent,
        uint256 _devBuyPercent,
        uint256 _devSellPercent,
        uint256 _liquidityBuyPercent,
        uint256 _liquiditySellPercent
    ) external onlyOwner {
        require(inSwap == false, "Cannot call when in swap");
        require(taxable, "This token has no taxes.");
        uint256 amount = _balances[address(this)];
        if (_operaTax == 20) {
            if (amount > 0) {
                tokenSwap();
            }

            _operaTax = 4;
        }
        _marketingBuyTax = _marketingBuyPercent;
        _liquidityBuyTax = _liquidityBuyPercent;
        _devBuyTax = _devBuyPercent;
        _marketingSellTax = _marketingSellPercent;
        _liquiditySellTax = _liquiditySellPercent;
        _devSellTax = _devSellPercent;
        require(
            getBuyTax() <= (borrowedLP ? 100 : 500),
            "Buy tax can't be greater than 10% if borrowed lp and 50% if not."
        );
        require(
            getSellTax() <= (borrowedLP ? 100 : 500),
            "Sell tax can't be greater than 10% if borrowed lp and 50% if not."
        );
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
        path[1] = WETHAddress;

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
            address liqAddress = borrowedLP
                ? OperaFactoryAddress
                : _marketingAddress;
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                liqAddress,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
        uint256 operaFee = amountETH.mul(_operaTax.mul(2)).div(totalETHFee);

        OperaRevenue rewardContract = OperaRevenue(
            payable(OperaRevenueAddress)
        );
        rewardContract.recieveRewards{value: operaFee}();
    }

    function shouldTokenSwap(address recipient) internal view returns (bool) {
        return ((recipient == pair) &&
            taxable &&
            !inSwap &&
            _balances[address(this)] >= _swapThreshold);
    }

    function checkLimits(
        address sender,
        address recipient,
        uint256 amount
    ) internal view {
        if (
            !authorizations[sender] &&
            !authorizations[recipient] &&
            recipient != address(this) &&
            sender != address(this) &&
            recipient != 0x000000000000000000000000000000000000dEaD &&
            recipient != pair &&
            recipient != _marketingAddress &&
            recipient != _devAddress &&
            recipient != OperaFactoryAddress
        ) {
            uint256 heldTokens = balanceOf(recipient);
            require(
                (heldTokens + amount) <= _maxWalletToken,
                "Total Holding is currently limited, you can not buy that much."
            );
        }
    }

    function setMaxWallet(uint256 percent) external onlyOwner {
        require(inSwap == false, "Cannot call when in swap");
        _maxWalletToken = (_totalSupply * percent) / 1000;
        require(
            _maxWalletToken >= (_totalSupply / 500),
            "Max Wallet must be greater than 0.2%."
        );
    }

    function setTokenSwapSettings(uint256 percent) external onlyOwner {
        require(inSwap == false, "Cannot call when in swap");
        require(taxable, "This token has no taxes.");
        _swapThreshold = (_totalSupply * percent) / 1000;
        require(
            _swapThreshold <= (_totalSupply / 20) &&
                _swapThreshold >= (_totalSupply / 500),
            "Swap Threshold must be less than 5% of total supply, or greater than 0.2%."
        );
    }

    // function getAddress() external view returns (address) {
    //     return address(this);
    // }

    function aboutMe() external view returns (string memory, string memory) {
        return (_telegram, _website);
    }

    function updateAboutMe(
        string memory telegram,
        string memory website
    ) external onlyOwner {
        _telegram = telegram;
        _website = website;
    }

    function setAddresses(
        address marketingAddress,
        address devAddress
    ) external onlyOwner {
        require(inSwap == false, "Cannot call when in swap");
        require(taxable, "This token has no taxes.");
        if (marketingAddress != address(0)) {
            _marketingAddress = marketingAddress;
        }
        if (devAddress != address(0)) {
            _devAddress = devAddress;
        }

        require(
            _devAddress != address(0) && _marketingAddress != address(0),
            "Reciever wallets can't be Zero address."
        );
    }

    function setFeeExemption(address user, bool status) external onlyOwner {
        isFeeExempt[user] = status;
    }

    function clearStuckBalance() external onlyOwner {
        require(inSwap == false, "Cannot call when in swap");
        payable(msg.sender).transfer(address(this).balance);
    }
}