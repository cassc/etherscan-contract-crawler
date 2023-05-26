// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";
import "@rari-capital/solmate/src/auth/Owned.sol";
import "./rocketPool/RocketStorageInterface.sol";
import "./rocketPool/RocketDepositPoolInterface.sol";
import "./rocketPool/RocketTokenRETHInterface.sol";
import "./libraries/FullMath.sol";

contract StakingContract is Owned, ReentrancyGuard {
    address private constant DEAD_ADDRESS =
        0x000000000000000000000000000000000000dEaD;
    address public immutable POS32;
    address public protocolWallet;

    RocketStorageInterface public immutable rocketStorage;

    uint256 public endTime;
    uint256 public lastRewardTime;
    uint256 public rewardRemaining;
    uint256 public totalStaked;
    uint256 public tokenStaked;
    uint256 public tokenBurnBIPS;

    uint256 public eTH2TokenNumerator;
    uint256 public eTH2TokenDenominator;

    // Initial value of rewardPerLiquidity can be arbitrarily set to a non-zero value.
    uint256 public rewardPerLiquidity = type(uint256).max / 2;

    /// @dev rewardPerLiquidityLast[user]
    mapping(address => uint256) public rewardPerLiquidityLast;

    /// @dev userStakes[user]
    mapping(address => UserStake) public userStakes;

    struct UserStake {
        uint128 liquidity;
        uint128 tokenStaked;
    }

    error ZeroDenominator();
    error InvalidTimeFrame();
    error PercentageTooHigh();
    error InsufficientRethMinted();
    error InsufficientStakedAmount();

    event IncentiveUpdated(
        uint256 newStartTime,
        uint256 newEndTime,
        uint256 changeAmount
    );
    event Stake(
        address indexed user,
        uint256 amountETH,
        uint256 amountToken,
        uint256 amountTokenLeft
    );
    event Unstake(address indexed user, uint256 amountETH, uint256 amountToken);
    event Claim(address indexed user, uint256 amountETH);
    event ETH2TokenRaioUpdated(uint256 numerator, uint256 denominator);
    event BurnBIPSUpdated(uint256 newBIPS);
    event ProtocolWalletUpdated(address newAddress);

    constructor(
        address _pos32,
        address _rocketStorageAddress,
        address _protocolWallet,
        uint256 _eTH2TokenNumerator,
        uint256 _eTH2TokenDenominator,
        uint256 _tokenBurnBIPS
    ) Owned(msg.sender) {
        POS32 = _pos32;
        rocketStorage = RocketStorageInterface(_rocketStorageAddress);
        _updateProtocolWallet(_protocolWallet);
        _updateTokenBurnBIPS(_tokenBurnBIPS);
        _updateETH2TokenRatio(_eTH2TokenNumerator, _eTH2TokenDenominator);
    }

    function updateETH2TokenRatio(
        uint256 numerator,
        uint256 denominator
    ) external onlyOwner {
        _updateETH2TokenRatio(numerator, denominator);
    }

    function updateTokenBurnBIPS(uint256 newBIPS) external onlyOwner {
        _updateTokenBurnBIPS(newBIPS);
    }

    function updateProtocolWallet(address newAddress) external onlyOwner {
        _updateProtocolWallet(newAddress);
    }

    function updateIncentive(
        uint256 newStartTime,
        uint256 newEndTime
    ) external payable onlyOwner nonReentrant {
        _accrueRewards();

        if (newStartTime != 0) {
            if (newStartTime < block.timestamp) newStartTime = block.timestamp;
            lastRewardTime = newStartTime;
        }

        if (newEndTime != 0) {
            if (newEndTime < block.timestamp) newEndTime = block.timestamp;
            endTime = newEndTime;
        }

        if (lastRewardTime >= endTime) revert InvalidTimeFrame();

        if (msg.value != 0) {
            rewardRemaining += msg.value;
        }

        emit IncentiveUpdated(lastRewardTime, endTime, msg.value);
    }

    function stake(bool transferExistingRewards) external payable nonReentrant {
        // Get both ETH, token into the contract
        uint256 amountETH = msg.value;
        uint256 amountToken = calculateToken(amountETH);
        _receivePOS32From(msg.sender, amountToken);

        // Calculate and burn required amount of token
        uint256 amountTokenBurn = calculateTokenBurn(amountToken);
        uint256 amountTokenLeft = amountToken - amountTokenBurn;
        if (amountTokenBurn != 0) {
            _burnPOS32(amountTokenBurn);
        }

        // Fetch user stake info
        UserStake storage userStake = userStakes[msg.sender];
        uint128 previousLiquidity = userStake.liquidity;

        uint256 amountETHNet = _depositToRocketPool(amountETH);

        // Update user stake info
        userStake.liquidity += uint128(amountETHNet);
        userStake.tokenStaked += uint128(amountTokenLeft);

        // Accrue and handle rewards
        uint256 rewards;
        _accrueRewards();
        if (transferExistingRewards) {
            rewards = _claimReward(previousLiquidity);
        } else {
            _saveReward(previousLiquidity, userStake.liquidity);
        }

        // Update global trackers
        totalStaked += amountETHNet;
        tokenStaked += amountTokenLeft;

        _sendETH(msg.sender, rewards);

        emit Stake(msg.sender, amountETHNet, amountToken, amountTokenLeft);
    }

    function unstake(
        uint128 amountETH,
        bool transferExistingRewards
    ) external nonReentrant {
        // Fetch user stake info
        UserStake storage userStake = userStakes[msg.sender];

        // Check limits
        uint128 previousLiquidity = userStake.liquidity;
        if (amountETH > previousLiquidity) revert InsufficientStakedAmount();

        // Calculate token to return
        uint256 amountToken = FullMath.mulDiv(
            userStake.tokenStaked,
            amountETH,
            previousLiquidity
        );

        // Update user stake info
        userStake.liquidity -= amountETH;
        userStake.tokenStaked -= uint128(amountToken);

        // Accrue and handle rewards
        uint256 rewards;
        _accrueRewards();
        if (transferExistingRewards || userStake.liquidity == 0) {
            rewards = _claimReward(previousLiquidity);
        } else {
            _saveReward(previousLiquidity, userStake.liquidity);
        }

        address rocketTokenRETHAddress = rocketStorage.getAddress(
            keccak256(abi.encodePacked("contract.address", "rocketTokenRETH"))
        );

        uint256 equivalentReth = (RocketTokenRETHInterface(
            rocketTokenRETHAddress
        ).balanceOf(address(this)) * amountETH) / totalStaked;
        uint256 principalReth = RocketTokenRETHInterface(rocketTokenRETHAddress)
            .getRethValue(amountETH);

        // Update global trackers
        totalStaked -= amountETH;
        tokenStaked -= amountToken;

        // Distribute principal
        _sendRethTo(rocketTokenRETHAddress, msg.sender, principalReth);
        _sendRethTo(
            rocketTokenRETHAddress,
            protocolWallet,
            equivalentReth - principalReth
        );
        _sendPOS32To(msg.sender, amountToken);

        // Distribute rewards
        _sendETH(msg.sender, rewards);

        emit Unstake(msg.sender, amountETH, amountToken);
    }

    function accrueRewards() external {
        _accrueRewards();
    }

    function claim() external nonReentrant {
        _accrueRewards();
        uint256 rewards = _claimReward(userStakes[msg.sender].liquidity);
        _sendETH(msg.sender, rewards);
    }

    function getAPR() external view returns (uint256) {
        if (endTime < block.timestamp || totalStaked == 0) {
            return 0;
        }

        uint256 timeRemaining = endTime - block.timestamp;
        uint256 secondsInAYear = 31_536_000;
        return
            (rewardRemaining * secondsInAYear * 10_000) /
            (timeRemaining * totalStaked);
    }

    function pendingRewards(address user) external view returns (uint256) {
        return _calculateReward(user, userStakes[user].liquidity);
    }

    function calculateToken(uint256 amountETH) public view returns (uint256) {
        return (amountETH * eTH2TokenNumerator) / eTH2TokenDenominator;
    }

    function calculateTokenBurn(
        uint256 amountToken
    ) public view returns (uint256) {
        return (amountToken * tokenBurnBIPS) / 10_000;
    }

    // This returns the net eth value deposited at RocketPool (net of their fees)
    function _depositToRocketPool(
        uint256 amountETH
    ) internal returns (uint256) {
        // Load contracts
        address rocketDepositPoolAddress = rocketStorage.getAddress(
            keccak256(abi.encodePacked("contract.address", "rocketDepositPool"))
        );
        address rocketTokenRETHAddress = rocketStorage.getAddress(
            keccak256(abi.encodePacked("contract.address", "rocketTokenRETH"))
        );

        // Forward deposit to RP & get amount of Reth minted
        uint256 rethBalance1 = RocketTokenRETHInterface(rocketTokenRETHAddress)
            .balanceOf(address(this));
        RocketDepositPoolInterface(rocketDepositPoolAddress).deposit{
            value: amountETH
        }();
        uint256 rethBalance2 = RocketTokenRETHInterface(rocketTokenRETHAddress)
            .balanceOf(address(this));

        if (rethBalance2 == rethBalance1) revert InsufficientRethMinted();

        return
            RocketTokenRETHInterface(rocketTokenRETHAddress).getEthValue(
                rethBalance2 - rethBalance1
            );
    }

    function _updateETH2TokenRatio(
        uint256 numerator,
        uint256 denominator
    ) internal {
        if (denominator == 0) revert ZeroDenominator();

        eTH2TokenNumerator = numerator;
        eTH2TokenDenominator = denominator;

        emit ETH2TokenRaioUpdated(numerator, denominator);
    }

    function _accrueRewards() internal {
        uint256 lastRewardTimeLocal = lastRewardTime;
        uint256 totalStakedLocal = totalStaked;
        uint256 endTimeLocal = endTime;

        unchecked {
            uint256 maxTime = block.timestamp < endTimeLocal
                ? block.timestamp
                : endTimeLocal;
            if (totalStakedLocal > 0 && lastRewardTimeLocal < maxTime) {
                uint256 totalTime = endTimeLocal - lastRewardTimeLocal;
                uint256 passedTime = maxTime - lastRewardTimeLocal;
                uint256 reward = (uint256(rewardRemaining) * passedTime) /
                    totalTime;

                // Overflow is unrealistic.
                rewardPerLiquidity +=
                    (reward * type(uint128).max) /
                    totalStakedLocal;
                rewardRemaining -= reward;
                lastRewardTime = maxTime;
            } else if (
                totalStakedLocal == 0 && lastRewardTimeLocal < block.timestamp
            ) {
                lastRewardTime = maxTime;
            }
        }
    }

    /*
    This function DOES NOT SEND the rewards. It returns the reward amount to the caller function
    */
    function _claimReward(
        uint128 usersLiquidity
    ) internal returns (uint256 reward) {
        reward = _calculateReward(msg.sender, usersLiquidity);
        rewardPerLiquidityLast[msg.sender] = rewardPerLiquidity;
        emit Claim(msg.sender, reward);
    }

    // We offset the rewardPerLiquidityLast snapshot so that the current reward is included next time we call _claimReward.
    function _saveReward(
        uint128 usersLiquidity,
        uint128 newLiquidity
    ) internal returns (uint256 reward) {
        reward = _calculateReward(msg.sender, usersLiquidity);
        uint256 rewardPerLiquidityDelta = (reward * type(uint128).max) /
            newLiquidity;
        rewardPerLiquidityLast[msg.sender] =
            rewardPerLiquidity -
            rewardPerLiquidityDelta;
    }

    function _calculateReward(
        address user,
        uint128 usersLiquidity
    ) internal view returns (uint256 reward) {
        uint256 userRewardPerLiquidtyLast = rewardPerLiquidityLast[user];
        uint256 rewardPerLiquidityDelta;

        unchecked {
            rewardPerLiquidityDelta =
                rewardPerLiquidity -
                userRewardPerLiquidtyLast;
        }

        reward = FullMath.mulDiv(
            rewardPerLiquidityDelta,
            usersLiquidity,
            type(uint128).max
        );
    }

    function _updateTokenBurnBIPS(uint256 newBIPS) internal {
        if (newBIPS > 1000) revert PercentageTooHigh();
        tokenBurnBIPS = newBIPS;
        emit BurnBIPSUpdated(newBIPS);
    }

    function _updateProtocolWallet(address newAddress) internal {
        protocolWallet = newAddress;
        emit ProtocolWalletUpdated(newAddress);
    }

    function _receivePOS32From(address to, uint256 amount) internal {
        IERC20(POS32).transferFrom(to, address(this), amount);
    }

    function _sendRethTo(
        address rocketTokenRETHAddress,
        address to,
        uint256 amount
    ) internal {
        if(amount != 0) {
            IERC20(rocketTokenRETHAddress).transfer(to, amount);
        }
    }

    function _sendPOS32To(address to, uint256 amount) internal {
        IERC20(POS32).transfer(to, amount);
    }

    function _burnPOS32(uint256 amount) internal {
        IERC20(POS32).transfer(DEAD_ADDRESS, amount);
    }

    function _sendETH(address to, uint256 amount) internal {
        if (amount != 0) {
            bool success;
            /// @solidity memory-safe-assembly
            assembly {
                // Transfer the ETH and store if it succeeded or not.
                success := call(gas(), to, amount, 0, 0, 0, 0)
            }
            require(success, "ETH_TRANSFER_FAILED");
        }
    }
}