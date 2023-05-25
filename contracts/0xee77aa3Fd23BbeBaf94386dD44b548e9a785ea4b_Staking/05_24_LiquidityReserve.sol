// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../libraries/Ownable.sol";
import "../interfaces/IStaking.sol";

contract LiquidityReserve is ERC20Permit, Ownable {
    using SafeERC20 for IERC20;

    event FeeChanged(uint256 fee);

    address public stakingToken; // staking token address
    address public rewardToken; // reward token address
    address public stakingContract; // staking contract address
    uint256 public fee; // fee for instant unstaking
    address public initializer; // LiquidityReserve initializer
    uint256 public constant MINIMUM_LIQUIDITY = 10**15; // lock .001 stakingTokens for initial liquidity
    uint256 public constant BASIS_POINTS = 10000; // 100% in basis points

    // check if sender is the stakingContract
    modifier onlyStakingContract() {
        require(msg.sender == stakingContract, "Not staking contract");
        _;
    }

    constructor(address _stakingToken)
        ERC20("Liquidity Reserve FOX", "lrFOX")
        ERC20Permit("Liquidity Reserve FOX")
    {
        // verify address isn't 0x0
        require(_stakingToken != address(0), "Invalid address");
        initializer = msg.sender;
        stakingToken = _stakingToken;
    }

    /**
        @notice initialize by setting stakingContract & setting initial liquidity
        @param _stakingContract address
     */
    function initialize(address _stakingContract, address _rewardToken)
        external
    {
        // check if initializer is msg.sender that was set in constructor
        require(msg.sender == initializer, "Must be called from initializer");
        initializer = address(0);

        uint256 stakingTokenBalance = IERC20(stakingToken).balanceOf(
            msg.sender
        );

        // verify addresses aren't 0x0
        require(
            _stakingContract != address(0) && _rewardToken != address(0),
            "Invalid address"
        );

        // require address has minimum liquidity
        require(
            stakingTokenBalance >= MINIMUM_LIQUIDITY,
            "Not enough staking tokens"
        );
        stakingContract = _stakingContract;
        rewardToken = _rewardToken;

        // permanently lock the first MINIMUM_LIQUIDITY of lrTokens
        IERC20(stakingToken).safeTransferFrom(
            msg.sender,
            address(this),
            MINIMUM_LIQUIDITY
        );
        _mint(address(this), MINIMUM_LIQUIDITY);

        IERC20(rewardToken).approve(stakingContract, type(uint256).max);
    }

    /**
        @notice sets Fee (in basis points eg. 100 bps = 1%) for instant unstaking
        @param _fee uint - fee in basis points
     */
    function setFee(uint256 _fee) external onlyOwner {
        // check range before setting fee
        require(_fee <= BASIS_POINTS, "Out of range");
        fee = _fee;

        emit FeeChanged(_fee);
    }

    /**
        @notice addLiquidity for the stakingToken and receive lrToken in exchange
        @param _amount uint - amount of staking tokens to add
     */
    function addLiquidity(uint256 _amount) external {
        uint256 stakingTokenBalance = IERC20(stakingToken).balanceOf(
            address(this)
        );
        uint256 rewardTokenBalance = IERC20(rewardToken).balanceOf(
            address(this)
        );
        uint256 lrFoxSupply = totalSupply();
        uint256 coolDownAmount = IStaking(stakingContract)
            .coolDownInfo(address(this))
            .amount;
        uint256 totalLockedValue = stakingTokenBalance +
            rewardTokenBalance +
            coolDownAmount;

        uint256 amountToMint = (_amount * lrFoxSupply) / totalLockedValue;
        IERC20(stakingToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        _mint(msg.sender, amountToMint);
    }

    /**
        @notice calculate current lrToken withdraw value
        @param _amount uint - amount of tokens that will be withdrawn
        @return uint - converted amount of staking tokens to withdraw from lr tokens
     */
    function _calculateReserveTokenValue(uint256 _amount)
        internal
        view
        returns (uint256)
    {
        uint256 lrFoxSupply = totalSupply();
        uint256 stakingTokenBalance = IERC20(stakingToken).balanceOf(
            address(this)
        );
        uint256 rewardTokenBalance = IERC20(rewardToken).balanceOf(
            address(this)
        );
        uint256 coolDownAmount = IStaking(stakingContract)
            .coolDownInfo(address(this))
            .amount;
        uint256 totalLockedValue = stakingTokenBalance +
            rewardTokenBalance +
            coolDownAmount;
        uint256 convertedAmount = (_amount * totalLockedValue) / lrFoxSupply;

        return convertedAmount;
    }

    /**
        @notice removeLiquidity by swapping your lrToken for stakingTokens
        @param _amount uint - amount of tokens to remove from liquidity reserve
     */
    function removeLiquidity(uint256 _amount) external {
        // check balance before removing liquidity
        require(_amount <= balanceOf(msg.sender), "Not enough lr tokens");
        // claim the stakingToken from previous unstakes
        IStaking(stakingContract).claimWithdraw(address(this));

        uint256 amountToWithdraw = _calculateReserveTokenValue(_amount);

        // verify that we have enough stakingTokens
        require(
            IERC20(stakingToken).balanceOf(address(this)) >= amountToWithdraw,
            "Not enough funds"
        );

        _burn(msg.sender, _amount);
        IERC20(stakingToken).safeTransfer(msg.sender, amountToWithdraw);
    }

    /**
        @notice allow instant unstake their stakingToken for a fee paid to the liquidity providers
        @param _amount uint - amount of tokens to instantly unstake
        @param _recipient address - address to send staking tokens to
     */
    function instantUnstake(uint256 _amount, address _recipient)
        external
        onlyStakingContract
    {
        // claim the stakingToken from previous unstakes
        IStaking(stakingContract).claimWithdraw(address(this));

        uint256 amountMinusFee = _amount - ((_amount * fee) / BASIS_POINTS);

        IERC20(rewardToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        IERC20(stakingToken).safeTransfer(_recipient, amountMinusFee);
        unstakeAllRewardTokens();
    }

    /**
        @notice find balance of reward tokens in contract and unstake them from staking contract
     */
    function unstakeAllRewardTokens() public {
        uint256 amount = IERC20(rewardToken).balanceOf(address(this));
        if (amount > 0) IStaking(stakingContract).unstake(amount, false);
    }
}