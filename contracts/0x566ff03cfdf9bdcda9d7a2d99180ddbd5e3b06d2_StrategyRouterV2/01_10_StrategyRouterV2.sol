// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.15;

import "https://github.com/yearn/yearn-vaults/blob/v0.4.6/contracts/BaseStrategy.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

interface IVault is IERC20 {
    function token() external view returns (address);

    function decimals() external view returns (uint256);

    function deposit() external;

    function pricePerShare() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function lockedProfit() external view returns (uint256);

    function lockedProfitDegradation() external view returns (uint256);

    function lastReport() external view returns (uint256);

    function withdraw(
        uint256 amount,
        address account,
        uint256 maxLoss
    ) external returns (uint256);
}

interface IOracle {
    // pull our asset price, in usdc, via yearn's oracle
    function getPriceUsdcRecommended(address tokenAddress)
        external
        view
        returns (uint256);
}

interface IHelper {
    function sharesToAmount(address vault, uint256 shares)
        external
        view
        returns (uint256);

    function amountToShares(address vault, uint256 amount)
        external
        view
        returns (uint256);
}

contract StrategyRouterV2 is BaseStrategy {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    /// @notice The newer yVault we are routing this strategy to.
    IVault public yVault;

    /// @notice Max percentage loss we will take, in basis points (100% = 10_000). Default setting is zero.
    uint256 public maxLoss;

    /// @notice Address of our share value helper contract, which we use for conversions between shares and underlying amounts. Big 🧠 math here.
    IHelper public constant shareValueHelper =
        IHelper(0x444443bae5bB8640677A8cdF94CB8879Fec948Ec);

    /// @notice Minimum profit size in USDC that we want to harvest.
    /// @dev Only used in harvestTrigger.
    uint256 public harvestProfitMinInUsdc;

    /// @notice Maximum profit size in USDC that we want to harvest (ignore gas price once we get here).
    /// @dev Only used in harvestTrigger.
    uint256 public harvestProfitMaxInUsdc;

    /// @notice Amount we accept as a loss in liquidatePosition if we don't get 100% back due to rounding errors.
    uint256 public dustThreshold;

    /// @notice Will only be true on the original deployed contract and not on clones; we don't want to clone a clone.
    bool public isOriginal = true;

    // Do I really need to explain this one?
    string internal strategyName;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _vault,
        address _yVault,
        string memory _strategyName
    ) BaseStrategy(_vault) {
        _initializeThis(_yVault, _strategyName);
    }

    /* ========== CLONING ========== */

    event Cloned(address indexed clone);

    /// @notice Use this to clone an exact copy of this strategy on another vault.
    /// @param _vault Vault address we want to attach our new strategy to.
    /// @param _strategist Address to grant the strategist role.
    /// @param _rewards If we have any strategist rewards, send them here.
    /// @param _keeper Address to grant the keeper role.
    /// @param _yVault The newer vault we will route our funds to.
    /// @param _strategyName Name to use for our new strategy.
    function cloneRouterStrategy(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper,
        address _yVault,
        string memory _strategyName
    ) external virtual returns (address newStrategy) {
        require(isOriginal);
        // Copied from https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
        bytes20 addressBytes = bytes20(address(this));
        assembly {
            // EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(
                clone_code,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(
                add(clone_code, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            newStrategy := create(0, clone_code, 0x37)
        }

        StrategyRouterV2(newStrategy).initialize(
            _vault,
            _strategist,
            _rewards,
            _keeper,
            _yVault,
            _strategyName
        );

        emit Cloned(newStrategy);
    }

    function initialize(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper,
        address _yVault,
        string memory _strategyName
    ) public {
        require(address(yVault) == address(0));
        _initialize(_vault, _strategist, _rewards, _keeper);
        _initializeThis(_yVault, _strategyName);
    }

    function _initializeThis(address _yVault, string memory _strategyName)
        internal
    {
        yVault = IVault(_yVault);
        strategyName = _strategyName;
        harvestProfitMinInUsdc = 5_000e6;
        harvestProfitMaxInUsdc = 50_000e6;
        dustThreshold = 10;
    }

    /* ========== VIEWS ========== */

    /// @notice Strategy name.
    function name() external view override returns (string memory) {
        return strategyName;
    }

    /// @notice Total assets the strategy holds, sum of loose and staked want.
    function estimatedTotalAssets()
        public
        view
        virtual
        override
        returns (uint256)
    {
        return balanceOfWant() + valueOfInvestment();
    }

    /// @notice Assets delegated to another vault. Helps to avoid double-counting of TVL.
    /// @dev While a strategy may have loose want, only donations would be unaccounted for, and thus are not counted here.
    ///  Note that a strategy could also have loose want from a manual withdrawFromYVault() call.
    function delegatedAssets() public view override returns (uint256) {
        return vault.strategies(address(this)).totalDebt;
    }

    /// @notice Balance of want sitting in our strategy.
    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    /// @notice Balance of underlying we are holding as vault tokens of our delegated vault.
    function valueOfInvestment() public view virtual returns (uint256) {
        return
            shareValueHelper.sharesToAmount(
                address(yVault),
                yVault.balanceOf(address(this))
            );
    }

    /// @notice Balance of underlying we will gain on our next harvest
    function claimableProfits() public view returns (uint256 profits) {
        uint256 assets = estimatedTotalAssets();
        uint256 debt = delegatedAssets();

        if (assets > debt) {
            unchecked {
                profits = assets - debt;
            }
        } else {
            profits = 0;
        }
    }

    /* ========== CORE STRATEGY FUNCTIONS ========== */

    function prepareReturn(uint256 _debtOutstanding)
        internal
        virtual
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        )
    {
        // serious loss should never happen, but if it does, let's record it accurately
        uint256 assets = estimatedTotalAssets();
        uint256 debt = delegatedAssets();

        // if assets are greater than debt, things are working great!
        if (assets >= debt) {
            unchecked {
                _profit = assets - debt;
            }
            _debtPayment = _debtOutstanding;

            uint256 toFree = _profit + _debtPayment;

            // freed is math.min(wantBalance, toFree)
            (uint256 freed, ) = liquidatePosition(toFree);

            if (toFree > freed) {
                if (_debtPayment >= freed) {
                    _debtPayment = freed;
                    _profit = 0;
                } else {
                    unchecked {
                        _profit = freed - _debtPayment;
                    }
                }
            }
        }
        // if assets are less than debt, we are in trouble. don't worry about withdrawing here, just report losses
        else {
            unchecked {
                _loss = debt - assets;
            }
        }
    }

    function adjustPosition(uint256 _debtOutstanding)
        internal
        virtual
        override
    {
        if (emergencyExit) {
            return;
        }

        uint256 balance = balanceOfWant();
        if (balance > 0) {
            _checkAllowance(address(yVault), address(want), balance);
            yVault.deposit();
        }
    }

    function liquidatePosition(uint256 _amountNeeded)
        internal
        virtual
        override
        returns (uint256 _liquidatedAmount, uint256 _loss)
    {
        uint256 balance = balanceOfWant();
        if (balance >= _amountNeeded) {
            return (_amountNeeded, 0);
        }

        uint256 toWithdraw;
        unchecked {
            toWithdraw = _amountNeeded - balance;
        }

        // withdraw the remainder we need
        _withdrawFromYVault(toWithdraw);

        uint256 looseWant = balanceOfWant();

        // because of slippage, dust-sized losses are acceptable
        // however, we don't want to take losses for funds stuck in a strategy in the destination vault
        if (_amountNeeded > looseWant) {
            uint256 diff = _amountNeeded - looseWant;
            _liquidatedAmount = looseWant;
            if (diff < dustThreshold) {
                _loss = diff;
            }
        } else {
            _liquidatedAmount = _amountNeeded;
        }
    }

    /// @notice Manually withdraw underlying assets from our target vault.
    /// @dev Only governance or management may call this.
    /// @param _amount Shares of our target vault to withdraw.
    function withdrawFromYVault(uint256 _amount) external onlyVaultManagers {
        _withdrawFromYVault(_amount);
    }

    function _withdrawFromYVault(uint256 _amount) internal {
        if (_amount == 0) {
            return;
        }

        uint256 _balanceOfYShares = yVault.balanceOf(address(this));
        uint256 sharesToWithdraw =
            Math.min(
                shareValueHelper.amountToShares(address(yVault), _amount),
                _balanceOfYShares
            );

        if (sharesToWithdraw == 0) {
            return;
        }

        yVault.withdraw(sharesToWithdraw, address(this), maxLoss);
    }

    function liquidateAllPositions()
        internal
        virtual
        override
        returns (uint256 _amountFreed)
    {
        // withdraw as much as we can from vault tokens
        uint256 vaultTokenBalance = yVault.balanceOf(address(this));
        if (vaultTokenBalance > 0) {
            yVault.withdraw(vaultTokenBalance, address(this), maxLoss);
        }

        // return our want balance
        return balanceOfWant();
    }

    function prepareMigration(address _newStrategy) internal virtual override {
        IERC20(yVault).safeTransfer(
            _newStrategy,
            IERC20(yVault).balanceOf(address(this))
        );
    }

    function protectedTokens()
        internal
        view
        override
        returns (address[] memory ret)
    {}

    function _checkAllowance(
        address _contract,
        address _token,
        uint256 _amount
    ) internal {
        if (IERC20(_token).allowance(address(this), _contract) < _amount) {
            IERC20(_token).safeApprove(_contract, 0);
            IERC20(_token).safeApprove(_contract, type(uint256).max);
        }
    }

    /// @notice Convert our keeper's eth cost into want
    /// @dev We don't use this since we don't factor call cost into our harvestTrigger.
    /// @param _amtInWei Amount of ether spent.
    /// @return Value of ether in want.
    function ethToWant(uint256 _amtInWei)
        public
        view
        virtual
        override
        returns (uint256)
    {}

    /* ========== KEEP3RS ========== */

    /**
     * @notice
     *  Provide a signal to the keeper that harvest() should be called.
     *
     *  Don't harvest if a strategy is inactive.
     *  If our profit exceeds our upper limit, then harvest no matter what. For
     *  our lower profit limit, credit threshold, max delay, and manual force trigger,
     *  only harvest if our gas price is acceptable.
     *
     * @param callCostinEth The keeper's estimated gas cost to call harvest() (in wei).
     * @return True if harvest() should be called, false otherwise.
     */
    function harvestTrigger(uint256 callCostinEth)
        public
        view
        override
        returns (bool)
    {
        // Should not trigger if strategy is not active (no assets and no debtRatio). This means we don't need to adjust keeper job.
        if (!isActive()) {
            return false;
        }

        // harvest if we have a profit to claim at our upper limit without considering gas price
        uint256 claimableProfit = claimableProfitInUsdc();
        if (claimableProfit > harvestProfitMaxInUsdc) {
            return true;
        }

        // check if the base fee gas price is higher than we allow. if it is, block harvests.
        if (!isBaseFeeAcceptable()) {
            return false;
        }

        // trigger if we want to manually harvest, but only if our gas price is acceptable
        if (forceHarvestTriggerOnce) {
            return true;
        }

        // harvest if we have a sufficient profit to claim, but only if our gas price is acceptable
        if (claimableProfit > harvestProfitMinInUsdc) {
            return true;
        }

        StrategyParams memory params = vault.strategies(address(this));
        // harvest regardless of profit once we reach our maxDelay
        if (block.timestamp - params.lastReport > maxReportDelay) {
            return true;
        }

        // harvest our credit if it's above our threshold
        if (vault.creditAvailable() > creditThreshold) {
            return true;
        }

        // otherwise, we don't harvest
        return false;
    }

    /// @notice Calculates the profit if all claimable assets were sold for USDC (6 decimals).
    /// @dev Uses yearn's lens oracle, if returned values are strange then troubleshoot there.
    /// @return Total return in USDC from taking profits on yToken gains.
    function claimableProfitInUsdc() public view returns (uint256) {
        IOracle yearnOracle =
            IOracle(0x83d95e0D5f402511dB06817Aff3f9eA88224B030); // yearn lens oracle
        uint256 underlyingPrice =
            yearnOracle.getPriceUsdcRecommended(address(want));

        // Oracle returns prices as 6 decimals, so multiply by claimable amount and divide by token decimals
        return (claimableProfits() * underlyingPrice) / (10**yVault.decimals());
    }

    /* ========== SETTERS ========== */
    // These functions are useful for setting parameters of the strategy that may need to be adjusted.

    /// @notice Set the maximum loss we will accept (due to slippage or locked funds) on a vault withdrawal.
    /// @dev Generally, this should be zero, and this function will only be used in special/emergency cases.
    /// @param _maxLoss Max percentage loss we will take, in basis points (100% = 10_000).
    function setMaxLoss(uint256 _maxLoss) public onlyVaultManagers {
        maxLoss = _maxLoss;
    }

    /// @notice This allows us to set the dust threshold for our strategy.
    /// @param _dustThreshold This sets what dust is. If we have less than this remaining after withdrawing, accept it as a loss.
    function setDustThreshold(uint256 _dustThreshold)
        external
        onlyVaultManagers
    {
        require(_dustThreshold < 10000, "Your size is too much size");
        dustThreshold = _dustThreshold;
    }

    /**
     * @notice
     *  Here we set various parameters to optimize our harvestTrigger.
     * @param _harvestProfitMinInUsdc The amount of profit (in USDC, 6 decimals)
     *  that will trigger a harvest if gas price is acceptable.
     * @param _harvestProfitMaxInUsdc The amount of profit in USDC that
     *  will trigger a harvest regardless of gas price.
     */
    function setHarvestTriggerParams(
        uint256 _harvestProfitMinInUsdc,
        uint256 _harvestProfitMaxInUsdc
    ) external onlyVaultManagers {
        harvestProfitMinInUsdc = _harvestProfitMinInUsdc;
        harvestProfitMaxInUsdc = _harvestProfitMaxInUsdc;
    }
}