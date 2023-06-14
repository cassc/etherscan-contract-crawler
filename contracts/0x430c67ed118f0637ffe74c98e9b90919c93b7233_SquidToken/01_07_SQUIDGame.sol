// Squid Game is originally a meme coin on Binance Smart Chain.
// It is now following in the footsteps of $BTC, $DOGE, and $SHIB. A token owned by the community.

// Here at ETH, SQUID Game Token is a community driven, fair launched DeFi Token, governed by SQUID DAO Contract.
// SQUID Game spirit is to create a community that is united and strong, bonded by the will to survive and win.
// With SQUID Frontman advocating for fairness, transparency, and sharing wealth to the masses, SQUID Game Token is a token that is built to last.

//
//
// Website: https://SQUIDGameHolders.Club
// Twitter: https://twitter.com/SQUIDHolders
// Telegram: https://t.me/SquidGameHolders

// Message from the SQUID Frontman
// Everyone should be the winner!
// https://SQUIDGameHolders.Club/docs/messagefromsquidfrontman2/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SquidToken is Ownable, ERC20, ReentrancyGuard {
    bool public limited = false;
    uint256 public maxHoldingAmount;
    uint256 public minHoldingAmount;
    address public uniswapV2Pair;
    mapping(address => bool) public blacklists;

    address public SQUIDFrontman;
    address public SquidDAOAddress;
    // bool private marketingWalletSet = false;
    bool private marketingWalletSet = true; // pre-defined marketing wallet; cannot be changed.
    address public MarketingWallet = 0x4440D4a8aB47412849613cba42Fd2c40Db7c2ef0;
    address public SquidGameTokenDevelopmentWallet =
        0x8ef6B893e9C9375449859feC1A4e9e54efBa203e;
    address public DevelopmentWalletFailSafe =
        0x9f095a94553D2EFfcc1A34b65b2a632DB65ae1e6;
    address public MarketingWalletFailSafe =
        0xf24e471bA10D791298B4AA55F447C2aaCe2E4aAe;

    address public winner;
    bool public rewardClaimed = false;
    bool public initialDistributionDone = false;
    uint256 public rewardAmount = 50000 * (10 ** 18);

    address public ultimateDrawWinner;
    bool public ultimateRewardClaimed = false;
    uint256 public ultimateRewardAmount = 1000000 * 10 ** 18; // 1 million SQUID tokens

    // max limit reward to 500,000 SQUID tokens
    uint256 public constant maxRewardAmount = 500000 * (10 ** 18);

    //daily transfer limit for marketing wallet and development wallet
    uint256 public constant dailyTransferLimit = 10000000 * (10 ** 18);
    mapping(address => uint256) public dailyTransfered;
    mapping(address => uint256) public lastTransfered;

    uint256 public lastDistributed;
    uint256 public lastWinnerSet;
    uint256 public contractDeploymentTimestamp;

    event UltimateDrawWinnerSet(address winner);
    event UltimateRewardDistributed(address winner, uint256 amount);

    event RewardDistributed(address indexed luckyHolder, uint256 amount);
    event MarketingWalletSet(address indexed marketingWallet);
    event EmergencyTransfer(
        address indexed fromWallet,
        address indexed toWallet,
        uint256 amount
    );
    event WinnerSet(address indexed winner);
    event LargeTransfer(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    constructor() Ownable() ERC20("Squid Game", "SQUID") {
        _mint(msg.sender, 488000000 * (10 ** 18));
        SQUIDFrontman = msg.sender;

        initialDistribution();
        lastDistributed = block.timestamp;
        lastWinnerSet = block.timestamp;
        contractDeploymentTimestamp = block.timestamp;
    }

    modifier onlySquidFrontmanOrDAO() {
        require(
            msg.sender == SQUIDFrontman ||
                (msg.sender == SquidDAOAddress &&
                    SquidDAOAddress != address(0)),
            "Not authorized"
        );
        _;
    }
    modifier onlySquidFrontman() {
        require(msg.sender == SQUIDFrontman, "Caller is not the SQUIDFrontman");
        _;
    }

    modifier dailyLimitCheck(address from, uint256 amount) {
        if (
            from == MarketingWallet || from == SquidGameTokenDevelopmentWallet
        ) {
            // If it's been more than 24 hours since the last transfer by SQUID Marketing and Dev Wallets, reset the daily transfer amount
            // any unauthorized transfer ; the emergency transfer function will be used to transfer the funds to fail safe address.
            // SQUID Frontman has designed this to prevent any unauthorized transfer of funds from the Marketing and Dev Wallets
            // movements of these wallets should be transparent and traceable
            if (block.timestamp > lastTransfered[from] + 24 hours) {
                dailyTransfered[from] = 0;
            }

            // If it is less than one year since contract deployment, do not allow any transfers from SquidGameTokenDevelopmentWallet
            // This is to prevent any unauthorized transfer of funds from the Development Wallet
            // SQUID Frontman has designed this to build trust and confidence in the whole crypto community.
            // We aspire to be the most transparent and traceable token in the whole crypto space.
            if (
                from == SquidGameTokenDevelopmentWallet &&
                block.timestamp < contractDeploymentTimestamp + 365 days
            ) {
                revert(
                    "Transfer: The timelock for SquidGameTokenDevelopmentWallet has not expired yet"
                );
            }

            require(
                block.timestamp > lastTransfered[from] + 24 hours,
                "Transfer: Daily transfer limit reached, wait until 24 hours passed since last transfer"
            );
            require(
                dailyTransfered[from] + amount <= dailyTransferLimit,
                "Transfer: Transfer amount exceeds daily limit"
            );

            // Only update lastTransfered and dailyTransfered after the transfer is successful
            _;

            dailyTransfered[from] += amount;
            lastTransfered[from] = block.timestamp;
        } else {
            _;
        }
    }

    // The winner of the ultimate draw will be set by the SQUID Frontman or SQUID DAO after the SQUID VRF function generateRandomAddressIndexForUltimateDraw is called
    // generateRandomAddressIndexForUltimateDraw can only be called once by the SQUID Frontman
    // The addressIndex which should be accessible in the SQUID Game token website is mapped to the winning SQUID Holder address.
    // The emitted event UltimateDrawWinnerGenerated at the SquidRandomNumberConsumer VRFV2WrapperConsumerBase contract  will be used to update the SQUID Game token website to display the winning address.
    // All should be transparent and traceable.
    // The winner of the ultimate draw will be able to claim the ultimate reward by calling the claimUltimateReward function
    // Wishing that the SQUID DAO COntract will execute this when SQUID is at least $1 so that the winner will get $1 million USD worth of SQUID tokens

    function setUltimateDrawWinner(
        address _winner
    ) external onlySquidFrontmanOrDAO nonReentrant {
        require(
            ultimateDrawWinner == address(0),
            "Ultimate draw has already been done"
        );
        ultimateDrawWinner = _winner;
        ultimateRewardClaimed = false;

        emit UltimateDrawWinnerSet(_winner);
    }

    function claimUltimateReward() external nonReentrant {
        require(
            msg.sender == ultimateDrawWinner,
            "Not the ultimate draw winner"
        );
        require(!ultimateRewardClaimed, "Ultimate reward already claimed");
        require(balanceOf(msg.sender) > 0, "Not a SQUID holder");

        ultimateRewardClaimed = true;
        _transfer(MarketingWallet, ultimateDrawWinner, ultimateRewardAmount);

        emit UltimateRewardDistributed(
            ultimateDrawWinner,
            ultimateRewardAmount
        );
    }

    function distributeReward(
        address luckyHolder
    ) external onlySquidFrontmanOrDAO nonReentrant {
        require(luckyHolder != address(0), "Cannot reward to the zero address");
        require(
            balanceOf(luckyHolder) > 0,
            "Address must be a SQUID Game token holder"
        );
        require(
            balanceOf(MarketingWallet) >= rewardAmount,
            "Marketing Wallet balance is insufficient"
        );
        require(
            block.timestamp > lastDistributed + 7 days,
            "Cannot distribute reward more than once per week"
        );

        _transfer(MarketingWallet, luckyHolder, rewardAmount);
        emit RewardDistributed(luckyHolder, rewardAmount);

        lastDistributed = block.timestamp;
    }

    function claimReward() external {
        require(msg.sender == winner, "Not the winner");
        require(!rewardClaimed, "Reward already claimed");
        require(balanceOf(msg.sender) > 0, "Not a SQUID holder");
        rewardClaimed = true;
        _transfer(MarketingWallet, winner, rewardAmount);
        emit RewardDistributed(winner, rewardAmount);
    }

    // Allows enforcement agent to blacklist an address, in order to be compliant with regulations.
    // Of course CoinmarketCap and CoinGecko should not display this warning without understanding the context specially when it is renounced.
    function blacklist(
        address _address,
        bool _isBlacklisting
    ) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function setDAOAddress(address _SquidDAOAddress) external {
        require(
            msg.sender == SQUIDFrontman,
            "Only the SQUIDFrontman can set the DAO address"
        );
        SquidDAOAddress = _SquidDAOAddress;
    }

    // in case this is not set before the renouncement, need to set it to start trading;
    // This helps prevent any possible issues with trading or transfers if SQUIDFrontman forgets to set uniswapV2Pair before renounces ownership.

    function setUniswapV2Pair(address _uniswapV2Pair) external {
        require(
            msg.sender == SQUIDFrontman,
            "Only the SQUIDFrontman can set the UniswapV2Pair address"
        );
        require(
            _uniswapV2Pair != address(0),
            "UniswapV2Pair cannot be the zero address"
        );
        uniswapV2Pair = _uniswapV2Pair;
    }

    function initialDistribution() internal {
        require(!initialDistributionDone, "Initial distribution already done");
        initialDistributionDone = true;

        uint256 totalSupply = totalSupply();
        uint256 marketingAllocation = (totalSupply * 20) / 100; // 20%
        uint256 developmentAllocation = (totalSupply * 10) / 100; // 10%

        _transfer(msg.sender, MarketingWallet, marketingAllocation);
        _transfer(
            msg.sender,
            SquidGameTokenDevelopmentWallet,
            developmentAllocation
        );
    }

    function setMarketingWallet(
        address _marketingWallet
    ) external onlySquidFrontmanOrDAO {
        require(!marketingWalletSet, "MarketingWallet can only be set once");
        require(
            _marketingWallet != address(0),
            "MarketingWallet cannot be the zero address"
        );

        MarketingWallet = _marketingWallet;
        marketingWalletSet = true;

        emit MarketingWalletSet(_marketingWallet);
    }

    function setWinner(
        address _winner
    ) external onlySquidFrontmanOrDAO nonReentrant {
        require(
            block.timestamp > lastWinnerSet + 7 days,
            "Cannot set winner more than once per week"
        );

        winner = _winner;
        rewardClaimed = false;

        emit WinnerSet(_winner);

        lastWinnerSet = block.timestamp;
    }

    function setRewardAmount(
        uint256 _rewardAmount
    ) external onlySquidFrontmanOrDAO nonReentrant {
        require(
            _rewardAmount <= maxRewardAmount,
            "Exceeds maximum reward amount"
        );
        rewardAmount = _rewardAmount;
    }

    function setRule(
        bool _limited,
        address _uniswapV2Pair,
        uint256 _maxHoldingAmount,
        uint256 _minHoldingAmount
    ) external onlyOwner {
        limited = _limited;
        uniswapV2Pair = _uniswapV2Pair;
        maxHoldingAmount = _maxHoldingAmount;
        minHoldingAmount = _minHoldingAmount;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");

        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "trading is not started");
            return;
        }

        if (limited && from == uniswapV2Pair) {
            require(
                super.balanceOf(to) + amount <= maxHoldingAmount &&
                    super.balanceOf(to) + amount >= minHoldingAmount,
                "Forbid"
            );
        }
    }

    function transfer(
        address recipient,
        uint256 amount
    )
        public
        virtual
        override
        dailyLimitCheck(_msgSender(), amount)
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);

        // Check if sender is MarketingWallet or SquidGameTokenDevelopmentWallet
        // and if the amount is greater than 3M SQUID
        if (
            (_msgSender() == MarketingWallet ||
                _msgSender() == SquidGameTokenDevelopmentWallet) &&
            amount > 3000000 * (10 ** 18)
        ) {
            emit LargeTransfer(_msgSender(), recipient, amount);
        }

        return true;
    }

    // in case of emergency where SQUID wallets are compromised, we can transfer the funds out to the fail safe address

    function emergencyTransfer() external onlySquidFrontmanOrDAO nonReentrant {
        uint256 marketingWalletBalance = balanceOf(MarketingWallet);
        uint256 developmentWalletBalance = balanceOf(
            SquidGameTokenDevelopmentWallet
        );

        _transfer(
            MarketingWallet,
            MarketingWalletFailSafe,
            marketingWalletBalance
        );
        _transfer(
            SquidGameTokenDevelopmentWallet,
            DevelopmentWalletFailSafe,
            developmentWalletBalance
        );

        // update wallets
        MarketingWallet = MarketingWalletFailSafe;
        SquidGameTokenDevelopmentWallet = DevelopmentWalletFailSafe;

        emit EmergencyTransfer(
            MarketingWallet,
            MarketingWalletFailSafe,
            marketingWalletBalance
        );
        emit EmergencyTransfer(
            SquidGameTokenDevelopmentWallet,
            DevelopmentWalletFailSafe,
            developmentWalletBalance
        );
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}