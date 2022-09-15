//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./interfaces/INovationRouter02.sol";
import "./interfaces/INovationFactory.sol";

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IERC20 BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    INovationRouter02 router = INovationRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // PancakeRouter

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) public shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public currentIndex;

    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;
    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 1 * (10 ** 18);

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor () {
        _token = msg.sender;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    receive() external payable {
        deposit();
    }
    
    function deposit() public payable override {
        uint256 balanceBefore = BUSD.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(BUSD);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = BUSD.balanceOf(address(this)).sub(balanceBefore);

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            BUSD.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }

    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

contract VaultFinanceV2 is ERC20, Ownable {

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address public constant PCS_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    IDividendDistributor public dividendDistributor;
    uint256 distributorGas = 500000;

    bool public tradingEnabled;

    mapping(address => bool) private _blacklist;
    mapping(address => bool) private _sentinels;
    mapping(address => bool) private _canTransferBeforeTradingIsEnabled;
    mapping(address => bool) public isDividendExempt;
    mapping(uint256 => mapping(address => uint256)) public dailyVolumes;
    mapping(address => bool) private _excludedFromCheckingDailyVolume;

    address public pair;
    address public router;
    address public swap;

    uint256 public maxDailySellLimit = 300_000_000_000 ether; // 300 billion

    event Blacklisted(address account, bool status);
    event Sentinel(address account, bool status);
    event TradingEnabled();

    constructor(address _router, address _swap) ERC20("Vault Finance", "VFX") {
        require(msg.sender != address(0), "Error: Cannot be the null address");
        _mint(msg.sender, 1000000000000000 * 1e18);

        router = _router;
        pair = INovationFactory(INovationRouter02(router).factory()).createPair(
            INovationRouter02(router).WETH(),
            address(this)
        );
        swap = _swap;

        dividendDistributor = IDividendDistributor(new DividendDistributor());

        isDividendExempt[msg.sender] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        
        _excludedFromCheckingDailyVolume[router] = true;
        _excludedFromCheckingDailyVolume[swap] = true;
        _excludedFromCheckingDailyVolume[pair] = true;
    }

    modifier onlyOwnerOrSentinel() {
        require(_msgSender() == owner() || _sentinels[_msgSender()] == true, "Error: Caller is not owner neither sentinel");
        _;
    }

    function toggleBlacklist(address account) external onlyOwnerOrSentinel {
        _blacklist[account] = !_blacklist[account];
        emit Blacklisted(account, _blacklist[account]);
    }

    function toggleSentinel(address account) external onlyOwner {
        _sentinels[account] = !_sentinels[account];
        emit Sentinel(account, _sentinels[account]);
    }

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Trading has already been enabled");
        
        tradingEnabled = true;
        emit TradingEnabled();
    }

    function setCanTransferBeforeTrading(address account, bool status) external onlyOwner {
        _canTransferBeforeTradingIsEnabled[account] = status;
    }

    function blacklisted(address account) public view returns(bool) {
        return _blacklist[account];
    }

    function sentinel(address account) public view returns(bool) {
        return _sentinels[account];
    }

    function canTransferBeforeTrading(address account) public view returns (bool) {
        return _canTransferBeforeTradingIsEnabled[account];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        require(spender != PCS_ROUTER, "Error: Account cannot be the Pancakeswap Router");
        return super.approve(spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        require(from != PCS_ROUTER && msg.sender != PCS_ROUTER && to != PCS_ROUTER, "Error: Account cannot be the Pancakeswap Router");
        require(!blacklisted(from) && !blacklisted(to), "Error: Blacklisted sender or recipient");

        if(!_canTransferBeforeTradingIsEnabled[from]) {
            require(tradingEnabled, "Error: Cannot transfer before trading is enabled");
        }

        if (!_excludedFromCheckingDailyVolume[from]) {
            uint256 current = block.timestamp / 1 days * 1 days;
            require (dailyVolumes[current][tx.origin] + amount <= maxDailySellLimit, "Error: Exceeded daily trading");
            dailyVolumes[current][tx.origin] += amount;
        }

        super._transfer(from, to, amount);

        // Refresh dividend shares and process distribution...
        if(!isDividendExempt[from]){ try dividendDistributor.setShare(from, balanceOf(from)) {} catch {} }
        if(!isDividendExempt[to]){ try dividendDistributor.setShare(to, balanceOf(to)) {} catch {} }
        try dividendDistributor.process(distributorGas) {} catch {}
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external onlyOwner {
        dividendDistributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas < 750000, "Gas must be lower than 750000");
        distributorGas = gas;
    }

    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this), "Holder can't be token");
        isDividendExempt[holder] = exempt;

        if (exempt) {
            dividendDistributor.setShare(holder, 0);
        } else {
            dividendDistributor.setShare(holder, balanceOf(holder));
        }
    }

    function setExcludeFromDailyVolumeLimit(address _wallet, bool _flag) external onlyOwner {
        _excludedFromCheckingDailyVolume[_wallet] = _flag;
    }
    
    function setMaxDailySellLimit(uint256 _limit) external onlyOwner {
        require (_limit >= 300_000_000_000 ether, "can't be less than 300 billion");
        maxDailySellLimit = _limit;
    }

    function updateSwap(address _swap) external onlyOwner {
        _excludedFromCheckingDailyVolume[_swap] = true;
        swap = _swap;
    }

    function todayVolume(address _wallet) external view returns (uint256) {
        uint256 current = block.timestamp / 1 days * 1 days;
        return dailyVolumes[current][_wallet];
    }
}