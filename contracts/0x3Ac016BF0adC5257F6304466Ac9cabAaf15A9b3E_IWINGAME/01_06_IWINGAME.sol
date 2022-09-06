//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/* 

██╗░██╗░░░░░░░██╗██╗███╗░░██╗░░░░░░░██████╗░░█████╗░███╗░░░███╗███████╗░░░░█████╗░░█████╗░███╗░░░███╗
██║░██║░░██╗░░██║██║████╗░██║░░░░░░██╔════╝░██╔══██╗████╗░████║██╔════╝░░░██╔══██╗██╔══██╗████╗░████║
██║░╚██╗████╗██╔╝██║██╔██╗██║█████╗██║░░██╗░███████║██╔████╔██║█████╗░░░░░██║░░╚═╝██║░░██║██╔████╔██║
██║░░████╔═████║░██║██║╚████║╚════╝██║░░╚██╗██╔══██║██║╚██╔╝██║██╔══╝░░░░░██║░░██╗██║░░██║██║╚██╔╝██║
██║░░╚██╔╝░╚██╔╝░██║██║░╚███║░░░░░░╚██████╔╝██║░░██║██║░╚═╝░██║███████╗██╗╚█████╔╝╚█████╔╝██║░╚═╝░██║
╚═╝░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚══╝░░░░░░░╚═════╝░╚═╝░░╚═╝╚═╝░░░░░╚═╝╚══════╝╚═╝░╚════╝░░╚════╝░╚═╝░░░░░╚═╝
 
 */
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { IERC20 } from "./interfaces/IERC20.sol";
import { Auth } from "./lib/Auth.sol";
import { IDEXRouter } from "./interfaces/IDEXRouter.sol";
import { IDividendDistributor } from "./interfaces/IDividendDistributor.sol";                                                          

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract IWINGAME is IERC20, Auth {
    using SafeMath for uint256;

    uint256 public constant MASK = type(uint128).max;
    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; //Etherium 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2  ; Rinkeby: 0xc778417E063141139Fce010982780140Aa0cD5Ab //Goeli: 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address DEAD_NON_CHECKSUM = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "IWIN GAME";
    string constant _symbol = "IWIN";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 1_000_000_000 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply.div(400); // 0.25%

    mapping (address => uint256) _balances;
    uint256 _totalHolder;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isFeeExemptRecipient;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    mapping (address => bool) isWhiteList;

    uint256 liquidityFee = 500;
    uint256 buybackFee = 300;
    uint256 reflectionFee = 500;
    uint256 marketingFee = 200;
    uint256 totalFee = 1500;
    uint256 public buyFee = 500;
    uint256 feeDenominator = 10000;

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;

    uint256 targetLiquidity = 25;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public pair;
    mapping(address=>bool) public isPair;

    uint256 buybackMultiplierNumerator = 200;
    uint256 buybackMultiplierDenominator = 100;
    uint256 buybackMultiplierTriggeredAt;
    uint256 buybackMultiplierLength = 30 minutes;

    bool public autoBuybackEnabled = false;
    mapping (address => bool) buyBacker;
    uint256 autoBuybackCap;
    uint256 autoBuybackAccumulator;
    uint256 autoBuybackAmount;
    uint256 autoBuybackBlockPeriod;
    uint256 autoBuybackBlockLast;

    IDividendDistributor distributor;
    address public distributorAddress;

    uint256 distributorGas = 500000;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 5000; // 0.02%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false;}

    constructor (address _dexRouter) Auth(msg.sender) { 
        router = IDEXRouter(_dexRouter);
        WETH = router.WETH();
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        isPair[pair] = true;

        _allowances[address(this)][address(router)] = _totalSupply;
        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;
        isWhiteList[msg.sender] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isWhiteList[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[ZERO] = true;
        isDividendExempt[msg.sender] = true;

        buyBacker[msg.sender] = true;
        autoLiquidityReceiver = msg.sender;
        marketingFeeReceiver = msg.sender;
        approve(_dexRouter, _totalSupply);
        approve(address(pair), _totalSupply);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function withdrawMoney() external onlyOwner{
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    modifier onlyBuybacker() { require(buyBacker[msg.sender] == true, ""); _; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function setDividendDistributor(address _distributor) external onlyOwner{
        distributorAddress = _distributor;
        distributor = IDividendDistributor(_distributor);
        isDividendExempt[distributorAddress] = true;
        isWhiteList[distributorAddress] = true;
    }

    function setWhiteList(address holder, bool iswhitelist) external authorized {
        require(holder != address(0), "holder is 0");
        isWhiteList[holder] = iswhitelist;
    }

    function setPair(address _pair, bool _isPair) external authorized {
        isPair[_pair] = _isPair;
        isDividendExempt[_pair] = _isPair;
    }

    function setDexRouter(address _dexRouter) external onlyOwner {
        router = IDEXRouter(_dexRouter);
        WETH = router.WETH();
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        isPair[pair] = true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != _totalSupply){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap||sender == address(distributor)||recipient == address(distributor)){ return _basicTransfer(sender, recipient, amount); }

        checkTxLimit(sender, amount);
        if(shouldSwapBack()){ swapBack(); }
        if(shouldAutoBuyback()){ triggerAutoBuyback(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        if (_balances[sender] == 0) {
            _totalHolder = _totalHolder - 1;
        }
        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, amount) : amount;
        if (_balances[recipient] == 0) {
            _totalHolder = _totalHolder + 1;
        }
        _balances[recipient] = _balances[recipient].add(amountReceived);

        if(!isDividendExempt[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }

        try distributor.process(distributorGas) {
            
        } catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        if (_balances[sender] == 0) {
            _totalHolder = _totalHolder - 1;
        }
        if (_balances[recipient] == 0) {
            _totalHolder = _totalHolder + 1;
        }
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return !(isFeeExempt[sender]||isFeeExemptRecipient[recipient]||isWhiteList[sender]||isWhiteList[recipient]);
    }

    function getTotalFee(address sender, address receiver) public view returns (uint256) {
        //buying
        if(isPair[sender]){ 
            return buyFee;
        //selling
        }else if(isPair[receiver]){ return getMultipliedFee(); } 
        // transfer
        return totalFee;
    }

    function getTotalHolder() public view returns (uint256) {
        return _totalHolder;
    }

    function getMultipliedFee() public view returns (uint256) {
        if (buybackMultiplierTriggeredAt.add(buybackMultiplierLength) > block.timestamp) {
            uint256 remainingTime = buybackMultiplierTriggeredAt.add(buybackMultiplierLength).sub(block.timestamp);
            uint256 feeIncrease = totalFee.mul(buybackMultiplierNumerator).div(buybackMultiplierDenominator).sub(totalFee);
            return totalFee.add(feeIncrease.mul(remainingTime).div(buybackMultiplierLength));
        }
        return totalFee;
    }

    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee(sender, receiver)).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2);
        uint256 amountReflection = swapThreshold.mul(reflectionFee).div(totalFee);
        if(address(distributor) != address(0)){
            _transferFrom(address(this), address(distributor), amountReflection);
            distributor.deposit(amountReflection);
        }
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify).sub(amountReflection);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;
        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance.sub(balanceBefore);

        uint256 totalETHFee = totalFee.sub(dynamicLiquidityFee.div(2)).sub(reflectionFee);

        uint256 amountETHLiquidity = amountETH.mul(dynamicLiquidityFee).div(totalETHFee).div(2);
        uint256 amountETHMarketing = amountETH.mul(marketingFee).div(totalETHFee);
        
        (bool success,) = payable(marketingFeeReceiver).call{value: amountETHMarketing, gas: 30000}("");
        
        require(success, "Transfer failed.");
        if(amountToLiquify > 0){
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

    function shouldAutoBuyback() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && autoBuybackEnabled
        && autoBuybackBlockLast + autoBuybackBlockPeriod <= block.number // After N blocks from last buyback
        && address(this).balance >= autoBuybackAmount;
    }

    function triggerTokenBuyback(uint256 amount, bool triggerBuybackMultiplier) external authorized {
        buyTokens(amount, DEAD);
        if(triggerBuybackMultiplier){
            buybackMultiplierTriggeredAt = block.timestamp;
            emit BuybackMultiplierActive(buybackMultiplierLength);
        }
    }

    function clearBuybackMultiplier() external authorized {
        buybackMultiplierTriggeredAt = 0;
    }

    function triggerAutoBuyback() internal {
        buyTokens(autoBuybackAmount, DEAD);
        autoBuybackBlockLast = block.number;
        autoBuybackAccumulator = autoBuybackAccumulator.add(autoBuybackAmount);
        if(autoBuybackAccumulator > autoBuybackCap){ autoBuybackEnabled = false; }
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp
        );
    }

    function setAutoBuybackSettings(bool _enabled, uint256 _cap, uint256 _amount, uint256 _period) external authorized {
        autoBuybackEnabled = _enabled;
        autoBuybackCap = _cap;
        autoBuybackAccumulator = 0;
        autoBuybackAmount = _amount;
        autoBuybackBlockPeriod = _period;
        autoBuybackBlockLast = block.number;
    }

    function setBuybackMultiplierSettings(uint256 numerator, uint256 denominator, uint256 length) external authorized {
        require(numerator / denominator <= 2 && numerator > denominator);
        buybackMultiplierNumerator = numerator;
        buybackMultiplierDenominator = denominator;
        buybackMultiplierLength = length;
    }

    function setTxLimit(uint256 amount) external authorized {
        require(amount >= _totalSupply / 1000);
        _maxTxAmount = amount;
    }

    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsFeeExemptRecipient(address holder, bool exempt) external authorized {
        isFeeExemptRecipient[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function setFees(uint256 _liquidityFee, uint256 _buybackFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _feeDenominator) external authorized {
        liquidityFee = _liquidityFee;
        buybackFee = _buybackFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        totalFee = _liquidityFee.add(_buybackFee).add(_reflectionFee).add(_marketingFee);
        require(totalFee <= 3000, "Total fee less than 30%");
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator/4);
    }

    function setBuyFee(uint256 _buyFee) external authorized {
        require(_buyFee <= 1000, "Buy fee less than 10%");
        buyFee = _buyFee;
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 750000);
        distributorGas = gas;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }
 

    event AutoLiquify(uint256 amountETH, uint256 amountBOG);
    event BuybackMultiplierActive(uint256 duration);
}