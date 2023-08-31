// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract TargetRateVault is ERC4626, Ownable {
    using SafeERC20 for IERC20;

    uint256 public clockValue;
    uint256 public lastRewardTime;
    address public immutable REWARD_TOKEN;
    address public immutable STAKING_TOKEN;
    uint256 public targetTokensPerDay;
    uint256 public targetLockedStakingToken;
    uint8 public immutable STAKING_TOKEN_DECIMALS;

    mapping(address => UserInfo) userInfos;

    uint256 constant MAXIMUM_BONUS_RATE_MULTIPLIER = 5;

    bytes4 constant EIP2612_FUNCTION_SELECTOR = IERC20Permit.permit.selector;

    struct UserInfo {
        uint192 costBasis; 
        uint64 lastTimestamp; 
    }

    event TargetRatesModified(
        uint256 newTargetTokensPerDay,
        uint256 newTargetLockedStakingTokens
    );

    error InvalidPermit();
    error VaultTokenNontransferable();

    modifier senderOwnsAccount(address owner) {
        require(_msgSender() == owner);
        _;
    }

    constructor(
        address _rewardToken,
        IERC20 _stakingToken,
        uint256 _targetTokensPerDay,
        uint256 _targetLockedStakingToken
    ) ERC4626(_stakingToken) ERC20("Nontransferable Vault Token", "VAT") {
        REWARD_TOKEN = _rewardToken;
        STAKING_TOKEN_DECIMALS = IERC20Metadata(address(_stakingToken)).decimals();
        STAKING_TOKEN = address(_stakingToken);

        _setStakingTargets(_targetTokensPerDay, _targetLockedStakingToken);
    }

    function updateClock() virtual public {
        if (block.timestamp <= lastRewardTime) {
            return;
        }
        if (totalSupply() == 0) {
            lastRewardTime = block.timestamp;
            return;
        }
        clockValue = getClockIncrement() + clockValue;
        lastRewardTime = block.timestamp;
    }

    function getRewardAdjustment(uint256 unadjustedReward, uint256 timeElapsed) virtual public view returns (uint256) {
        return unadjustedReward;
    }

    function getClockIncrement() public view returns (uint256) {
        uint256 nSecondsSinceLastUpdate = (block.timestamp - lastRewardTime);
        return SafeCast.toUint192(((targetTokensPerDay/(1 days))*nSecondsSinceLastUpdate*(10**STAKING_TOKEN_DECIMALS))/(Math.max(IERC20(STAKING_TOKEN).balanceOf(address(this)), targetLockedStakingToken/MAXIMUM_BONUS_RATE_MULTIPLIER)));
    }

    function pendingRewards(address owner) public virtual view returns (uint256) {

        uint256 oldClock = userInfos[owner].costBasis;

        uint256 newClock = clockValue + getClockIncrement();

        uint256 amountToMintUnadjusted = ((newClock - oldClock)*((balanceOf(owner)*totalAssets())/totalSupply()))/(10**STAKING_TOKEN_DECIMALS);
        return getRewardAdjustment(amountToMintUnadjusted, block.timestamp-userInfos[owner].lastTimestamp);
    }

    function getUserInfo(address owner) public view returns (uint256, uint256) {
        return (userInfos[owner].costBasis, userInfos[owner].lastTimestamp);
    }

    function harvest(address owner, address receiver) virtual public senderOwnsAccount(owner) {
        // Effects
        uint256 oldClock = userInfos[owner].costBasis;
        updateClock();

        uint256 amountToMintUnadjusted = ((clockValue - oldClock)*((balanceOf(owner)*totalAssets())/totalSupply()))/(10**STAKING_TOKEN_DECIMALS);
        uint256 amountToMint = getRewardAdjustment(amountToMintUnadjusted, block.timestamp-userInfos[owner].lastTimestamp);
        uint256 rewardTokenBalance = IERC20(REWARD_TOKEN).balanceOf(address(this));
        
        userInfos[owner].lastTimestamp = SafeCast.toUint64(block.timestamp);
        userInfos[owner].costBasis = SafeCast.toUint192(clockValue);

        // Interactions
        if(rewardTokenBalance < amountToMint){
            IERC20(REWARD_TOKEN).transfer(receiver, rewardTokenBalance);
        } else {
            IERC20(REWARD_TOKEN).transfer(receiver, amountToMint);
        }
    }

    function newCostBasis(uint256 priorShares, uint256 priorCostBasis, uint256 newShares) internal view returns (uint192) {
        require(priorShares+newShares > 0);
        return SafeCast.toUint192((priorShares*priorCostBasis + newShares*clockValue)/(priorShares+newShares));
    }

    // Simple linear adjustment to timestamp for vesting. Used for multiple deposits logic.
    // Could potentially cause issues if vesting is non-linear.
    function sharesWeightedTimestamp(uint256 priorShares, uint256 priorTimestamp, uint256 newShares) internal view virtual returns (uint64) {
        require(priorShares+newShares > 0);
        return SafeCast.toUint64((priorShares*priorTimestamp + newShares*block.timestamp)/(priorShares+newShares));
    }

    function deposit(
        uint256 assets,
        address receiver
    ) public virtual override returns (uint256) {
        require(
            assets <= maxDeposit(receiver),
            "ERC4626: deposit more than max"
        );
        updateClock();
        uint256 receiverSharesBefore = balanceOf(receiver);
        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);

        userInfos[receiver].costBasis = newCostBasis(receiverSharesBefore, userInfos[receiver].costBasis, shares);
        userInfos[receiver].lastTimestamp = sharesWeightedTimestamp(receiverSharesBefore, userInfos[receiver].lastTimestamp, shares);

        return shares;
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override senderOwnsAccount(owner) returns (uint256) {
        require(
            assets <= maxWithdraw(owner),
            "ERC4626: withdraw more than max"
        );

        harvest(owner, receiver);
        uint256 shares = previewWithdraw(assets);

        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual override senderOwnsAccount(owner) returns (uint256) {
        require(shares <= maxRedeem(owner), "ERC4626: redeem more than max");

        harvest(owner, receiver);
        uint256 assets = previewRedeem(shares);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return assets;
    }

    function mint(
        uint256 shares,
        address receiver
    ) public virtual override returns (uint256) {
        require(shares <= maxMint(receiver), "ERC4626: mint more than max");

        updateClock();
        uint256 receiverSharesBefore = balanceOf(receiver);
		uint256 assets = previewMint(shares);
        _deposit(_msgSender(), receiver, assets, shares);

        userInfos[receiver].costBasis = newCostBasis(receiverSharesBefore, userInfos[receiver].costBasis, shares);
        userInfos[receiver].lastTimestamp = sharesWeightedTimestamp(receiverSharesBefore, userInfos[receiver].lastTimestamp, shares);

        return assets;
    }

    function _setStakingTargets(uint256 newTargetTokensPerDay, uint256 newTargetLockedStakingTokens) internal {
        targetTokensPerDay = newTargetTokensPerDay;
        targetLockedStakingToken = newTargetLockedStakingTokens;

        emit TargetRatesModified(targetTokensPerDay, targetLockedStakingToken);
    }

    function setStakingTargets(uint256 newTargetTokensPerDay, uint256 newTargetLockedStakingTokens) external onlyOwner {
        _setStakingTargets(newTargetTokensPerDay, newTargetLockedStakingTokens);
    }

    /* Disable ERC20 Transfer and Approval functionality for vault shares */
    function _transfer(address from, address to, uint256 amount) internal override {
    	revert VaultTokenNontransferable();
    }

    function _approve(address owner, address spender, uint256 amount) internal override {
        revert VaultTokenNontransferable();
    }

    function permitDeposit(uint256 assets, address receiver, bytes calldata permit) external returns (uint256) {
        safePermit(STAKING_TOKEN, permit);
        return deposit(assets, receiver);
    }

    function permitMint(uint256 shares, address receiver, bytes calldata permit) external returns (uint256) {
        safePermit(STAKING_TOKEN, permit);
        return mint(shares, receiver);
    }

    function safePermit(address token, bytes calldata permitCallData) internal {
        bytes4 functionSignature = bytes4(permitCallData[:4]);
        
        if(functionSignature != EIP2612_FUNCTION_SELECTOR){
            revert InvalidPermit();
        }

        (bool success, ) = token.call(permitCallData);
        if(!success){
            revert InvalidPermit();
        }
    }

    function withdrawWithoutHarvest(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual senderOwnsAccount(owner) returns (uint256) {
        require(
            assets <= maxWithdraw(owner),
            "ERC4626: withdraw more than max"
        );

        uint256 shares = previewWithdraw(assets);

        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    function evacuateRewards() public virtual onlyOwner {
        IERC20(REWARD_TOKEN).transfer(msg.sender, IERC20(REWARD_TOKEN).balanceOf(address(this)));
    }

}