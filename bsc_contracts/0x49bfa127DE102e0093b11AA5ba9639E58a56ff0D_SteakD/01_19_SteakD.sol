// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./PancakeswapInterface/IPancakeRouter02.sol";
import "./PancakeswapInterface/IPancakeFactory.sol";
import "./Interface/IDividendDistributor.sol";

contract SteakD is ERC20Upgradeable, UUPSUpgradeable, OwnableUpgradeable {
    using SafeMath for uint256;

    address public pancakeSwapPair;
    IPancakeRouter02 public pancakeSwapV2Router;

    uint256 public buyHoldersFee;
    uint256 public buyLPFee;
    uint256 public buyOperationFee;
    uint256 public buyPrimaryUtitlityFee;
    uint256 public buySecondUtitlityFee;

    uint256 public sellHoldersFee;
    uint256 public sellLPFee;
    uint256 public sellOperationFee;
    uint256 public sellPrimaryUtitlityFee;
    uint256 public sellSecondUtitlityFee;

    uint256 public amountForHolders;
    uint256 public amountForLP;
    uint256 public amountForOperation;
    uint256 public amountForPrimaryUtility;
    uint256 public amountForSecondUtility;

    uint256 public amountForTransferUtility;

    address public liquidityReceiver;
    address public operationsReceiver;
    address public primaryUtilityReceiver;
    address public secondUtilityReceiver;

    address public distributor;

    bool public tradeOn;

    uint256 public maxTransferAmountRate;

    mapping(address => bool) private _excludedFromAntiWhale;

    uint256 public timeBetweenSells;
    uint256 public timeBetweenBuys;

    mapping(address => uint256) public transactionLockTimeSell;
    mapping(address => uint256) public transactionLockTimeBuy;

    mapping(address => bool) public excludedFromAntiBot;
    mapping(address => bool) public excludedFromFee;
    mapping(address => bool) public excludedFromDivTracker;

    bool public inSwap;

    uint256 public swapThreshold;

    address[] public pairs;
    mapping(address => bool) public pairsMap;

    // BUSD mainnet: 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56
    // BUSD testnet: 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7
    address BUSD;

    uint256 distributorGas;

    uint256 public transferOperationFee;
    uint256 public transferUtitlityFee;

    bool public isPause;

    mapping(address => bool) public excludedFromPause;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event AutoLiquify(uint256 amountSDX, uint256 amountBNB);
    event SwapBackSuccess(uint256 amount);

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier antiWhale(
        address sender,
        address recipient,
        uint256 amount
    ) {
        uint256 _maxAmt = _maxTransferAmount();
        if (_maxAmt > 0) {
            if (
                _excludedFromAntiWhale[sender] == false &&
                _excludedFromAntiWhale[recipient] == false
            ) {
                require(
                    amount <= _maxAmt,
                    "AntiWhale: Transfer amount exceeds the maxTransferAmount"
                );
            }
        }
        _;
    }

    function initialize(
        address _routerAddrss,
        address _busd,
        address _liquidityReceiver,
        address _operationsReceiver,
        address _firstUtilityReceiver,
        address _secondUtilityReceiver
    ) public initializer {
        __ERC20_init("SteakD", "SDX");
        __Ownable_init();

        uint256 value = 1000000000000000;

        BUSD = _busd;

        buyHoldersFee = 300;
        buyLPFee = 200;
        buyOperationFee = 200;
        buyPrimaryUtitlityFee = 200;
        buySecondUtitlityFee = 200;

        sellHoldersFee = 1000;
        sellLPFee = 200;
        sellOperationFee = 300;
        sellPrimaryUtitlityFee = 300;
        sellSecondUtitlityFee = 300;

        transferOperationFee = 0;

        liquidityReceiver = _liquidityReceiver;
        operationsReceiver = _operationsReceiver;
        primaryUtilityReceiver = _firstUtilityReceiver;
        secondUtilityReceiver = _secondUtilityReceiver;

        maxTransferAmountRate = 500;

        _excludedFromAntiWhale[msg.sender] = true;
        _excludedFromAntiWhale[address(0)] = true;
        _excludedFromAntiWhale[address(this)] = true;

        timeBetweenSells = 100; // seconds
        timeBetweenBuys = 100;

        _mint(owner(), value * (10**18));

        tradeOn = false;

        swapThreshold = 50000000000 * (10**18);

        pancakeSwapV2Router = IPancakeRouter02(_routerAddrss);

        address WBNB = pancakeSwapV2Router.WETH();
        pancakeSwapPair = IPancakeFactory(pancakeSwapV2Router.factory())
            .createPair(WBNB, address(this));
        _addPair(pancakeSwapPair);

        amountForHolders = 0;
        amountForLP = 0;
        amountForOperation = 0;
        amountForPrimaryUtility = 0;
        amountForSecondUtility = 0;

        distributorGas = 600000;

        isPause = false;
    }

    function _authorizeUpgrade(address newImplementaion)
        internal
        override
        onlyOwner
    {}

    function _takeFee(
        address from,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        if (excludedFromFee[from] || excludedFromFee[to]) {
            return 0;
        }

        uint256 txFee = 0;

        if (pairsMap[from]) {
            uint256 totalTxFee = buyHoldersFee
                .add(buyLPFee)
                .add(buyOperationFee)
                .add(buyPrimaryUtitlityFee)
                .add(buySecondUtitlityFee);
            txFee = (amount * totalTxFee) / 10000;
            amountForHolders = amountForHolders.add(
                amount.mul(buyHoldersFee).div(10000)
            );
            amountForLP = amountForLP.add(amount.mul(buyLPFee).div(10000));
            amountForOperation = amountForOperation.add(
                amount.mul(buyOperationFee).div(10000)
            );
            amountForPrimaryUtility = amountForPrimaryUtility.add(
                amount.mul(buyPrimaryUtitlityFee).div(10000)
            );
            amountForSecondUtility = amountForSecondUtility.add(
                amount.mul(buySecondUtitlityFee).div(10000)
            );
        }

        if (pairsMap[to]) {
            uint256 totalTxFee = sellHoldersFee
                .add(sellLPFee)
                .add(sellOperationFee)
                .add(sellPrimaryUtitlityFee)
                .add(sellSecondUtitlityFee);
            txFee = (amount * totalTxFee) / 10000;
            amountForHolders = amountForHolders.add(
                amount.mul(sellHoldersFee).div(10000)
            );
            amountForLP = amountForLP.add(amount.mul(sellLPFee).div(10000));
            amountForOperation = amountForOperation.add(
                amount.mul(sellOperationFee).div(10000)
            );
            amountForPrimaryUtility = amountForPrimaryUtility.add(
                amount.mul(sellPrimaryUtitlityFee).div(10000)
            );
            amountForSecondUtility = amountForSecondUtility.add(
                amount.mul(sellSecondUtitlityFee).div(10000)
            );
        }

        if (txFee > 0) {
            super._transfer(from, address(this), txFee);
        }

        return txFee;
    }

    function _takeTransferFee(
        address from,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        if (excludedFromFee[from] || excludedFromFee[to]) {
            return 0;
        }
        uint256 txFee = 0;
        uint256 totalFee = transferOperationFee + transferUtitlityFee;
        if (totalFee > 0) {
            txFee = (amount * totalFee) / 10000;
            super._transfer(from, address(this), txFee);
            amountForOperation = amountForOperation.add(
                (amount * transferOperationFee) / 10000
            );
            amountForTransferUtility = amountForTransferUtility.add(
                (amount * transferUtitlityFee) / 10000
            );
            return txFee;
        }
        return txFee;
    }

    function _isOnSwap(address from, address to) internal view returns (bool) {
        bool isOnSwap = false;
        if (from == pancakeSwapPair || to == pancakeSwapPair) {
            isOnSwap = true;
        }
        return isOnSwap;
    }

    function _checkAntiBot(address from, address to) internal {
        if (!excludedFromAntiBot[from]) {
            if (timeBetweenSells > 0) {
                require(
                    block.timestamp - transactionLockTimeSell[from] >
                        timeBetweenSells,
                    "Wait before Sell!"
                );
                transactionLockTimeSell[from] = block.timestamp;
            }
        }

        if (!excludedFromAntiBot[to]) {
            if (timeBetweenBuys > 0) {
                require(
                    block.timestamp - transactionLockTimeBuy[to] >
                        timeBetweenBuys,
                    "Wait before Buy!"
                );
                transactionLockTimeBuy[to] = block.timestamp;
            }
        }
    }

    function _basicTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        super._transfer(from, to, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override antiWhale(from, to, amount) {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");

        bool blockedFromPause = isPause;
        
        if(blockedFromPause){
            if(excludedFromPause[from]){
                blockedFromPause = false;
            }
            if(excludedFromPause[to]){
                blockedFromPause = false;
            }
        }
        require(!blockedFromPause, "BEP20: transfer is paused.");

        if (amount == 0) {
            return;
        }

        if (!tradeOn) {
            _basicTransfer(from, to, amount);
            return;
        }

        if (inSwap) {
            return _basicTransfer(from, to, amount);
        }

        if (shouldSwapBack()) {
            _swapBack();
        }
        if (shouldSendBUSD()) {
            _sendBUSD();
        }

        if (_isOnSwap(from, to)) {
            _checkAntiBot(from, to);
            uint256 txFee = _takeFee(from, to, amount);
            amount = amount.sub(txFee);
            _basicTransfer(from, to, amount);
        } else {
            uint256 txFee = _takeTransferFee(from, to, amount);
            amount = amount.sub(txFee);
            _basicTransfer(from, to, amount);
        }

        if (!excludedFromDivTracker[from]) {
            try
                IDividendDistributor(distributor).setShare(
                    from,
                    balanceOf(from)
                )
            {} catch {}
        }
        if (!excludedFromDivTracker[to]) {
            try
                IDividendDistributor(distributor).setShare(to, balanceOf(to))
            {} catch {}
        }

        try
            IDividendDistributor(distributor).process(distributorGas)
        {} catch {}
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pancakeSwapPair &&
            !inSwap &&
            balanceOf(address(this)) >= swapThreshold;
    }

    function _swapBack() internal swapping {
        uint256 amountForUtility = amountForPrimaryUtility +
            amountForSecondUtility +
            amountForTransferUtility;
        uint256 amountForBNB = amountForLP.div(2).add(amountForOperation).add(
            amountForUtility
        );
        uint256 amountToLiquify = amountForLP.sub(amountForLP.div(2));
        uint256 rewardBNB = swapTokensForBNB(address(this), amountForBNB);
        uint256 bnbToLiquidity = rewardBNB.mul(amountForLP.div(2)).div(
            amountForBNB
        );
        uint256 bnbForOperation = rewardBNB.mul(amountForOperation).div(
            amountForBNB
        );
        uint256 bnbForUtility = rewardBNB.mul(amountForUtility).div(
            amountForBNB
        );

        // add liquidity
        addLiquidity(amountToLiquify, bnbToLiquidity);
        amountForLP = 0;

        // send fee to Operation Receiver
        payable(operationsReceiver).transfer(bnbForOperation);
        amountForOperation = 0;

        // send fee to the Utility Receiver
        uint256 bnbForPrimaryUtilityReceiver = (bnbForUtility *
            (amountForPrimaryUtility + amountForTransferUtility)) /
            amountForUtility;
        payable(primaryUtilityReceiver).transfer(bnbForPrimaryUtilityReceiver);
        payable(primaryUtilityReceiver).transfer(
            bnbForUtility - bnbForPrimaryUtilityReceiver
        );
        amountForPrimaryUtility = 0;
        amountForSecondUtility = 0;
        amountForTransferUtility = 0;

        // swap tokens for BUSD
        _swapTokensForBUSD(amountForHolders);
        amountForHolders = 0;

        emit SwapBackSuccess(amountForBNB);
    }

    function shouldSendBUSD() internal view returns (bool) {
        return
            msg.sender != pancakeSwapPair &&
            IERC20(BUSD).balanceOf(address(this)) > 0;
    }

    function _sendBUSD() internal {
        uint256 sendBUSDAmount = IERC20(BUSD).balanceOf(address(this));
        IERC20(BUSD).transfer(address(distributor), sendBUSDAmount);
        IDividendDistributor(distributor).depositBUSD(sendBUSDAmount);
    }

    function _swapTokensForBUSD(uint256 _amountIn) internal returns (uint256) {
        address[] memory path = new address[](3);
        require(path.length <= 3, "fail");
        path[0] = address(this);
        path[1] = pancakeSwapV2Router.WETH();
        path[2] = BUSD;

        IERC20(address(this)).approve(address(pancakeSwapV2Router), _amountIn);

        uint256 initialBUSD = IERC20(path[2]).balanceOf(address(this));

        // make the swap
        pancakeSwapV2Router
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _amountIn,
                0,
                path,
                address(this),
                block.timestamp
            );

        // after swaping
        uint256 newBUSD = IERC20(path[2]).balanceOf(address(this));

        return newBUSD.sub(initialBUSD);
    }

    function swapTokensForBNB(address tokenAddress, uint256 tokenAmount)
        private
        returns (uint256)
    {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        require(path.length <= 2, "fail");
        path[0] = tokenAddress;
        path[1] = pancakeSwapV2Router.WETH();

        uint256 initialBalance = address(this).balance;

        IERC20(address(this)).approve(
            address(pancakeSwapV2Router),
            tokenAmount
        );

        // make the swap
        pancakeSwapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

        return address(this).balance.sub(initialBalance);
    }

    function isExcludedFromAntiwhale(address ac) external view returns (bool) {
        return _excludedFromAntiWhale[ac];
    }

    /**
     * @dev Returns the max transfer amount.
     */
    function _maxTransferAmount() internal view returns (uint256) {
        // we can either use a percentage of supply
        if (maxTransferAmountRate > 0) {
            return (totalSupply() * maxTransferAmountRate) / 10000;
        }
        // or we can just set an actual number
        return (totalSupply() * 100) / 10000;
    }

    function excludeFromFees(address account, bool excluded)
        external
        onlyOwner
    {
        require(
            excludedFromFee[account] != excluded,
            "Rematic: Account is already the value of 'excluded'"
        );
        excludedFromFee[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function withdrawToken(address token, address account) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(account, balance);
    }

    function widthrawBNB(address _to) external onlyOwner {
        payable(_to).transfer(address(this).balance);
    }

    function excludeFromAntiwhale(address account, bool excluded)
        external
        onlyOwner
    {
        _excludedFromAntiWhale[account] = excluded;
    }

    function excludedAccountFromAntiBot(address account, bool excluded)
        external
        onlyOwner
    {
        excludedFromAntiBot[account] = excluded;
    }

    function changeTimeSells(uint256 _value) external onlyOwner {
        require(_value <= 60 * 60 * 60, "Max 1 hour");
        timeBetweenSells = _value;
    }

    function changeTimeBuys(uint256 _value) external onlyOwner {
        require(_value <= 60 * 60 * 60, "Max 1 hour");
        timeBetweenBuys = _value;
    }

    function setMaxTransfertAmountRate(uint256 value) external onlyOwner {
        require(value > 0, "fail");
        maxTransferAmountRate = value;
    }

    function setTradeOn(bool flag) external onlyOwner {
        require(tradeOn != flag, "Same value set already");
        tradeOn = flag;
    }

    function setPancakeSwapPair(address _pair) external onlyOwner {
        require(pancakeSwapPair != _pair, "already same value");
        pancakeSwapPair = _pair;
        pairs.push(_pair);
        pairsMap[_pair] = true;
    }

    function getParis()
        external
        view
        returns (address[] memory availablePairs)
    {
        uint256 length = 0;
        for (uint256 i = 0; i < pairs.length; i++) {
            address pair = pairs[i];
            if (pairsMap[pair]) {
                length.add(1);
            }
        }
        availablePairs = new address[](length);
        uint256 index = 0;
        for (uint256 i = 0; i < pairs.length; i++) {
            address pair = pairs[i];
            if (pairsMap[pair]) {
                availablePairs[index] = pair;
                index.add(1);
            }
        }
    }

    function addPair(address _pair) external onlyOwner {
        _addPair(_pair);
    }

    function _addPair(address _pair) internal onlyOwner {
        pairs.push(_pair);
        pairsMap[_pair] = true;
    }

    function removePair(address _pair) external onlyOwner {
        pairsMap[_pair] = false;
    }

    function setBUSD(address _busd) external onlyOwner {
        require(BUSD != _busd, "same value already");
        BUSD = _busd;
    }

    function addLiquidity(uint256 liquidityToken, uint256 liquidityBNB)
        private
    {
        // approve token transfer to cover all possible scenarios
        IERC20(address(this)).approve(
            address(pancakeSwapV2Router),
            liquidityToken
        );

        // add the liquidity
        try
            pancakeSwapV2Router.addLiquidityETH{value: liquidityBNB}(
                address(this),
                liquidityToken,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                liquidityReceiver,
                block.timestamp
            )
        {
            emit AutoLiquify(liquidityToken, liquidityBNB);
        } catch {
            emit AutoLiquify(0, 0);
        }
    }

    function excludeFromDividendTracker(address holder, bool _flag)
        external
        onlyOwner
    {
        require(excludedFromDivTracker[holder] = _flag, "Same value already");
        excludedFromDivTracker[holder] = _flag;
        if (_flag) {
            IDividendDistributor(distributor).setShare(holder, 0);
        } else {
            IDividendDistributor(distributor).setShare(
                holder,
                balanceOf(holder)
            );
        }
    }

    function setDistributorGas(uint256 gas) external onlyOwner {
        require(distributorGas != gas, "already same value");
        distributorGas = gas;
    }

    function setDistributorAddress(address _distributor) external onlyOwner {
        require(distributor != _distributor, "same value already!");
        distributor = _distributor;
    }

    function setSwapThreshold(uint256 _swapthreshold) external onlyOwner {
        require(swapThreshold != _swapthreshold, "same value already!");
        swapThreshold = _swapthreshold;
    }

    function updateSellFee(
        uint256 _sellHoldersFee,
        uint256 _sellLPFee,
        uint256 _sellOperationFee,
        uint256 _sellPrimaryUtitlityFee,
        uint256 _sellSecondUtitlityFee
    ) external onlyOwner {
        sellHoldersFee = _sellHoldersFee;
        sellLPFee = _sellLPFee;
        sellOperationFee = _sellOperationFee;
        sellPrimaryUtitlityFee = _sellPrimaryUtitlityFee;
        sellSecondUtitlityFee = _sellSecondUtitlityFee;
    }

    function updateBuyFee(
        uint256 _buyHoldersFee,
        uint256 _buyLPFee,
        uint256 _buyOperationFee,
        uint256 _buyPrimaryUtitlityFee,
        uint256 _buySecondUtitlityFee
    ) external onlyOwner {
        buyHoldersFee = _buyHoldersFee;
        buyLPFee = _buyLPFee;
        buyOperationFee = _buyOperationFee;
        buyPrimaryUtitlityFee = _buyPrimaryUtitlityFee;
        buySecondUtitlityFee = _buySecondUtitlityFee;
    }

    function updateTransferFee(
        uint256 _transferOperationFee,
        uint256 _transferUtitlityFee
    ) public onlyOwner {
        transferOperationFee = _transferOperationFee;
        transferUtitlityFee = _transferUtitlityFee;
    }

    function updateReceiverAddresses(
        address _liquidityReceiver,
        address _operationsReceiver,
        address _primaryUtilityReceiver,
        address _secondUtilityReceiver
    ) external onlyOwner {
        liquidityReceiver = _liquidityReceiver;
        operationsReceiver = _operationsReceiver;
        primaryUtilityReceiver = _primaryUtilityReceiver;
        secondUtilityReceiver = _secondUtilityReceiver;
    }

    function pauseTransaction(bool _paused) external onlyOwner {
        require(isPause != _paused, "same value already!");
        isPause = _paused;
    }

    function excludeWalletFromPause(address _account, bool flag)
        external
        onlyOwner
    {
        require(excludedFromPause[_account] != flag, "already same value");
        excludedFromPause[_account] = flag;
    }

    receive() external payable {}
}