// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../../interfaces/euler/IEToken.sol";
import "../../interfaces/euler/IDToken.sol";
import "../../interfaces/euler/IMarkets.sol";
import "../../interfaces/euler/IEulerGeneralView.sol";
import "../../interfaces/IStakingRewards.sol";
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
// One line change is needed for solidity 0.8.X to make it compile check here 
// https://ethereum.stackexchange.com/questions/96642/unary-operator-minus-cannot-be-applied-to-type-uint256
import '@uniswap/v3-core/contracts/libraries/FullMath.sol';

import "../BaseStrategy.sol";

/// @author Euler Finance + Idle Finance
/// @title IdleEulerStakingStrategy
/// @notice IIdleCDOStrategy to deploy funds in Euler Finance and then stake eToken in Euler staking contracts
/// @dev This contract should not have any funds at the end of each tx.
/// The contract is upgradable, to add storage slots, add them after the last `###### End of storage VXX`
contract IdleEulerStakingStrategy is BaseStrategy {
    using SafeERC20Upgradeable for IERC20Detailed;

    /// ###### End of storage BaseStrategy

    /// @notice Euler account id
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant UNI_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    uint256 internal constant SUB_ACCOUNT_ID = 0;
    /// @notice Euler Governance Token
    IERC20Detailed internal constant EUL = IERC20Detailed(0xd9Fcd98c322942075A5C3860693e9f4f03AAE07b);
    /// @notice Euler markets contract address
    IMarkets internal constant EULER_MARKETS = IMarkets(0x3520d5a913427E6F0D6A83E07ccD4A4da316e4d3);
    /// @notice Euler general view contract address
    IEulerGeneralView internal constant EULER_GENERAL_VIEW =
        IEulerGeneralView(0xACC25c4d40651676FEEd43a3467F3169e3E68e42);

    IEToken public eToken;
    IStakingRewards public stakingRewards;

    /// ###### End of storage IdleEulerStakingStrategy

    // ###################
    // Initializer
    // ###################

    /// @notice can only be called once
    /// @dev Initialize the upgradable contract
    /// @param _eToken address of the eToken
    /// @param _underlyingToken address of the underlying token
    /// @param _eulerMain Euler main contract address
    /// @param _stakingRewards stakingRewards contract address
    /// @param _owner owner address
    function initialize(
        address _eToken,
        address _underlyingToken,
        address _eulerMain,
        address _stakingRewards,
        address _owner
    ) public virtual initializer {
        _initialize(
            string(abi.encodePacked("Idle Euler ", IERC20Detailed(_eToken).name(), " Staking Strategy")),
            string(abi.encodePacked("idleEulStk_", IERC20Detailed(_eToken).symbol())),
            _underlyingToken,
            _owner
        );
        eToken = IEToken(_eToken);
        stakingRewards = IStakingRewards(_stakingRewards);

        // approve Euler protocol uint256 max for deposits
        underlyingToken.safeApprove(_eulerMain, type(uint256).max);
        // approve stakingRewards contract uint256 max for staking
        IERC20Detailed(_eToken).safeApprove(_stakingRewards, type(uint256).max);
    }

    // ###################
    // Public methods
    // ###################

    /// @dev msg.sender should approve this contract first to spend `_amount` of `token`
    /// @param _amount amount of `token` to deposit
    /// @return shares strategyTokens minted
    function deposit(uint256 _amount) external virtual override onlyIdleCDO returns (uint256 shares) {
        if (_amount != 0) {
            IEToken _eToken = eToken;
            IStakingRewards _stakingRewards = stakingRewards;
            uint256 eTokenBalanceBefore = _eToken.balanceOf(address(this));
            // Send tokens to the strategy
            underlyingToken.safeTransferFrom(msg.sender, address(this), _amount);

            _eToken.deposit(SUB_ACCOUNT_ID, _amount);

            // Mint shares 1:1 ratio
            shares = _eToken.balanceOf(address(this)) - eTokenBalanceBefore;
            if (address(_stakingRewards) != address(0)) {
                _stakingRewards.stake(shares);
            }

            _mint(msg.sender, shares);
        }
    }

    function redeemRewards(bytes calldata data)
        public
        override
        onlyIdleCDO
        nonReentrant
        returns (uint256[] memory rewards)
    {
        rewards = _redeemRewards(data);
    }

    /// @dev msg.sender should approve this contract first to spend `_amount` of `strategyToken`
    /// @param _shares amount of strategyTokens to redeem
    /// @return amountRedeemed  amount of underlyings redeemed
    function redeem(uint256 _shares) external override onlyIdleCDO returns (uint256 amountRedeemed) {
        if (_shares != 0) {
            _burn(msg.sender, _shares);
            // Withdraw amount needed
            amountRedeemed = _withdraw((_shares * price()) / EXP_SCALE, msg.sender);
        }
    }

    /// @notice Redeem Tokens
    /// @param _amount amount of underlying tokens to redeem
    /// @return amountRedeemed Amount of underlying tokens received
    function redeemUnderlying(uint256 _amount) external override onlyIdleCDO returns (uint256 amountRedeemed) {
        uint256 _shares = (_amount * EXP_SCALE) / price();
        if (_shares != 0) {
            _burn(msg.sender, _shares);
            // Withdraw amount needed
            amountRedeemed = _withdraw(_amount, msg.sender);
        }
    }

    // ###################
    // Internal
    // ###################

    /// @dev Unused but needed for BaseStrategy
    function _deposit(uint256 _amount) internal override returns (uint256 amountUsed) {}

    /// @param _amountToWithdraw in underlyings
    /// @param _destination address where to send underlyings
    /// @return amountWithdrawn returns the amount withdrawn
    function _withdraw(uint256 _amountToWithdraw, address _destination)
        internal
        virtual
        override
        returns (uint256 amountWithdrawn)
    {
        IEToken _eToken = eToken;
        IERC20Detailed _underlyingToken = underlyingToken;
        IStakingRewards _stakingRewards = stakingRewards;

        if (address(_stakingRewards) != address(0)) {
            // Unstake from StakingRewards
            _stakingRewards.withdraw(_eToken.convertUnderlyingToBalance(_amountToWithdraw));
        }

        uint256 underlyingsInEuler = _eToken.balanceOfUnderlying(address(this));
        if (_amountToWithdraw > underlyingsInEuler) {
            _amountToWithdraw = underlyingsInEuler;
        }

        // Withdraw from Euler
        uint256 underlyingBalanceBefore = _underlyingToken.balanceOf(address(this));
        _eToken.withdraw(SUB_ACCOUNT_ID, _amountToWithdraw);
        amountWithdrawn = _underlyingToken.balanceOf(address(this)) - underlyingBalanceBefore;
        // Send tokens to the destination
        _underlyingToken.safeTransfer(_destination, amountWithdrawn);
    }

    /// @return rewards rewards[0] : rewards redeemed
    function _redeemRewards(bytes calldata) internal override returns (uint256[] memory rewards) {
        IStakingRewards _stakingRewards = stakingRewards;
        if (address(_stakingRewards) != address(0)) {
            // Get rewards from StakingRewards contract
            _stakingRewards.getReward();
        }
        // transfer rewards to the IdleCDO contract
        rewards = new uint256[](1);
        rewards[0] = EUL.balanceOf(address(this));
        EUL.safeTransfer(idleCDO, rewards[0]);
    }

    // ###################
    // Views
    // ###################

    /// @return net price in underlyings of 1 strategyToken
    function price() public view virtual override returns (uint256) {
        IEToken _eToken = eToken;
        uint256 eTokenDecimals = _eToken.decimals();
        // return price of 1 eToken in underlying
        return _eToken.convertBalanceToUnderlying(10**eTokenDecimals);
    }

    /// @dev Returns supply apr for providing liquidity minus reserveFee
    /// @return apr net apr (fees should already be excluded)
    function getApr() external view override returns (uint256 apr) {
        // Use the markets module:
        address _token = token;
        IMarkets markets = IMarkets(EULER_MARKETS);
        IDToken dToken = IDToken(markets.underlyingToDToken(_token));
        uint256 borrowSPY = uint256(int256(markets.interestRate(_token)));
        uint256 totalBorrows = dToken.totalSupply();
        uint256 totalBalancesUnderlying = eToken.totalSupplyUnderlying();
        uint32 reserveFee = markets.reserveFee(_token);
        // (borrowAPY, supplyAPY)
        (, apr) = IEulerGeneralView(EULER_GENERAL_VIEW).computeAPYs(
            borrowSPY,
            totalBorrows,
            totalBalancesUnderlying,
            reserveFee
        );
        // apr is eg 0.024300334 * 1e27 for 2.43% apr
        // while the method needs to return the value in the format 2.43 * 1e18
        // so we do apr / 1e9 * 100 -> apr / 1e7
        // then we add the staking apr
        apr = apr / 1e7 + _getStakingApr();
    }

    /// @dev Calculates staking apr
    /// @return _apr 
    function _getStakingApr() internal view returns (uint256 _apr) {
        IStakingRewards _stakingRewards = stakingRewards;
        IERC20Detailed _underlying = underlyingToken;
        uint256 _tokenDec = tokenDecimals;

        // get quote of 1 EUL in underlyings, 1% fee pool for EUL. 
        uint256 eulPrice = _getPriceUniV3(address(EUL), WETH, uint24(10000));
        if (address(_underlying) != WETH) {
            // 0.05% fee pool. This returns a price with tokenDecimals
            uint256 wethToUnderlying = _getPriceUniV3(WETH, address(_underlying), uint24(500));
            eulPrice = eulPrice * wethToUnderlying / EXP_SCALE; // in underlyings
        }

        // USDC as example (6 decimals)
        // underlyingsPerPoolYear = EULPerSec * EULPrice * 365 days / 1e18 => 1e6
        uint256 underlyingsPerPoolYear = _stakingRewards.rewardRate() * eulPrice * 365 days / EXP_SCALE;
        uint256 eTokensStaked = eToken.balanceOf(address(_stakingRewards));
        // underlyings_per_year_per_token  = underlyings_per_year_whole_pool * 1e18 / (eTokensStaked * eTokenPrice / 1e6) => 1e6 
        uint256 underlyingsPerTokenYear = underlyingsPerPoolYear * EXP_SCALE / (eTokensStaked * price() / 10**(_tokenDec));
        // we normalize underlyingsPerTokenYear and multiply by 100 to get the apr % with 18 decimals
        _apr = underlyingsPerTokenYear * 10**(18-_tokenDec) * 100;
    }

    /// @notice this price is not safe from flash loan attacks, but it is used only for showing the apr on the UI
    function _getPriceUniV3(address tokenIn, address tokenOut, uint24 _fee)
        internal
        view
        returns (uint256 _price)
    {
        IUniswapV3Pool pool = IUniswapV3Pool(IUniswapV3Factory(UNI_V3_FACTORY).getPool(tokenIn, tokenOut, _fee));
        (uint160 sqrtPriceX96,,,,,,) =  pool.slot0();
        uint256 _scaledPrice = uint256(sqrtPriceX96) * uint256(sqrtPriceX96);
        if (tokenOut == pool.token0()) {
            // token1Price -> ratio of token0 over token1
            _price = FullMath.mulDiv(2**192, EXP_SCALE, _scaledPrice);
        } else {
            // token0Price -> ratio of token1 over token0 
            _price = FullMath.mulDiv(EXP_SCALE, _scaledPrice, 2**192);
        }
    }

    /// @return tokens array of reward token addresses
    function getRewardTokens() external pure override returns (address[] memory tokens) {
        tokens = new address[](1);
        tokens[0] = address(EUL);
    }

    // ###################
    // Protected
    // ###################

    ///@notice Claim rewards and withdraw all from StakingRewards contract
    function exitStaking() external onlyOwner {
        stakingRewards.exit();
    }

    function setStakingRewards(address _stakingRewards) external onlyOwner {
        stakingRewards = IStakingRewards(_stakingRewards);
    }
}