// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract TokuToken is Ownable, IERC20Metadata {
    using SafeMath for uint256;

    uint8 constant _decimals = 18;

    uint256 _totalSupply = 10_000_000 * (10 ** _decimals);
    uint256 public _maxTxAmount = (_totalSupply * 2) / 100; //2% of supply

    uint256 public _walletMax = (_totalSupply * 2) / 100; //2% of supply

    address DEAD_WALLET = 0x000000000000000000000000000000000000dEaD;
    address ZERO_WALLET = 0x0000000000000000000000000000000000000000;

    address routerAddress;

    string constant _name = "Toku Token";
    string constant _symbol = "TOKU";

    bool public restrictWhales = true;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isTxLimitExempt;

    //buy sell, fee extraction
    uint256 public liquidityFee = 30; // 0.3% in bips
    uint256 public totalFee = 500; //5% buy fee
    uint256 public totalFeeIfSelling = 470; //4.7% in bips

    //tax imbursement, eth liquidation
    uint256 public liquidityTax = 1000; // 10% in bips
    uint256 public treasuryTax = 1000; // 10% in bips
    uint256 public markTax = 4000;
    uint256 public devTax = 4000;

    //tax wallets
    address private treasury;
    address private marketing;
    address private development;
    address private autoLiquidityReceiver;

    IUniswapV2Router02 public router;
    address public pair;

    uint256 public launchedAt;
    bool public tradingOpen = false;
    mapping(address => bool) public isInternal;
    mapping(address => bool) public authorizations;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public swapAndLiquifyByLimitOnly = false;
    bool checkOn = false;

    // wallet threshold limit, changeable
    uint256 public swapThreshold = _totalSupply / 200_000; //50 tokens default

    event AutoLiquify(uint256 amountETH, uint256 amountBOG);
    event SwapAndLiquifyEnabledUpdated(bool enabled);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(address _routerAddress, address _treasury, address _marketing, address _devWallet) {
        routerAddress = _routerAddress;
        treasury = _treasury;
        marketing = _marketing;
        development = _devWallet;
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

        authorizations[_routerAddress] = true;
        isFeeExempt[_routerAddress] = true;
        isTxLimitExempt[_routerAddress] = true;

        isFeeExempt[treasury] = true;
        isTxLimitExempt[treasury] = true;

        isFeeExempt[marketing] = true;
        isTxLimitExempt[marketing] = true;

        isFeeExempt[development] = true;
        isTxLimitExempt[development] = true;

        totalFee = totalFee.add(liquidityFee);
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
        uint256 feeImbursement = treasuryTax + markTax + devTax + liquidityTax; // 10% + 40% + 40% + 10% lp fee

        // half lp in tokens to add equal Token/eth liqudity in pool
        uint256 amountToLiquify = tokensToLiquify.mul(liquidityTax).div(feeImbursement).div(2); 
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

        uint256 totalETHFee = feeImbursement.sub(liquidityTax.div(2)); // also half LP fee in ETH 0.15%

        uint256 amountETHLiquidity = amountETH.mul(liquidityTax).div(totalETHFee).div(2);
        uint256 amountETHTreasury = amountETH.mul(treasuryTax).div(totalETHFee);
        uint256 amountETHMark = amountETH.mul(markTax).div(totalETHFee);
        uint256 amountETHDev = amountETH.mul(devTax).div(totalETHFee);

        (bool tmpSuccess1, ) = payable(treasury).call{value: amountETHTreasury}("");
        tmpSuccess1 = false;

        (bool tmpSuccess2, ) = payable(marketing).call{value: amountETHMark}("");
        tmpSuccess2 = false;

        (bool tmpSuccess3, ) = payable(development).call{value: amountETHDev}("");
        tmpSuccess3 = false;

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

    function isCont(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    // CONTRACT OWNER FUNCTIONS

    /** overriding transferOwnership to authorize the new owner as well */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        super.transferOwnership(newOwner);
        authorizations[newOwner] = true;
    }

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
     * @param newLiqFee = default 0.3% set as 30 bips
     * @param newBuyFee = default 12% set as 8000 bips
     * @param newSellFee = default 12% 1200 bips
     */
    function setFees(uint256 newLiqFee, uint256 newBuyFee, uint256 newSellFee) external onlyOwner {
        liquidityFee = newLiqFee;
        totalFee = liquidityFee.add(newBuyFee);
        totalFeeIfSelling = liquidityFee.add(newSellFee);
    }

    /**
     * @dev used to set liquidation/fee imbursement rate % for auto eth liquidation, out of 100% accumulated fees
     * @param _treasuryTax = default 80% 8000 bips
     * @param _markTax = default 20% 2000 bips
     * @param _markTax = default 20% 2000 bips
     */
    function setWalletsLiquidationRate(
        uint256 _treasuryTax,
        uint256 _markTax,
        uint256 _devTax,
        uint256 _liquidityTax
    ) external onlyOwner {
        treasuryTax = _treasuryTax;
        markTax = _markTax;
        devTax = _devTax;
        liquidityTax = _liquidityTax;
    }

    function setSwapThreshold(uint256 _newSwapThreshold) public onlyOwner {
        swapThreshold = _newSwapThreshold;
    }

    function rescueToken(
        address tokenAddress,
        uint256 tokens
    ) public onlyOwner returns (bool success) {
        return IERC20Metadata(tokenAddress).transfer(msg.sender, tokens);
    }

    function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
        uint256 amountETH = address(this).balance;
        payable(msg.sender).transfer((amountETH * amountPercentage) / 100);
    }

    // change the wallet that receives owner tax benifits
    function setTreasury(address _newWallet) public onlyOwner {
        treasury = _newWallet;
    }

    function setMarketing(address _newWallet) public onlyOwner {
        marketing = _newWallet;
    }

    function setDevelopment(address _newWallet) public onlyOwner {
        development = _newWallet;
    }
}