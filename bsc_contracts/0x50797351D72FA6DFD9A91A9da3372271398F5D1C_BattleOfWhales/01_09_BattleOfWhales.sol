pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract BattleOfWhales is ERC20, Ownable {
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    mapping(address => bool) public automatedMarketMakerPairs;

    uint256 leaderboardLength = 10;
    uint256 public leaderCount = 0;

    uint256 public buyTotalFees;
    uint256 public buyDevelopmentFee;
    uint256 public buyBuybackFee;
    uint256 public buyTeamFee;

    uint256 public sellTotalFees;
    uint256 public sellDevelopmentFee;
    uint256 public sellBuybackFee;
    uint256 public sellTeamFee;
    uint256 public sellSheikhFee;

    address developmentWallet;
    address buybackWallet;
    address teamWallet;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedFromRewards;
    uint256 public swapTokensAtAmount;
    bool public tradingActive = false;
    bool public swapEnabled = false;
    uint256 public tradingBlock = 0;
    bool private swapping;
    uint256 public devAccrued;
    uint256 public teamAccrued;
    uint256 public buybackAccrued;

    struct User {
        address wallet;
        uint256 balance;
    }

    mapping(uint256 => User) public leaderboard;

    // Events
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeFromRewards(address indexed account, bool isExcluded);
    event DevelopmentWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );
    event TeamWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );
    event BuybackWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function excludeFromRewards(address account, bool excluded)
        public
        onlyOwner
    {
        _isExcludedFromRewards[account] = excluded;
        emit ExcludeFromRewards(account, excluded);
    }

    function excludeFromFeesAndRewards(address account, bool excluded)
        public
        onlyOwner
    {
        _isExcludedFromFees[account] = excluded;
        _isExcludedFromRewards[account] = excluded;
        emit ExcludeFromFees(account, excluded);
        emit ExcludeFromRewards(account, excluded);
    }

    constructor(uint256 initialSupply) ERC20("BattleOfWhales", "$BOW") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(uniswapV2Router.WETH(), address(this));
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        buyDevelopmentFee = 1;
        buyBuybackFee = 0;
        buyTeamFee = 4;
        buyTotalFees = buyDevelopmentFee + buyBuybackFee + buyTeamFee;

        sellDevelopmentFee = 0;
        sellBuybackFee = 0;
        sellTeamFee = 3;
        sellSheikhFee = 1;
        sellTotalFees =
            sellDevelopmentFee +
            sellBuybackFee +
            sellTeamFee +
            sellSheikhFee;

        developmentWallet = address(owner());
        buybackWallet = address(owner());
        teamWallet = address(owner());

        swapTokensAtAmount = (initialSupply * 1) / 1000000;

        excludeFromFeesAndRewards(owner(), true);
        excludeFromFeesAndRewards(address(this), true);
        excludeFromFeesAndRewards(
            address(0x000000000000000000000000000000000000dEaD),
            true
        );
        excludeFromRewards(address(uniswapV2Pair), true);

        _mint(msg.sender, initialSupply);
    }

    function airdropToWallets(
        address[] memory airdropWallets,
        uint256[] memory amounts
    ) external onlyOwner {
        require(
            airdropWallets.length == amounts.length,
            "arrays must be the same length"
        );
        require(
            airdropWallets.length < 200,
            "Can only airdrop 200 wallets per txn due to gas limits"
        );
        for (uint256 i = 0; i < airdropWallets.length; i++) {
            address wallet = airdropWallets[i];
            uint256 amount = amounts[i];
            super._transfer(msg.sender, wallet, amount);
        }
    }

    receive() external payable {}

    function enableTrading() external onlyOwner {
        require(!tradingActive, "Cannot enable trading again");
        tradingActive = true;
        swapEnabled = true;
        tradingBlock = block.number;
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        external
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function updateBuyFees(
        uint256 _developmentFee,
        uint256 _buybackFee,
        uint256 _teamFee
    ) external onlyOwner {
        buyDevelopmentFee = _developmentFee;
        buyBuybackFee = _buybackFee;
        buyTeamFee = _teamFee;
        buyTotalFees = buyDevelopmentFee + buyBuybackFee + buyTeamFee;
        require(buyTotalFees <= 10, "Must keep fees at 10% or less");
    }

    function updateSellFees(
        uint256 _developmentFee,
        uint256 _buybackFee,
        uint256 _teamFee,
        uint256 _sheikhFee
    ) external onlyOwner {
        sellDevelopmentFee = _developmentFee;
        sellBuybackFee = _buybackFee;
        sellTeamFee = _teamFee;
        sellSheikhFee = _sheikhFee;
        sellTotalFees =
            sellDevelopmentFee +
            sellBuybackFee +
            sellTeamFee +
            sellSheikhFee;
        require(sellTotalFees <= 10, "Must keep fees at 10% or less");
    }

    function updateDevelopmentWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "cannot set to 0 address");
        emit DevelopmentWalletUpdated(newWallet, developmentWallet);
        developmentWallet = newWallet;
    }

    function updateTeamWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "cannot set to 0 address");
        emit TeamWalletUpdated(newWallet, teamWallet);
        teamWallet = newWallet;
    }

    function updateBuybackWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "cannot set to 0 address");
        emit BuybackWalletUpdated(newWallet, buybackWallet);
        buybackWallet = newWallet;
    }

    function updateSwapTokensAtAmount(uint256 newAmount)
        external
        onlyOwner
        returns (bool)
    {
        require(
            newAmount >= (totalSupply() * 1) / 1000000,
            "Swap amount cannot be lower than 0.0001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 1) / 1000,
            "Swap amount cannot be higher than 0.1% total supply."
        );
        swapTokensAtAmount = newAmount;
        return true;
    }

    function swapTokensForBNB(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of WBNB
            path,
            address(this),
            block.timestamp
        );
    }

    function safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "STE");
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = devAccrued + teamAccrued + buybackAccrued;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        uint256 initialBNBBalance = address(this).balance;
        swapTokensForBNB(totalTokensToSwap);

        uint256 bnbBalance = address(this).balance - initialBNBBalance;

        safeTransferBNB(
            developmentWallet,
            (bnbBalance * devAccrued) / totalTokensToSwap
        );
        safeTransferBNB(
            teamWallet,
            (bnbBalance * teamAccrued) / totalTokensToSwap
        );
        safeTransferBNB(
            buybackWallet,
            (bnbBalance * buybackAccrued) / totalTokensToSwap
        );

        devAccrued = teamAccrued = buybackAccrued = 0;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (!tradingActive) {
            require(
                _isExcludedFromFees[from] || _isExcludedFromFees[to],
                "Trading is not active."
            );
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        uint256 sheikhTax = 0;

        if (takeFee) {
            if (automatedMarketMakerPairs[to]) {
                if (sellTotalFees > 0) {
                    // selling tokens
                    fees = (amount * sellTotalFees) / 100;
                    devAccrued += (fees * sellDevelopmentFee) / sellTotalFees;
                    teamAccrued += (fees * sellTeamFee) / sellTotalFees;
                    buybackAccrued += (fees * sellBuybackFee) / sellTotalFees;
                    sheikhTax = (fees * sellSheikhFee) / sellTotalFees;
                }
            } else if (automatedMarketMakerPairs[from]) {
                if (buyTotalFees > 0) {
                    // buying tokens
                    fees = (amount * buyTotalFees) / 100;
                    devAccrued += (fees * buyDevelopmentFee) / buyTotalFees;
                    teamAccrued += (fees * buyTeamFee) / buyTotalFees;
                    buybackAccrued += (fees * buyBuybackFee) / buyTotalFees;
                }
            } else {
                // transfer tokens
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
                amount -= fees;
            }
        }

        if (sheikhTax > 0 && leaderCount > 0) {
            swapping = true;
            distributeSheikhTax(sheikhTax);
            swapping = false;
        }

        super._transfer(from, to, amount);

        updateLeaderboard(from);
        updateLeaderboard(to);
        updateLeaderCount();
    }

    function distributeSheikhTax(uint256 totalTokensToSwap) private {
        uint256 initialBNBBalance = address(this).balance;
        swapTokensForBNB(totalTokensToSwap);

        uint256 bnbBalance = address(this).balance - initialBNBBalance;

        for (uint256 i = 0; i < leaderboardLength; i++) {
            if (leaderboard[i].wallet != address(0)) {
                safeTransferBNB(
                    leaderboard[i].wallet,
                    bnbBalance / leaderCount
                );
            }
        }
    }

    function updateLeaderCount() private returns (uint256) {
        leaderCount = 0;
        for (uint256 i = 0; i < leaderboardLength; i++) {
            if (leaderboard[i].wallet != address(0)) {
                leaderCount += 1;
            }
        }
        return leaderCount;
    }

    function updateLeaderboard(address wallet) private returns (bool) {
        if (_isExcludedFromRewards[wallet]) {
            return false;
        }

        for (uint256 i = 0; i < leaderboardLength; i++) {
            if (leaderboard[i].wallet == wallet) {
                for (uint256 j = i; j < leaderboardLength; j++) {
                    leaderboard[j] = leaderboard[j + 1];
                }

                delete leaderboard[leaderboardLength - 1];
                break;
            }
        }

        uint256 newBalance = balanceOf(wallet);

        if (leaderboard[leaderboardLength - 1].balance >= newBalance)
            return false;

        for (uint256 i = 0; i < leaderboardLength; i++) {
            if (leaderboard[i].balance < newBalance) {
                User memory currentUser = leaderboard[i];
                for (uint256 j = i + 1; j < leaderboardLength + 1; j++) {
                    User memory nextUser = leaderboard[j];
                    leaderboard[j] = currentUser;
                    currentUser = nextUser;
                }

                leaderboard[i] = User({wallet: wallet, balance: newBalance});

                delete leaderboard[leaderboardLength];

                return true;
            }
        }

        return false;
    }
}