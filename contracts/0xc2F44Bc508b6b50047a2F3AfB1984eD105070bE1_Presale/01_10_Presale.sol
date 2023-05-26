// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './ITokenStaked.sol';

contract Presale is Ownable, ReentrancyGuard, ITokenStaked {
    using SafeERC20 for IERC20;

    enum SalePhase {
        Sale,
        SaleOver,
        Staking
    }

    struct UserInfo {
        uint256 tokensClaimed;
        uint256 rewardDebt;
        bool hasShare;
    }

    uint256 public immutable safetyBufferInBlocks;

    IERC20 public immutable x2y2Token; // x2y2
    IERC20 public immutable rewardToken; // weth

    // staking period in blocks
    uint256 public immutable STAKING_PERIOD_IN_BLOCKS;
    uint256 public immutable stakingStartBlock;
    uint256 public immutable stakingEndBlock;

    uint256 public immutable TOTAL_TOKEN_AMOUNT;
    uint256 public immutable TOTAL_RAISING_AMOUNT;
    uint256 public immutable MAX_SHARES;
    uint256 public immutable PRICE_PER_SHARE;
    uint256 public immutable TOKENS_PER_SHARE;

    SalePhase public currentPhase;

    // total shares sold (length of userInfo)
    uint256 public totalShareSold;
    // share * TOKENS_PER_SHARE
    uint256 public totalTokensSold;

    // weth harvested by user
    uint256 public totalRewardDistributed;
    // withdrawn reward token
    uint256 public tokenRewardTreasuryWithdrawn;

    mapping(address => bool) public signers;
    mapping(address => UserInfo) public userInfo;

    event SignerUpdate(address signer, bool isRemoval);
    event Deposit(address indexed user);
    event Harvest(address indexed user, uint256 amount);
    event NewPhase(SalePhase newSalePhase);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event TreasuryWithdraw(uint256 amount);

    constructor(
        IERC20 _x2y2Token,
        IERC20 _rewardToken,
        uint256 _stakingStartBlock,
        uint256 _stakingEndBlock,
        address[] memory _signers
    ) {
        x2y2Token = (_x2y2Token);
        rewardToken = (_rewardToken);

        for (uint256 i = 0; i < _signers.length; i++) {
            signers[_signers[i]] = true;
            emit SignerUpdate(_signers[i], false);
        }

        // 15M token presale
        TOTAL_TOKEN_AMOUNT = 15_000_000 ether;
        TOTAL_RAISING_AMOUNT = 1500 ether;
        MAX_SHARES = 1000;
        PRICE_PER_SHARE = TOTAL_RAISING_AMOUNT / MAX_SHARES;
        TOKENS_PER_SHARE = TOTAL_TOKEN_AMOUNT / MAX_SHARES;

        STAKING_PERIOD_IN_BLOCKS = _stakingEndBlock - _stakingStartBlock;
        stakingStartBlock = _stakingStartBlock;
        stakingEndBlock = _stakingEndBlock;

        currentPhase = SalePhase.Sale;
        safetyBufferInBlocks = 30 * 6500; // ~ 1 month
    }

    function getTotalStaked() external view override returns (uint256) {
        if (block.number >= stakingStartBlock && block.number < stakingEndBlock) {
            return totalTokensSold;
        }
        return 0;
    }

    function updateSigners(address[] memory toAdd, address[] memory toRemove) public onlyOwner {
        for (uint256 i = 0; i < toAdd.length; i++) {
            signers[toAdd[i]] = true;
            emit SignerUpdate(toAdd[i], false);
        }
        for (uint256 i = 0; i < toRemove.length; i++) {
            delete signers[toRemove[i]];
            emit SignerUpdate(toRemove[i], true);
        }
    }

    function deposit(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable nonReentrant {
        require(currentPhase == SalePhase.Sale, 'Deposit: Phase must be Sale');
        require(!userInfo[msg.sender].hasShare, 'Deposit: Has deposited');
        require(msg.value == PRICE_PER_SHARE, 'Deposit: Wrong amount');
        require(totalShareSold < MAX_SHARES, 'Deposit: Not raising anymore');

        address signer = ECDSA.recover(keccak256(abi.encode(msg.sender)), v, r, s);
        require(signers[signer], 'Deposit: Signature error');

        userInfo[msg.sender].hasShare = true;

        totalShareSold += 1;
        totalTokensSold += TOKENS_PER_SHARE;

        emit Deposit(msg.sender);
    }

    function _totalReward() internal view returns (uint256) {
        return
            tokenRewardTreasuryWithdrawn +
            totalRewardDistributed +
            rewardToken.balanceOf(address(this));
    }

    function _pendingReward(address user) internal view returns (uint256, uint256) {
        uint256 totalReward = _totalReward();
        uint256 userDebt = userInfo[user].rewardDebt;
        uint256 userTokensLeft = TOKENS_PER_SHARE - userInfo[user].tokensClaimed;

        uint256 theoreticalReward = totalReward / totalShareSold;
        uint256 userReward = ((theoreticalReward - userDebt) * userTokensLeft) / TOKENS_PER_SHARE;

        return (userReward, theoreticalReward);
    }

    function pendingRewards(address[] memory users) external view returns (uint256) {
        uint256 total;
        for (uint256 i = 0; i < users.length; i++) {
            (uint256 pending, uint256 _debt) = _pendingReward(users[i]);
            total += pending;
        }
        return total;
    }

    function pendingReward(address user) external view returns (uint256) {
        (uint256 _amount, uint256 _debt) = _pendingReward(user);
        return _amount;
    }

    function _pendingTokens(address user) internal view returns (uint256) {
        uint256 claimed = userInfo[user].tokensClaimed;

        if (block.number < stakingStartBlock) {
            return 0;
        } else if (block.number >= stakingEndBlock) {
            return TOKENS_PER_SHARE - claimed;
        }

        uint256 passingBlocks = block.number - stakingStartBlock;
        uint256 unlockedAmount = (TOKENS_PER_SHARE * passingBlocks) / STAKING_PERIOD_IN_BLOCKS;

        return unlockedAmount - claimed;
    }

    function pendingTokens(address user) external view returns (uint256) {
        return _pendingTokens(user);
    }

    function _harvest(address user) internal returns (uint256) {
        (uint256 _pending, uint256 _debt) = _pendingReward(user);

        if (_pending > 0) {
            totalRewardDistributed += _pending;
            userInfo[user].rewardDebt = _debt;
            rewardToken.safeTransfer(user, _pending);
            emit Harvest(user, _pending);
        }
        return _pending;
    }

    function harvest() external nonReentrant {
        require(currentPhase == SalePhase.Staking, 'Harvest: Phase must be Staking');
        require(userInfo[msg.sender].hasShare, 'Harvest: User not eligible');

        require(_harvest(msg.sender) > 0, 'Harvest: No pending reward');
    }

    function withdraw() external nonReentrant {
        require(currentPhase == SalePhase.Staking, 'Withdraw: Phase must be Staking');
        require(userInfo[msg.sender].hasShare, 'Withdraw: User not eligible');

        uint256 pending = _pendingTokens(msg.sender);

        require(pending > 0, 'Withdraw: No pending token');

        _harvest(msg.sender);

        userInfo[msg.sender].tokensClaimed += pending;
        x2y2Token.safeTransfer(msg.sender, pending);

        emit Withdraw(msg.sender, pending);
    }

    function emergencyWithdraw() external nonReentrant {
        require(block.number >= stakingEndBlock, 'Withdraw: Too early');
        require(currentPhase == SalePhase.Staking, 'Withdraw: Phase must be Staking');
        require(userInfo[msg.sender].hasShare, 'Withdraw: User not eligible');

        uint256 amount = TOKENS_PER_SHARE - userInfo[msg.sender].tokensClaimed;
        require(amount > 0, 'Withdraw: No pending token');

        x2y2Token.safeTransfer(msg.sender, amount);
        userInfo[msg.sender].tokensClaimed = TOKENS_PER_SHARE;
        emit EmergencyWithdraw(msg.sender, amount);
    }

    // withdraw presale ETH & remaining token, update to saleover
    function withdrawPresale() external onlyOwner nonReentrant {
        require(currentPhase == SalePhase.Sale, 'Owner: Phase must be Sale');

        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);

        uint256 returnAmount = x2y2Token.balanceOf(address(this)) -
            totalShareSold *
            TOKENS_PER_SHARE;
        if (returnAmount > 0) {
            x2y2Token.safeTransfer(msg.sender, returnAmount);
        }

        currentPhase = SalePhase.SaleOver;
        emit NewPhase(SalePhase.SaleOver);
    }

    function updatePhaseToStaking() external onlyOwner nonReentrant {
        require(currentPhase == SalePhase.SaleOver, 'Owner: Phase must be SaleOver');
        currentPhase = SalePhase.Staking;
        emit NewPhase(SalePhase.Staking);
    }

    function treasuryWithdraw(uint256 amount) external onlyOwner nonReentrant {
        require(
            block.number > stakingEndBlock + safetyBufferInBlocks,
            'Owner: staking have not ended yet'
        );
        require(amount > 0, 'Owner: withdraw > 0');

        tokenRewardTreasuryWithdrawn += amount;
        rewardToken.safeTransfer(msg.sender, amount);
        emit TreasuryWithdraw(amount);
    }
}