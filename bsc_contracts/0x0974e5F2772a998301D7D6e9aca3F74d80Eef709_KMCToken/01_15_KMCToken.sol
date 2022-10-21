// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract KMCToken is ERC20, Ownable, AccessControl {
    using Address for address payable;

    uint256 constant ONE_BILLION = 1_000_000_000 * 1e18; // 1,000,000,000 (100%)
    uint256 constant TEN_MILLION = 10_000_000 * 1e18; // 10,000,000 (1%)
    uint256 constant ONE_MILLION = 1_000_000 * 1e18; // 1,000,000 (0.1%)
    uint256 constant HUNDERD_THO = 100_000 * 1e18; // 100,000 (0.01%)

    uint256 constant MAX_REST_TIME = 120; // 120 seconds (2 minutes)
    uint256 constant MAX_TAX = 25; // 25%
    uint256 constant MAX_TOKEN_LIQUIDITY_THRESHOLD = TEN_MILLION; // 1%
    uint256 constant MIN_TX_LIMIT = ONE_MILLION; // 0.1%
    uint256 constant MIN_HOLD_LIMIT = TEN_MILLION; // 1%
    uint256 constant MAX_ANTIBOT_BLOCKS = 5; // 5 blocks
    uint256 constant MAX_ANTIBOT_TAX = 99; // 99%

    event SetMarketingAddress(address receiver);
    event SetProjectAddress(address receiver);
    event SetTeamAddress(address receiver);
    event SetRouterAddress(address receiver);
    event SetBuyTax(Tax buyTax);
    event SetSellTax(Tax sellTax);
    event SetTokenLiquidityThreshold(uint256 amount);
    event TradingEnabled();
    event SetMaxBuy(uint256 amount);
    event SetMaxSell(uint256 amount);
    event SetMaxW2W(uint256 amount);
    event SetMaxHoldLimit(uint256 amount);
    event SetExcludeFromTax(address _address, bool value);
    event SetExcludeFromMaxBuy(address _address, bool value);
    event SetExcludeFromMaxSell(address _address, bool value);
    event SetExcludeFromMaxW2W(address _address, bool value);
    event SetExcludeFromMaxHoldLimit(address _address, bool value);
    event SetRestTime(uint256 duration);
    event SetExcludeFromRestTime(address _address, bool value);
    event SetProvidingLiquidity(bool value);
    event SetAntibotBlocks(uint256 blocks);
    event SetAntibotTax(uint256 tax);
    event SetPairAddress(address _address);
    event RescuedETH(uint256 amount);
    event RescuedERC20(address _address, uint256 amount);

    struct Tax {
        uint256 marketing;
        uint256 project;
        uint256 team;
        uint256 liquidity;
    }

    struct NormalizedTax {
        uint256 marketing;
        uint256 project;
        uint256 team;
        uint256 liquidityToken;
        uint256 liquidityETH;
    }

    Tax public buyTax = Tax(3, 3, 2, 2);
    Tax public sellTax = Tax(3, 3, 2, 2);

    bool public tradingEnabled = false;
    bool public providingLiquidity = false;

    uint256 public tokenLiquidityThreshold = HUNDERD_THO / 2;
    bool private _liquidityMutex = false;

    uint256 public restTime = 60;

    uint256 public genesisBlock;
    uint256 public antibotBlocks = 3;
    uint256 public antibotTax = 99;

    address payable public marketingAddress;
    address payable public projectAddress;
    address payable public teamAddress;
    address payable public liquidityAddress;
    address constant deadAddress = 0x000000000000000000000000000000000000dEaD;

    address public routerAddress;
    address public pairAddress;
    IUniswapV2Router02 private router;

    uint256 public maxBuy = MIN_TX_LIMIT / 2; // 1% of initial circulating supply
    uint256 public maxSell = MIN_TX_LIMIT / 2; // 1% of initial circulating supply
    uint256 public maxW2W = MIN_TX_LIMIT / 2; // 1% of initial circulating supply
    uint256 public maxHoldLimit = MIN_HOLD_LIMIT / 10; // 2% of initial circulating supply

    mapping(address => bool) private excludeFromTax;
    mapping(address => bool) private excludeFromMaxBuy;
    mapping(address => bool) private excludeFromMaxSell;
    mapping(address => bool) private excludeFromMaxW2W;
    mapping(address => bool) private excludeFromMaxHoldLimit;
    mapping(address => bool) private excludeFromRestTime;

    mapping(address => uint) private transferInTimestamp;
    mapping(address => uint) private transferOutTimestamp;

    modifier mutexLock() {
        if (!_liquidityMutex) {
            _liquidityMutex = true;
            _;
            _liquidityMutex = false;
        }
    }

    constructor(
        address payable _marketingAddress,
        address payable _projectAddress,
        address payable _teamAddress,
        address payable _routerAddress
    ) ERC20("Kammoros", "KMC") Ownable() {
        _mint(owner(), ONE_BILLION);
        _grantRole(DEFAULT_ADMIN_ROLE, owner());

        setMarketingAddress(_marketingAddress);
        setProjectAddress(_projectAddress);
        setTeamAddress(_teamAddress);

        setRouterAddress(_routerAddress);
        _createTradingPair();

        // exclude from tax
        setExcludeFromTax(owner(), true);
        setExcludeFromTax(address(this), true);

        // exclude from max buy
        setExcludeFromMaxBuy(owner(), true);
        setExcludeFromMaxBuy(address(this), true);
        setExcludeFromMaxBuy(pairAddress, true);

        // exclude from max sell
        setExcludeFromMaxSell(owner(), true);
        setExcludeFromMaxSell(address(this), true);
        setExcludeFromMaxSell(pairAddress, true);

        // exclude from max w2w
        setExcludeFromMaxW2W(owner(), true);
        setExcludeFromMaxW2W(address(this), true);
        setExcludeFromMaxW2W(pairAddress, true);

        // exclude from max hold limit
        setExcludeFromMaxHoldLimit(owner(), true);
        setExcludeFromMaxHoldLimit(address(this), true);
        setExcludeFromMaxHoldLimit(pairAddress, true);

        // exclude from transferRestTimeTime
        setExcludeFromRestTime(owner(), true);
        setExcludeFromRestTime(address(this), true);
    }

    // INTERNAL FUNCTIONS

    function setMarketingAddress(address payable _address) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _address != address(0),
            "Token: marketing address can not be address zero"
        );
        marketingAddress = _address;
        emit SetMarketingAddress(marketingAddress);
    }

    function setProjectAddress(address payable _address) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _address != address(0),
            "Token: project address can not be address zero"
        );
        projectAddress = _address;
        emit SetProjectAddress(projectAddress);
    }

    function setTeamAddress(address payable _address) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _address != address(0),
            "Token: team address can not be address zero"
        );
        teamAddress = _address;
        emit SetTeamAddress(teamAddress);
    }

    function setRouterAddress(address payable _address) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _address != address(0),
            "Token: router address can not be address zero"
        );
        require(
            !tradingEnabled,
            "Token: can not change router address once trading enabled"
        );
        routerAddress = _address;
        router = IUniswapV2Router02(routerAddress);
        emit SetRouterAddress(routerAddress);
    }

    function isExcludedFromTax(address _address) public view returns (bool) {
        return excludeFromTax[_address];
    }

    function setBuyTax(
        uint256 marketingTax,
        uint256 projectTax,
        uint256 teamTax,
        uint256 liquidityTax
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 sum = marketingTax +
            projectTax +
            teamTax +
            liquidityTax +
            _sumSellTax();
        require(sum <= MAX_TAX, "Token: sum of tax can not exceed MAX_TAX");
        buyTax = Tax(marketingTax, projectTax, teamTax, liquidityTax);
        emit SetBuyTax(buyTax);
    }

    function setSellTax(
        uint256 marketingTax,
        uint256 projectTax,
        uint256 teamTax,
        uint256 liquidityTax
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 sum = marketingTax +
            projectTax +
            teamTax +
            liquidityTax +
            _sumBuyTax();
        require(sum <= MAX_TAX, "Token: sum of tax can not exceed MAX_TAX");
        sellTax = Tax(marketingTax, projectTax, teamTax, liquidityTax);
        emit SetSellTax(sellTax);
    }

    function setTokenLiquidityThreshold(uint256 threshhold) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            threshhold <= MAX_TOKEN_LIQUIDITY_THRESHOLD,
            "Token: tokenLiquidityThreshold can not exceed MAX_TOKEN_LIQUIDITY_THRESHOLD"
        );
        tokenLiquidityThreshold = threshhold;
        emit SetTokenLiquidityThreshold(tokenLiquidityThreshold);
    }

    function enableTrading() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(tradingEnabled == false, "Token: trading is already enabled");
        tradingEnabled = true;
        providingLiquidity = true;
        genesisBlock = block.number;
        emit TradingEnabled();
    }

    function setMaxBuy(uint256 _maxBuy) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _maxBuy >= MIN_TX_LIMIT,
            "Token: maxBuy must exceed or equal MIN_TX_LIMIT"
        );
        maxBuy = _maxBuy;
        emit SetMaxBuy(maxBuy);
    }

    function setMaxSell(uint256 _maxSell) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _maxSell >= MIN_TX_LIMIT,
            "Token: maxSell must exceed or equal MIN_TX_LIMIT"
        );
        maxSell = _maxSell;
        emit SetMaxSell(maxSell);
    }

    function setMaxW2W(uint256 _maxW2W) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _maxW2W >= MIN_TX_LIMIT,
            "Token: maxW2W must exceed or equal MIN_TX_LIMIT"
        );
        maxW2W = _maxW2W;
        emit SetMaxW2W(maxW2W);
    }

    function setMaxHoldLimit(uint256 _maxHoldLimit) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _maxHoldLimit >= MIN_HOLD_LIMIT,
            "Token: maxHoldLimit must exceed or equal MIN_HOLD_LIMIT"
        );
        maxHoldLimit = _maxHoldLimit;
        emit SetMaxHoldLimit(maxHoldLimit);
    }

    function setExcludeFromTax(address _address, bool value) public onlyRole(DEFAULT_ADMIN_ROLE) {
        excludeFromTax[_address] = value;
        emit SetExcludeFromTax(_address, value);
    }

    function setExcludeFromMaxBuy(address _address, bool value)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        excludeFromMaxBuy[_address] = value;
        emit SetExcludeFromMaxBuy(_address, value);
    }

    function setExcludeFromMaxSell(address _address, bool value)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        excludeFromMaxSell[_address] = value;
        emit SetExcludeFromMaxSell(_address, value);
    }

    function setExcludeFromMaxW2W(address _address, bool value)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        excludeFromMaxW2W[_address] = value;
        emit SetExcludeFromMaxW2W(_address, value);
    }

    function setExcludeFromMaxHoldLimit(address _address, bool value)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        excludeFromMaxHoldLimit[_address] = value;
        emit SetExcludeFromMaxHoldLimit(_address, value);
    }

    function isExcludedFromMaxBuy(address _address) public view returns (bool) {
        return excludeFromMaxBuy[_address];
    }

    function isExcludedFromMaxSell(address _address)
        public
        view
        returns (bool)
    {
        return excludeFromMaxSell[_address];
    }

    function isExcludedFromMaxW2W(address _address) public view returns (bool) {
        return excludeFromMaxW2W[_address];
    }

    function isExcludedFromMaxHoldLimit(address _address)
        public
        view
        returns (bool)
    {
        return excludeFromMaxHoldLimit[_address];
    }

    function setRestTime(uint256 duration) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            duration <= MAX_REST_TIME,
            "Token: rest time must not exceed MAX_REST_TIME"
        );
        restTime = duration;
        emit SetRestTime(restTime);
    }

    function isExcludedFromRestTime(address _address)
        public
        view
        returns (bool)
    {
        return excludeFromRestTime[_address];
    }

    function setExcludeFromRestTime(address _address, bool value)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        excludeFromRestTime[_address] = value;
        emit SetExcludeFromRestTime(_address, value);
    }

    function setProvidingLiquidity(bool value) public onlyRole(DEFAULT_ADMIN_ROLE) {
        providingLiquidity = value;
        emit SetProvidingLiquidity(providingLiquidity);
    }

    function setAntibotBlocks(uint256 blocks) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            blocks <= MAX_ANTIBOT_BLOCKS,
            "Token: antibot blocks can not exceed MAX_ANTIBOT_BLOCKS"
        );
        require(
            !tradingEnabled,
            "Token: can not change antibot blocks once trading enabled"
        );
        antibotBlocks = blocks;
        emit SetAntibotBlocks(antibotBlocks);
    }

    function setAntibotTax(uint256 tax) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            tax <= MAX_ANTIBOT_TAX,
            "Token: antibot tax can not exceed MAX_ANTIBOT_TAX"
        );
        require(
            !tradingEnabled,
            "Token: can not change antibot tax once trading enabled"
        );
        antibotTax = tax;
        emit SetAntibotTax(antibotTax);
    }

    function setPairAddress(address _address) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            !tradingEnabled,
            "Token: can not change pair address once trading enabled"
        );
        pairAddress = _address;
        emit SetPairAddress(pairAddress);
    }

    function bulkSetExcludeFromTax(address[] memory addressList, bool value)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint i = 0; i < addressList.length; i++) {
            address _address = addressList[i];
            setExcludeFromTax(_address, value);
        }
    }

    function bulkSetExcludeFromMaxBuy(address[] memory addressList, bool value)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint i = 0; i < addressList.length; i++) {
            address _address = addressList[i];
            setExcludeFromMaxBuy(_address, value);
        }
    }

    function bulkSetExcludeFromMaxSell(address[] memory addressList, bool value)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint i = 0; i < addressList.length; i++) {
            address _address = addressList[i];
            setExcludeFromMaxSell(_address, value);
        }
    }

    function bulkSetExcludeFromMaxW2W(address[] memory addressList, bool value)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint i = 0; i < addressList.length; i++) {
            address _address = addressList[i];
            setExcludeFromMaxW2W(_address, value);
        }
    }

    function bulkSetExcludeFromMaxHoldLimit(
        address[] memory addressList,
        bool value
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i = 0; i < addressList.length; i++) {
            address _address = addressList[i];
            setExcludeFromMaxHoldLimit(_address, value);
        }
    }

    function bulkSetExcludeFromRestTime(
        address[] memory addressList,
        bool value
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i = 0; i < addressList.length; i++) {
            address _address = addressList[i];
            setExcludeFromRestTime(_address, value);
        }
    }

    function rescueETH(uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        Address.sendValue(payable(owner()), amount);
        emit RescuedETH(amount);
    }

    function rescueERC20(address _address, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(_address).transfer(owner(), amount);
        emit RescuedERC20(_address, amount);
    }

    // INTERNAL FUNCTION

    function _isTransferExcludedFromTax(address sender, address recipient)
        internal
        view
        returns (bool)
    {
        return isExcludedFromTax(sender) || isExcludedFromTax(recipient);
    }

    function _useAntibotTax(address sender, address recipient)
        internal
        view
        returns (bool)
    {
        return
            !_isTransferExcludedFromTax(sender, recipient) && _isAntibotPhase();
    }

    function _isBuy(address sender) internal view returns (bool) {
        return sender == pairAddress;
    }

    function _isSell(address recipient) internal view returns (bool) {
        return recipient == pairAddress;
    }

    function _isAntibotPhase() internal view returns (bool) {
        return block.number <= genesisBlock + antibotBlocks;
    }

    function _sumTax(Tax memory tax) internal pure returns (uint256) {
        return tax.marketing + tax.project + tax.team + tax.liquidity;
    }

    function _sumBuyTax() internal view returns (uint256) {
        return _sumTax(buyTax);
    }

    function _sumSellTax() internal view returns (uint256) {
        return _sumTax(sellTax);
    }

    function _createTradingPair() internal {
        router = IUniswapV2Router02(routerAddress);
        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
        pairAddress = factory.createPair(address(this), router.WETH());
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        _preTransferValidation(sender, recipient, amount);

        (
            Tax memory tax,
            uint256 taxRate,
            uint256 taxAmount,
            uint256 recipientAmount
        ) = _computeTax(sender, recipient, amount);

        if (providingLiquidity && !_isBuy(sender)) {
            _distributeTax(taxRate, tax);
        }

        super._transfer(sender, recipient, recipientAmount);
        if (taxAmount > 0) {
            super._transfer(sender, address(this), taxAmount);
        }
    }

    function _computeTax(
        address sender,
        address recipient,
        uint256 amount
    )
        internal
        view
        returns (
            Tax memory _tax,
            uint256 _taxRate,
            uint256 _taxAmount,
            uint256 _recipientAmount
        )
    {
        Tax memory tax;
        uint256 taxRate;

        if (_isTransferExcludedFromTax(sender, recipient) || _liquidityMutex) {
            taxRate = 0;
        } else if (_useAntibotTax(sender, recipient)) {
            taxRate = antibotTax;
        } else if (_isBuy(sender)) {
            tax = buyTax;
            taxRate = _sumBuyTax();
        } else {
            tax = sellTax;
            taxRate = _sumSellTax();
        }

        uint256 taxAmount = (amount * taxRate) / 100;
        uint256 recipientAmount = amount - taxAmount;

        return (tax, taxRate, taxAmount, recipientAmount);
    }

    function _distributeTax(uint256 rate, Tax memory tax) internal mutexLock {
        uint256 balanceToken = balanceOf(address(this));

        if (balanceToken >= tokenLiquidityThreshold) {
            uint256 balanceETH = address(this).balance;

            uint256 denominator = rate * 2;
            uint256 liquidityToken = (balanceToken * tax.liquidity) /
                denominator;
            uint256 amountToken = balanceToken - liquidityToken;

            _swapTokensForETH(amountToken);

            uint256 deltaETH = address(this).balance - balanceETH;
            uint256 amountETH = deltaETH / (denominator - tax.liquidity);
            uint256 liquidityETH = amountETH * tax.liquidity;

            _addLiquidity(liquidityToken, liquidityETH);

            uint256 marketingETH = amountETH * 2 * tax.marketing;
            _transferTax(marketingETH, marketingAddress);

            uint256 projectETH = amountETH * 2 * tax.project;
            _transferTax(projectETH, projectAddress);

            uint256 teamETH = amountETH * 2 * tax.team;
            _transferTax(teamETH, teamAddress);
        }
    }

    function _transferTax(uint256 amount, address payable _address) internal {
        if (amount > 0) {
            Address.sendValue(_address, amount);
        }
    }

    function _addLiquidity(uint256 amountToken, uint256 amountETH) internal {
        _approve(address(this), address(router), amountToken);

        router.addLiquidityETH{value: amountETH}(
            address(this),
            amountToken,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function _swapTokensForETH(uint256 amountToken) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(router.WETH());
        _approve(address(this), address(router), amountToken);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToken,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _preTransferValidation(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(amount > 0, "Token: Transfer amount must be greater than zero");
        if (!_isTransferExcludedFromTax(sender, recipient)) {
            require(tradingEnabled, "Token: Trading not enabled");
        }

        if (_isBuy(sender)) {
            // Note: Buy order
            if (!isExcludedFromMaxBuy(recipient)) {
                require(
                    amount <= maxBuy,
                    "Token: recipient amount must not exceed maxBuy"
                );
            }
            if (!isExcludedFromMaxHoldLimit(recipient)) {
                require(
                    amount + balanceOf(recipient) <= maxHoldLimit,
                    "Token: recipient balance must not exceed maxHoldLimit"
                );
            }
            if (!isExcludedFromRestTime(recipient)) {
                require(
                    block.timestamp >
                        (transferInTimestamp[recipient] + restTime),
                    "Token: recipient must rest between transfers"
                );
                transferInTimestamp[recipient] = block.timestamp;
            }
        } else if (_isSell(recipient)) {
            // NOTE: Sell order
            if (!isExcludedFromMaxSell(sender)) {
                require(
                    amount <= maxSell,
                    "Token: sender amount must not exceed maxSell"
                );
            }
            if (!isExcludedFromRestTime(sender)) {
                require(
                    block.timestamp > (transferOutTimestamp[sender] + restTime),
                    "Token: sender must rest between transfers"
                );
                transferOutTimestamp[sender] = block.timestamp;
            }
        } else {
            // NOTE: Wallet to wallet
            if (!isExcludedFromMaxW2W(sender)) {
                if (!isExcludedFromMaxW2W(recipient)) {
                    require(
                        amount <= maxW2W,
                        "Token: sender amount must not exceed maxW2W"
                    );
                }
            }
            if (!isExcludedFromMaxHoldLimit(recipient)) {
                require(
                    amount + balanceOf(recipient) <= maxHoldLimit,
                    "Token: recipient balance must not exceed maxHoldLimit"
                );
            }
            if (!isExcludedFromRestTime(sender)) {
                if (!isExcludedFromRestTime(recipient)) {
                    require(
                        block.timestamp >
                            (transferOutTimestamp[sender] + restTime),
                        "Token: sender must rest between transfers"
                    );
                }
                transferOutTimestamp[sender] = block.timestamp;
            }
        }
    }

    // fallback
    receive() external payable {}

    function burn(uint256 amount) external {
        _approve(msg.sender, address(this), amount);
        _burn(msg.sender, amount);
    }
}