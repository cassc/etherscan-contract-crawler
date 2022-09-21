// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/IPancakeRouter02.sol";
import "./interfaces/IPancakeFactory.sol";
import "./interfaces/IPancakePair.sol";
import "./interfaces/IAvionCollection.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

interface IPresaleReign {
    function getPresaleAmount(address who) external view returns(uint256);
}

contract ReignToken is ERC20Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable  {
    // for uint256;
    VRFCoordinatorV2Interface COORDINATOR;
    using SafeMathUpgradeable for uint256;

    //VRF Part

    error OnlyCoordinatorCanFulfill(address have, address want);

    bytes32 constant KEY_HASH = 0xcaf3c3727e033261d383b315559476f48034c13b18f8cafed4d871abe5049186;

    uint64 public s_subscriptionId;
    uint32 public numWords;
    uint16 public requestConfirmations;
    uint32 public callbackGasLimit;
    address public s_owner;
    bytes32 public keyHash;
    address private vrfCoordinator;


    //Real values

    struct StakingUserStruct {
        uint256 amount;
        uint256 unlockDate;
        uint256 amountAtStaking;
        uint256 amountClaim;
    }

    mapping(address => mapping(uint256 => StakingUserStruct)) public stacking;

    uint256[] public stakingDuration;
    uint256 public stakingTypeCount;

    bool public initialDistributionFinished;
    bool public swapEnabled;
    bool public autoRebase;

    uint256[] public rewardYields;
    uint256 public rewardYieldDenominator;

    uint256 public rebaseFrequency;
    uint256 public nextRebase;

    mapping(address => bool) _isFeeExempt;
    address[] public _markerPairs;
    mapping(address => bool) public automatedMarketMakerPairs;

    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY =
        150_000_000 ether;
    uint256 private constant MAX_SUPPLY = ~uint128(0);

    uint256 private constant TOTAL_GONS =
        MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;

    address public liquidityReceiver;
    address public treasuryReceiver;
    address public teamReceiver;
    address public burnReceiver;

    address public busdToken;

    IPancakeRouter02 public router;
    address public pair;
    address public presale;

    uint256[] public buyFees;
    uint256[] public sellFees;

    uint256 public totalBuyFee;
    uint256 public totalSellFee;
    uint256 public totalTransferFee;

    uint256 public feeDenominator;

    uint256 public percentageForLessThanSevenDays;
    uint256 public percentageForMoreThanSevenDays;

    bool inSwap;

    modifier swapping() {
        require (inSwap == false, "ReentrancyGuard: reentrant call");
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier validRecipient(address to) {
        require(to != address(0x0), "Recipient zero address");
        _;
    }

    uint256 private _totalSupply;
    uint256[] private _yields;
    uint256[] private supplys;
    uint256 private gonSwapThreshold;

    struct userSale {
        uint256 amountAvailable;
        uint256 lastTimeSold;
    }

    mapping(address => userSale) public usersInfo;

    mapping(address => uint256) private _gonBalances;
    mapping(address => uint256) public _depositBalances;
    mapping(address => mapping(address => uint256)) private _allowedFragments;
    mapping(address => bool) public isMigrate;

    function initialize(address _busdToken, address _presale) public initializer {

        __ERC20_init("Reign", "REIGN");
        __ReentrancyGuard_init();
        __Ownable_init();
        rewardYieldDenominator = 10000000000;
        
        busdToken = _busdToken;
        presale = _presale;

        _allowedFragments[address(this)][address(this)] = type(uint256).max;

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[msg.sender] = TOTAL_GONS;

        _yields = [TOTAL_GONS.div(_totalSupply), TOTAL_GONS.div(_totalSupply), TOTAL_GONS.div(_totalSupply), TOTAL_GONS.div(_totalSupply)];

        gonSwapThreshold = (1500 * (10 ** 18)) * rewardYieldDenominator;

        _isFeeExempt[treasuryReceiver] = true;
        _isFeeExempt[teamReceiver] = true;
        _isFeeExempt[address(this)] = true;
        _isFeeExempt[msg.sender] = true;

        emit Transfer(address(0x0), msg.sender, _totalSupply);

        swapEnabled = true;
        rewardYields = [3541667, 3958333, 4375000, 4791667];
        stakingDuration = [30 days, 45 days, 60 days];


        supplys = [_totalSupply, _totalSupply, _totalSupply, _totalSupply];

        rebaseFrequency = 1800;
        nextRebase = block.timestamp + 31536000;

        liquidityReceiver = 0xd16455d232541976fa0CAe45beBeD2EBc0E22a36;
        treasuryReceiver = 0xd16455d232541976fa0CAe45beBeD2EBc0E22a36;
        teamReceiver = 0xef85dD99AfDC6b8c2878F1ea50d57F1Ad75fC9bB;
        burnReceiver = 0xd4b83a1fbb5A9B5925A77fEbb78D6e7b99975815;

        feeDenominator = 100;

        percentageForLessThanSevenDays = 50;
        percentageForMoreThanSevenDays = 100;
    }






    /* Blacklist */

    mapping(address => bool) public blacklist;

    function setBlacklist(address user, bool isBlacklist) external onlyOwner {
        blacklist[user] = isBlacklist;
    }

    modifier noBlacklist(address user) {
        require(blacklist[user] == false, "You're blacklist");
        _;
    }





    /* Basic token function */

    uint256 public holders;
    mapping(address => bool) public alreadyHolder;

    function allowance(address owner_, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    function balanceOf(address who) public view override returns (uint256) {
        return _gonBalances[who].div(getYield());
    }

    function transfer(address to, uint256 value)
        public
        override
        returns (bool)
    {
        _transferFrom(msg.sender, to, value);
        return true;
    }

    function _basicTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        uint256 gonAmountFrom = amount.mul(getYield());
        uint256 gonAmountTo = amount.mul(getYield());
        _gonBalances[from] = _gonBalances[from].sub(gonAmountFrom);
        _gonBalances[to] = _gonBalances[to].add(gonAmountTo);

        emit Transfer(from, to, amount);

        return true;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal noBlacklist(sender) noBlacklist(recipient) returns (bool) {
        bool excludedAccount = _isFeeExempt[sender] || _isFeeExempt[recipient];

        require(
            initialDistributionFinished || excludedAccount,
            "Trading not started"
        );

        uint256 gonAmount = amount.mul(getYield());

        if (recipient == address(pair)) require(sender == address(router), "NO");
        if (sender == address(pair)) require(recipient == address(router), "NO");

        _gonBalances[sender] = _gonBalances[sender].sub(gonAmount);

        uint256 gonAmountReceived = shouldTakeFee(sender, recipient)
            ? takeFee(sender, recipient, gonAmount, getYield())
            : gonAmount;

        _gonBalances[recipient] = _gonBalances[recipient].add(
            gonAmountReceived
        );

        if (usersInfo[recipient].lastTimeSold == 0) usersInfo[recipient].lastTimeSold = block.timestamp;

        if (alreadyHolder[recipient] == false) {
            alreadyHolder[recipient] = true;
            holders += 1;
        }

        emit Transfer(
            sender,
            recipient,
            gonAmountReceived.div(getYield())
        );

        if (shouldRebase() && autoRebase && sender != address(router) && recipient != address(router)) {
            _rebase();
        }

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override validRecipient(to) returns (bool) {
        if (_allowedFragments[from][msg.sender] != type(uint256).max) {
            _allowedFragments[from][msg.sender] = _allowedFragments[from][
                msg.sender
            ].sub(value, "Insufficient Allowance");
        }

        _transferFrom(from, to, value);
        return true;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return (TOTAL_GONS.sub(_gonBalances[DEAD]).sub(_gonBalances[ZERO])).div(getYield());
    }

    function mint(uint256 amount) external onlyOwner {
        _gonBalances[msg.sender] += amount.mul(getYield());
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        override
        returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(
                subtractedValue
            );
        }
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        override
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][
            spender
        ].add(addedValue);
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function approve(address spender, uint256 value)
        public
        override
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }




    /* Rebase function */


    function setNextRebase(uint256 _nextRebase) external onlyOwner {
        nextRebase = _nextRebase;
        emit SetNextRebase(_nextRebase);
    }

    function shouldRebase() internal view returns (bool) {
        return nextRebase <= block.timestamp;
    }

    function _rebase() private {
        if (!inSwap) {

            if (rebaseWithBonus >= 2) {
                resetYieldStaking();
                rebaseWithBonus = 0;
            }

            uint256 epoch = block.timestamp;
            nextRebase = epoch + rebaseFrequency;

            for (uint256 i; i < rewardYields.length; i++) {

                supplys[i] += supplys[i] * rewardYields[i] / rewardYieldDenominator;

                _yields[i]= TOTAL_GONS.div(supplys[i]);
            }

            if (pair != address(0x0)) IPancakePair(pair).sync();

            if (rewardYields[1] != 3958333) rebaseWithBonus += 1;

            emit LogRebase(epoch);
        }
    }

    function setAutoRebase(bool _autoRebase) external onlyOwner {
        require(autoRebase != _autoRebase, "Not changed");
        autoRebase = _autoRebase;
        emit SetAutoRebase(_autoRebase);
    }

    function getYield() public view returns(uint256) {
        return _yields[0];
    }

    function manualRebase() external nonReentrant {
        require(!inSwap, "Try again");
        require(nextRebase <= block.timestamp, "Not in time");

        _rebase();
        emit ManualRebase();
    }

    function setRebaseFrequency(uint256 _rebaseFrequency) external onlyOwner {
        rebaseFrequency = _rebaseFrequency;
        emit SetRebaseFrequency(_rebaseFrequency);
    }

    address public botForBonus;

    function setBotForBonus(
        address _botForBonus
    ) external onlyOwner {
        botForBonus = _botForBonus;
    }

    function bonusTime() external {
        require(msg.sender == botForBonus);

        COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function getNextRebaseToken(address user) external view returns (uint256 _amount) {
        return balanceOf(user) * rewardYields[0] / rewardYieldDenominator;
    }




    /* VRF config */

    function setChainLinkParam(
        uint64 _s_subscriptionId,
        uint32 _numWords,
        uint16 _requestConfirmations,
        uint32 _callbackGasLimit,
        address _vrfCoordinator,
        bytes32 _keyHash,
        address _owner
    ) external onlyOwner {
        s_subscriptionId = _s_subscriptionId;
        numWords = _numWords;
        requestConfirmations = _requestConfirmations;
        callbackGasLimit = _callbackGasLimit;
        s_owner = _owner;
        keyHash = _keyHash;
        vrfCoordinator = _vrfCoordinator;
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
    }

    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
        if (msg.sender != vrfCoordinator) {
            revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
        }
        fulfillRandomWords(requestId, randomWords);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomness) internal {
        uint256 random1 = (randomness[0] % 14530000) + 6300000;
        uint256 random2 = (randomness[1] % 14530000) + 6300000;
        uint256 random3 = (randomness[2] % 14530000) + 6300000;

        rewardYields = [3541667, random1, random2, random3];
        rebaseWithBonus = 0;
    }

    function resetYieldStaking() internal {
        rewardYields = [3541667, 3958333, 4375000, 4791667];
    }





    /* Tax functions */

    function setFeeExempt(address _addr, bool _value) external onlyOwner {
        require(_isFeeExempt[_addr] != _value, "Not changed");
        _isFeeExempt[_addr] = _value;
        emit SetFeeExempted(_addr, _value);
    }

    function checkFeeExempt(address _addr) external view returns (bool) {
        return _isFeeExempt[_addr];
    }

    function setFees(
        //0 : Liquidity
        //1 : Treasury
        //2 : Team
        //3 : Burn
        uint256[] memory _buyFees,
        uint256[] memory _sellFees,
        uint256[] memory _transferFees,
        uint256 _feeDenominator
    ) external onlyOwner {

        buyFees = _buyFees;
        sellFees = _sellFees;

        totalBuyFee = 0;
        totalSellFee = 0;
        totalTransferFee = 0;

        for (uint256 i; i < buyFees.length; i++) {
            totalBuyFee += buyFees[i];
        }

        require(totalBuyFee <= 40, 'Buy tax too high');

        for (uint256 i; i < sellFees.length; i++) {
            totalSellFee += sellFees[i];
        }

        require(totalSellFee <= 40, 'Sell tax too high');

        for (uint256 i; i < _transferFees.length; i++) {
            totalTransferFee += _transferFees[i];
        }

        require(totalTransferFee <= 40, 'Transfer tax too high');

        feeDenominator = _feeDenominator;
    }

    function shouldTakeFee(address from, address to)
        internal
        view
        returns (bool)
    {
        if (_isFeeExempt[from] || _isFeeExempt[to] || to == address(pair)) {
            return false;
        } else return true;
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 gonAmount,
        uint256 gonsPerFragment
    ) internal returns (uint256) {
        uint256 _realFee = totalTransferFee;
        /* if (automatedMarketMakerPairs[recipient]) {
            _realFee = totalSellFee;
if (automatedMarketMakerPairs[sender]) _realFee = totalBuyFee;
            if (updateAvailableAmount(sender, gonAmount.div(gonsPerFragment))) _realFee += 40;
        } else  */
        

        uint256 feeAmount = gonAmount.mul(_realFee).div(feeDenominator);

        _gonBalances[address(this)] = _gonBalances[address(this)].add(
            feeAmount
        );

        emit Transfer(sender, address(this), feeAmount.div(gonsPerFragment));

        return gonAmount.sub(feeAmount);
    }

    function getAvailableAmount(address sender) external view returns(uint256) {
        if (block.timestamp - usersInfo[sender].lastTimeSold >= 1 days) {
            return getMaxSellAmount(sender);
        }
        return usersInfo[sender].amountAvailable;
    }

    function updateAvailableAmount(address sender, uint256 amount) public returns (bool overTheLimit) {
        require(msg.sender == address(router), 'ERR');
        if (_isFeeExempt[sender]) {
            return false;
        }

        if (block.timestamp - usersInfo[sender].lastTimeSold >= 1 days) {
            usersInfo[sender].amountAvailable = getMaxSellAmount(sender);
            usersInfo[sender].lastTimeSold = block.timestamp;
        }

        if (amount > usersInfo[sender].amountAvailable) {
            usersInfo[sender].amountAvailable = 0;
            return true;
        } else {
            usersInfo[sender].amountAvailable = (usersInfo[sender].amountAvailable).sub(amount);
            return false;
        }        
    }





    /* Swap Back sell tokens */

    function setRouter(address _router) external onlyOwner {
        router = IPancakeRouter02(_router);
    }


    /* Staking part */

    mapping(uint256 => uint256) public totalStaked;
    
    uint256 public rebaseWithBonus;

    function stake(uint256 stakingType, uint256 amount) external  {
        require(stacking[msg.sender][stakingType].amount == 0, "You already staking this type");
        require(stakingType < stakingTypeCount, "Staking type doesn't exist");

        require(amount != 0, "Amount can't be 0");

        require(balanceOf(msg.sender) >= amount, "Insufficient amount");

        _gonBalances[msg.sender] -= amount.mul(getYield());

        totalStaked[stakingType] += amount.mul(_yields[stakingType + 1]);

        stacking[msg.sender][stakingType] = StakingUserStruct(
            amount.mul(_yields[stakingType + 1]),
            block.timestamp + stakingDuration[stakingType],
            amount,
            0
        );

        emit Transfer(msg.sender, address(this), amount);
    }

    function claim(uint256 stakingType) external nonReentrant {
        require(stacking[msg.sender][stakingType].amount != 0, "Staking unused");
        require(stakingType < stakingTypeCount, "Staking type doesn't exist");

        require(stacking[msg.sender][stakingType].amount.div(_yields[stakingType + 1]) - stacking[msg.sender][stakingType].amountAtStaking - stacking[msg.sender][stakingType].amountClaim > 0, "You have nothing to claim");

        uint256 amountToClaim = (stacking[msg.sender][stakingType].amount.div(_yields[stakingType + 1]) - stacking[msg.sender][stakingType].amountAtStaking - stacking[msg.sender][stakingType].amountClaim);

        totalStaked[stakingType] -= amountToClaim.mul(_yields[stakingType + 1]);
        _gonBalances[msg.sender] += amountToClaim.mul(getYield());

        stacking[msg.sender][stakingType].amountClaim += amountToClaim;

        emit Transfer(address(this), msg.sender, amountToClaim);
    }

    function unstake(uint256 stakingType) external nonReentrant {
        require(stacking[msg.sender][stakingType].amount != 0, "Staking unused");
        require(stakingType < stakingTypeCount, "Staking type doesn't exist");

        require(stacking[msg.sender][stakingType].unlockDate <= block.timestamp, "You need to wait the unstake date");

        _gonBalances[msg.sender] += (stacking[msg.sender][stakingType].amount.div(_yields[stakingType + 1]) - stacking[msg.sender][stakingType].amountClaim).mul(getYield());

        totalStaked[stakingType] -= stacking[msg.sender][stakingType].amount;

        emit Transfer(address(this), msg.sender, stacking[msg.sender][stakingType].amount.div(_yields[stakingType + 1]) - stacking[msg.sender][stakingType].amountClaim);

        stacking[msg.sender][stakingType] = StakingUserStruct(0,0,0,0);
    }

    function setStakeDuration(uint256 stakeType, uint256 timeInSec) external onlyOwner {
        stakingDuration[stakeType] = timeInSec;
    }

    function setStakingTypeCount(uint256 _stakingTypeCount) external onlyOwner {
        stakingTypeCount = _stakingTypeCount;
    }

    function getStakingAmount(address user) external view returns (uint256[] memory _used) {
        uint256[] memory used = new uint256[](stakingTypeCount);
        for (uint256 i = 0; i < stakingTypeCount; i++) {
            used[i] = (stacking[user][i].amount.div(_yields[i + 1]) - stacking[msg.sender][i].amountClaim);
        }
        return used;
    }

    function getStakingUnlocked(address user) external view returns (bool[] memory _used) {
        bool[] memory used = new bool[](stakingTypeCount);
        for (uint256 i = 0; i < stakingTypeCount; i++) {
            used[i] = stacking[user][i].unlockDate < block.timestamp;
        }
        return used;
    }

    function getStakingAmountInitial(address user) external view returns (uint256[] memory _initial) {
        uint256[] memory used = new uint256[](stakingTypeCount);
        for (uint256 i = 0; i < stakingTypeCount; i++) {
            used[i] = stacking[user][i].amountAtStaking;
        }
        return used;
    }

    function getTotalStaked() external view returns (uint256 staked) {
        uint256 _totalStaked;
        for (uint256 i = 0; i < stakingTypeCount; i++) {
            _totalStaked += totalStaked[i].div(_yields[i + 1]);
        }
        return _totalStaked;
    }

    function getStakedTokens(address user, uint256 stakeType) external view returns (uint256 tokenStaked) {
        return stacking[user][stakeType].amount.div(_yields[stakeType + 1]);
    }

    function getNewRebaseStakedToken(address user) external view returns (uint256 _nextRebase) {
        uint256 nextRebase;
        for (uint256 i = 0; i < stakingTypeCount; i++) {
            nextRebase += (stacking[user][i].amount.div(_yields[i + 1]) - stacking[msg.sender][i].amountClaim) * rewardYields[i + 1] / rewardYieldDenominator;
        }
        return nextRebase;
    }

    function getRebaseDailyStakedToken(address user) public view returns (uint256 _nextRebase) {
        uint256 nextRebase;
        nextRebase += (stacking[user][0].amount.div(_yields[1]) - stacking[msg.sender][0].amountClaim) * 19 / 1000;
        nextRebase += (stacking[user][1].amount.div(_yields[2]) - stacking[msg.sender][1].amountClaim) * 21 / 1000;
        nextRebase += (stacking[user][2].amount.div(_yields[3]) - stacking[msg.sender][2].amountClaim) * 23 / 1000;
        return nextRebase;
    }



    /* Anti Whale system */

    function getMaxSellAmount(address user) public view returns(uint256 maxSell) {
        return (getRebaseDailyStakedToken(user) + (balanceOf(user) * 17 / 1000)) * 2;
    }




    /* Random things */

    receive() external payable {}

    function setBUSD(address _busdToken) external onlyOwner {
        busdToken = _busdToken;
    }

    function setAutomatedMarketMakerPair(address _pair, bool _value)
        public
        onlyOwner
    {
        automatedMarketMakerPairs[_pair] = _value;
        pair = _pair;

        emit SetAutomatedMarketMakerPair(_pair, _value);
    }

    function setInitialDistributionFinished(bool _value) external onlyOwner {
        require(initialDistributionFinished != _value, "Not changed");
        initialDistributionFinished = _value;
        emit SetInitialDistributionFinished(_value);
    }

    function clearStuckBalance(address _receiver) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_receiver).transfer(balance);
        emit ClearStuckBalance(_receiver);
    }


    event SwapBack(
        uint256 contractTokenBalance,
        uint256 amountToLiquify,
        uint256 amountToTreasury,
        uint256 amountToTeam,
        uint256 amountToBurn
    );
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiqudity
    );
    event LogRebase(uint256 indexed epoch);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event ManualRebase();
    event SetInitialDistributionFinished(bool _value);
    event SetFeeExempted(address _addr, bool _value);
    event SetSwapBackSettings(bool _enabled, uint256 _num, uint256 _denom);
    event SetFeeReceivers(
        address _liquidityReceiver,
        address _treasuryReceiver,
        address _teamReceiver
    );
    event ClearStuckBalance(address _receiver);
    event SetAutoRebase(bool _autoRebase);
    event SetRebaseFrequency(uint256 _rebaseFrequency);
    event SetRewardYield(uint256[] _rewardYield, uint256 _rewardYieldDenominator);
    event SetIsLiquidityInBnb(bool _value);
    event SetNextRebase(uint256 _nextRebase);

}