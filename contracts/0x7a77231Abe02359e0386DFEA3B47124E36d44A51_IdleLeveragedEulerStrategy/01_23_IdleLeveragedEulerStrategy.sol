// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../BaseStrategy.sol";

import "../../interfaces/euler/IEToken.sol";
import "../../interfaces/euler/IDToken.sol";
import "../../interfaces/euler/IMarkets.sol";
import "../../interfaces/euler/IExec.sol";
import "../../interfaces/euler/IEulerGeneralView.sol";
import "../../interfaces/euler/IEulDistributor.sol";
import "../../interfaces/ISwapRouter.sol";

contract IdleLeveragedEulerStrategy is BaseStrategy {
    using SafeERC20Upgradeable for IERC20Detailed;

    /// @notice Euler markets contract
    IMarkets internal constant EULER_MARKETS = IMarkets(0x3520d5a913427E6F0D6A83E07ccD4A4da316e4d3);

    /// @notice Euler general view contract
    IEulerGeneralView internal constant EULER_GENERAL_VIEW =
        IEulerGeneralView(0xACC25c4d40651676FEEd43a3467F3169e3E68e42);

    /// @notice Euler general Exec contract
    IExec internal constant EULER_EXEC = IExec(0x59828FdF7ee634AaaD3f58B19fDBa3b03E2D9d80);

    /// @notice Euler Governance Token
    IERC20Detailed internal constant EUL = IERC20Detailed(0xd9Fcd98c322942075A5C3860693e9f4f03AAE07b);

    uint256 internal constant EXP_SCALE = 1e18;

    uint256 internal constant ONE_FACTOR_SCALE = 1_000_000_000;

    uint256 internal constant CONFIG_FACTOR_SCALE = 4_000_000_000;

    uint256 internal constant SELF_COLLATERAL_FACTOR = 0.95 * 4_000_000_000;

    /// @notice Euler account id
    uint256 internal constant SUB_ACCOUNT_ID = 0;

    /// @notice EToken contract
    IEToken public eToken;

    /// @notice DToken contract
    IDToken public dToken;

    /// @notice target health score is defined as adjusted collateral divided by adjusted liability.
    /// @dev 18 decimals. 1 == 1e18. must be greater 1e18
    uint256 public targetHealthScore;

    /// @notice price used to mint tranche tokens if current tranche price < last harvest
    uint256 public mintPrice;

    /// @notice Eul reward distributor
    IEulDistributor public eulDistributor;

    /// @notice uniswap v3 router
    ISwapRouter public router;

    /// @notice uniswap v3 router path
    bytes public path;

    /// @notice address used to manage targetHealth
    address public rebalancer;

    event UpdateTargetHealthScore(uint256 oldHeathScore, uint256 newHeathScore);

    event UpdateEulDistributor(address oldEulDistributor, address newEulDistributor);

    event UpdateSwapRouter(address oldRouter, address newRouter);

    event UpdateRouterPath(bytes oldRouter, bytes _path);

    function initialize(
        address _euler,
        address _eToken,
        address _dToken,
        address _underlying,
        address _owner,
        address _eulDistributor,
        address _router,
        bytes memory _path,
        uint256 _targetHealthScore
    ) public initializer {
        _initialize(
            string(abi.encodePacked("Idle ", IERC20Detailed(_underlying).name(), " Euler Leverege Strategy")),
            string(abi.encodePacked("idleEulLev", IERC20Detailed(_underlying).symbol())),
            _underlying, 
            _owner
        );
        eToken = IEToken(_eToken);
        dToken = IDToken(_dToken);
        eulDistributor = IEulDistributor(_eulDistributor);
        router = ISwapRouter(_router);
        path = _path;
        targetHealthScore = _targetHealthScore;
        // This should be more than the Euler epoch period
        releaseBlocksPeriod = 108900; // ~15 days in blocks (counting 11.9 sec per block with PoS)
        mintPrice = oneToken;

        // Enter the collateral market (collateral's address, *not* the eToken address)
        EULER_MARKETS.enterMarket(SUB_ACCOUNT_ID, _underlying);

        underlyingToken.safeApprove(_euler, type(uint256).max);
    }

    /// @return _price net in underlyings of 1 strategyToken
    function price() public view override returns (uint256 _price) {
        uint256 _totalSupply = totalSupply();
        uint256 _tokenValue = eToken.balanceOfUnderlying(address(this)) - dToken.balanceOf(address(this));
        if (_totalSupply == 0) {
            _price = oneToken;
        } else {
            _price = ((_tokenValue - _lockedTokens()) * EXP_SCALE) / _totalSupply;
        }
    }

    function _setMintPrice() internal {
        uint256 _tokenValue = eToken.balanceOfUnderlying(address(this)) - dToken.balanceOf(address(this));
        // count all tokens as unlocked so price will be higher for mint (otherwise interest unlocked is stealed from others)
        mintPrice = (_tokenValue * EXP_SCALE) / totalSupply();
    }

    /// @param _amount amount of underlying to deposit
    function _deposit(uint256 _amount) internal override returns (uint256 amountUsed) {
        if (_amount == 0) {
            return 0;
        }
        IEToken _eToken = eToken;
        IERC20Detailed _underlyingToken = underlyingToken;
        uint256 balanceBefore = _underlyingToken.balanceOf(address(this));
        // get amount to deposit to retain a target health score
        uint256 amountToMint = getSelfAmountToMint(targetHealthScore, _amount);

        // some of the amount should be deposited to make the health score close to the target one.
        _eToken.deposit(SUB_ACCOUNT_ID, _amount);

        // self borrow
        if (amountToMint != 0) {
            _eToken.mint(SUB_ACCOUNT_ID, amountToMint);
        }

        amountUsed = balanceBefore - _underlyingToken.balanceOf(address(this));
    }

    function _redeemRewards(bytes calldata data) internal override returns (uint256[] memory rewards) {
        rewards = new uint256[](1);
        IEulDistributor _eulDistributor = eulDistributor;
        ISwapRouter _router = router;
        if (address(_eulDistributor) != address(0) && address(_router) != address(0) && data.length != 0) {
            (uint256 claimable, bytes32[] memory proof, uint256 minAmountOut) = abi.decode(
                data,
                (uint256, bytes32[], uint256)
            );

            if (claimable == 0) {
                return rewards;
            }
            // claim EUL by verifying a merkle root
            _eulDistributor.claim(address(this), address(EUL), claimable, proof, address(0));
            uint256 amountIn = EUL.balanceOf(address(this));

            // swap EUL for underlying
            EUL.safeApprove(address(_router), amountIn);
            _router.exactInput(
                ISwapRouter.ExactInputParams({
                    path: path,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: amountIn,
                    amountOutMinimum: minAmountOut
                })
            );

            rewards[0] = underlyingToken.balanceOf(address(this));
        }
    }

    /// @notice redeem the rewards
    /// @return rewards amount of reward that is deposited to the ` strategy`
    ///         rewards[0] : mintedUnderlyings
    function redeemRewards(bytes calldata data)
        public
        override
        onlyIdleCDO
        returns (uint256[] memory rewards)
    {
        rewards = super.redeemRewards(data);
        _setMintPrice();
    }

    function _withdraw(uint256 _amountToWithdraw, address _destination)
        internal
        override
        returns (uint256 amountWithdrawn)
    {
        IERC20Detailed _underlyingToken = underlyingToken;
        IEToken _eToken = eToken;
        uint256 balanceBefore = _underlyingToken.balanceOf(address(this));
        uint256 amountToBurn = getSelfAmountToBurn(targetHealthScore, _amountToWithdraw);

        if (amountToBurn != 0) {
            // Pay off dToken liability with eTokens ("self-repay")
            _eToken.burn(SUB_ACCOUNT_ID, amountToBurn);
        }

        uint256 balanceInUnderlying = _eToken.balanceOfUnderlying(address(this));
        if (_amountToWithdraw > balanceInUnderlying) {
            _amountToWithdraw = balanceInUnderlying;
        }
        // withdraw underlying
        _eToken.withdraw(SUB_ACCOUNT_ID, _amountToWithdraw);

        amountWithdrawn = _underlyingToken.balanceOf(address(this)) - balanceBefore;
        _underlyingToken.safeTransfer(_destination, amountWithdrawn);
    }

    /// @dev Pay off dToken liability with eTokens ("self-repay") and depost the withdrawn underlying
    function deleverageManually(uint256 _amount, uint256 _targetHealthScore) external {
        require(msg.sender == owner() || msg.sender == rebalancer, '!AUTH');

        IEToken _eToken = eToken;
        if (_amount == 0) {
            // deleverage all
            _amount = dToken.balanceOf(address(this));
        }
        _eToken.burn(SUB_ACCOUNT_ID, _amount);
        _eToken.deposit(SUB_ACCOUNT_ID, underlyingToken.balanceOf(address(this)));
        targetHealthScore = _targetHealthScore;
    }

    function setTargetHealthScore(uint256 _healthScore) external {
        require(msg.sender == owner() || msg.sender == rebalancer, '!AUTH');
        require(_healthScore > EXP_SCALE || _healthScore == 0, "strat/invalid-target-hs");

        uint256 _oldTargetHealthScore = targetHealthScore;
        targetHealthScore = _healthScore;

        emit UpdateTargetHealthScore(_oldTargetHealthScore, _healthScore);
    }

    function setEulDistributor(address _eulDistributor) external onlyOwner {
        address oldEulDistributor = address(eulDistributor);
        eulDistributor = IEulDistributor(_eulDistributor);

        emit UpdateEulDistributor(oldEulDistributor, _eulDistributor);
    }

    function setRebalancer(address _rebalancer) external onlyOwner {
        require(_rebalancer != address(0), '0');
        rebalancer = _rebalancer;
    }

    function setSwapRouter(address _router) external onlyOwner {
        address oldRouter = address(router);
        router = ISwapRouter(_router);

        emit UpdateSwapRouter(oldRouter, _router);
    }

    function setRouterPath(bytes calldata _path) external onlyOwner {
        bytes memory oldPath = path;
        path = _path;

        emit UpdateRouterPath(oldPath, _path);
    }

    /// @notice For example
    /// - deposit $1000 RBN
    /// - mint $10,00 RBN
    /// in the end this contract holds $11000 RBN deposits and $10,000 RBN debts.
    /// will have a health score of exactly 1.
    /// Changes in price of RBN will have no effect on a user's health score,
    /// because their collateral deposits rise and fall at the same rate as their debts.
    /// So, is a user at risk of liquidation? This depends on how much more interest they are
    /// paying on their debts than they are earning on their deposits.
    /// @dev
    /// Euler fi defines health score a little differently
    /// Health score = risk adjusted collateral / risk adjusted liabilities
    /// Collateral amount * collateral factor = risk adjusted collateral
    /// Borrow amount / borrow factor = risk adjusted liabilities
    /// ref: https://github.com/euler-xyz/euler-contracts/blob/0fade57d9ede7b010f943fa8ad3ad74b9c30e283/contracts/modules/RiskManager.sol#L314
    /// @param _targetHealthScore  health score 1.0 == 1e18
    /// @param _amount _amount to deposit or withdraw. _amount greater than zero means `deposit`. _amount less than zero means `withdraw`
    function _getSelfAmount(uint256 _targetHealthScore, int256 _amount) internal view returns (uint256 selfAmount) {
        // target health score has 1e18 decimals.
        require(_targetHealthScore > EXP_SCALE || _targetHealthScore == 0, "strat/invalid-target-hs");
        if (_targetHealthScore == 0) {
            // no leverage
            return 0;
        }

        // Calculate amount to `mint` or `burn` to maintain a target health score.
        // Let `h` denote the target health score we want to maintain.
        // Let `ac` denote the balance of collateral and `sc` denote the self-collateralized balance of collateral.
        // Let `fc` denote the collateral factor of a asset,
        // `fb` denote its borrow factor and `fs` denote the collateral factor of a self-collateralized asset (called self-collateralized factor).

        // Let `x` denote its newly added collateral by user and `xs` denote its newly added collateral with recursive borrowing/repay (`eToken.mint()` or `eToken.burn()`).
        // Heath score is:
        // h = {fc[ac + x + xs - (sc + xs)/fs] + sc + xs} / (sc + xs)

        // Resolve the equation for xs.
        // xs = {fc(ac + x) - (h + fc/fs - 1)sc} / {h + fc(1/fs -1) - 1}
        // Here, we define term1 := fc(ac + x) and term2 := (h + fc/fs - 1)sc.

        uint256 debtInUnderlying = dToken.balanceOf(address(this)); // liability in underlying `sc`

        uint256 cf; // underlying collateral factor
        // collateral balance in underlying
        // this is `a` which is the summation of usual collateral and self-borrowed collateral
        uint256 balanceInUnderlying;
        {
            // avoid stack too deep error
            IMarkets.AssetConfig memory config = EULER_MARKETS.underlyingToAssetConfig(token);
            cf = config.collateralFactor;
            balanceInUnderlying = IEToken(config.eTokenAddress).balanceOfUnderlying(address(this));
        }

        {
            int256 collateral = int256(balanceInUnderlying) + _amount; // `ac` + `x`
            require(collateral > 0, "strat/exceed-balance");

            uint256 term1 = ((cf * uint256(collateral))) / CONFIG_FACTOR_SCALE; // in underlying terms
            // health score must be normalized
            uint256 term2 = (((_targetHealthScore * ONE_FACTOR_SCALE) /
                EXP_SCALE +
                (cf * ONE_FACTOR_SCALE) /
                SELF_COLLATERAL_FACTOR -
                ONE_FACTOR_SCALE) * debtInUnderlying) / ONE_FACTOR_SCALE; // in underlying terms

            uint256 denominator = (_targetHealthScore * ONE_FACTOR_SCALE) /
                EXP_SCALE +
                (cf * ONE_FACTOR_SCALE) /
                SELF_COLLATERAL_FACTOR -
                (cf * ONE_FACTOR_SCALE) /
                CONFIG_FACTOR_SCALE -
                ONE_FACTOR_SCALE; // in ONE_FACTOR_SCALE terms

            // `selfAmount` := abs(xs) = abs(term1 - term2) / denominator.
            // when depositing, xs is greater than zero.
            // when withdrawing, xs is less than current debt and less than zero.
            if (term1 >= term2) {
                // when withdrawing, maximum value of xs is zero.
                if (_amount <= 0) return 0;
                selfAmount = ((term1 - term2) * ONE_FACTOR_SCALE) / denominator;
            } else {
                // when depositing, minimum value of xs is zero.
                if (_amount >= 0) return 0;
                selfAmount = ((term2 - term1) * ONE_FACTOR_SCALE) / denominator;
                if (selfAmount > debtInUnderlying) {
                    // maximum repayable value is current debt value.
                    selfAmount = debtInUnderlying;
                }
            }
        }
    }

    function getSelfAmountToMint(uint256 _targetHealthScore, uint256 _amount) public view returns (uint256) {
        return _getSelfAmount(_targetHealthScore, int256(_amount));
    }

    function getSelfAmountToBurn(uint256 _targetHealthScore, uint256 _amount) public view returns (uint256) {
        return _getSelfAmount(_targetHealthScore, -int256(_amount));
    }

    function getCurrentHealthScore() public view returns (uint256) {
        IRiskManager.LiquidityStatus memory status = EULER_EXEC.liquidity(address(this));
        // approximately equal to `eToken.balanceOfUnderlying(address(this))` divide by ` dToken.balanceOf(address(this))`
        if (status.liabilityValue == 0) {
            return 0;
        }
        return (status.collateralValue * EXP_SCALE) / status.liabilityValue;
    }

    function getCurrentLeverage() public view returns (uint256) {
        uint256 balanceInUnderlying = eToken.balanceOfUnderlying(address(this));
        uint256 debtInUnderlying = dToken.balanceOf(address(this));
        uint256 principal = balanceInUnderlying - debtInUnderlying;
        if (principal == 0) {
            return EXP_SCALE;
        }
        // leverage = debt / principal
        return debtInUnderlying * oneToken / principal;
    }

    /// @notice this should be empty as rewards are sold directly in the strategy and 
    /// `getRewardTokens` is used only in IdleCDO for selling rewards
    function getRewardTokens() external pure override returns (address[] memory) {
    }
}