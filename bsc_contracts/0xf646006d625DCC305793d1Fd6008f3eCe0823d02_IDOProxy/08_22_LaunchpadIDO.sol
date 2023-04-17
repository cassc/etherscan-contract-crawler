// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './WithLimits.sol';
import '../sale/Timed.sol';
import './WithWhitelist.sol';
import './WithLevelsSale.sol';
import '../sale/Withdrawable.sol';
import './GeneralIDO.sol';

contract LaunchpadIDO is
    Adminable,
    ReentrancyGuard,
    Timed,
    GeneralIDO,
    Withdrawable,
    WithLimits,
    WithWhitelist,
    WithLevelsSale
{
    using SafeERC20 for IERC20;

    struct UserState {
        bool isWhitelisted;
        bool isRegistered;
        bool isLottery;
        bool isLotteryWinner;
        // wlAlloc + fcfsAlloc + levelAlloc
        uint256 totalAlloc;
        uint256 wlAlloc;
        uint256 fcfsAlloc;
        uint256 levelAlloc;
        string tierId;
        uint256 weight;
        uint256 contributed;
        uint256 balance;
    }

    string public id;
    uint256 public tokensSold;
    uint256 public raised;
    uint256 public participants;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public contributed;
    uint256 public firstPurchaseBlockN;
    uint256 public lastPurchaseBlockN;

    event TokensPurchased(address indexed beneficiary, uint256 value, uint256 amount);
    event UserRefunded(address indexed beneficiary, uint256 value, uint256 amount, bool refunded);

    constructor(
        string memory _id,
        uint256 _rate,
        uint256 _tokensForSale,
        address _fundToken,
        address _fundsReceiver,
        ILevelManager _levelManager,
        uint256 _max,
        uint256 _minAllowedLevelMultiplier,
        uint256[] memory _timeline,
        address[] memory _admins
    )
        GeneralIDO(_rate, _tokensForSale)
        Timed(_timeline)
        WithLevelsSale(_levelManager, _minAllowedLevelMultiplier)
        Withdrawable(_fundToken, _fundsReceiver)
    {
        id = _id;
        setMax(_max);

        for (uint256 i = 0; i < _admins.length; i++) {
            _grantRole(DEFAULT_ADMIN_ROLE, _admins[i]);
        }
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    receive() external payable {
        require(!fundByTokens, 'Sale: This presale is funded by tokens, use buyTokens(value)');
        buyTokens();
    }

    // Returns the whole sale state for the account.
    function getUserState(address account) public view returns (UserState memory) {
        bool levelsOpen = levelsOpenAll();
        UserState memory state;

        state.isRegistered = levelsEnabled && bytes(userLevel[account]).length > 0;
        state.isWhitelisted = whitelistEnabled && whitelisted[account];
        ILevelManager.Tier memory tier = levelsOpen
            ? levelManager.getUserTier(account)
            : levelManager.getTierById(state.isRegistered ? userLevel[account] : 'none');
        state.tierId = tier.id;
        state.isLottery = tier.random;
        // For non-registered in non-FCFS = 0
        state.weight = levelsEnabled ? (levelsOpen ? tier.multiplier : userWeight[account]) : 0;
        state.levelAlloc = (state.weight * baseAllocation) / WEIGHT_DECIMALS;

        // Winner when: tier must be random, and winners must be picked, and user must be registered
        state.isLotteryWinner =
            state.isRegistered &&
            state.isLottery &&
            levelWinners[tier.id].length > 0 &&
            userWeight[account] > 0;

        // FCFS alloc:
        // Registered, guaranteed or won lottery: baseAlloc + fcfsAlloc
        // Registered, lost lottery: fcfsAlloc
        // Not registered: 0 when < FCFS_3, fcfsAlloc when >= FCFS_3
        uint16 fcfsMultiplier = getFcfsAllocationMultiplier();
        uint256 fcfsAlloc = (state.levelAlloc * fcfsMultiplier) / 100;
        if (state.isRegistered) {
            state.fcfsAlloc = fcfsAlloc;
            bool lostLottery = state.isLottery && !state.isLotteryWinner;
            state.totalAlloc = lostLottery ? fcfsAlloc : state.levelAlloc + fcfsAlloc;
            if (lostLottery) {
                state.levelAlloc = 0;
            }
        } else if (fcfsMultiplier >= FCFS_3) {
            state.levelAlloc = 0;
            state.totalAlloc = state.fcfsAlloc = fcfsAlloc;
        } else {
            // Not-registered in FCFS < FCFS_3
            state.tierId = 'none';
            state.levelAlloc = 0;
            state.weight = 0;
        }

        // Whitelist alloc adds to the level alloc, but does not affect FCFS alloc.
        if (state.isWhitelisted) {
            state.wlAlloc = calculatePurchaseAmount(
                whitelistUserAllocation[account] > 0 ? whitelistUserAllocation[account] : maxSell
            );
            state.totalAlloc += state.wlAlloc;
        }
        
        state.contributed = contributed[account];
        state.balance = balances[account];

        return state;
    }

    function buyTokens() public payable ongoingSale nonReentrant {
        require(!fundByTokens, 'Sale: presale is funded by tokens but value is missing');

        internalBuyTokens(msg.value);
    }

    /**
     * The fund token must be first approved to be transferred by presale contract for the given "value".
     */
    function buyTokens(uint256 value) public ongoingSale nonReentrant {
        require(fundByTokens, 'Sale: funding by tokens is not allowed');
        require(fundToken.allowance(msg.sender, address(this)) >= value, 'Sale: fund token not approved');

        fundToken.safeTransferFrom(msg.sender, address(this), value);

        if (currencyDecimals < 18) {
            value = value * (10**(18 - currencyDecimals));
        }
        internalBuyTokens(value);
    }

    function internalBuyTokens(uint256 value) private {
        uint256 maxAllocation = checkAccountAllowedToBuy();
        address account = _msgSender();

        require(value > 0, 'Sale: value is 0');
        uint256 amount = calculatePurchaseAmount(value);
        require(amount > 0, 'Sale: amount is 0');

        tokensSold += amount;
        balances[account] += amount;
        contributed[account] += value;

        require(value >= minSell, 'Sale: amount is too small');
        require(maxAllocation == 0 || balances[account] <= maxAllocation, 'Sale: amount exceeds max allocation');
        require(tokensSold <= tokensForSale, 'Sale: cap reached');

        raised += value;
        participants += 1;

        // Store the first and last block numbers to simplify data collection later
        if (firstPurchaseBlockN == 0) {
            firstPurchaseBlockN = block.number;
        }
        lastPurchaseBlockN = block.number;

        emit TokensPurchased(account, value, amount);
    }

    function checkAccountAllowedToBuy() private view returns (uint256) {
        address account = _msgSender();
        // Public sale with no whitelist or levels
        if (!whitelistEnabled && !levelsEnabled) {
            return calculatePurchaseAmount(maxSell);
        }
        require(!levelsEnabled || baseAllocation > 0, 'Sale: levels are enabled but baseAllocation is not set');
        UserState memory userState = getUserState(account);
        require(userState.totalAlloc > 0, 'Sale: zero allocation');

        return userState.totalAlloc;
    }

    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a : b;
    }

    function batchAddBalance(address[] calldata accounts, uint256[] calldata values) external onlyOwnerOrAdmin {
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            uint256 value = values[i];
            uint256 amount = calculatePurchaseAmount(value);

            tokensSold += amount;
            balances[account] += amount;
            contributed[account] += value;

            raised += value;
            participants = participants + 1;

            emit TokensPurchased(account, value, amount);
        }

        if (firstPurchaseBlockN == 0) {
            firstPurchaseBlockN = block.number;
        }
        lastPurchaseBlockN = block.number;
    }
}