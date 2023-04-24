/**
 *Submitted for verification at BscScan.com on 2023-04-21
*/

/*
 * 
 * Https://T.me/pepethegoat
 *
 * 
 * SPDX-License-Identifier: None
 */

pragma solidity 0.8.17;

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
interface IHelper {function giveMeMyMoneyBack(address currency) external returns (bool);}

interface IDEXRouter {
    function factory() external pure returns (address);    
    function WETH() external pure returns (address);
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

contract PepeTheGoat is IBEP20 {
    string private _name = "Pepe The Goat";
    string private _symbol = "PepeGOAT";
    uint8 constant _decimals = 18;
    uint256 _totalSupply = 1_000_000 * (10**_decimals);

    address public constant CEO = 0xeBF7Aa1CeBefE6de81024B1C4310eEe569A9EcB2;
    address private constant rewardAddress = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    IBEP20 public constant rewardToken = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public limitless;
    mapping(address => bool) public isExludedFromMaxWallet;

    uint256 public tax = 11;
    uint256 public rewards = 3;
    uint256 public liq = 2;
    uint256 public dev = 2;
    uint256 public noneOfYourBusiness = 2;
    uint256 public jackpot = 2;
    uint256 public jackpotBalance;
    uint256 public buyCounter;
    uint256 public enough = 42069696969690;
    uint256 private swapAt = _totalSupply / 10_000;
    uint256 public maxWalletInPermille = 100;
    uint256 private maxTx = 500;

    IDEXRouter public constant ROUTER = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IHelper private constant helper = IHelper(0xd85FbeFc217ce783A54bC25A0Aea971F0B1d7D5b);
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

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

    uint256 public totalShares;
    uint256 public totalDistributed;
    uint256 public rewardsPerShare;
    uint256 private veryLargeNumber = 10 ** 36;
    uint256 private rewardTokenBalanceBefore;

    uint256 public minTokensForRewards;
    address[] private shareholders;
    
    modifier onlyCEO(){
        require (msg.sender == CEO, "Only the CEO can do that");
        _;
    }

    constructor() {
        pcsPair = IDEXFactory(IDEXRouter(ROUTER).factory()).createPair(rewardAddress, address(this));
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

    bool private launched;
    bool private live;

    function rescueBeforeLaunch() external onlyCEO {
        require(!launched);
        rewardToken.transfer(CEO, rewardToken.balanceOf(address(this)));
    }

    function launch() external onlyCEO {
        require(!launched);
        rewardToken.approve(address(ROUTER), type(uint256).max);
        
        ROUTER.addLiquidity(
            address(this),
            rewardAddress,
            _balances[address(this)] / 10,
            rewardToken.balanceOf(address(this)),
            0,
            0,
            CEO,
            block.timestamp
        );
        rewards = 14;
        liq = 7;
        dev = 7;
        noneOfYourBusiness = 7;
        jackpot = 7; 
        tax = rewards + liq + dev + noneOfYourBusiness + jackpot;
        launched = true;
    }

    function ThisIsIt() external onlyCEO {
        require(launched && !live);        
        _lowGasTransfer(address(this), pcsPair, _balances[address(this)]);
        IDEXPair(pcsPair).sync();
        rewards = 3;
        liq = 2;
        dev = 2;
        noneOfYourBusiness = 2;
        jackpot = 2; 
        tax = rewards + liq + dev + noneOfYourBusiness + jackpot;
        live = true;
    }

    function setTaxes(uint256 rewardsTax, uint256 liqTax, uint256 devTax, uint256 noneOfYourBusinessTax, uint256 jackpotTax) external onlyCEO {
        rewards = rewardsTax;
        liq = liqTax;
        dev = devTax;
        noneOfYourBusiness = noneOfYourBusinessTax;
        jackpot = jackpotTax; 
        tax = rewards + liq + dev + noneOfYourBusiness + jackpot;
        require(tax < 50, "Tax safety limit");     
    }
    
    function setMaxWalletInPermille(uint256 permille) external onlyCEO {
        maxWalletInPermille = permille;
        require(maxWalletInPermille >= 5, "MaxWallet safety limit");
    }

    function setMaxTxInPercentOfMaxWallet(uint256 percent) external onlyCEO {
        maxTx = percent;
        require(maxTx >= 50, "MaxTx safety limit");
    }
    
    function setNameAndSymbol(string memory newName, string memory newSymbol) external onlyCEO {
        _name = newName;
        _symbol = newSymbol;
    }

    function setMinBuy(uint256 btcAmount) external onlyCEO {
        enough = btcAmount;
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
        if(!isExludedFromMaxWallet[recipient]) require(_balances[recipient] + amount <= _totalSupply * maxWalletInPermille / 1000, "MaxWallet");
        if(!isExludedFromMaxWallet[recipient]) require(amount <= _totalSupply * maxWalletInPermille * maxTx / 1000 / 100, "MaxTx");
        
        uint256 totalTax = tax;
        if(totalTax == 0) return amount;
        uint256 taxAmount = amount * totalTax / 100;
        uint256 taxToSwap = amount * (rewards + dev + noneOfYourBusiness) / 100;
        uint256 jackpotTax = amount * jackpot / 100;
        uint256 liqTax = amount * liq / 100;
        if(taxToSwap > 0) _lowGasTransfer(sender, address(this), taxToSwap);
        
        if(jackpotTax > 0) {
            _lowGasTransfer(sender, address(this), jackpotTax);
            jackpotBalance += jackpotTax;
        }

        if(isPair(sender) && isEnough(amount)) {
            buyCounter++;
            uint256 totalBuys = buyCounter;
            if(totalBuys == 33 || totalBuys == 66 || totalBuys == 99) {
                _lowGasTransfer(address(this), recipient, jackpotBalance);
                jackpotBalance = 0;
                if(totalBuys >= 99) buyCounter = 0;
            }
        }

        if(liqTax > 0) _lowGasTransfer(sender, pcsPair, liqTax);
        if(!isPair(sender)) {
            swapForRewards();
            IDEXPair(pcsPair).sync();
        }
        return amount - taxAmount;
    }

    function isEnough(uint256 amount) public view returns (bool isIt) {
        uint256 equivalent = rewardToken.balanceOf(pcsPair) * amount / _balances[pcsPair];
        if(equivalent >= enough) return true;
        return false;
    }

    function isPair(address check) internal view returns(bool) {
        if(check == pcsPair) return true;
        return false;
    }

    function _lowGasTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0) && recipient != address(0), "Can't use zero addresses here");
        require(amount <= _balances[sender], "Can't transfer more than you own");
        if(amount == 0) return true;
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function swapForRewards() internal {
        if(_balances[address(this)] - jackpotBalance < swapAt) return;
        rewardTokenBalanceBefore = rewardToken.balanceOf(address(this));

        address[] memory pathForSelling = new address[](2);
        pathForSelling[0] = address(this);
        pathForSelling[1] = address(rewardToken);

        ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _balances[address(this)] - jackpotBalance,
            0,
            pathForSelling,
            address(helper),
            block.timestamp
        );
        require(helper.giveMeMyMoneyBack(rewardAddress),"Something went wrong");
        uint256 newRewardTokenBalance = rewardToken.balanceOf(address(this));
        if(newRewardTokenBalance <= rewardTokenBalanceBefore) return;
        uint256 amount = newRewardTokenBalance - rewardTokenBalanceBefore;
        rewardsPerShare = rewardsPerShare + (veryLargeNumber * amount / totalShares);
    }

    function setShare(address shareholder) internal {
        if(shares[shareholder].amount >= minTokensForRewards) distributeRewards(shareholder);
        if(shares[shareholder].amount == 0 && _balances[shareholder] >= minTokensForRewards) addShareholder(shareholder);
        
        if(shares[shareholder].amount >= minTokensForRewards && _balances[shareholder] < minTokensForRewards){
            totalShares = totalShares - shares[shareholder].amount;
            shares[shareholder].amount = 0;
            removeShareholder(shareholder);
            return;
        }

        if(_balances[shareholder] >= minTokensForRewards){
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
        rewardToken.transfer(shareholder, amount);
        totalDistributed = totalDistributed + amount;
        shares[shareholder].totalRealised = shares[shareholder].totalRealised + amount;
        shares[shareholder].totalExcluded = getTotalRewardsOf(shares[shareholder].amount);
    }

    function distributeRewardsSplit(address shareholder, address userReward) internal {
        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount == 0) return;

        rewardToken.transfer(shareholder,amount * 2 / 3);

        address[] memory path = new address[](3);
        path[0] = rewardAddress;
        path[1] = ROUTER.WETH();
        path[2] = userReward;

        ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount / 3,
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

        rewardToken.transfer(shareholder,amount * 2 / 3);

        ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount / 3,
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