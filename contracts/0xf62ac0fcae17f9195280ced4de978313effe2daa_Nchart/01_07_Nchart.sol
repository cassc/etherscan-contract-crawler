/**                                
Nchart Token

Website: nchart.io
Docs: docs.nchart.io
twitter.com/Nchart_
twitter.com/Kekotron_
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@solady/tokens/ERC20.sol";
import "@solady/auth/Ownable.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

/**
            ........            
       ..::::::::::::.  .       
     .:::::::::::::::.  =+-.    
   --::::::::::::::::.  =+++-   
  *##*+::::::::::::::.  =+++++  
 *#####:  .::::::::::.  =++++++ 
-######:     .:::::::.  =++++++-
*######:  :.    .::::.  =+++++++
#######:  -=-:.    .:.  =+++++++
+######:  -=====:.      =++++++=
:######:  -========-.   =++++++:
 +#####:  -===========-.-+++++= 
  =####:  -==============-==+-  
   :*##:  -================-.   
     :+:  -==============-.     
          :==========-:.        
             ......                                       
*/

contract Nchart is ERC20, Ownable {
    struct User {
        bool isBlacklisted;
        bool isAutomatedMarketMaker;
        bool isExcludedFromFees;
        bool isExcludedFromMaxTransactionAmount;
    }

    struct Fees {
        uint8 buy;
        uint8 sell;
        uint8 liquidity;
        uint8 revShare;
        uint8 team;
    }

    struct Settings {
        bool limitsInEffect;
        bool swapEnabled;
        bool blacklistRenounced;
        bool feeChangeRenounced;
        bool tradingActive;
        /// @dev Upon enabling trading, record the end block for bot protection fee
        /// @dev This fee is a 90% fee that is reduced by 5% every block for 18 blocks.
        uint216 endBlock;
    }

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    /// @dev Constant to access the allowance slot
    uint256 private constant _ALLOWANCE_SLOT_SEED = 0x7f5e9f20;
    uint256 public constant MAX_SUPPLY = 10_000_000 * 1e18;
    uint256 public constant MIN_SWAP_AMOUNT = MAX_SUPPLY / 100_000; // 0.001%
    uint256 public constant MAX_SWAP_AMOUNT = MAX_SUPPLY * 5 / 1_000; // 0.5%

    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    address public revShareWallet;
    address public teamWallet;

    bool private _swapping;

    uint256 public tokensForBotProtection;

    Fees public feeAmounts;

    Settings private settings = Settings({
        limitsInEffect: true,
        swapEnabled: true,
        blacklistRenounced: false,
        feeChangeRenounced: false,
        tradingActive: false,
        endBlock: uint216(0)
    });

    mapping(address => User) private _users;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeFromMaxTransaction(address indexed account, bool isExcluded);
    event FailedSwapBackTransfer(address indexed destination, uint256 amount);
    event FeesUpdated(uint8 buyFee, uint8 sellFee, uint8 revSharePercent, uint8 liquidityPercent, uint8 teamPercent);
    event MaxTransactionAmountUpdated(uint256 newAmount, uint256 oldAmount);
    event MaxWalletAmountUpdated(uint256 newAmount, uint256 oldAmount);
    event RevShareWalletUpdated(address indexed newWallet, address indexed oldWallet);
    event SetAutomatedMarketMakerPair(address indexed pair, bool value);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived);
    event SwapTokensAtAmountUpdated(uint256 newAmount, uint256 oldAmount);
    event TeamWalletUpdated(address indexed newWallet, address indexed oldWallet);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    error Nchart__BlacklistModificationDisabled();
    error Nchart__BuyAmountGreaterThanMax();
    error Nchart__CannotBlacklistLPPair();
    error Nchart__CannotBlacklistRouter();
    error Nchart__CannotRemovePairFromAMMs();
    error Nchart__CannotSetWalletToAddressZero();
    error Nchart__CannotTransferFromAddressZero();
    error Nchart__CannotTransferToAddressZero();
    error Nchart__ErrorWithdrawingEth();
    error Nchart__FeeChangeRenounced();
    error Nchart__MaxFeeFivePercent();
    error Nchart__MaxTransactionTooLow();
    error Nchart__MaxWalletAmountExceeded();
    error Nchart__MaxWalletAmountTooLow();
    error Nchart__OnlyOwner();
    error Nchart__ReceiverBlacklisted();
    error Nchart__ReceiverCannotBeAddressZero();
    error Nchart__SellAmountGreaterThanMax();
    error Nchart__SenderBlacklisted();
    error Nchart__StuckEthWithdrawError();
    error Nchart__SwapAmountGreaterThanMaximum();
    error Nchart__SwapAmountLowerThanMinimum();
    error Nchart__TokenAddressCannotBeAddressZero();
    error Nchart__TradingNotActive();

    constructor(address ownerWallet, address teamWallet_, address revShareWallet_, address routerAddress) {
        _initializeOwner(ownerWallet);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddress);

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        maxTransactionAmount = MAX_SUPPLY / 100; // 1%
        maxWallet = MAX_SUPPLY / 100; // 1%
        swapTokensAtAmount = MAX_SUPPLY * 5 / 10_000; // 0.05%

        feeAmounts = Fees({buy: 5, sell: 5, revShare: 0, liquidity: 25, team: 75});

        revShareWallet = revShareWallet_;
        teamWallet = teamWallet_;

        _users[teamWallet_] = User({
            isExcludedFromFees: true,
            isExcludedFromMaxTransactionAmount: true,
            isAutomatedMarketMaker: false,
            isBlacklisted: false
        });
        _users[address(this)] = User({
            isExcludedFromFees: true,
            isExcludedFromMaxTransactionAmount: true,
            isAutomatedMarketMaker: false,
            isBlacklisted: false
        });
        _users[address(0xdead)] = User({
            isExcludedFromFees: true,
            isExcludedFromMaxTransactionAmount: true,
            isAutomatedMarketMaker: false,
            isBlacklisted: false
        });
        _users[address(ownerWallet)] = User({
            isExcludedFromFees: true,
            isExcludedFromMaxTransactionAmount: true,
            isAutomatedMarketMaker: false,
            isBlacklisted: false
        });

        _users[address(uniswapV2Router)] = User({
            isExcludedFromMaxTransactionAmount: true,
            isAutomatedMarketMaker: false,
            isExcludedFromFees: false,
            isBlacklisted: false
        });
        _users[address(uniswapV2Pair)] = User({
            isExcludedFromMaxTransactionAmount: true,
            isAutomatedMarketMaker: true,
            isExcludedFromFees: false,
            isBlacklisted: false
        });

        _mint(ownerWallet, MAX_SUPPLY);
    }

    receive() external payable {}

    function name() public pure override returns (string memory) {
        return "Nchart Token";
    }

    function symbol() public pure override returns (string memory) {
        return "CHART";
    }

    function enableTrading() public {
        _requireIsOwner();
        settings.endBlock = uint216(block.number) + 19;
        settings.tradingActive = true;
    }

    // remove limits after token is stable
    function removeLimits() external {
        _requireIsOwner();
        settings.limitsInEffect = false;
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external {
        _requireIsOwner();
        if (newAmount < MIN_SWAP_AMOUNT) {
            revert Nchart__SwapAmountLowerThanMinimum();
        }
        if (newAmount > MAX_SWAP_AMOUNT) {
            revert Nchart__SwapAmountGreaterThanMaximum();
        }
        uint256 oldSwapAmount = swapTokensAtAmount;
        swapTokensAtAmount = newAmount;
        emit SwapTokensAtAmountUpdated(newAmount, oldSwapAmount);
    }

    function updateMaxTransactionAmount(uint256 newAmount) external {
        _requireIsOwner();
        if (newAmount < MAX_SUPPLY * 5 / 1000) {
            revert Nchart__MaxTransactionTooLow();
        }
        uint256 oldMaxTransactionAmount = maxTransactionAmount;
        maxTransactionAmount = newAmount;
        emit MaxTransactionAmountUpdated(newAmount, oldMaxTransactionAmount);
    }

    function updateMaxWalletAmount(uint256 newNum) external {
        _requireIsOwner();
        if (newNum < MAX_SUPPLY / 100) {
            revert Nchart__MaxWalletAmountTooLow();
        }
        uint256 oldMaxWallet = maxWallet;
        maxWallet = newNum;
        emit MaxWalletAmountUpdated(newNum, oldMaxWallet);
    }

    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external {
        _requireIsOwner();
        settings.swapEnabled = enabled;
    }

    function updateBuyFees(uint8 revShareFee, uint8 liquidityFee, uint8 teamFee) external {
        _requireIsOwner();

        if (settings.feeChangeRenounced) {
            revert Nchart__FeeChangeRenounced();
        }

        uint8 totalFees = revShareFee + liquidityFee + teamFee;
        if (totalFees > 5) {
            revert Nchart__MaxFeeFivePercent();
        }

        uint8 sellFee = feeAmounts.sell;
        uint8 revPercent = revShareFee * 100 / totalFees;
        uint8 liqPercent = liquidityFee * 100 / totalFees;
        uint8 teamPercent = 100 - revPercent - liqPercent;

        feeAmounts =
            Fees({buy: totalFees, sell: sellFee, revShare: revPercent, liquidity: liqPercent, team: teamPercent});
        emit FeesUpdated(totalFees, sellFee, revPercent, liqPercent, teamPercent);
    }

    function updateSellFees(uint8 revShareFee, uint8 liquidityFee, uint8 teamFee) external {
        _requireIsOwner();

        if (settings.feeChangeRenounced) {
            revert Nchart__FeeChangeRenounced();
        }

        uint8 totalFees = revShareFee + liquidityFee + teamFee;
        if (totalFees > 5) {
            revert Nchart__MaxFeeFivePercent();
        }

        uint8 buyFee = feeAmounts.buy;
        uint8 revPercent = revShareFee * 100 / totalFees;
        uint8 liqPercent = liquidityFee * 100 / totalFees;
        uint8 teamPercent = 100 - revPercent - liqPercent;

        feeAmounts =
            Fees({buy: buyFee, sell: totalFees, revShare: revPercent, liquidity: liqPercent, team: teamPercent});
        emit FeesUpdated(buyFee, totalFees, revPercent, liqPercent, teamPercent);
    }

    function excludeFromFees(address account, bool excluded) external {
        _requireIsOwner();
        _users[account].isExcludedFromFees = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function excludeFromMaxTransaction(address account, bool isExcluded) external {
        _requireIsOwner();
        _users[account].isExcludedFromMaxTransactionAmount = isExcluded;
        emit ExcludeFromMaxTransaction(account, isExcluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external {
        _requireIsOwner();
        if (pair == uniswapV2Pair) {
            revert Nchart__CannotRemovePairFromAMMs();
        }

        _users[pair].isAutomatedMarketMaker = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateRevShareWallet(address newWallet) external {
        _requireIsOwner();
        if (newWallet == address(0)) {
            revert Nchart__CannotSetWalletToAddressZero();
        }
        address oldWallet = revShareWallet;
        revShareWallet = newWallet;
        emit RevShareWalletUpdated(newWallet, oldWallet);
    }

    function updateTeamWallet(address newWallet) external {
        _requireIsOwner();
        if (newWallet == address(0)) {
            revert Nchart__CannotSetWalletToAddressZero();
        }
        address oldWallet = teamWallet;
        teamWallet = newWallet;
        emit TeamWalletUpdated(newWallet, oldWallet);
    }

    function withdrawStuckChart(uint256 amount) external {
        _requireIsOwner();
        uint256 transferAmount;
        if (amount == 0) {
            transferAmount = balanceOf(address(this));
        } else {
            transferAmount = amount;
        }
        super._transfer(address(this), msg.sender, transferAmount);
    }

    function withdrawStuckToken(address _token) external {
        _requireIsOwner();
        if (_token == address(0)) {
            revert Nchart__TokenAddressCannotBeAddressZero();
        }
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, _contractBalance);
    }

    function withdrawStuckEth() external {
        _requireIsOwner();
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        if (!success) {
            revert Nchart__ErrorWithdrawingEth();
        }
    }

    function renounceBlacklist() external {
        _requireIsOwner();
        settings.blacklistRenounced = true;
    }

    function renounceFeeChange() external {
        _requireIsOwner();
        settings.feeChangeRenounced = true;
    }

    function blacklist(address account) external {
        _requireIsOwner();
        if (settings.blacklistRenounced) {
            revert Nchart__BlacklistModificationDisabled();
        }
        if (account == uniswapV2Pair) {
            revert Nchart__CannotBlacklistLPPair();
        }
        if (account == address(uniswapV2Router)) {
            revert Nchart__CannotBlacklistRouter();
        }
        _users[account].isBlacklisted = true;
    }

    // @dev unblacklist address; not affected by blacklistRenounced incase team wants to unblacklist v3 pools down the
    // @dev road
    function unblacklist(address account) external {
        _requireIsOwner();
        _users[account].isBlacklisted = false;
    }

    function isExcludedFromFees(address account) external view returns (bool) {
        return _users[account].isExcludedFromFees;
    }

    function isExcludedFromMaxTransactionAmount(address account) external view returns (bool) {
        return _users[account].isExcludedFromMaxTransactionAmount;
    }

    function isAutomatedMarketMakerPair(address pair) external view returns (bool) {
        return _users[pair].isAutomatedMarketMaker;
    }

    function isBlacklisted(address account) external view returns (bool) {
        return _users[account].isBlacklisted;
    }

    function isSwapEnabled() external view returns (bool) {
        return settings.swapEnabled;
    }

    function isBlacklistRenounced() external view returns (bool) {
        return settings.blacklistRenounced;
    }

    function isFeeChangeRenounced() external view returns (bool) {
        return settings.feeChangeRenounced;
    }

    function isTradingActive() external view returns (bool) {
        return settings.tradingActive;
    }

    function isLimitInEffect() external view returns (bool) {
        return settings.limitsInEffect;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        // Check allowance and reduce it if used, reverts with `InsufficientAllowance()` if not approved.
        assembly {
            let from_ := shl(96, from)
            // Compute the allowance slot and load its value.
            mstore(0x20, caller())
            mstore(0x0c, or(from_, _ALLOWANCE_SLOT_SEED))
            let allowanceSlot := keccak256(0x0c, 0x34)
            let allowance_ := sload(allowanceSlot)
            // If the allowance is not the maximum uint256 value.
            if iszero(eq(allowance_, not(0))) {
                // Revert if the amount to be transferred exceeds the allowance.
                if gt(amount, allowance_) {
                    mstore(0x00, 0x13be252b) // `InsufficientAllowance()`.
                    revert(0x1c, 0x04)
                }
                // Subtract and store the updated allowance.
                sstore(allowanceSlot, sub(allowance_, amount))
            }
        }
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        // Ignore mints, burns not enabled
        if (from == address(0)) {
            revert Nchart__CannotTransferFromAddressZero();
        }
        if (to == address(0)) {
            revert Nchart__CannotTransferToAddressZero();
        }

        User memory fromData = _users[from];
        User memory toData = _users[to];
        Settings memory settingCache = settings;

        if (!settingCache.tradingActive) {
            if (!fromData.isExcludedFromFees) {
                if (!toData.isExcludedFromFees) {
                    revert Nchart__TradingNotActive();
                }
            }
        }

        // Apply blacklist protection
        if (fromData.isBlacklisted) {
            revert Nchart__SenderBlacklisted();
        }
        if (toData.isBlacklisted) {
            revert Nchart__ReceiverBlacklisted();
        }

        // If zero amount, continue
        if (amount == 0) {
            return;
        }

        bool excludedFromFees = fromData.isExcludedFromFees || toData.isExcludedFromFees;

        // Cache transaction type for reference.
        // 1 = Buy
        // 2 = Sell
        // 3 = Transfer
        uint8 txType = 3;

        if (fromData.isAutomatedMarketMaker) {
            // Buys originate from the AMM pair
            txType = 1;
        } else if (toData.isAutomatedMarketMaker) {
            // Sells send funds to AMM pair
            txType = 2;
        }

        if (!_swapping) {
            if (settingCache.limitsInEffect) {
                //when buy
                if (txType == 1 && !toData.isExcludedFromMaxTransactionAmount) {
                    if (amount > maxTransactionAmount) {
                        revert Nchart__BuyAmountGreaterThanMax();
                    }
                    if (amount + balanceOf(to) > maxWallet) {
                        revert Nchart__MaxWalletAmountExceeded();
                    }
                }
                //when sell
                else if (txType == 2 && !fromData.isExcludedFromMaxTransactionAmount) {
                    if (amount > maxTransactionAmount) {
                        revert Nchart__SellAmountGreaterThanMax();
                    }
                } else if (!toData.isExcludedFromMaxTransactionAmount) {
                    if (amount + balanceOf(to) > maxWallet) {
                        revert Nchart__MaxWalletAmountExceeded();
                    }
                }
            }

            if (settingCache.swapEnabled) {
                // Only sells will trigger the fee swap
                if (txType == 2) {
                    if (balanceOf(address(this)) >= swapTokensAtAmount) {
                        _swapping = true;
                        _swapBack();
                        _swapping = false;
                    }
                }
            }
        }

        if (txType < 3) {
            bool takeFee = !_swapping;

            // if any account belongs to _isExcludedFromFee account then remove the fee
            if (excludedFromFees) {
                takeFee = false;
            }
            uint256 fees = 0;
            // only take fees on buys/sells, do not take on wallet transfers
            if (takeFee) {
                Fees memory feeCache = feeAmounts;
                // on sell
                if (txType == 2) {
                    if (feeCache.sell > 0) {
                        fees = amount * feeCache.sell / 100;
                    }
                }
                // on buy
                else if (txType == 1) {
                    if (feeCache.buy > 0) {
                        fees = amount * feeCache.buy / 100;
                    }
                }

                if (block.number < settingCache.endBlock) {
                    uint256 blocksLeft = settingCache.endBlock - block.number;
                    uint256 botFeeMultiplier = 90;

                    // Apply sniper protection - first 18 blocks have a fee reduced 5% each block.
                    if (blocksLeft < 18) {
                        botFeeMultiplier -= (5 * (18 - blocksLeft));
                    }
                    uint256 botFee = (amount * botFeeMultiplier) / 100;
                    super._transfer(from, teamWallet, botFee);
                    amount -= botFee;
                    tokensForBotProtection += botFee;
                }

                amount -= fees;

                if (fees > 0) {
                    super._transfer(from, address(this), fees);
                }
            }
        }
        super._transfer(from, to, amount);
    }

    function _swapTokensForEth(uint256 tokenAmount) internal {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function _swapBack() internal {
        // Cache values
        uint256 contractBalance = balanceOf(address(this));
        Fees memory feeCache = feeAmounts;
        bool success;

        if (contractBalance == 0) {
            return;
        }

        // Prevent too many tokens from being swapped
        uint256 maxAmount = swapTokensAtAmount * 20;
        if (contractBalance > maxAmount) {
            contractBalance = maxAmount;
        }

        uint256 liquidityAmount = contractBalance * feeCache.liquidity / 100;

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = liquidityAmount - (liquidityAmount / 2);
        uint256 amountToSwapForETH = contractBalance - liquidityTokens;

        uint256 initialETHBalance = address(this).balance;

        _swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance - initialETHBalance;

        uint256 ethForRevShare = ethBalance * feeCache.revShare / 100;
        uint256 ethForTeam = ethBalance * feeCache.team / 100;
        uint256 ethForLiquidity = ethBalance - ethForRevShare - ethForTeam;

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            _addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity);
        }

        address teamWallet_ = teamWallet;

        (success,) = address(teamWallet_).call{value: ethForTeam}("");
        if (!success) {
            emit FailedSwapBackTransfer(teamWallet_, ethForTeam);
        }

        if (ethForRevShare > 0) {
            (success,) = address(revShareWallet).call{value: ethForRevShare}("");
            if (!success) {
                emit FailedSwapBackTransfer(revShareWallet, ethForRevShare);
            }
        }
    }

    function _requireIsOwner() internal view {
        if (msg.sender != owner()) {
            revert Nchart__OnlyOwner();
        }
    }
}