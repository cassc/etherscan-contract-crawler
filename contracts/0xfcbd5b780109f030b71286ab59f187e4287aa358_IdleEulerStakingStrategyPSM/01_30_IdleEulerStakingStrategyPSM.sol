// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../../interfaces/IPSM.sol";
import "./IdleEulerStakingStrategy.sol";

/// @author Idle Finance
/// @title IdleEulerStakingStrategyPSM
/// @notice IIdleCDOStrategy to deploy funds in Euler Finance. DAI are converted to USDC using MakerDAO PSM.
contract IdleEulerStakingStrategyPSM is IdleEulerStakingStrategy {
    using SafeERC20Upgradeable for IERC20Detailed;

    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    IPSM public constant DAIPSM = IPSM(0x89B78CfA322F6C5dE0aBcEecab66Aee45393cC5A);
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
    ) public virtual override initializer {
        super.initialize(_eToken, _underlyingToken, _eulerMain, _stakingRewards, _owner);

        // approve psm and helper to spend DAI and USDC
        IERC20Detailed(DAI).safeApprove(address(DAIPSM), type(uint256).max);
        // underlying here is USDC
        underlyingToken.safeApprove(address(DAIPSM.gemJoin()), type(uint256).max);
    }

    /// @notice return the price from the strategy token contract
    /// @return _price
    function price() public view override returns (uint256 _price) {
        // 18 decimals, ie DAI decimals
        _price = super.price() * 10**12; // 12 => 18 - tokenDecimals which for usdc is 6
    }

     /// @notice Deposit the underlying token to vault
    /// @param _amount number of tokens to deposit
    /// @return shares minted number of reward tokens minted
    function deposit(uint256 _amount)
        external
        override
        onlyIdleCDO
        returns (uint256 shares)
    {
        if (_amount > 0) {
            IERC20Detailed(DAI).safeTransferFrom(
                msg.sender,
                address(this),
                _amount
            );
            // convert amount of DAI in USDC, 1-to-1
            // Maker expect amount to be in `gem` (ie USDC in this case)
            _amount = _amount / 10**12; // 12 => 18 - tokenDecimals which for usdc is 6
            sellDAI(_amount);
            IEToken _eToken = eToken;
            IStakingRewards _stakingRewards = stakingRewards;
            uint256 eTokenBalanceBefore = _eToken.balanceOf(address(this));
            // the amount passed here is in USDC (6 decimals)
            _eToken.deposit(SUB_ACCOUNT_ID, _amount);
            shares = _eToken.balanceOf(address(this)) - eTokenBalanceBefore;
            // stake in euler
            if (address(_stakingRewards) != address(0)) {
                _stakingRewards.stake(shares);
            }
            // Mint shares 1:1 ratio, shares have 18 decimals like eUSDC
            _mint(msg.sender, shares);
        }
    }

    /// @param _amountToWithdraw in underlyings (DAI)
    /// @param _destination address where to send underlyings
    /// @return amountWithdrawn returns the amount withdrawn
    function _withdraw(uint256 _amountToWithdraw, address _destination)
        internal
        override
        returns (uint256 amountWithdrawn)
    {
        IEToken _eToken = eToken;
        IERC20Detailed _underlyingToken = underlyingToken;
        IStakingRewards _stakingRewards = stakingRewards;

        // _amountToWithdraw has 18 decimals and we need to pass an amount in underlyings (USDC) so 6 decimals
        _amountToWithdraw = _amountToWithdraw / 10**12;

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

        // Modified from here wrt the original _withdraw
        // buy DAI with USDC redeemed via PSM, Maker expect 18 decimals here
        buyDAI(amountWithdrawn);
        // Send DAI to the destination
        IERC20Detailed dai = IERC20Detailed(DAI);
        amountWithdrawn = dai.balanceOf(address(this));
        dai.safeTransfer(_destination, amountWithdrawn);
    }

    function sellDAI(uint256 _amount) internal {
        // 1inch fallback?
        require(DAIPSM.tin() == 0 && DAIPSM.tout() == 0, 'FEE!0');
        DAIPSM.buyGem(address(this), _amount);
    }

    function buyDAI(uint256 _amount) internal {
        // 1inch fallback?
        require(DAIPSM.tin() == 0 && DAIPSM.tout() == 0, 'FEE!0');
        DAIPSM.sellGem(address(this), _amount);
    }
}