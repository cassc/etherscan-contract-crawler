pragma solidity ^0.8.17;
import 'contracts/lib/ownable/OwnableSimple.sol';
import 'contracts/interfaces/assets/IAsset.sol';
import 'contracts/position_trading/assets/AssetListenerBase.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import 'contracts/interfaces/IFeeDistributer.sol';

contract FeeDistributer is OwnableSimple, AssetListenerBase, IFeeDistributer {
    // fee token
    IERC20 public feeToken;
    // fee token user locks
    mapping(address => uint256) public feeTokenLocks;
    mapping(address => uint256) public claimRounds;
    uint256 public totalFeetokensLocked;
    // fee round
    uint256 public feeRoundNumber;
    uint256 public constant feeRoundInterval = 1 days;
    uint256 public nextFeeRoundTime;
    // assets
    IAsset _ownerAsset;
    IAsset _outputAsset;
    // distribution snapshot
    uint256 public distributeRoundTotalFeeTokensLock;
    uint256 public ownerAssetToDistribute;
    uint256 public outputAssetToDistribute;
    // statistics
    uint256 public ownerAssetDistributedTotal;
    uint256 public outputAssetDistributedTotal;
    // events
    event OnLock(address indexed account, uint256 amount);
    event OnUnlock(address indexed account, uint256 amount);

    constructor(
        address owner_,
        address feeTokenAddress_,
        address ownerAsset_,
        address outputAsset_
    ) OwnableSimple(owner_) {
        feeToken = IERC20(feeTokenAddress_);
        _ownerAsset = IAsset(ownerAsset_);
        _outputAsset = IAsset(outputAsset_);
        nextFeeRoundTime = block.timestamp + feeRoundInterval;
    }

    function lockFeeTokens(uint256 amount) external {
        _claimRewards(msg.sender);
        tryNextFeeRound();
        feeToken.transferFrom(msg.sender, address(this), amount);
        feeTokenLocks[msg.sender] += amount;
        totalFeetokensLocked += amount;
        emit OnLock(msg.sender, amount);
    }

    function unlockFeeTokens(uint256 amount) external {
        _claimRewards(msg.sender);
        tryNextFeeRound();
        require(feeTokenLocks[msg.sender] >= amount, 'not enough fee tokens');
        feeTokenLocks[msg.sender] -= amount;
        totalFeetokensLocked -= amount;
        emit OnUnlock(msg.sender, amount);
    }

    function tryNextFeeRound() public {
        //console.log('nextFeeRoundTime-block.timestamp', nextFeeRoundTime-block.timestamp);
        if (block.timestamp < nextFeeRoundTime) return;
        ++feeRoundNumber;
        nextFeeRoundTime = block.timestamp + feeRoundInterval;
        // snapshot for distribute
        distributeRoundTotalFeeTokensLock = totalFeetokensLocked;
        ownerAssetToDistribute = _ownerAsset.count();
        outputAssetToDistribute = _outputAsset.count();
    }

    function claimRewards() external {
        require(feeRoundNumber > 0, 'nothing to claim');
        require(claimRounds[msg.sender] < feeRoundNumber, 'reward claimed yet');
        _claimRewards(msg.sender);
        tryNextFeeRound();
    }

    function _claimRewards(address account) internal {
        if (claimRounds[account] >= feeRoundNumber) return;
        claimRounds[account] = feeRoundNumber;
        uint256 ownerCount = (ownerAssetToDistribute * feeTokenLocks[account]) /
            distributeRoundTotalFeeTokensLock;
        uint256 outputCount = (outputAssetToDistribute *
            feeTokenLocks[account]) / distributeRoundTotalFeeTokensLock;
        ownerAssetDistributedTotal += ownerCount;
        outputAssetDistributedTotal += outputCount;
        if (ownerCount > 0) _ownerAsset.withdraw(account, ownerCount);
        if (outputCount > 0) _outputAsset.withdraw(account, outputCount);
    }

    function nextFeeRoundLapsedMinutes() external view returns (uint256) {
        if (block.timestamp >= nextFeeRoundTime) return 0;
        return (nextFeeRoundTime - block.timestamp) / (1 minutes);
    }

    function ownerAsset() external view override returns (IAsset) {
        return _ownerAsset;
    }

    function outputAsset() external view override returns (IAsset) {
        return _outputAsset;
    }
}