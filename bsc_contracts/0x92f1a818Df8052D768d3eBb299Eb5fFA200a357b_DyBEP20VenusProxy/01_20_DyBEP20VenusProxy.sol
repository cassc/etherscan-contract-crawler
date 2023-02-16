// contracts/Venus/DyBEP20Venus.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../DyERC20.sol";
import "./interfaces/IVenusBEP20Delegator.sol";
import "./interfaces/IVenusUnitroller.sol";
import "./interfaces/IPancakeRouter.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./lib/VenusLibrary.sol";
import "./interfaces/IDyBorrow.sol";

/**
 ________      ___    ___ ________   ________  _____ ______   ___  ________     
|\   ___ \    |\  \  /  /|\   ___  \|\   __  \|\   _ \  _   \|\  \|\   ____\    
\ \  \_|\ \   \ \  \/  / | \  \\ \  \ \  \|\  \ \  \\\__\ \  \ \  \ \  \___|    
 \ \  \ \\ \   \ \    / / \ \  \\ \  \ \   __  \ \  \\|__| \  \ \  \ \  \       
  \ \  \_\\ \   \/  /  /   \ \  \\ \  \ \  \ \  \ \  \    \ \  \ \  \ \  \____  
   \ \_______\__/  / /      \ \__\\ \__\ \__\ \__\ \__\    \ \__\ \__\ \_______\
    \|_______|\___/ /        \|__| \|__|\|__|\|__|\|__|     \|__|\|__|\|_______|
             \|___|/                                                            
 */

contract DyBEP20VenusProxy is Initializable, OwnableUpgradeable, DyERC20 {
    using SafeMath for uint256;

    struct LeverageSettings {
        uint256 leverageLevel;
        uint256 leverageBips;
        uint256 minMinting;
    }

    struct BorrowBalance {
        uint256 supply;
        uint256 loan;
    }

    mapping(address => BorrowBalance) public userBorrow;

    event TrackingDeposit(uint256 amount, uint256 usdt);
    event TrackingUserDeposit(address user, uint256 amount);
    event TrackingWithdraw(uint256 amount, uint256 usdt);
    event TrackingUserWithdraw(address user, uint256 amount);
    event TrackingInterest(uint256 moment, uint256 amount);
    event TrackingUserInterest(address user, uint256 amount);

    IDyBNBBorrow public borrowVenus;
    IVenusBEP20Delegator public tokenDelegator;
    IVenusUnitroller public rewardController;
    IERC20Upgradeable public xvsToken;
    IERC20Upgradeable public WBNB;
    IPancakeRouter public pancakeRouter;
    uint256 public leverageLevel;
    uint256 public leverageBips;
    uint256 public minMinting;
    uint256 public redeemLimitSafetyMargin;
    uint256 public totalInterest;

    function initialize(
        address borrowVenus_,
        address underlying_,
        string memory name_,
        string memory symbol_,
        address tokenDelegator_,
        address rewardController_,
        address xvsAddress_,
        address WBNB_,
        address USD_,
        address pancakeRouter_,
        LeverageSettings memory leverageSettings_,
        uint256 assetDecimals_
    ) public initializer {
        __Ownable_init();
        __initialize__DyERC20(underlying_, name_, symbol_, assetDecimals_);
        borrowVenus = IDyBNBBorrow(borrowVenus_);
        tokenDelegator = IVenusBEP20Delegator(tokenDelegator_);
        rewardController = IVenusUnitroller(rewardController_);
        minMinting = leverageSettings_.minMinting;
        xvsToken = IERC20Upgradeable(xvsAddress_);
        WBNB = IERC20Upgradeable(WBNB_);
        USD = USD_;
        pancakeRouter = IPancakeRouter(pancakeRouter_);
        _enterMarket();
        updateDepositsEnabled(true);
    }

    function deposit(uint256 amountUnderlying_) public override(DyERC20) {
        super.deposit(amountUnderlying_);
        // emit TrackingDeposit(amountUnderlying_, _getVaultValueInDollar());
        emit TrackingUserDeposit(_msgSender(), amountUnderlying_);
    }

    function withdraw(uint256 amount_) public override(DyERC20) {
        super.withdraw(amount_);
        DepositStruct storage user = userInfo[_msgSender()];
        uint256 reward = user.rewardBalance;
        user.rewardBalance = 0;
        underlying.transferFrom(address(this), _msgSender(), reward);
        // emit TrackingWithdraw(amount_, _getVaultValueInDollar());
        emit TrackingUserWithdraw(_msgSender(), amount_);
    }

    function totalDeposits() public view virtual override returns (uint256) {
        (
            ,
            uint256 internalBalance,
            uint256 borrowAmount,
            uint256 exchangeRate
        ) = tokenDelegator.getAccountSnapshot(address(this));
        return internalBalance.mul(exchangeRate).div(1e18).sub(borrowAmount);
    }

    function _totalDepositsFresh() internal override returns (uint256) {
        uint256 borrowAmount = tokenDelegator.borrowBalanceCurrent(
            address(this)
        );
        uint256 balance = tokenDelegator.balanceOfUnderlying(address(this));
        return balance.sub(borrowAmount);
    }

    function _enterMarket() internal {
        address[] memory tokens = new address[](1);
        tokens[0] = address(tokenDelegator);
        rewardController.enterMarkets(tokens);
    }

    function _stakeDepositTokens(uint256 amountUnderlying_)
        internal
        virtual
        override
    {
        require(amountUnderlying_ > 0, "DyBEP20Venus::stakeDepositTokens");
        underlying.approve(address(borrowVenus), amountUnderlying_);
        borrowVenus.deposit(
            amountUnderlying_,
            _msgSender(),
            address(underlying)
        );
    }

    function _getAccountData() internal returns (uint256, uint256) {
        uint256 balance = tokenDelegator.balanceOfUnderlying(address(this));
        uint256 borrowed = tokenDelegator.borrowBalanceCurrent(address(this));
        return (balance, borrowed);
    }

    function _getBorrowable(
        uint256 balance_,
        uint256 borrowed_,
        uint256 borrowLimit_,
        uint256 bips_
    ) internal pure returns (uint256) {
        return balance_.mul(borrowLimit_).div(bips_).sub(borrowed_);
    }

    function _getBorrowLimit() internal view returns (uint256, uint256) {
        (, uint256 borrowLimit) = rewardController.markets(
            address(tokenDelegator)
        );
        return (borrowLimit, 1e18);
    }

    function _withdrawDepositTokens(uint256 amountUnderlying_)
        internal
        virtual
        override
    {
        require(
            amountUnderlying_ >= minMinting,
            "DyBEP20Venus::below minimum withdraw"
        );
        borrowVenus.withdraw(
            amountUnderlying_,
            _msgSender(),
            address(underlying)
        );
    }

    function _getRedeemable(
        uint256 balance,
        uint256 borrowed,
        uint256 borrowLimit,
        uint256 bips
    ) internal view returns (uint256) {
        return
            balance
                .sub(borrowed.mul(bips).div(borrowLimit))
                .mul(redeemLimitSafetyMargin)
                .div(leverageBips);
    }

    function reinvest() external {
        _reinvest(false);
    }

    /**
     * @notice Reinvest rewards from staking contract to deposit tokens
     */
    function _reinvest(bool userDeposit) private {
        address[] memory markets = new address[](1);
        markets[0] = address(tokenDelegator);
        uint256 reward = distributeReward();
        totalInterest += reward;
        rewardController.claimVenus(address(this), markets);

        uint256 xvsBalance = xvsToken.balanceOf(address(this));
        if (xvsBalance > 0) {
            xvsToken.approve(address(pancakeRouter), xvsBalance);
            address[] memory path = new address[](3);
            path[0] = address(xvsToken);
            path[1] = address(WBNB);
            path[2] = address(underlying);
            uint256 _deadline = block.timestamp + 3000;
            pancakeRouter.swapExactTokensForTokens(
                xvsBalance,
                0,
                path,
                address(this),
                _deadline
            );
        }

        _distributeRewardByAmount(reward);

        uint256 amount = underlying.balanceOf(address(this));
        if (!userDeposit) {
            require(amount >= minTokensToReinvest, "DyBEP20Venus::reinvest");
        }
        if (amount > 0) {
            _stakeDepositTokens(amount);
        }

        emit Reinvest(totalDeposits(), totalSupply());
        emit TrackingInterest(block.timestamp, reward);
    }

    function getActualLeverage() public view returns (uint256) {
        (
            ,
            uint256 internalBalance,
            uint256 borrowAmount,
            uint256 exchangeRate
        ) = tokenDelegator.getAccountSnapshot(address(this));
        uint256 balance = internalBalance.mul(exchangeRate).div(1e18);
        return balance.mul(1e18).div(balance.sub(borrowAmount));
    }

    function distributeReward() public view returns (uint256) {
        uint256 xvsRewards = VenusLibrary.calculateReward(
            rewardController,
            tokenDelegator,
            address(this)
        );
        if (xvsRewards == 0) {
            return 0;
        }
        address[] memory path = new address[](3);
        path[0] = address(xvsToken);
        path[1] = address(WBNB);
        path[2] = address(underlying);
        uint256[] memory amounts = pancakeRouter.getAmountsOut(
            xvsRewards,
            path
        );
        return amounts[2];
    }

    function _distributeRewardByAmount(uint256 _rewardAmount) internal {
        uint256 totalProduct = _calculateTotalProduct();
        for (uint256 i = 0; i < depositors.length; i++) {
            DepositStruct storage user = userInfo[depositors[i]];
            uint256 stackingPeriod = block.timestamp - user.lastDepositTime;
            uint256 APY = _getAPYValue();
            uint256 interest = (_rewardAmount * user.amount * stackingPeriod) /
                totalProduct +
                (user.amount * stackingPeriod * APY) /
                (ONE_MONTH_IN_SECONDS * 1000);
            user.rewardBalance += (interest * 90) / 100; // 10 % performance fee
            user.lastDepositTime = block.timestamp;
            emit TrackingUserInterest(depositors[i], interest);
        }
    }

    function _calculateTotalProduct() internal view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < depositors.length; i++) {
            DepositStruct memory user = userInfo[depositors[i]];
            total += user.amount * (block.timestamp - user.lastDepositTime);
        }
        return total;
    }

    function _getAPYValue() public view returns (uint256) {
        uint256 totalValue = _getVaultValueInDollar();
        uint256 percent = 0;

        for (uint256 i = 0; i < totalValues.length; i++) {
            if (totalValue >= totalValues[i]) {
                percent = percentByValues[i];
                break;
            }
        }

        return percent;
    }

    function _getVaultValueInDollar() public view returns (uint256) {
        if (totalTokenStack == 0) {
            return 0;
        }
        if (address(underlying) == USD) {
            return totalTokenStack;
        }
        address[] memory path = new address[](2);
        path[0] = address(underlying);
        path[1] = address(USD);
        uint256[] memory amounts = pancakeRouter.getAmountsOut(
            totalTokenStack,
            path
        );
        return amounts[1];
    }
}