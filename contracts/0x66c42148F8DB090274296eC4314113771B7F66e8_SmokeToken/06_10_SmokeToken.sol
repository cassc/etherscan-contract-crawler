// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";


contract SmokeToken is Ownable, IERC20Metadata {
    using SafeMath for uint256; // this safemath relies on solidity's built in overflow checks

    uint8 constant _decimals = 18;

    uint256 _totalSupply = 100000000 * (10**_decimals); // 100 mill
    uint256 public _maxTxAmount = (_totalSupply * 2) / 100; // 2 mill default

    uint256 public _walletMax = (_totalSupply * 2) / 100;

    address DEAD_WALLET = 0x000000000000000000000000000000000000dEaD;
    address ZERO_WALLET = 0x0000000000000000000000000000000000000000;

    address routerAddress; // uniswap v2 router

    string constant _name = "Smoke Protocol Token";
    string constant _symbol = "$SMOKE";

    bool public restrictWhales = true;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isTxLimitExempt;

    uint256 public liquidityFee = 30; // 0.3% in bips
    uint256 public sessionsFee = 167; //  1.67% default sessions wallet fee
    uint256 public devFee = 333; //3.33% default developer wallet fee

    uint256 public totalFee = 500;
    uint256 public totalFeeIfSelling = 1000;  //10% in bips

    address private autoLiquidityReceiver;
    address private sessionsWallet;
    address private devWallet;

    IUniswapV2Router02 public router;
    address public pair;

    uint256 public launchedAt;
    bool public tradingOpen = true;
    bool public blacklistMode = true;
    mapping(address => bool) public isBlacklisted;
    mapping(address => bool) public isInternal;
    mapping(address => bool) internal authorizations;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public swapAndLiquifyByLimitOnly = false;
    bool checkOn = false;

    // wallet threshold limit, changeable
    uint256 public swapThreshold = _totalSupply / 5000; //20k default

    event AutoLiquify(uint256 amountETH, uint256 amountBOG);
    event SwapAndLiquifyEnabledUpdated(bool enabled);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(
        address _routerAddress,
        address _devWallet,
        address _sessionsWallet
    ) {
        routerAddress = _routerAddress;
        devWallet = _devWallet;
        sessionsWallet = _sessionsWallet;
        router = IUniswapV2Router02(routerAddress);
        pair = IUniswapV2Factory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;
        _allowances[address(this)][address(pair)] = type(uint256).max;

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[DEAD_WALLET] = true;

        authorizations[owner()] = true;
        isInternal[address(this)] = true;
        isInternal[msg.sender] = true;
        isInternal[address(pair)] = true;
        isInternal[address(router)] = true;

        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[pair] = true;
        isTxLimitExempt[DEAD_WALLET] = true;

        autoLiquidityReceiver = address(0);

        isFeeExempt[sessionsWallet] = true;
        isFeeExempt[devWallet] = true;
        totalFee = liquidityFee.add(sessionsFee).add(devFee);
        totalFeeIfSelling = totalFeeIfSelling.add(liquidityFee);

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function name() external pure override returns (string memory) {
        return _name;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD_WALLET)).sub(balanceOf(ZERO_WALLET));
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount; // approve from holder(msg.sender) to spender to spend this amount
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function setBridge(address bridge) public onlyOwner {
        authorizations[bridge] = true;
        isFeeExempt[bridge] = true;
        isTxLimitExempt[bridge] = true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(
                amount,
                "Insufficient Allowance"
            );
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (inSwapAndLiquify) {
            return _basicTransfer(sender, recipient, amount);
        }
        if (!authorizations[sender] && !authorizations[recipient]) {
            require(tradingOpen, "Trading not open yet");
        }

        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
        if (
            msg.sender != pair &&
            !inSwapAndLiquify &&
            swapAndLiquifyEnabled &&
            _balances[address(this)] >= swapThreshold
        ) {
            marketingAndLiquidity();
        }
        if (!launched() && recipient == pair) {
            require(_balances[sender] > 0, "Zero balance violated!");
            launch();
        }

        if (checkOn) {
            checkBot(sender, recipient);
        }

        // Blacklist
        if (blacklistMode) {
            require(!isBlacklisted[sender], "Blacklisted");
        }

        //Exchange tokens
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        if (!isTxLimitExempt[recipient] && restrictWhales) {
            require(_balances[recipient].add(amount) <= _walletMax, "Max wallet violated!");
        }

        uint256 finalAmount = !isFeeExempt[sender] && !isFeeExempt[recipient]
            ? extractFee(sender, recipient, amount)
            : amount;
        _balances[recipient] = _balances[recipient].add(finalAmount);

        emit Transfer(sender, recipient, finalAmount);
        return true;
    }

    function extractFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeApplicable = pair == recipient ? totalFeeIfSelling : totalFee;
        uint256 feeAmount = amount.mul(feeApplicable).div(10_000); //fee in bips so divide by 10k

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function marketingAndLiquidity() internal lockTheSwap {
        uint256 tokensToLiquify = _balances[address(this)];

        uint256 sessionF = 3330;
        uint256 devF = 6660;
        uint256 feeEmbersement = sessionF + devF + liquidityFee; // 33.4% + 66.6% + 0.3%

        uint256 amountToLiquify = tokensToLiquify.mul(liquidityFee).div(feeEmbersement).div(2);
        uint256 amountToSwap = tokensToLiquify.sub(amountToLiquify);

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

        uint256 amountETH = address(this).balance;

        uint256 totalETHFee = feeEmbersement.sub(liquidityFee.div(2)); // also half LP fee in ETH 0.15%

        uint256 amountETHLiquidity = amountETH.mul(liquidityFee).div(totalETHFee).div(2);
        uint256 amountETHSessions = amountETH.mul(sessionF).div(totalETHFee);
        uint256 amountETHDev = amountETH.mul(devF).div(totalETHFee);
        //gas 30000
        (bool tmpSuccess1, ) = payable(sessionsWallet).call{value: amountETHSessions}("");
        tmpSuccess1 = false;

        (bool tmpSuccess2, ) = payable(devWallet).call{value: amountETHDev}("");
        tmpSuccess2 = false;

        // burning LP tokens to remove a proportional share of the underlying reserves.
        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
    }

    function checkBot(address sender, address recipient) internal {
        if (
            (isCont(recipient) && !isInternal[recipient] && !isFeeExempt[recipient] && checkOn) ||
            (sender == pair && !isInternal[sender] && msg.sender != tx.origin && checkOn)
        ) {
            isBlacklisted[recipient] = true;
        }
    }

    function isCont(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    // CONTRACT OWNER FUNCTIONS
    function setisInternal(bool _bool, address _address) external onlyOwner {
        isInternal[_address] = _bool;
    }

    function setMode(bool _bool) external onlyOwner {
        checkOn = _bool;
    }

    function setWalletLimit(uint256 newLimit) external onlyOwner {
        _walletMax = newLimit;
    }

    function setTransactionLimit(uint256 newLimit) external onlyOwner {
        _maxTxAmount = newLimit;
    }

    function tradingStatus(bool newStatus) public onlyOwner {
        tradingOpen = newStatus;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setIsAuthorized(address _address, bool isAuth) external onlyOwner {
        authorizations[_address] = isAuth;
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    /**
     * @dev fees should be set in bips aka basis points 1% == 100 bips
     * @param newLiqFee = default 0.3% set as 30
     * @param newsessionsFee = default 1.67% as 167
     * @param newDevFee = default 3.33% set as 333
     * @param extraSellFee = default 5% extra, total 10% in sell
     */
    function setFees(
        uint256 newLiqFee,
        uint256 newsessionsFee,
        uint256 newDevFee,
        uint256 extraSellFee
    ) external onlyOwner {
        liquidityFee = newLiqFee;
        sessionsFee = newsessionsFee;
        devFee = newDevFee;

        totalFee = liquidityFee.add(sessionsFee).add(devFee);
        totalFeeIfSelling = totalFee + extraSellFee;
    }

    function setSwapThreshold(uint256 _newSwapThreshold) public onlyOwner {
        swapThreshold = _newSwapThreshold;
    }

    function enable_blacklist(bool _status) public onlyOwner {
        blacklistMode = _status;
    }

    function manage_blacklist(address[] calldata addresses, bool status) public onlyOwner {
        for (uint256 i; i < addresses.length; ++i) {
            isBlacklisted[addresses[i]] = status;
        }
    }

    function rescueToken(address tokenAddress, uint256 tokens)
        public
        onlyOwner
        returns (bool success)
    {
        return IERC20Metadata(tokenAddress).transfer(msg.sender, tokens);
    }

    function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
        uint256 amountETH = address(this).balance;
        payable(msg.sender).transfer((amountETH * amountPercentage) / 100);
    }

    /** Getters */

    /** Setters */

    // change the developer wallet that receives developer tax benifits
    function setDeveloperWallet(address _newDevWallet) public onlyOwner {
        devWallet = _newDevWallet;
    }

    // change the marketing wallet that receives marketing tax benifits
    function setSessionsWallet(address _newSessionsWallet) public onlyOwner {
        sessionsWallet = _newSessionsWallet;
    }
}