/**
 *Submitted for verification at Etherscan.io on 2023-04-14
*/

/**
 *Submitted for verification at Etherscan.io on 2023-04-10
 */

// SPDX-License-Identifier: MIT

/*
                                                                                            
 .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------. 
| .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
| |    _______   | || |     ______   | || |  _______     | || |     _____    | || |   _____      | || |   _____      | || |      __      | |
| |   /  ___  |  | || |   .' ___  |  | || | |_   __ \    | || |    |_   _|   | || |  |_   _|     | || |  |_   _|     | || |     /  \     | |
| |  |  (__ \_|  | || |  / .'   \_|  | || |   | |__) |   | || |      | |     | || |    | |       | || |    | |       | || |    / /\ \    | |
| |   '.___`-.   | || |  | |         | || |   |  __ /    | || |      | |     | || |    | |   _   | || |    | |   _   | || |   / ____ \   | |
| |  |`\____) |  | || |  \ `.___.'\  | || |  _| |  \ \_  | || |     _| |_    | || |   _| |__/ |  | || |   _| |__/ |  | || | _/ /    \ \_ | |
| |  |_______.'  | || |   `._____.'  | || | |____| |___| | || |    |_____|   | || |  |________|  | || |  |________|  | || ||____|  |____|| |
| |              | || |              | || |              | || |              | || |              | || |              | || |              | |
| '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
 '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'                                                                   
*/

pragma solidity ^0.8.10;

// interface IUniFactory   : Interface of Uniswap Router

interface IUniFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

// interface IUniRouter  : Interface of Uniswap

interface IUniRouter {
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
        returns (uint256 amountToken, uint256 amountETH, uint256 _liquedity);

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

// interface IERC20 : IERC20 Token Interface which would be used in calling token contract
interface IERC20 {
    function totalSupply() external view returns (uint256); //Total Supply of Token

    function decimals() external view returns (uint8); // Decimal of TOken

    function symbol() external view returns (string memory); // Symbol of Token

    function name() external view returns (string memory); // Name of Token

    function balanceOf(address account) external view returns (uint256); // Balance of TOken

    //Transfer token from one address to another

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    // Get allowance to the spacific users

    function allowance(
        address _owner,
        address spender
    ) external view returns (uint256);

    // Give approval to spend token to another addresses

    function approve(address spender, uint256 amount) external returns (bool);

    // Transfer token from one address to another

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    //Trasfer Event
    event Transfer(address indexed from, address indexed to, uint256 value);

    //Approval Event
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// This contract helps to add Owners
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Interface IRewardDistributor : Interface that is used by  Reward Distributor

interface IRewardDistributor {
    function setDistributionStandard(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external;

    function setShare(address shareholder, uint256 amount) external;

    function depositEth() external payable;

    function process(uint256 gas) external;

    function claimReward(address _user) external;

    function getPaidEarnings(
        address shareholder
    ) external view returns (uint256);

    function getUnpaidEarnings(
        address shareholder
    ) external view returns (uint256);

    function totalDistributed() external view returns (uint256);
}

// RewardDistributor : It distributes reward amoung holders

contract RewardDistributor is IRewardDistributor {
    using SafeMath for uint256;

    address public _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IERC20 public rewardTok =
        IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IUniRouter public router;

    address[] public shareholders;
    mapping(address => uint256) public shareholderIndexes;
    mapping(address => uint256) public shareholderClaims;

    mapping(address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalRewards;
    uint256 public totalDistributed;
    uint256 public rewardsPerShare;
    uint256 public rewardsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 1 minutes;
    uint256 public minDistribution = 1 * (10 ** rewardTok.decimals());

    uint256 currentIndex;

    bool initialized;
    modifier initializer() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    constructor(address _router) {
        _token = msg.sender;
        router = IUniRouter(_router);
    }

    function setDistributionStandard(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(
        address shareholder,
        uint256 amount
    ) external override onlyToken {
        if (shares[shareholder].amount > 0) {
            distributeReward(shareholder);
        }

        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeRewards(
            shares[shareholder].amount
        );
    }

    function depositEth() external payable override onlyToken {
        uint256 balanceBefore = rewardTok.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(rewardTok);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: msg.value
        }(0, path, address(this), block.timestamp);

        uint256 amount = rewardTok.balanceOf(address(this)).sub(balanceBefore);

        totalRewards = totalRewards.add(amount);
        rewardsPerShare = rewardsPerShare.add(
            rewardsPerShareAccuracyFactor.mul(amount).div(totalShares)
        );
    }

    function _changeRewardToken(address _rewadToken) public onlyToken {
        rewardTok = IERC20(_rewadToken);
    }

    function _withdrawTokenFunds(
        address _tokenAddress,
        uint256 _amount,
        address _reciverAddress
    ) public onlyToken {
        IERC20(_tokenAddress).transfer(_reciverAddress, _amount);
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) {
            return;
        }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }

            if (shouldDistribute(shareholders[currentIndex])) {
                distributeReward(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(
        address shareholder
    ) internal view returns (bool) {
        return
            shareholderClaims[shareholder] + minPeriod < block.timestamp &&
            getUnpaidEarnings(shareholder) > minDistribution;
    }

    //This function distribute the amounts
    function distributeReward(address shareholder) internal {
        if (shares[shareholder].amount == 0) {
            return;
        }

        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            rewardTok.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder]
                .totalRealised
                .add(amount);
            shares[shareholder].totalExcluded = getCumulativeRewards(
                shares[shareholder].amount
            );
        }
    }

    function claimReward(address _user) external {
        distributeReward(_user);
    }

    function getPaidEarnings(
        address shareholder
    ) public view returns (uint256) {
        return shares[shareholder].totalRealised;
    }

    function getUnpaidEarnings(
        address shareholder
    ) public view returns (uint256) {
        if (shares[shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalRewards = getCumulativeRewards(
            shares[shareholder].amount
        );
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalRewards <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalRewards.sub(shareholderTotalExcluded);
    }

    function getCumulativeRewards(
        uint256 share
    ) internal view returns (uint256) {
        return share.mul(rewardsPerShare).div(rewardsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[
            shareholders.length - 1
        ];
        shareholderIndexes[
            shareholders[shareholders.length - 1]
        ] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

// main contract of Token
contract Scrilla is IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = "Scrilla"; // Name
    string private constant _symbol = "Scrilla"; // Symbol
    uint8 private constant _decimals = 18;
    uint256 private constant _totalSupply = 1_000_000_000 * 10 ** _decimals; //Token Decimals

    uint256 maxTxnLimit = _totalSupply.div(100);
    uint256 maxHoldLimit = _totalSupply.mul(2).div(100);

    address public rewardTok = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // Reward Token
    address private constant ZERO = address(0); //Zero Address

    IUniRouter public router; //Router
    address public uniPair; //Pair
    address public marketFeeReceiver;
    address public devFeeReceiver;
    address public treasuryFeeReceiver;
    address public liquidityReceiver;

    uint256 public totalBuyFee = 5; //Total Buy Fee
    uint256 public totalSellFee = 5; //Total Sell Fee
    uint256 public feeDivider = 100; // Fee deniminator

    RewardDistributor public distributor;
    uint256 public distributorGas = 500000;

    // 5% on Buying
    uint256 _reflectionBuyFee = 1; // 1% on Buying
    uint256 _marketBuyFee = 2; // 2% on Buying
    uint256 _devBuyFee = 1; // 1% on Buying
    uint256 _treasuryBuyFee = 0; //0% on Buying
    uint256 _liquidityBuyFee = 1; //1% on Buying
    // 5% on Selling
    uint256 _reflectionSellFee = 1; // 1% on Selling
    uint256 _marketSellFee = 2; // 2% on Selling
    uint256 _devSellFee = 1; // 1% on Selling
    uint256 _treasurySellFee = 0; //0% on Selling
    uint256 _liquiditySellFee = 1; //1% on Selling

    uint256 _reflectionFeeCounter;
    uint256 _marketFeeCounter;
    uint256 _devFeeCounter;
    uint256 _treasuryFeeCounter;
    uint256 _liquidityFeeCounter;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isRewardExempt;
    mapping(address => bool) public _isExcludedFromMaxTxn;
    mapping(address => bool) public _isExcludedMaxHolding;

    bool public enableSwap = true;
    uint256 public swapLimit = 500_000 * (10 ** _decimals);
    uint256 public minTokenHoldingForReward;

    bool inSwap;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    event AutoLiquify(uint256 amountEth, uint256 amountBOG);

    // intializing the addresses

    constructor() {
        address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; //mainnet
        marketFeeReceiver = 0x71D911b5a55934C22dD62562CD8CccF313C0c0f8;
        devFeeReceiver = 0xe3b2899572780B4127aBC55b6A24EB1241e3D666;
        treasuryFeeReceiver = 0x71D911b5a55934C22dD62562CD8CccF313C0c0f8;
        liquidityReceiver = 0x71D911b5a55934C22dD62562CD8CccF313C0c0f8;

        minTokenHoldingForReward = 10000000e18;
        router = IUniRouter(_router);
        uniPair = IUniFactory(router.factory()).createPair(
            address(this),
            router.WETH()
        );
        distributor = new RewardDistributor(_router);

        isRewardExempt[uniPair] = true;
        isRewardExempt[address(this)] = true;
        isFeeExempt[marketFeeReceiver] = true;
        isFeeExempt[devFeeReceiver] = true;
        isFeeExempt[treasuryFeeReceiver] = true;
        isFeeExempt[liquidityReceiver] = true;
        isFeeExempt[owner()] = true;

        _isExcludedFromMaxTxn[owner()] = true;
        _isExcludedFromMaxTxn[uniPair] = true;
        _isExcludedFromMaxTxn[treasuryFeeReceiver] = true;
        _isExcludedFromMaxTxn[address(this)] = true;
        _isExcludedFromMaxTxn[liquidityReceiver] = true;
        _isExcludedFromMaxTxn[address(router)] = true;
        _isExcludedFromMaxTxn[marketFeeReceiver] = true;
        _isExcludedFromMaxTxn[devFeeReceiver] = true;

        _isExcludedMaxHolding[address(this)] = true;
        _isExcludedMaxHolding[owner()] = true;
        _isExcludedMaxHolding[uniPair] = true;
        _isExcludedMaxHolding[treasuryFeeReceiver] = true;
        _isExcludedMaxHolding[liquidityReceiver] = true;
        _isExcludedMaxHolding[address(router)] = true;
        _isExcludedMaxHolding[marketFeeReceiver] = true;
        _isExcludedMaxHolding[devFeeReceiver] = true;

        _balances[owner()] = _totalSupply;

        _allowances[address(this)][address(router)] = _totalSupply;
        _allowances[address(this)][address(uniPair)] = _totalSupply;

        emit Transfer(address(0), owner(), _totalSupply);
    }

    receive() external payable {}

    // totalSupply() : Shows total Supply of token

    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }

    //decimals() : Shows decimals of token

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    // symbol() : Shows symbol of function

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    // name() : Shows name of Token

    function name() external pure override returns (string memory) {
        return _name;
    }

    // balanceOf() : Shows balance of the spacific user

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    //allowance()  : Shows allowance of the address from another address

    function allowance(
        address holder,
        address spender
    ) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    // approve() : This function gives allowance of token from one address to another address
    //  ****     : Allowance is checked in TransferFrom() function.

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // approveMax() : approves the token amount to the spender that is maximum amount of token

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    // transfer() : Transfers tokens  to another address

    function transfer(
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        return _transfer(msg.sender, recipient, amount);
    }

    // transferFrom() : Transfers token from one address to another address by utilizing allowance

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != _totalSupply) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }

        return _transfer(sender, recipient, amount);
    }

    // _transfer() :   called by external transfer and transferFrom function

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (!_isExcludedMaxHolding[recipient]) {
            require(
                amount.add(balanceOf(recipient)) <= maxHoldLimit,
                "Max hold limit exceeds"
            );
        }
        if (
            !_isExcludedFromMaxTxn[sender] && !_isExcludedFromMaxTxn[recipient]
        ) {
            require(amount <= maxTxnLimit, "BigBuy: max txn limit exceeds");
        }
        if (inSwap) {
            return _simpleTransfer(sender, recipient, amount);
        }

        if (shouldSwap()) {
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
            (sender != uniPair && recipient != uniPair)
        ) {
            amountReceived = amount;
        } else {
            uint256 feeAmount;
            if (sender == uniPair) {
                feeAmount = amount.mul(totalBuyFee).div(feeDivider);
                amountReceived = amount.sub(feeAmount);
                _takeFee(sender, feeAmount);
                setBuyFeeCount(amount);
            }
            if (recipient == uniPair) {
                feeAmount = amount.mul(totalSellFee).div(feeDivider);
                amountReceived = amount.sub(feeAmount);
                _takeFee(sender, feeAmount);
                setSellFeeCount(amount);
            }
        }

        _balances[recipient] = _balances[recipient].add(amountReceived);

        if (!isRewardExempt[sender]) {
            if ((balanceOf(sender)) >= minTokenHoldingForReward) {
                try distributor.setShare(sender, _balances[sender]) {} catch {}
            } else {
                try distributor.setShare(sender, 0) {} catch {}
            }
        }
        if (!isRewardExempt[recipient]) {
            if ((balanceOf(recipient)) >= minTokenHoldingForReward) {
                try
                    distributor.setShare(recipient, _balances[recipient])
                {} catch {}
            } else {
                try distributor.setShare(recipient, 0) {} catch {}
            }
        }

        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    // _simpleTransfer() : Transfer basic token account to account

    function _simpleTransfer(
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

    function airdrop(
        address[] calldata addresses,
        uint256[] calldata amounts
    ) external onlyOwner {
        require(
            addresses.length == amounts.length,
            "Array sizes must be equal"
        );
        uint256 i = 0;
        while (i < addresses.length) {
            uint256 _amount = amounts[i].mul(1e18);
            _simpleTransfer(msg.sender, addresses[i], _amount);
            i += 1;
        }
    }

    // _takeFee() : This function get calls internally to take fee

    function _takeFee(address sender, uint256 feeAmount) internal {
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
    }

    function setBuyFeeCount(uint256 _amount) internal {
        _reflectionFeeCounter = _amount.mul(_reflectionBuyFee).div(feeDivider);
        _marketFeeCounter = _amount.mul(_marketBuyFee).div(feeDivider);
        _devFeeCounter = _amount.mul(_devBuyFee).div(feeDivider);
        _treasuryFeeCounter = _amount.mul(_treasuryBuyFee).div(feeDivider);
        _liquidityFeeCounter = _amount.mul(_liquidityBuyFee).div(feeDivider);
    }

    function setSellFeeCount(uint256 _amount) internal {
        _reflectionFeeCounter = _amount.mul(_reflectionSellFee).div(feeDivider);
        _marketFeeCounter = _amount.mul(_marketSellFee).div(feeDivider);
        _devFeeCounter = _amount.mul(_devSellFee).div(feeDivider);
        _treasuryFeeCounter = _amount.mul(_treasurySellFee).div(feeDivider);
        _liquidityFeeCounter = _amount.mul(_liquiditySellFee).div(feeDivider);
    }

    //shouldSwap() : To check swap should be done or not

    function shouldSwap() internal view returns (bool) {
        return (msg.sender != uniPair &&
            !inSwap &&
            enableSwap &&
            _balances[address(this)] >= swapLimit);
    }

    //Swapback() : To swap and liqufy the token

    function swapBack() internal swapping {
        uint256 totalFee = _reflectionFeeCounter
            .add(_marketFeeCounter)
            .add(_devFeeCounter)
            .add(_treasuryFeeCounter)
            .add(_liquidityFeeCounter);
        if (totalFee > 0) {
            uint256 amountToLiquify = swapLimit
                .mul(_liquidityFeeCounter)
                .div(totalFee)
                .div(2);

            uint256 amountToSwap = swapLimit.sub(amountToLiquify);

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

            uint256 totalEthFee = totalFee.sub(_liquidityFeeCounter.div(2));

            uint256 amountEthForLiqudity = amountEth
                .mul(_liquidityFeeCounter)
                .div(totalEthFee)
                .div(2);

            uint256 amountEthForReflection = amountEth
                .mul(_reflectionFeeCounter)
                .div(totalFee);
            uint256 amountEthForMarket = amountEth.mul(_marketFeeCounter).div(
                totalFee
            );
            uint256 amountEthForDev = amountEth.mul(_devFeeCounter).div(
                totalFee
            );
            uint256 amountEthForTreasury = amountEth
                .mul(_treasuryFeeCounter)
                .div(totalFee);

            try
                distributor.depositEth{value: amountEthForReflection}()
            {} catch {}
            if (amountEthForMarket > 0) {
                payable(marketFeeReceiver).transfer(amountEthForMarket);
            }

            if (amountEthForDev > 0) {
                payable(devFeeReceiver).transfer(amountEthForDev);
            }
            if (amountEthForTreasury > 0) {
                payable(treasuryFeeReceiver).transfer(amountEthForTreasury);
            }

            if (amountToLiquify > 0) {
                router.addLiquidityETH{value: amountEthForLiqudity}(
                    address(this),
                    amountToLiquify,
                    0,
                    0,
                    liquidityReceiver,
                    block.timestamp
                );
                emit AutoLiquify(amountEthForLiqudity, amountToLiquify);
            }

            _reflectionFeeCounter = 0;
            _marketFeeCounter = 0;
            _devFeeCounter = 0;
            _treasuryFeeCounter = 0;
        }
    }

    // claimReward() : Function that claims divident manually

    function claimReward() external {
        distributor.claimReward(msg.sender);
    }

    // getPaidReward() :Function shows paid Rewards of the user

    function getPaidReward(address shareholder) public view returns (uint256) {
        return distributor.getPaidEarnings(shareholder);
    }

    // getUnpaidReward() : Function shows unpaid rewards of the user

    function getUnpaidReward(
        address shareholder
    ) external view returns (uint256) {
        return distributor.getUnpaidEarnings(shareholder);
    }

    // getTotalDistributedReward(): Shows total distributed Reward

    function getTotalDistributedReward() external view returns (uint256) {
        return distributor.totalDistributed();
    }

    function withdrawReflectionTokenFunds(
        address _tokenAddress,
        uint256 _amount
    ) public onlyOwner {
        distributor._withdrawTokenFunds(_tokenAddress, _amount, msg.sender);
    }

    function MinTokenHoldingForReward(
        uint256 _minTokenHoldingForReward
    ) public onlyOwner {
        minTokenHoldingForReward = _minTokenHoldingForReward;
    }

    function withdrawEth(uint256 _ethValue) public onlyOwner {
        payable(msg.sender).transfer(_ethValue);
    }

    function changeRewardToken(address _tokenAddress) public onlyOwner {
        distributor._changeRewardToken(_tokenAddress);
    }

    // setFeeExempt() : Function that Set Holders Fee Exempt
    //   ***          : It add user in fee exempt user list
    //   ***          : Owner & Authoized user Can set this

    function setFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    // setRewardExempt() : Set Holders Reward Exempt
    //      ***          : Function that add user in reward exempt user list
    //      ***          : Owner & Authoized user Can set this

    function setRewardExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != uniPair);
        isRewardExempt[holder] = exempt;
        if (exempt) {
            distributor.setShare(holder, 0);
        } else {
            distributor.setShare(holder, _balances[holder]);
        }
    }

    // includeOrExcludeFromMaxTxn() : Function that set users exclude from fee
    //   ***       : Owner & Authoized user Can set the fees
    function includeOrExcludeFromMaxTxn(
        address account,
        bool value
    ) external onlyOwner {
        _isExcludedFromMaxTxn[account] = value;
    }

    function includeOrExcludeFromMaxHolding(
        address account,
        bool value
    ) external onlyOwner {
        _isExcludedMaxHolding[account] = value;
    }

    function setMaxHoldLimit(uint256 _amount) external onlyOwner {
        maxHoldLimit = _amount * 1e18;
    }

    function setMaxTxnLimit(uint256 _amount) external onlyOwner {
        maxTxnLimit = _amount * 1e18;
    }

    // setBuyFee() : Function that set Buy Fee of token
    //   ***       : Owner & Authoized user Can set the fees

    function setBuyFee(
        uint256 _reflectionFee,
        uint256 _marketFee,
        uint256 _devFee,
        uint256 _treasuryFee,
        uint256 _liquidityFee
    ) public onlyOwner {
        _reflectionBuyFee = _reflectionFee;
        _marketBuyFee = _marketFee;
        _devBuyFee = _devFee;
        _treasuryBuyFee = _treasuryFee;
        _liquidityBuyFee = _liquidityFee;
        totalBuyFee = (_reflectionFee)
            .add(_marketFee)
            .add(_devFee)
            .add(_liquidityFee)
            .add(_treasuryFee);
        require(totalBuyFee <= feeDivider.div(4), "Can't be greater than 25%");
    }

    // setSellFee() : Function that set Sell Fee
    //    ***       : Owner & Authoized user Can set the fees

    function setSellFee(
        uint256 _reflectionFee,
        uint256 _marketFee,
        uint256 _devFee,
        uint256 _treasuryFee,
        uint256 _liquidityFee
    ) public onlyOwner {
        _reflectionSellFee = _reflectionFee;
        _marketSellFee = _marketFee;
        _devSellFee = _devFee;
        _treasurySellFee = _treasuryFee;
        _liquiditySellFee = _liquidityFee;
        totalSellFee = (_reflectionFee)
            .add(_marketFee)
            .add(_liquidityFee)
            .add(_devFee)
            .add(_treasuryFee);
        require(totalSellFee <= feeDivider.div(4), "Can't be greater than 25%");
    }

    // setFeeReceivers() : Function to  set the addresses of Receivers
    //    ***            : Owner & Authoized user Can set the receivers

    function setFeeReceivers(
        address _marketFeeReceiver,
        address _devFeeReceiver,
        address _treasuryFeeReceiver,
        address _liquidityReceiver
    ) external onlyOwner {
        marketFeeReceiver = _marketFeeReceiver;
        devFeeReceiver = _devFeeReceiver;
        treasuryFeeReceiver = _treasuryFeeReceiver;
        liquidityReceiver = _liquidityReceiver;
    }

    // setSwapBack() : Function that enable of disable swapping functionality of token while transfer
    //     ***       : Swap Limit can be changed through this function
    //     ***       : Owner & Authoized user Can set the swapBack

    function setSwapBack(bool _enabled, uint256 _amount) external onlyOwner {
        enableSwap = _enabled;
        swapLimit = _amount;
    }

    // setDistributionStandard() : Function that set distribution standerd on which distributor works
    //      ***                  : Owner & Authoized user Can set the standerd of distributor

    function setDistributionStandard(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external onlyOwner {
        distributor.setDistributionStandard(_minPeriod, _minDistribution);
    }

    //setDistributorSetting() : Function that set changes the distribution gas fee which is used in distributor
    //        ***             : Owner & Authoized user Can set the this amount

    function setDistributorSetting(uint256 gas) external onlyOwner {
        require(gas < 750000, "Gas must be lower than 750000");
        distributorGas = gas;
    }
}

// Library used to perfoem math operations
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