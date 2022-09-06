//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IDividendPayingToken.sol";
import "./interfaces/IDividendPayingTokenOptional.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Router02.sol";

import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract DividendPayingToken is
    ERC20,
    IDividendPayingToken,
    IDividendPayingTokenOptional,
    Ownable
{
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using SafeCast for uint256;
    using SafeCast for int256;

    uint256 internal constant magnitude = 2**128;

    uint256 internal magnifiedDividendPerShare;
    uint256 internal lastAmount;

    address public dividendToken;

    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;
    mapping(address => bool) internal _isAuth;

    uint256 public totalDividendsDistributed;

    modifier onlyAuth() {
        require(_isAuth[msg.sender], "Auth: caller is not the authorized");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _token
    ) ERC20(_name, _symbol) {
        dividendToken = _token;
        _isAuth[msg.sender] = true;
    }

    function setAuth(address account) external onlyOwner {
        _isAuth[account] = true;
    }

    function distributeDividends(uint256 amount) public onlyOwner {
        require(totalSupply() > 0);

        if (amount > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add(
                (amount).mul(magnitude) / totalSupply()
            );
            emit DividendsDistributed(msg.sender, amount);

            totalDividendsDistributed = totalDividendsDistributed.add(amount);
        }
    }

    function withdrawDividend() public virtual override {
        _withdrawDividendOfUser(payable(msg.sender));
    }

    function setDividendTokenAddress(address newToken)
        external
        virtual
        onlyOwner
    {
        dividendToken = newToken;
    }

    function _withdrawDividendOfUser(address payable user)
        internal
        returns (uint256)
    {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user].add(
                _withdrawableDividend
            );
            emit DividendWithdrawn(user, _withdrawableDividend);
            bool success = IERC20(dividendToken).transfer(
                user,
                _withdrawableDividend
            );

            if (!success) {
                withdrawnDividends[user] = withdrawnDividends[user].sub(
                    _withdrawableDividend
                );
                return 0;
            }

            return _withdrawableDividend;
        }

        return 0;
    }

    function dividendOf(address _owner) public view override returns (uint256) {
        return withdrawableDividendOf(_owner);
    }

    function withdrawableDividendOf(address _owner)
        public
        view
        override
        returns (uint256)
    {
        return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
    }

    function withdrawnDividendOf(address _owner)
        public
        view
        override
        returns (uint256)
    {
        return withdrawnDividends[_owner];
    }

    function accumulativeDividendOf(address _owner)
        public
        view
        override
        returns (uint256)
    {
        return
            magnifiedDividendPerShare
                .mul(balanceOf(_owner))
                .toInt256()
                .add(magnifiedDividendCorrections[_owner])
                .toUint256() / magnitude;
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        require(false);

        int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256();
        magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from]
            .add(_magCorrection);
        magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(
            _magCorrection
        );
    }

    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[
            account
        ].sub((magnifiedDividendPerShare.mul(value)).toInt256());
    }

    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[
            account
        ].add((magnifiedDividendPerShare.mul(value)).toInt256());
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf(account);

        if (newBalance > currentBalance) {
            uint256 mintAmount = newBalance.sub(currentBalance);
            _mint(account, mintAmount);
        } else if (newBalance < currentBalance) {
            uint256 burnAmount = currentBalance.sub(newBalance);
            _burn(account, burnAmount);
        }
    }
}

contract _SHIBADividendTracker is DividendPayingToken {
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using SafeCast for uint256;
    using SafeCast for int256;
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    EnumerableMap.AddressToUintMap private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping(address => bool) public excludedFromDividends;

    mapping(address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(
        address indexed account,
        uint256 amount,
        bool indexed automatic
    );

    constructor(address _dividentToken)
        DividendPayingToken("Shiba_Tracker", "Shiba_Tracker", _dividentToken)
    {
        claimWait = 60;
        minimumTokenBalanceForDividends = 1_000_000 * (10**9);
    }

    function _transfer(
        address,
        address,
        uint256
    ) internal pure override {
        require(false, "Shiba_Tracker: No transfers allowed");
    }

    function withdrawDividend() public pure override {
        require(
            false,
            "Shiba_Tracker: withdrawDividend disabled. Use the 'claim' function on the main Shiba contract."
        );
    }

    function setDividendTokenAddress(address newToken)
        external
        override
        onlyOwner
    {
        dividendToken = newToken;
    }

    function updateMinimumTokenBalanceForDividends(uint256 _newMinimumBalance)
        external
        onlyOwner
    {
        require(
            _newMinimumBalance != minimumTokenBalanceForDividends,
            "New mimimum balance for dividend cannot be same as current minimum balance"
        );
        minimumTokenBalanceForDividends = _newMinimumBalance * (10**9);
    }

    function excludeFromDividends(address account) external onlyOwner {
        require(
            !excludedFromDividends[account],
            "address already excluded from dividends"
        );
        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }

    function includeFromDividends(address account) external onlyOwner {
        excludedFromDividends[account] = false;
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(
            newClaimWait >= 3600 && newClaimWait <= 86400,
            "Shiba_Tracker: claimWait must be updated to between 1 and 24 hours"
        );
        require(
            newClaimWait != claimWait,
            "Shiba_Tracker: Cannot update claimWait to same value"
        );
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns (uint256) {
        return tokenHoldersMap.length();
    }

    function getAccount(address _account)
        public
        view
        returns (
            address account,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable
        )
    {
        account = _account;

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ? lastClaimTime.add(claimWait) : 0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp
            ? nextClaimTime.sub(block.timestamp)
            : 0;
    }

    function getAccountAtIndex(uint256 index)
        public
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        if (index >= tokenHoldersMap.length()) {
            return (0x0000000000000000000000000000000000000000, 0, 0, 0, 0, 0);
        }

        (address account, uint256 v) = tokenHoldersMap.at(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if (lastClaimTime > block.timestamp) {
            return false;
        }

        return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(address payable account, uint256 newBalance)
        external
        onlyOwner
    {
        if (excludedFromDividends[account]) {
            return;
        }

        if (newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
        } else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }

        processAccount(account, true);
    }

    function process(uint256 gas)
        public
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 numberOfTokenHolders = tokenHoldersMap.length();

        if (numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 claims = 0;

        while (gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if (_lastProcessedIndex >= tokenHoldersMap.length()) {
                _lastProcessedIndex = 0;
            }

            (address account, uint256 v) = tokenHoldersMap.at(
                _lastProcessedIndex
            );

            if (canAutoClaim(lastClaimTimes[account])) {
                if (processAccount(payable(account), true)) {
                    claims++;
                }
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if (gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;

        return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic)
        public
        onlyOwner
        returns (bool)
    {
        uint256 amount = _withdrawDividendOfUser(account);

        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }

        return false;
    }
}

contract ShibaBurnProtocol is ERC20, Ownable {
    //library
    using SafeMath for uint256;
    //custom
    IUniswapV2Router02 public uniswapV2Router;
    _SHIBADividendTracker public _shibaDividendTracker;
    //address
    address public uniswapV2Pair;
    address public marketingWallet = 0x053df45FD629d5D0d1605D9F3B50df212c8a7DAf;
    address public shibaBurnWallet = 0x837A70DCdd7AAc1732b15EC571f42156c779b436;
    address public liqWallet = 0x09ba4baB3369fac1Fd59dc6eea25e7144EfC9F48;
    address public _shibaDividendToken;
    address public deadWallet = 0xdEAD000000000000000042069420694206942069;
    address public shibaAddress = 0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE;
    //bool
    bool public marketingSwapSendActive = true;
    bool public shibaBurnSwapSendActive = true;
    bool public LiqSwapSendActive = true;
    bool public swapAndLiquifyEnabled = true;
    bool public ProcessDividendStatus = true;
    bool public _shibaDividendEnabled = true;
    bool public marketActive;
    bool public blockMultiBuys = true;
    bool public limitSells = true;
    bool public limitBuys = true;
    bool public feeStatus = true;
    bool public buyFeeStatus = true;
    bool public sellFeeStatus = true;
    bool public maxWallet = true;
    bool private isInternalTransaction;

    //uint
    uint256 public buySecondsLimit = 3;
    uint256 public minimumWeiForTokenomics = 1 * 10**17; // 0.1 bnb
    uint256 public maxBuyTxAmount; // 1% tot supply (constructor)
    uint256 public maxSellTxAmount; // 1% tot supply (constructor)
    uint256 public minimumTokensBeforeSwap = 10_000_000 * 10**decimals();
    uint256 public tokensToSwap = 10_000_000 * 10**decimals();
    uint256 public intervalSecondsForSwap = 20;
    uint256 public SHIBARewardsBuyFee = 2;
    uint256 public SHIBARewardsSellFee = 2;
    uint256 public SHIBABurnBuyFee = 2;
    uint256 public SHIBABurnSellFee = 2;
    uint256 public marketingBuyFee = 3;
    uint256 public marketingSellFee = 3;
    uint256 public burnSellFee = 1;
    uint256 public burnBuyFee = 1;
    uint256 public liqBuyFee = 2;
    uint256 public liqSellFee = 2;
    uint256 public totalBuyFees =
        SHIBARewardsBuyFee
            .add(marketingBuyFee)
            .add(liqBuyFee)
            .add(burnBuyFee)
            .add(SHIBABurnBuyFee);
    uint256 public totalSellFees =
        SHIBARewardsSellFee
            .add(marketingSellFee)
            .add(liqSellFee)
            .add(burnSellFee)
            .add(SHIBABurnSellFee);
    uint256 public gasForProcessing = 300000;
    uint256 public maxWalletAmount; // 1% tot supply (constructor)
    uint256 private startTimeForSwap;
    uint256 private marketActiveAt;

    //struct
    struct userData {
        uint256 lastBuyTime;
    }

    //mapping
    mapping(address => bool) public premarketUser;
    mapping(address => bool) public excludedFromFees;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) public excludedFromMaxWallet;
    mapping(address => userData) public userLastTradeData;
    //event
    event Update_shibaDividendTracker(
        address indexed newAddress,
        address indexed oldAddress
    );

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event MarketingEnabledUpdated(bool enabled);
    event _SHIBADividendEnabledUpdated(bool enabled);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event MarketingWalletUpdated(
        address indexed newMarketingWallet,
        address indexed oldMarketingWallet
    );

    event GasForProcessingUpdated(
        uint256 indexed newValue,
        uint256 indexed oldValue
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(uint256 amount);

    event Processed_shibaDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );
    event MarketingFeeCollected(uint256 amount);
    event ShibaBurnFeeCollected(uint256 amount);
    event ExcludedFromMaxWalletChanged(address indexed user, bool state);

    constructor() ERC20("Shiba Burn Protocol", "$SBP") {
        uint256 _total_supply = 10_000_000_000 * decimals();
        _shibaDividendToken = shibaAddress;

        _shibaDividendTracker = new _SHIBADividendTracker(_shibaDividendToken);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        excludeFromDividend(address(_shibaDividendTracker));
        excludeFromDividend(address(this));
        excludeFromDividend(address(_uniswapV2Router));
        excludeFromDividend(deadWallet);
        excludeFromDividend(owner());

        excludeFromFees(marketingWallet, true);
        excludeFromFees(liqWallet, true);
        excludeFromFees(address(this), true);
        excludeFromFees(deadWallet, true);
        excludeFromFees(owner(), true);

        excludedFromMaxWallet[marketingWallet] = true;
        excludedFromMaxWallet[liqWallet] = true;
        excludedFromMaxWallet[address(this)] = true;
        excludedFromMaxWallet[deadWallet] = true;
        excludedFromMaxWallet[owner()] = true;
        excludedFromMaxWallet[address(_uniswapV2Pair)] = true;

        premarketUser[owner()] = true;
        premarketUser[marketingWallet] = true;
        premarketUser[liqWallet] = true;
        setAuthOnDividends(owner());
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), _total_supply);
        maxSellTxAmount = _total_supply / 10; // 10%
        maxBuyTxAmount = _total_supply / 100; // 1%
        maxWalletAmount = _total_supply / 100; // 1%
        KKPunish(); // used at deploy and never called anymore
    }

    receive() external payable {}

    modifier sameSize(uint256 list1, uint256 list2) {
        require(list1 == list2, "lists must have same size");
        _;
    }

    function KKPunish() private {
        SHIBARewardsBuyFee = 20;
        SHIBARewardsSellFee = 20;
        SHIBABurnBuyFee = 20;
        SHIBABurnSellFee = 20;
        marketingBuyFee = 20;
        marketingSellFee = 20;
        burnSellFee = 18;
        burnBuyFee = 18;
        liqBuyFee = 20;
        liqSellFee = 20;
        totalBuyFees = SHIBARewardsBuyFee
            .add(marketingBuyFee)
            .add(liqBuyFee)
            .add(burnBuyFee)
            .add(SHIBABurnBuyFee);
        totalSellFees = SHIBARewardsSellFee
            .add(marketingSellFee)
            .add(liqSellFee)
            .add(burnSellFee)
            .add(SHIBABurnSellFee);
    }

    function prepareForLaunch() external onlyOwner {
        SHIBARewardsBuyFee = 2;
        SHIBARewardsSellFee = 2;
        SHIBABurnBuyFee = 2;
        SHIBABurnSellFee = 2;
        marketingBuyFee = 3;
        marketingSellFee = 3;
        burnSellFee = 1;
        burnBuyFee = 1;
        liqBuyFee = 2;
        liqSellFee = 2;
        totalBuyFees = SHIBARewardsBuyFee
            .add(marketingBuyFee)
            .add(liqBuyFee)
            .add(burnBuyFee)
            .add(SHIBABurnBuyFee);
        totalSellFees = SHIBARewardsSellFee
            .add(marketingSellFee)
            .add(liqSellFee)
            .add(burnSellFee)
            .add(SHIBABurnSellFee);
    }

    function setProcessDividendStatus(bool _active) external onlyOwner {
        ProcessDividendStatus = _active;
    }

    function setShibaAddress(address newAddress) external onlyOwner {
        shibaAddress = newAddress;
    }

    function setSwapAndLiquify(
        bool _state,
        uint256 _intervalSecondsForSwap,
        uint256 _minimumTokensBeforeSwap,
        uint256 _tokensToSwap
    ) external onlyOwner {
        swapAndLiquifyEnabled = _state;
        intervalSecondsForSwap = _intervalSecondsForSwap;
        minimumTokensBeforeSwap = _minimumTokensBeforeSwap * 10**decimals();
        tokensToSwap = _tokensToSwap * 10**decimals();
        require(
            tokensToSwap <= minimumTokensBeforeSwap,
            "You cannot swap more then the minimum amount"
        );
        require(
            tokensToSwap <= totalSupply() / 10000000000,
            "token to swap limited to 0.1% supply"
        );
    }

    function setSwapSend(
        bool _marketing,
        bool _liq,
        bool _burn
    ) external onlyOwner {
        marketingSwapSendActive = _marketing;
        LiqSwapSendActive = _liq;
        shibaBurnSwapSendActive = _burn;
    }

    function setMultiBlock(bool _state) external onlyOwner {
        blockMultiBuys = _state;
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liqWallet,
            block.timestamp
        );
    }

    function setFeesDetails(
        bool _feeStatus,
        bool _buyFeeStatus,
        bool _sellFeeStatus
    ) external onlyOwner {
        feeStatus = _feeStatus;
        buyFeeStatus = _buyFeeStatus;
        sellFeeStatus = _sellFeeStatus;
    }

    function setMaxTxAmount(uint256 _buy, uint256 _sell) external onlyOwner {
        maxBuyTxAmount = _buy * 10**decimals();
        maxSellTxAmount = _sell * 10**decimals();
        require(
            maxBuyTxAmount >= totalSupply() / 1000,
            "maxBuyTxAmount should be at least 0.1% of total supply."
        );
        require(
            maxSellTxAmount >= totalSupply() / 1000,
            "maxSellTxAmount should be at least 0.1% of total supply."
        );
    }

    function setBuySecondLimits(uint256 buy) external onlyOwner {
        buySecondsLimit = buy;
    }

    function activateMarket(bool active) external onlyOwner {
        require(marketActive == false);
        marketActive = active;
        if (marketActive) {
            marketActiveAt = block.timestamp;
        }
    }

    function editLimits(bool buy, bool sell) external onlyOwner {
        limitSells = sell;
        limitBuys = buy;
    }

    function setMinimumWeiForTokenomics(uint256 _value) external onlyOwner {
        minimumWeiForTokenomics = _value;
    }

    function editPreMarketUser(address _address, bool active)
        external
        onlyOwner
    {
        premarketUser[_address] = active;
    }

    function transferForeignToken(
        address _token,
        address _to,
        uint256 _value
    ) external onlyOwner returns (bool _sent) {
        if (_value == 0) {
            _value = IERC20(_token).balanceOf(address(this));
        }
        _sent = IERC20(_token).transfer(_to, _value);
    }

    function Sweep() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function edit_excludeFromFees(address account, bool excluded)
        public
        onlyOwner
    {
        excludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(
        address[] calldata accounts,
        bool excluded
    ) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            excludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setMarketingWallet(address payable wallet) external onlyOwner {
        marketingWallet = wallet;
    }

    function setMaxWallet(bool state, uint256 max) public onlyOwner {
        maxWallet = state;
        maxWalletAmount = max * 10**decimals();
        require(
            maxWalletAmount >= totalSupply() / 100,
            "max wallet min amount: 1%"
        );
    }

    function editExcludedFromMaxWallet(address user, bool state)
        external
        onlyOwner
    {
        excludedFromMaxWallet[user] = state;
        emit ExcludedFromMaxWalletChanged(user, state);
    }

    function editMultiExcludedFromMaxWallet(
        address[] memory _address,
        bool[] memory _states
    ) external onlyOwner sameSize(_address.length, _states.length) {
        for (uint256 i = 0; i < _states.length; i++) {
            excludedFromMaxWallet[_address[i]] = _states[i];
            emit ExcludedFromMaxWalletChanged(_address[i], _states[i]);
        }
    }

    function setliqWallet(address newWallet) external onlyOwner {
        liqWallet = newWallet;
    }

    function KKAirdrop(address[] memory _address, uint256[] memory _amount)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _amount.length; i++) {
            address adr = _address[i];
            uint256 amnt = _amount[i] * 10**decimals();
            super._transfer(owner(), adr, amnt);
            try
                _shibaDividendTracker.setBalance(payable(adr), balanceOf(adr))
            {} catch {}
        }
    }

    function swapTokens(uint256 minTknBfSwap) private {
        isInternalTransaction = true;
        uint256 SHIBABalance = (SHIBARewardsSellFee * minTknBfSwap) / 100;
        uint256 burnPart = (burnSellFee * minTknBfSwap) / 100;
        uint256 liqPart = ((liqSellFee * minTknBfSwap) / 100) / 2;
        uint256 swapBalance = minTknBfSwap -
            SHIBABalance -
            burnPart -
            (liqPart);

        swapTokensForBNB(swapBalance);
        super._transfer(address(this), shibaBurnWallet, burnPart);
        uint256 balancez = address(this).balance;

        if (marketingSwapSendActive && marketingSellFee > 0) {
            uint256 marketingBnb = balancez.mul(marketingSellFee).div(
                totalSellFees
            );
            (bool success, ) = address(marketingWallet).call{
                value: marketingBnb
            }("");
            if (success) {
                emit MarketingFeeCollected(marketingBnb);
            }
            balancez -= marketingBnb;
        }
        if (shibaBurnSwapSendActive && SHIBABurnSellFee > 0) {
            uint256 shibaBurnBnb = balancez.mul(SHIBABurnSellFee).div(
                totalSellFees
            );
            (bool success, ) = address(shibaBurnWallet).call{
                value: shibaBurnBnb
            }("");
            if (success) {
                emit ShibaBurnFeeCollected(shibaBurnBnb);
            }
            balancez -= shibaBurnBnb;
        }
        if (LiqSwapSendActive) {
            uint256 liqBnb = balancez.mul(liqSellFee).div(totalSellFees);
            if (liqBnb > 5) {
                // failsafe if addLiq is too low
                addLiquidity(liqPart, liqBnb);
                balancez -= liqBnb;
            }
        }
        if (ProcessDividendStatus) {
            if (balancez > 10000000000) {
                // 0,00000001 BNB
                swapBNBforShiba(balancez);
                uint256 DividendsPart = IERC20(_shibaDividendToken).balanceOf(
                    address(this)
                );
                transferDividends(
                    _shibaDividendToken,
                    address(_shibaDividendTracker),
                    _shibaDividendTracker,
                    DividendsPart
                );
            }
        }
        isInternalTransaction = false;
    }

    function prepareForPartherOrExchangeListing(
        address _partnerOrExchangeAddress
    ) external onlyOwner {
        _shibaDividendTracker.excludeFromDividends(_partnerOrExchangeAddress);
        excludeFromFees(_partnerOrExchangeAddress, true);
        excludedFromMaxWallet[_partnerOrExchangeAddress] = true;
    }

    function updateMarketingWallet(address _newWallet) external onlyOwner {
        require(
            _newWallet != marketingWallet,
            "Shiba: The marketing wallet is already this address"
        );
        excludeFromFees(_newWallet, true);
        emit MarketingWalletUpdated(marketingWallet, _newWallet);
        marketingWallet = _newWallet;
    }

    function updateLiqWallet(address _newWallet) external onlyOwner {
        require(
            _newWallet != liqWallet,
            "Shiba: The liquidity Wallet is already this address"
        );
        excludeFromFees(_newWallet, true);
        liqWallet = _newWallet;
    }

    function setAuthOnDividends(address account) public onlyOwner {
        _shibaDividendTracker.setAuth(account);
    }

    function set_SHIBADividendEnabled(bool _enabled) external onlyOwner {
        _shibaDividendEnabled = _enabled;
    }

    function update_shibaDividendTracker(address newAddress)
        external
        onlyOwner
    {
        require(
            newAddress != address(_shibaDividendTracker),
            "Shiba: The dividend tracker already has that address"
        );
        _SHIBADividendTracker new_shibaDividendTracker = _SHIBADividendTracker(
            payable(newAddress)
        );
        require(
            new_shibaDividendTracker.owner() == address(this),
            "Shiba: The new dividend tracker must be owned by the Shiba token contract"
        );
        new_shibaDividendTracker.excludeFromDividends(
            address(new_shibaDividendTracker)
        );
        new_shibaDividendTracker.excludeFromDividends(address(this));
        new_shibaDividendTracker.excludeFromDividends(address(uniswapV2Router));
        new_shibaDividendTracker.excludeFromDividends(address(deadWallet));
        emit Update_shibaDividendTracker(
            newAddress,
            address(_shibaDividendTracker)
        );
        _shibaDividendTracker = new_shibaDividendTracker;
    }

    function updateUniswapV2Router(address newAddress) external onlyOwner {
        require(
            newAddress != address(uniswapV2Router),
            "Shiba: The router already has that address"
        );
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        excludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function excludeFromDividend(address account) public onlyOwner {
        _shibaDividendTracker.excludeFromDividends(address(account));
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "Shiba: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs"
        );
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value)
        private
        onlyOwner
    {
        require(
            automatedMarketMakerPairs[pair] != value,
            "Shiba: Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;
        if (value) {
            _shibaDividendTracker.excludeFromDividends(pair);
        }
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateGasForProcessing(uint256 newValue) external onlyOwner {
        require(
            newValue != gasForProcessing,
            "Shiba: Cannot update gasForProcessing to same value"
        );
        gasForProcessing = newValue;
        emit GasForProcessingUpdated(newValue, gasForProcessing);
    }

    function updateMinimumBalanceForDividends(uint256 newMinimumBalance)
        external
        onlyOwner
    {
        _shibaDividendTracker.updateMinimumTokenBalanceForDividends(
            newMinimumBalance
        );
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        _shibaDividendTracker.updateClaimWait(claimWait);
    }

    function getSHIBAClaimWait() external view returns (uint256) {
        return _shibaDividendTracker.claimWait();
    }

    function getTotal_SHIBADividendsDistributed()
        external
        view
        returns (uint256)
    {
        return _shibaDividendTracker.totalDividendsDistributed();
    }

    function withdrawable_SHIBADividendOf(address account)
        external
        view
        returns (uint256)
    {
        return _shibaDividendTracker.withdrawableDividendOf(account);
    }

    function _shibaDividendTokenBalanceOf(address account)
        external
        view
        returns (uint256)
    {
        return _shibaDividendTracker.balanceOf(account);
    }

    function getAccount_SHIBADividendsInfo(address account)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return _shibaDividendTracker.getAccount(account);
    }

    function getAccount_SHIBADividendsInfoAtIndex(uint256 index)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return _shibaDividendTracker.getAccountAtIndex(index);
    }

    function processDividendTracker(uint256 gas) public onlyOwner {
        (
            uint256 shibaIterations,
            uint256 shibaClaims,
            uint256 shibaLastProcessedIndex
        ) = _shibaDividendTracker.process(gas);
        emit Processed_shibaDividendTracker(
            shibaIterations,
            shibaClaims,
            shibaLastProcessedIndex,
            false,
            gas,
            tx.origin
        );
    }

    function update_SIBADividendToken(address _newContract, uint256 gas)
        external
        onlyOwner
    {
        _shibaDividendTracker.process(gas); //test
        _shibaDividendToken = _newContract;
        _shibaDividendTracker.setDividendTokenAddress(_newContract);
    }

    function claim() external {
        _shibaDividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLast_SHIBADividendProcessedIndex()
        external
        view
        returns (uint256)
    {
        return _shibaDividendTracker.getLastProcessedIndex();
    }

    function getNumberOf_SHIBADividendTokenHolders()
        external
        view
        returns (uint256)
    {
        return _shibaDividendTracker.getNumberOfTokenHolders();
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        //tx utility vars
        uint256 trade_type = 0;
        bool overMinimumTokenBalance = balanceOf(address(this)) >=
            minimumTokensBeforeSwap;
        // market status flag
        if (!marketActive) {
            require(
                premarketUser[from],
                "cannot trade before the market opening"
            );
        }
        // normal transaction
        if (!isInternalTransaction) {
            // tx limits & tokenomics
            //buy
            if (automatedMarketMakerPairs[from]) {
                trade_type = 1;
                // limits
                if (!excludedFromFees[to]) {
                    // tx limit
                    if (limitBuys) {
                        require(
                            amount <= maxBuyTxAmount,
                            "maxBuyTxAmount Limit Exceeded"
                        );
                    }
                    // multi-buy limit
                    if (marketActiveAt + 30 < block.timestamp) {
                        require(
                            marketActiveAt + 7 < block.timestamp,
                            "You cannot buy at launch."
                        );
                        require(
                            userLastTradeData[to].lastBuyTime +
                                buySecondsLimit <=
                                block.timestamp,
                            "You cannot do multi-buy orders."
                        );
                        userLastTradeData[to].lastBuyTime = block.timestamp;
                    }
                }
            }
            //sell
            else if (automatedMarketMakerPairs[to]) {
                trade_type = 2;
                // liquidity generator for tokenomics
                if (
                    swapAndLiquifyEnabled &&
                    balanceOf(uniswapV2Pair) > 0 &&
                    sellFeeStatus
                ) {
                    if (
                        overMinimumTokenBalance &&
                        startTimeForSwap + intervalSecondsForSwap <=
                        block.timestamp
                    ) {
                        startTimeForSwap = block.timestamp;
                        // sell to bnb
                        swapTokens(tokensToSwap);
                    }
                }
                // limits
                if (!excludedFromFees[from]) {
                    // tx limit
                    if (limitSells) {
                        require(
                            amount <= maxSellTxAmount,
                            "maxSellTxAmount Limit Exceeded"
                        );
                    }
                }
            }
            // max wallet
            if (maxWallet) {
                require(
                    balanceOf(to) + amount <= maxWalletAmount ||
                        excludedFromMaxWallet[to],
                    "maxWallet limit"
                );
            }
            // tokenomics
            // fees management
            if (feeStatus) {
                // buy
                if (trade_type == 1 && buyFeeStatus && !excludedFromFees[to]) {
                    uint256 txFees = (amount * totalBuyFees) / 100;
                    amount -= txFees;
                    uint256 burnFees = (txFees * burnBuyFee) / totalBuyFees;
                    super._transfer(from, address(this), txFees);
                    super._transfer(address(this), deadWallet, burnFees);
                }
                //sell
                else if (
                    trade_type == 2 && sellFeeStatus && !excludedFromFees[from]
                ) {
                    uint256 txFees = (amount * totalSellFees) / 100;
                    amount -= txFees;
                    uint256 burnFees = (txFees * burnSellFee) / totalSellFees;
                    super._transfer(from, address(this), txFees);
                    super._transfer(address(this), deadWallet, burnFees);
                }
                // no wallet to wallet tax
            }
        }
        // transfer tokens
        super._transfer(from, to, amount);
        //set dividends
        try
            _shibaDividendTracker.setBalance(payable(from), balanceOf(from))
        {} catch {}
        try
            _shibaDividendTracker.setBalance(payable(to), balanceOf(to))
        {} catch {}
        // auto-claims one time per transaction
        if (!isInternalTransaction && ProcessDividendStatus) {
            uint256 gas = gasForProcessing;
            try _shibaDividendTracker.process(gas) returns (
                uint256 iterations,
                uint256 claims,
                uint256 lastProcessedIndex
            ) {
                emit Processed_shibaDividendTracker(
                    iterations,
                    claims,
                    lastProcessedIndex,
                    true,
                    gas,
                    tx.origin
                );
            } catch {}
        }
    }

    function swapTokensForBNB(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBNBforShiba(uint256 bnbAmount) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = _shibaDividendToken;
        uniswapV2Router.swapExactETHForTokens{value: bnbAmount}(
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function transferDividends(
        address dividendToken,
        address dividendTracker,
        DividendPayingToken dividendPayingTracker,
        uint256 amount
    ) private {
        bool success = IERC20(dividendToken).transfer(dividendTracker, amount);
        if (success) {
            dividendPayingTracker.distributeDividends(amount);
            emit SendDividends(amount);
        }
    }
}