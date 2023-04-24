/**
 *Submitted for verification at BscScan.com on 2023-04-21
*/

/*
 * 
 * Written by: MrGreenCrypto
 * Co-Founder of CodeCraftrs.com
 * 
 * SPDX-License-Identifier: None
 */

pragma solidity 0.8.19;

interface IBEP20 {
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

interface IDEXFactory {function createPair(address tokenA, address tokenB) external returns (address pair);}
interface IDEXPair {function sync() external;}
interface IHelper {
    function giveMeMyMoneyBack(uint256 tax) external returns (bool);
}

interface IDEXRouter {
    function factory() external pure returns (address);    
    function WETH() external pure returns (address);
    function addLiquidityETH(address token,uint amountTokenDesired,uint amountTokenMin,uint amountETHMin,address to,uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable;
}

contract PipiPupu is IBEP20 {
    string private _name = "PipiPupu";
    string private _symbol = "PipiPupu";
    uint8 constant _decimals = 18;
    uint256 _totalSupply = 1_000_000 * (10**_decimals);

    address public constant CEO = 0xA10a79eE5E2a2f4E7dc748BA12EFcDaff77EadB3;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public limitless;
    mapping(address => bool) public isExludedFromMaxWallet;

    bool public renounced = false;

    uint256 public tax = 8;
    uint256 public rewards = 2;
    uint256 public liq = 4;
    uint256 public outreach = 1;
    uint256 public ecosystem = 1;
    uint256 public estate = 1;
    uint256 public jackpot = 1;
    uint256 public jackpotBalance;
    uint256 public jackpotFrequency = 50;
    uint256 public buyCounter;
    uint256 public enough = 0.02 ether;
    uint256 private swapAt = _totalSupply / 10_000;
    uint256 public maxWalletInPermille = 10;
    uint256 private maxTx = 75;
    bool private launched;

    IDEXRouter public constant ROUTER = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IHelper private constant helper = IHelper(0x37AA8EC8382CCC16cD53d2500eBbe5C64Ee25268);
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public mainReward = 0xe91a8D2c584Ca93C7405F15c22CdFE53C29896E3;
    address public outreachWallet = 0xC7e3318C300f0b821C27888E88a2417Bb8F7c8e2;

    address public immutable pcsPair;
    
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised; 
    }

    mapping (address => uint256) public shareholderIndexes;
    mapping (address => uint256) public lastClaim;
    mapping (address => Share) public shares;
    mapping (address => bool) public addressNotGettingRewards;
    mapping (address => bool) public isPaperhand;

    uint256 public totalShares;
    uint256 public totalDistributed;
    uint256 public rewardsPerShare;
    uint256 private veryLargeNumber = 10 ** 36;
    uint256 private rewardTokenBalanceBefore;

    address[] private shareholders;
    
    modifier onlyCEO(){
        require (msg.sender == CEO, "Only the CEO can do that");
        _;
    }

    constructor() {
        pcsPair = IDEXFactory(IDEXRouter(ROUTER).factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(ROUTER)] = type(uint256).max;
        isExludedFromMaxWallet[pcsPair] = true;
        isExludedFromMaxWallet[address(this)] = true;

        addressNotGettingRewards[pcsPair] = true;
        addressNotGettingRewards[address(this)] = true;

        limitless[CEO] = true;
        limitless[address(this)] = true;

        _balances[address(this)] = _totalSupply;
        emit Transfer(address(0), address(this), _totalSupply);
    }

    receive() external payable {}
    function name() public view override returns (string memory) {return _name;}
    function totalSupply() public view override returns (uint256) {return _totalSupply - _balances[DEAD];}
    function decimals() public pure override returns (uint8) {return _decimals;}
    function symbol() public view override returns (string memory) {return _symbol;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function rescueBnb(uint256 amount) external onlyCEO {payable(CEO).transfer(amount);}
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

    function launch() external payable onlyCEO {
        require(!launched);

        ROUTER.addLiquidityETH(
            address(this),
            _balances[address(this)],
            0,
            0,
            CEO,
            block.timestamp
        );
        launched = true;
    }

    function setTaxes(uint256 rewardsTax, uint256 liqTax, uint256 outreachTax, uint256 estateTax, uint256 ecosystemTax, uint256 jackpotTax) external onlyCEO {
        if(renounced) require(rewardsTax + liqTax + estateTax + ecosystemTax + outreachTax+ jackpotTax <= tax , "Once renounced, taxes can only be lowered");
        rewards = rewardsTax;
        liq = liqTax;
        outreach = outreachTax;
        ecosystem = ecosystemTax;
        estate = estateTax;
        jackpot = jackpotTax; 
        tax = rewards + liq + outreach + ecosystem + estate + jackpot;
        require(tax < 18, "Tax safety limit");     
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

    function setMinBuy(uint256 inWei) external onlyCEO {
        enough = inWei;
    }

    function setLimitlessWallet(address limitlessWallet, bool status) external onlyCEO {
        if(renounced) return;
        isExludedFromMaxWallet[limitlessWallet] = status;
        addressNotGettingRewards[limitlessWallet] = status;
        limitless[limitlessWallet] = status;
    }

    function excludeFromRewards(address excludedWallet, bool status) external onlyCEO {
        addressNotGettingRewards[excludedWallet] = status;
    }

    function changeOutreachWallet(address newOutreachWallet) external onlyCEO {
        outreachWallet = newOutreachWallet;
    }    
    
    function changeMainRewards(address newRewards) external onlyCEO {
        mainReward = newRewards;
    }

    function excludeFromMax(address excludedWallet, bool status) external onlyCEO {
        isExludedFromMaxWallet[excludedWallet] = status;
    }    
    
    function changeJackpotFrequency(uint256 frequency) external onlyCEO {
        jackpotFrequency = frequency;
    }

    function renounceOnwrship() external onlyCEO {
        if(renounced) return;
        renounced = true;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (limitless[sender] || limitless[recipient]) return _lowGasTransfer(sender, recipient, amount);
        amount = takeTax(sender, recipient, amount);
        _lowGasTransfer(sender, recipient, amount);
        if(!addressNotGettingRewards[sender]) setShare(sender);
        if(!addressNotGettingRewards[recipient]) setShare(recipient);
        return true;
    }

    function takeTax(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if(maxWalletInPermille <= 1000) {    
            if(!isExludedFromMaxWallet[recipient]) require(_balances[recipient] + amount <= _totalSupply * maxWalletInPermille / 1000, "MaxWallet");
            if(!isExludedFromMaxWallet[sender]) require(amount <= _totalSupply * maxWalletInPermille * maxTx / 1000 / 100, "MaxTx");
        }

        if(tax == 0) return amount;
        uint256 taxToSwap = amount * (rewards + outreach + ecosystem + estate) / 100;
        if(taxToSwap > 0) _lowGasTransfer(sender, address(this), taxToSwap);
        
        if(jackpot > 0) {
            uint256 jackpotTax = amount * jackpot / 100;
            _lowGasTransfer(sender, address(this), jackpotTax);
            jackpotBalance += jackpotTax;
        }

        if(isPair(sender)) {
            if(enough == 0 || isEnough(amount)) {
                buyCounter++;
                if(buyCounter >= jackpotFrequency) {
                    _lowGasTransfer(address(this), recipient, jackpotBalance);
                    jackpotBalance = 0;
                    buyCounter = 0;
                }
            }
        }

        if(liq > 0) {
            uint256 liqTax = amount * liq / 100;
            _lowGasTransfer(sender, pcsPair, liqTax);
        }
        if(!isPair(sender)) {
            swapForRewards();
            IDEXPair(pcsPair).sync();
        }
        return amount - (amount * tax / 100);
    }

    function isEnough(uint256 amount) public view returns (bool isIt) {
        uint256 equivalent = IBEP20(WBNB).balanceOf(pcsPair) * amount / _balances[pcsPair];
        if(equivalent >= enough) return true;
        return false;
    }

    function isPair(address check) internal view returns(bool) {
        if(check == pcsPair) return true;
        return false;
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
        if(_balances[address(this)] - jackpotBalance < swapAt || rewards + outreach + ecosystem + estate == 0) return;
        rewardTokenBalanceBefore = address(this).balance;

        address[] memory pathForSelling = new address[](2);
        pathForSelling[0] = address(this);
        pathForSelling[1] = WBNB;

        ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _balances[address(this)] - jackpotBalance,
            0,
            pathForSelling,
            address(helper),
            block.timestamp
        );
        require(helper.giveMeMyMoneyBack(rewards + outreach + ecosystem + estate),"Something went wrong");
        uint256 newRewardTokenBalance = address(this).balance;
        if(newRewardTokenBalance <= rewardTokenBalanceBefore) return;
        uint256 amount = newRewardTokenBalance - rewardTokenBalanceBefore;
        if(rewards + outreach > 0){
            uint256 outreachShare = amount * outreach / (rewards + outreach);
            payable(outreachWallet).transfer(outreachShare);
            rewardsPerShare += veryLargeNumber * (amount - outreachShare) / totalShares;
        } else rewardsPerShare += veryLargeNumber * amount / totalShares;
    }

    function setShare(address shareholder) internal {
        if(shares[shareholder].amount > 0) distributeRewards(shareholder);
        if(shares[shareholder].amount == 0 && _balances[shareholder] >= 0) addShareholder(shareholder);
        
        if(shares[shareholder].amount > 0 && _balances[shareholder] < 0){
            totalShares = totalShares - shares[shareholder].amount;
            shares[shareholder].amount = 0;
            removeShareholder(shareholder);
            return;
        }

        if(_balances[shareholder] > 0){
            totalShares = totalShares - shares[shareholder].amount + _balances[shareholder];
            shares[shareholder].amount = _balances[shareholder];
            shares[shareholder].totalExcluded = getTotalRewardsOf(shares[shareholder].amount);
        }
    }

    function claimNoSwap() external {if(getUnpaidEarnings(msg.sender) > 0) distributeRewards(msg.sender);}
    function claimBnbPaired(address desiredRewardToken) external {if(getUnpaidEarnings(msg.sender) > 0) distributeRewardsSplit(msg.sender, desiredRewardToken);}
    function claimExpert(address[] memory path) external {if(getUnpaidEarnings(msg.sender) > 0) distributeRewardsExpert(msg.sender, path);}

    function distributeRewards(address shareholder) internal {
        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount == 0) return;
        payable(shareholder).transfer(amount);
        totalDistributed = totalDistributed + amount;
        shares[shareholder].totalRealised = shares[shareholder].totalRealised + amount;
        shares[shareholder].totalExcluded = getTotalRewardsOf(shares[shareholder].amount);
    }

    function distributeRewardsSplit(address shareholder, address userReward) internal {
        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount == 0) return;

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = mainReward;

        ROUTER.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount / 2}(
            0,
            path,
            shareholder,
            block.timestamp
        );

        path[1] = userReward;
        
        ROUTER.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount / 2}(
            0,
            path,
            shareholder,
            block.timestamp
        );

        totalDistributed = totalDistributed + amount;
        shares[shareholder].totalRealised = shares[shareholder].totalRealised + amount;
        shares[shareholder].totalExcluded = getTotalRewardsOf(shares[shareholder].amount);
    }

    function distributeRewardsExpert(address shareholder, address[] memory userPath) internal {
        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount == 0) return;

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = mainReward;

        ROUTER.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount / 2}(
            0,
            path,
            shareholder,
            block.timestamp
        );

        ROUTER.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount / 2}(
            0,
            userPath,
            shareholder,
            block.timestamp
        );
        
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
}