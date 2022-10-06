//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account)
        internal
        view
        returns (bool)
    {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

contract DENJI is ERC20Detailed, Ownable {
    using SafeMath for uint256;

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);
    event NewNextRebase(uint256 nextRebase);
    event NewRewardYield(uint256 _rewardYield, uint256 _rewardYieldDenominator);
    event NewAutoRebase(bool _autoRebase);
    event NewRebaseFrequency(uint256 _rebaseFrequency);
    event DustSwiped(address _receiver, uint256 balance);
    event ManualRebase();
    event NewLPSet(address _address);
    event InitialDistributionFinished();
    event AddressExemptedFromTransferLock(address _addr);
    event AddressExemptedFromFee(address _addr);
    event NewSwapBackSet(bool _enabled, uint256 _num, uint256 _denom);
    event NewTargetLiquiditySet(uint256 target, uint256 accuracy);
    event NewFeeReceiversSet(
        address _autoLiquidityReceiver,
        address _treasuryReceiver
    );
    event NewFeesSet(
        uint256 _liquidityFee,
        uint256 _treasuryFee,
        uint256 _feeDenominator
    );

    IUniswapV2Pair public pairContract;

    bool public initialDistributionFinished;

    mapping(address => bool) allowTransfer;
    mapping(address => bool) _isFeeExempt;

    modifier initialDistributionLock() {
        require(
            initialDistributionFinished ||
                msg.sender == owner() ||
                allowTransfer[msg.sender]
        );
        _;
    }

    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }

    uint256 private constant DECIMALS = 18;
    uint256 private constant MAX_UINT256 = type(uint256).max;
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 4500 * 10**DECIMALS;
    IERC20 private constant USDC =
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    uint256 public liquidityFee = 2;
    uint256 private constant MaxliquidityFee = 2;
    uint256 public treasuryFee = 2;
    uint256 private constant MaxtreasuryFee = 2;
    uint256 public totalFee = liquidityFee.add(treasuryFee);
    uint256 public feeDenominator = 100;
    uint256 public rewardYield = 1272444125;
    uint256 public rewardYieldDenominator = 100000000000;
    uint256 public rebaseFrequency = 1 days;
    uint256 public nextRebase = block.timestamp + rebaseFrequency;
    bool public autoRebase = true;

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;

    address public autoLiquidityReceiver;
    address public treasuryReceiver;

    uint256 targetLiquidity = 50;
    uint256 targetLiquidityDenominator = 100;

    IUniswapV2Router02 public immutable router;

    bool public swapEnabled = true;
    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    uint256 private constant TOTAL_GONS = 
        MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    uint256 private constant MAX_SUPPLY = 10000 * 10**DECIMALS;
    uint256 private gonSwapThreshold = TOTAL_GONS / 1000;

    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;

    mapping(address => mapping(address => uint256)) private _allowedFragments;

    constructor(
        address _router,
        address _autoLiquidityReceiver,
        address _treasuryReceiver
    ) ERC20Detailed("Denji", "$DENJI", uint8(DECIMALS)) {
        router = IUniswapV2Router02(_router);

        address _pair = IUniswapV2Factory(IUniswapV2Router02(_router).factory())
            .createPair(address(USDC), address(this));

        autoLiquidityReceiver = _autoLiquidityReceiver;
        treasuryReceiver = _treasuryReceiver;

        _allowedFragments[address(this)][address(_router)] = type(uint256).max;
        USDC.approve(address(_router), type(uint256).max);

        pairContract = IUniswapV2Pair(_pair);

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[treasuryReceiver] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        initialDistributionFinished = false;
        _isFeeExempt[treasuryReceiver] = true;
        _isFeeExempt[address(this)] = true;

        _transferOwnership(treasuryReceiver);
        emit Transfer(address(0x0), treasuryReceiver, _totalSupply);
    }

    function setNextRebase(uint256 _nextRebase) external onlyOwner {
        nextRebase = _nextRebase;

        emit NewNextRebase(_nextRebase);
    }

    function setRewardYield(
        uint256 _rewardYield,
        uint256 _rewardYieldDenominator
    ) external onlyOwner {
        rewardYield = _rewardYield;
        rewardYieldDenominator = _rewardYieldDenominator;

        emit NewRewardYield(_rewardYield, _rewardYieldDenominator);
    }

    function setAutoRebase(bool _autoRebase) external onlyOwner {
        autoRebase = _autoRebase;

        emit NewAutoRebase(_autoRebase);
    }

    function setRebaseFrequency(uint256 _rebaseFrequency) external onlyOwner {
        rebaseFrequency = _rebaseFrequency;

        emit NewRebaseFrequency(_rebaseFrequency);
    }

    function shouldRebase() public view returns (bool) {
        return nextRebase <= block.timestamp;
    }

    function swipe(address _receiver) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_receiver).transfer(balance);

        emit DustSwiped(_receiver, balance);
    }

    function coreRebase(uint256 epoch, int256 supplyDelta)
        private
        returns (uint256)
    {
        if (supplyDelta == 0) {
            emit LogRebase(epoch, _totalSupply);
            return _totalSupply;
        }

        if (supplyDelta < 0) {
            _totalSupply = _totalSupply.sub(uint256(-supplyDelta));
        } else {
            _totalSupply = _totalSupply.add(uint256(supplyDelta));
        }

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        pairContract.sync();

        emit LogRebase(epoch, _totalSupply);
        return _totalSupply;
    }

    function _rebase() private {
        if (!inSwap) {
            uint256 epoch = block.timestamp;
            uint256 circulatingSupply = getCirculatingSupply();
            int256 supplyDelta = int256(
                circulatingSupply.mul(rewardYield).div(rewardYieldDenominator)
            );

            coreRebase(epoch, supplyDelta);
            nextRebase = epoch + rebaseFrequency;
        }
    }

    function rebase() external onlyOwner {
        require(!inSwap && shouldRebase(), "Try again");
        _rebase();

        emit ManualRebase();
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function transfer(address to, uint256 value)
        external
        override
        validRecipient(to)
        initialDistributionLock
        returns (bool)
    {
        _transferFrom(msg.sender, to, value);
        return true;
    }

    function setLP(address _address) external onlyOwner {
        pairContract = IUniswapV2Pair(_address);
        _isFeeExempt[_address];

        emit NewLPSet(_address);
    }

    function allowance(address owner_, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    function balanceOf(address who) external view override returns (uint256) {
        return _gonBalances[who].div(_gonsPerFragment);
    }

    function scaledBalanceOf(address who) external view returns (uint256) {
        return _gonBalances[who];
    }

    function _basicTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        uint256 gonAmount = amount.mul(_gonsPerFragment);
        _gonBalances[from] = _gonBalances[from].sub(gonAmount);
        _gonBalances[to] = _gonBalances[to].add(gonAmount);
        return true;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        uint256 gonAmount = amount.mul(_gonsPerFragment);

        if (shouldSwapBack()) {
            swapBack();
        }

        _gonBalances[sender] = _gonBalances[sender].sub(gonAmount);

        uint256 gonAmountReceived = shouldTakeFee(sender, recipient)
            ? takeFee(sender, gonAmount)
            : gonAmount;

        _gonBalances[recipient] = _gonBalances[recipient].add(
            gonAmountReceived
        );

        emit Transfer(
            sender,
            recipient,
            gonAmountReceived.div(_gonsPerFragment)
        );

        if (shouldRebase() && autoRebase) {
            _rebase();
        }

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override validRecipient(to) returns (bool) {
        if (_allowedFragments[from][msg.sender] != ~uint256(0)) {
            _allowedFragments[from][msg.sender] = _allowedFragments[from][
                msg.sender
            ].sub(value, "Insufficient Allowance");
        }

        _transferFrom(from, to, value);
        return true;
    }

    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(
            targetLiquidity,
            targetLiquidityDenominator
        )
            ? 0
            : liquidityFee;
        uint256 contractTokenBalance = _gonBalances[address(this)].div(
            _gonsPerFragment
        );
        uint256 amountToLiquify = contractTokenBalance
            .mul(dynamicLiquidityFee)
            .div(totalFee)
            .div(2);
        uint256 amountToSwap = contractTokenBalance.sub(amountToLiquify);

        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = address(USDC);
        path[2] = router.WETH();

        uint256 balanceBefore = address(this).balance;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp + 100
        );
        uint256 amountETH = address(this).balance.sub(balanceBefore);

        path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(USDC);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amountETH
        }(0, path, address(this), block.timestamp.add(300));

        uint256 amountUSDC = USDC.balanceOf(address(this));
        uint256 totalETHFee = totalFee.sub(dynamicLiquidityFee.div(2));

        uint256 amountUSDCLiquidity = amountUSDC
            .mul(dynamicLiquidityFee)
            .div(totalETHFee)
            .div(2);

        uint256 amountUSDCTreasury = amountUSDC.mul(treasuryFee).div(
            totalETHFee
        );

        USDC.transfer(treasuryReceiver, amountUSDCTreasury);

        if (amountToLiquify > 0) {
            router.addLiquidity(
                address(USDC),
                address(this),
                amountUSDCLiquidity,
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp + 100
            );
        }
    }

    function takeFee(address sender, uint256 gonAmount)
        internal
        returns (uint256)
    {
        uint256 _totalFee = totalFee;
        uint256 feeAmount = gonAmount.mul(_totalFee).div(feeDenominator);

        _gonBalances[address(this)] = _gonBalances[address(this)].add(
            feeAmount
        );

        emit Transfer(sender, address(this), feeAmount.div(_gonsPerFragment));
        return gonAmount.sub(feeAmount);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        initialDistributionLock
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
        external
        initialDistributionLock
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
        external
        override
        validRecipient(spender)
        initialDistributionLock
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function checkFeeExempt(address _addr) external view returns (bool) {
        return _isFeeExempt[_addr];
    }

    function setInitialDistributionFinished() external onlyOwner {
        initialDistributionFinished = true;

        emit InitialDistributionFinished();
    }

    function enableTransfer(address _addr) external onlyOwner {
        allowTransfer[_addr] = true;

        emit AddressExemptedFromTransferLock(_addr);
    }

    function setFeeExempt(address _addr) external onlyOwner {
        _isFeeExempt[_addr] = true;

        emit AddressExemptedFromFee(_addr);
    }

    function shouldTakeFee(address from, address to)
        internal
        view
        returns (bool)
    {
        return
            (address(pairContract) == from || address(pairContract) == to) &&
            (!_isFeeExempt[from]);
    }

    function setSwapBackSettings(
        bool _enabled,
        uint256 _num,
        uint256 _denom
    ) external onlyOwner {
        swapEnabled = _enabled;
        gonSwapThreshold = TOTAL_GONS.div(_denom).mul(_num);

        emit NewSwapBackSet(_enabled, _num, _denom);
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != address(pairContract) &&
            !inSwap &&
            swapEnabled &&
            _gonBalances[address(this)] >= gonSwapThreshold;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return
            (TOTAL_GONS.sub(_gonBalances[DEAD]).sub(_gonBalances[ZERO])).div(
                _gonsPerFragment
            );
    }

    function setTargetLiquidity(uint256 target, uint256 accuracy)
        external
        onlyOwner
    {
        targetLiquidity = target;
        targetLiquidityDenominator = accuracy;

        emit NewTargetLiquiditySet(target, accuracy);
    }

    function isNotInSwap() external view returns (bool) {
        return !inSwap;
    }

    function checkSwapThreshold() external view returns (uint256) {
        return gonSwapThreshold.div(_gonsPerFragment);
    }

    function manualSync() external {
        pairContract.sync();
    }

    function setFeeReceivers(
        address _autoLiquidityReceiver,
        address _treasuryReceiver
    ) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        treasuryReceiver = _treasuryReceiver;

        emit NewFeeReceiversSet(_autoLiquidityReceiver, _treasuryReceiver);
    }

    function setFees(
        uint256 _liquidityFee,
        uint256 _treasuryFee,
        uint256 _feeDenominator
    ) external onlyOwner {
        require(
            _liquidityFee <= MaxliquidityFee,
            "You can't set higher than MAX"
        );
        require(
            _treasuryFee <= MaxtreasuryFee,
            "You can't set higher than MAX"
        );
        liquidityFee = _liquidityFee;
        treasuryFee = _treasuryFee;
        totalFee = liquidityFee.add(treasuryFee);
        feeDenominator = _feeDenominator;

        emit NewFeesSet(_liquidityFee, _treasuryFee, _feeDenominator);
    }

    function getLiquidityBacking(uint256 accuracy)
        public
        view
        returns (uint256)
    {
        uint256 liquidityBalance = _gonBalances[address(pairContract)].div(
            _gonsPerFragment
        );
        return
            accuracy.mul(liquidityBalance.mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy)
        public
        view
        returns (bool)
    {
        return getLiquidityBacking(accuracy) > target;
    }

    receive() external payable {}
}