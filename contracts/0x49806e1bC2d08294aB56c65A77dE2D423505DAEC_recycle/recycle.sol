/**
 *Submitted for verification at Etherscan.io on 2023-08-10
*/

/*
    Telegram: https://t.me/recycleerc
    Twitter:  https://twitter.com/recycleerc
    Website:  https://recycleerc.com
 *
 * 
 * SPDX-License-Identifier: None
 */

pragma solidity 0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);    
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable;
}

contract recycle is IERC20 {
    string private _name;
    string private _symbol;
    uint8 constant _decimals = 18;
    uint256 _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public limitless;
    mapping(address => bool) public isExludedFromMaxWallet;

    bool public renounced = false;

    uint256 public tax = 2;
    uint256 public rewards = 1;
    uint256 public liq = 0;
    uint256 public marketing = 1;
    uint256 private swapAt = _totalSupply / 10_000;
    uint256 private maxSwapAmount = _totalSupply / 100;
    uint256 public maxWalletInPermille = 30;
    uint256 private maxTx = 100;

    uint256 public sellMultiplier = 3;
    uint256 public sellDivisor = 1;

    address public constant CEO = 0x503a1Ad34340488ebc4d553E121A7Ed552b69edc;
    address public constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address public immutable WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant REWARD = 0x293F152d2265da6Afd2f8993b47A01D0a811aA01;
    address public marketingWallet;

    address public pair;
    address[] public pairs;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised; 
    }

    mapping (address => uint256) public shareholderIndexes;
    mapping (address => Share) public shares;
    mapping (address => bool) public addressNotGettingRewards;

    uint256 public totalShares;
    uint256 public totalDistributed;
    uint256 public rewardsPerShare;
    uint256 private veryLargeNumber = 10 ** 36;

    address[] private shareholders;

    modifier onlyCEO(){
        require (msg.sender == CEO, "Only the CEO can do that");
        _;
    }

    constructor() {
        _name = "RECYCLE";
        _symbol = "RECYCLE";
        _totalSupply = 1000000 * (10**_decimals);
    }
    
    function init(address marketing_) external onlyCEO {
        require(marketingWallet == address(0x0));
        marketingWallet = marketing_;

        pair = IDEXFactory(IDEXRouter(ROUTER).factory()).createPair(WETH, address(this));
        _allowances[address(this)][ROUTER] = type(uint256).max;
        _allowances[CEO][ROUTER] = type(uint256).max;
        isExludedFromMaxWallet[pair] = true;
        isExludedFromMaxWallet[address(this)] = true;
        pairs.push(pair);

        addressNotGettingRewards[pair] = true;
        addressNotGettingRewards[address(this)] = true;

        limitless[CEO] = true;
        limitless[address(this)] = true;
        tax = rewards + liq + marketing;

        _balances[CEO] = _totalSupply;
        emit Transfer(address(0), CEO, _totalSupply);     
    } 

    receive() external payable {}
    function name() public view override returns (string memory) {return _name;}
    function totalSupply() public view override returns (uint256) {return _totalSupply - _balances[DEAD];}
    function decimals() public pure override returns (uint8) {return _decimals;}
    function symbol() public view override returns (string memory) {return _symbol;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function rescueEth(uint256 amount) external onlyCEO {(bool success,) = address(CEO).call{value: amount}("");success = true;}
    function rescueToken(address token, uint256 amount) external onlyCEO {IERC20(token).transfer(CEO, amount);}
    function allowance(address holder, address spender) public view override returns (uint256) {return _allowances[holder][spender];}
    function transfer(address recipient, uint256 amount) external override returns (bool) {return _transferFrom(msg.sender, recipient, amount);}
    function approveMax(address spender) external returns (bool) {return approve(spender, type(uint256).max);}
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        require(spender != address(0), "Can't use zero address here");
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0), "Can't use zero address here");
        _allowances[msg.sender][spender]  = allowance(msg.sender, spender) + addedValue;
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0), "Can't use zero address here");
        require(allowance(msg.sender, spender) >= subtractedValue, "Can't subtract more than current allowance");
        _allowances[msg.sender][spender]  = allowance(msg.sender, spender) - subtractedValue;
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            require(_allowances[sender][msg.sender] >= amount, "Insufficient Allowance");
            _allowances[sender][msg.sender] -= amount;
            emit Approval(sender, msg.sender, _allowances[sender][msg.sender]);
        }
        return _transferFrom(sender, recipient, amount);
    }

    function setTaxes(uint256 rewardsTax, uint256 liqTax, uint256 marketingTax, uint256 newSellMultiplier, uint256 newSellDivisor) external onlyCEO {
        if(renounced) require(rewardsTax + liqTax + marketingTax <= tax , "Once renounced, taxes can only be lowered");
        rewards = rewardsTax;
        liq = liqTax;
        marketing = marketingTax;
        tax = rewards + liq + marketing;
        sellMultiplier = newSellMultiplier;
        sellDivisor = newSellDivisor;
        require(tax * sellMultiplier / sellDivisor < 34, "Tax safety limit");     
    }

    function setTokenLimitsForContractSells(uint256 min, uint256 max) external onlyCEO {
        swapAt = min;
        maxSwapAmount = max;
    }

    function addPair(address newPair) external onlyCEO {
        pairs.push(newPair);
    }

    function removeLastPair() external onlyCEO {
        if(pairs.length > 1) pairs.pop();
    }
    
    function setMaxWalletInPermille(uint256 permille) external onlyCEO {
        if(renounced) {
            maxWalletInPermille = 1000;
            return;
        }
        maxWalletInPermille = permille;
        require(maxWalletInPermille >= 10, "MaxWallet safety limit");
    }

    function setMaxTxInPercentOfMaxWallet(uint256 percent) external onlyCEO {
        if(renounced) {maxTx = 100; return;}
        maxTx = percent;
        require(maxTx >= 75, "MaxTx safety limit");
    }
    
    function setNameAndSymbol(string memory newName, string memory newSymbol) external onlyCEO {
        _name = newName;
        _symbol = newSymbol;
    }

    function setLimitlessWallet(address limitlessWallet, bool status) external onlyCEO {
        if(renounced) return;
        isExludedFromMaxWallet[limitlessWallet] = status;
        excludeFromRewards(limitlessWallet, status);
        limitless[limitlessWallet] = status;
    }

    function excludeFromRewards(address excludedWallet, bool status) public onlyCEO {
        addressNotGettingRewards[excludedWallet] = status;
        setShare(excludedWallet);
    }
    
    function changeMarketingWallet(address newMarketingWallet) external onlyCEO {
        marketingWallet = newMarketingWallet;
    }    
    
    function excludeFromMax(address excludedWallet, bool status) external onlyCEO {
        isExludedFromMaxWallet[excludedWallet] = status;
    }    

    function renounceOnwrship() external onlyCEO {
        if(renounced) return;
        renounced = true;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        amount = takeTax(sender, recipient, amount);
        _lowGasTransfer(sender, recipient, amount);
        if(!addressNotGettingRewards[sender]) setShare(sender);
        if(!addressNotGettingRewards[recipient]) setShare(recipient);
        return true;
    }

    function takeTax(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (limitless[sender] || limitless[recipient])  return amount;
        
        if(maxWalletInPermille < 1000) {    
            if(!isExludedFromMaxWallet[recipient]) require(_balances[recipient] + amount <= _totalSupply * maxWalletInPermille / 1000, "MaxWallet");
            if(!isExludedFromMaxWallet[sender]) require(amount <= _totalSupply * maxWalletInPermille * maxTx / 1000 / 100, "MaxTx");
        }

        if(!isPair(sender) && !isPair(recipient)) return amount;

        if(tax == 0) return amount;
        uint256 taxToSwap = isPair(recipient) ? amount * (rewards + marketing) * sellMultiplier / sellDivisor / 100 : amount * (rewards + marketing) / 100;
        if(taxToSwap > 0) _lowGasTransfer(sender, address(this), taxToSwap);
        
        if(liq > 0) {
            uint256 liqTax = isPair(recipient) ? amount * liq * sellMultiplier / sellDivisor / 100 : amount * liq / 100;
            _lowGasTransfer(sender, pair, liqTax);
        }

        if(!isPair(sender)) swapForRewards();

        return isPair(recipient) ? amount - (amount * tax * sellMultiplier / sellDivisor / 100) : amount - (amount * tax / 100);
    }

    function _lowGasTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0), "Can't use zero addresses here");
        require(amount <= _balances[sender], "Can't transfer more than you own");
        if(amount == 0) return true;
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function swapForRewards() internal {
        uint256 amount = _balances[address(this)] > maxSwapAmount ? maxSwapAmount : _balances[address(this)];
        if(amount < swapAt || rewards + marketing == 0) return;

        address[] memory pathForSelling = new address[](2);
        pathForSelling[0] = address(this);
        pathForSelling[1] = WETH;

        IDEXRouter(ROUTER).swapExactTokensForETHSupportingFeeOnTransferTokens(
            _balances[address(this)],
            0,
            pathForSelling,
            address(this),
            block.timestamp
        );
                
        uint256 marketingShare = address(this).balance * marketing / (rewards + marketing);
        (bool success,) = address(marketingWallet).call{value: marketingShare}("");
        success = true;

        if(totalShares > 0) buyRewards();
    }

    function buyRewards() internal {
        uint256 rewardTokenBalanceBefore = IERC20(REWARD).balanceOf(address(this));
        
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = REWARD;

        IDEXRouter(ROUTER).swapExactETHForTokensSupportingFeeOnTransferTokens{value: address(this).balance}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 newRewards = IERC20(REWARD).balanceOf(address(this)) - rewardTokenBalanceBefore;
        rewardsPerShare += veryLargeNumber * newRewards / totalShares;
    }

    function setShare(address shareholder) internal {
        uint256 balance = _balances[shareholder];
        if(addressNotGettingRewards[shareholder]) balance = 0;
        if(shares[shareholder].amount > 0) distributeRewards(shareholder);
        if(shares[shareholder].amount == 0 && balance > 0) addShareholder(shareholder);
        
        if(shares[shareholder].amount > 0 && balance == 0){
            totalShares = totalShares - shares[shareholder].amount;
            shares[shareholder].amount = 0;
            removeShareholder(shareholder);
            return;
        }

        if(balance > 0) {
            totalShares = totalShares - shares[shareholder].amount + balance;
            shares[shareholder].amount = balance;
            shares[shareholder].totalExcluded = getTotalRewardsOf(shares[shareholder].amount);
        }
    }

    function claim() external {if(getUnpaidEarnings(msg.sender) > 0) distributeRewards(msg.sender);}
    
    function claimableReward(address shareholder) public view returns (uint256) {
        return getUnpaidEarnings(shareholder) / 10**18;
    }

   
    function distributeRewards(address shareholder) internal {
        uint256 amount = getUnpaidEarnings(shareholder);
        IERC20(REWARD).transfer(shareholder, amount);
        
        totalDistributed = totalDistributed + amount;
        shares[shareholder].totalRealised = shares[shareholder].totalRealised + amount;
        shares[shareholder].totalExcluded = getTotalRewardsOf(shares[shareholder].amount);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        uint256 shareholderTotalRewards = getTotalRewardsOf(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;
        if(shareholderTotalRewards <= shareholderTotalExcluded) return 0;
        return shareholderTotalRewards - shareholderTotalExcluded;
    }

    function getTotalRewardsOf(uint256 share) internal view returns (uint256) {
        return share * rewardsPerShare / veryLargeNumber;
    }
   
    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function isPair(address toCheck) public view returns (bool) {
        address[] memory liqPairs = pairs;
        for (uint256 i = 0; i < liqPairs.length; i++) if (toCheck == liqPairs[i]) return true;
        return false;
    }
}