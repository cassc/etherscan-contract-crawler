// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;
/**
 * @title EUSDMiningIncentives is a stripped down version of Synthetix StakingRewards.sol, to reward esLBR to eUSD&peUSD minters.
 * Differences from the original contract,
 * - totalStaked and stakedOf(user) are different from the original version.
 * - When a user's borrowing changes in any of the Lst vaults, the `refreshReward()` function needs to be called to update the data.
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IesLBR.sol";
import "../interfaces/IEUSD.sol";
import "../interfaces/ILybra.sol";
import "../interfaces/Iconfigurator.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface IesLBRBoost {
    function getUserBoost(
        address user,
        uint256 userUpdatedAt,
        uint256 finishAt
    ) external view returns (uint256);
}

contract EUSDMiningIncentives is Ownable {
    Iconfigurator public immutable configurator;
    IesLBRBoost public esLBRBoost;
    IEUSD public immutable EUSD;
    address public esLBR;
    address public LBR;
    address public wETH;
    address[] public vaults;

    // Duration of rewards to be paid out (in seconds)
    uint256 public duration = 604_800;
    // Timestamp of when the rewards finish
    uint256 public finishAt;
    // Minimum of last updated time and reward finish time
    uint256 public updatedAt;
    // Reward to be paid out per second
    uint256 public rewardRatio;
    // Sum of (reward ratio * dt * 1e18 / total supply)
    uint256 public rewardPerTokenStored;
    // User address => rewardPerTokenStored
    mapping(address => uint256) public userRewardPerTokenPaid;
    // User address => rewards to be claimed
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public userUpdatedAt;
    uint256 public extraRatio = 10 * 1e18;
    uint256 public biddingFeeRatio = 3000;
    address public ethlbrStakePool;
    address public ethlbrLpToken;
    uint256 public minDlpRatio = 500;
    AggregatorV3Interface internal etherPriceFeed;
    AggregatorV3Interface internal lbrPriceFeed;
    bool public isEUSDBuyoutAllowed = true;
    bool public v1Supported;
    address immutable oldLybra;

    event VaultsChanged(address[] vaults, uint256 time);
    event LBROracleChanged(address newOracle, uint256 time);
    event TokenChanged(address newLBR, address newEsLBR, uint256 time);
    event ClaimReward(address indexed user, uint256 amount, uint256 time);
    event ClaimedOtherEarnings(address indexed user, address indexed Victim, uint256 buyAmount, uint256 biddingFee, bool useEUSD, uint256 time);
    event NotifyRewardChanged(uint256 addAmount, uint256 time);

    //etherOracle = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
    //wETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    constructor(address _config, address _etherOracle, address _lbrOracle, address _weth, address _oldEUSD) {
        configurator = Iconfigurator(_config);
        EUSD = IEUSD(configurator.getEUSDAddress());
        etherPriceFeed = AggregatorV3Interface(_etherOracle);
        lbrPriceFeed = AggregatorV3Interface(_lbrOracle);
        wETH = _weth;
        oldLybra = _oldEUSD;
    }

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
            userUpdatedAt[_account] = block.timestamp;
        }
        _;
    }

    function setToken(address _lbr, address _eslbr) external onlyOwner {
        LBR = _lbr;
        esLBR = _eslbr;
        emit TokenChanged(_lbr, _eslbr, block.timestamp);
    }

    function setLBROracle(address _lbrOracle) external onlyOwner {
        lbrPriceFeed = AggregatorV3Interface(_lbrOracle);
        emit LBROracleChanged(_lbrOracle, block.timestamp);
    }

    function setPools(address[] memory _vaults) external onlyOwner {
        require(_vaults.length <= 10, "EL");
        for (uint i = 0; i < _vaults.length; i++) {
            require(configurator.mintVault(_vaults[i]), "NOT_VAULT");
        }
        vaults = _vaults;
        emit VaultsChanged(_vaults, block.timestamp);
    }

    function setBiddingCost(uint256 _biddingRatio) external onlyOwner {
        require(_biddingRatio <= 8000, "BCE");
        biddingFeeRatio = _biddingRatio;
    }

    function setExtraRatio(uint256 ratio) external onlyOwner {
        require(ratio <= 1e20, "BCE");
        extraRatio = ratio;
    }

    function setMinDlpRatio(uint256 ratio) external onlyOwner {
        require(ratio <= 1_000, "BCE");
        minDlpRatio = ratio;
    }

    function setBoost(address _boost) external onlyOwner {
        esLBRBoost = IesLBRBoost(_boost);
    }

    function setV1Supported(bool _bool) external onlyOwner {
        v1Supported = _bool;
    }

    function setRewardsDuration(uint256 _duration) external onlyOwner {
        require(finishAt < block.timestamp, "reward duration not finished");
        duration = _duration;
    }

    function setEthlbrStakeInfo(address _pool, address _lp) external onlyOwner {
        ethlbrStakePool = _pool;
        ethlbrLpToken = _lp;
    }
    function setEUSDBuyoutAllowed(bool _bool) external onlyOwner {
        isEUSDBuyoutAllowed = _bool;
    }

    /**
     * @notice Returns the total amount of minted eUSD&peUSD in the asset pools.
     * @return The total amount of minted eUSD&peUSD.
     * @dev It iterates through the vaults array and retrieves the total circulation of each asset pool using the getPoolTotalCirculation()
     * function from the ILybra interface. The total staked amount is calculated by multiplying the total circulation by the vault's
     * weight (obtained from configurator.getVaultWeight()). 
     */
    function totalStaked() public view returns (uint256) {
        uint256 amount;
        for (uint i = 0; i < vaults.length; i++) {
            ILybra vault = ILybra(vaults[i]);
            amount += vault.getPoolTotalCirculation() * configurator.getVaultWeight(vaults[i]) / 1e20;
        }
        if(v1Supported) {
            amount += IEUSD(oldLybra).totalSupply() * configurator.getVaultWeight(oldLybra) / 1e20;
        }
        return amount;
    }

    /**
     * @notice Returns the total amount of borrowed eUSD and peUSD by the user.
     */
    function stakedOf(address user) public view returns (uint256) {
        uint256 amount;
        for (uint i = 0; i < vaults.length; i++) {
            ILybra vault = ILybra(vaults[i]);
            amount += vault.getBorrowedOf(user) * configurator.getVaultWeight(vaults[i]) / 1e20;
        }
        if(v1Supported) {
            amount += ILybra(oldLybra).getBorrowedOf(user) * configurator.getVaultWeight(oldLybra) / 1e20;
        }
        return amount;
    }

    /**
     * @notice Returns the value of the user's staked LP tokens in the ETH-LBR liquidity pool.
     * @param user The user's address.
     * @return The value of the user's staked LP tokens in ETH and LBR.
     */
    function stakedLBRLpValue(address user) public view returns (uint256) {
        uint256 totalLp = IEUSD(ethlbrLpToken).totalSupply();
        if(totalLp == 0) return 0;
        (, int etherPrice, , , ) = etherPriceFeed.latestRoundData();
        (, int lbrPrice, , , ) = lbrPriceFeed.latestRoundData();
        uint256 etherInLp = (IEUSD(wETH).balanceOf(ethlbrLpToken) * uint(etherPrice)) / 1e8;
        uint256 lbrInLp = (IEUSD(LBR).balanceOf(ethlbrLpToken) * uint(lbrPrice)) / 1e8;
        uint256 userStaked = IEUSD(ethlbrStakePool).balanceOf(user);
        return (userStaked * (lbrInLp + etherInLp)) / totalLp;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return _min(finishAt, block.timestamp);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalStaked() == 0) {
            return rewardPerTokenStored;
        }

        return rewardPerTokenStored + (rewardRatio * (lastTimeRewardApplicable() - updatedAt) * 1e18) / totalStaked();
    }

    /**
     * @notice Update user's claimable reward data and record the timestamp.
     */
    function refreshReward(address _account) external updateReward(_account) {}

    function getBoost(address _account) public view returns (uint256) {
        uint256 redemptionBoost;
        if (configurator.isRedemptionProvider(_account)) {
            redemptionBoost = extraRatio;
        }
        return 100 * 1e18 + redemptionBoost + esLBRBoost.getUserBoost(_account, userUpdatedAt[_account], finishAt);
    }

    function earned(address _account) public view returns (uint256) {
        return ((stakedOf(_account) * getBoost(_account) * (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e38) + rewards[_account];
    }

    /**
     * @notice Checks if the user's earnings can be claimed by others.
     * @param user The user's address.
     * @return  A boolean indicating if the user's earnings can be claimed by others.
     */
    function isOtherEarningsClaimable(address user) public view returns (bool) {
        uint256 staked = stakedOf(user);
        if(staked == 0) return true;
        return (stakedLBRLpValue(user) * 10_000) / staked < minDlpRatio;
    }

    function getReward() external updateReward(msg.sender) {
        require(!isOtherEarningsClaimable(msg.sender), "Insufficient DLP, unable to claim rewards");
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            IesLBR(esLBR).mint(msg.sender, reward);
            emit ClaimReward(msg.sender, reward, block.timestamp);
        }
    }

    /**
     * @notice Purchasing the esLBR earnings from users who have insufficient DLP.
     * @param user The address of the user whose earnings will be purchased.
     * @param useEUSD Boolean indicating if the purchase will be made using eUSD.
     * Requirements:
     * The user's earnings must be claimable by others.
     * If using eUSD, the purchase must be permitted.
     * The user must have non-zero rewards.
     * If using eUSD, the caller must have sufficient eUSD balance and allowance.
     */
    function _buyOtherEarnings(address user, bool useEUSD) internal updateReward(user) {
        require(isOtherEarningsClaimable(user), "The rewards of the user cannot be bought out");
        require(rewards[user] != 0, "ZA");
        if(useEUSD) {
            require(isEUSDBuyoutAllowed, "The purchase using eUSD is not permitted.");
        }
        uint256 reward = rewards[user];
        rewards[user] = 0;
        uint256 biddingFee = (reward * biddingFeeRatio) / 10_000;
        if(useEUSD) {
            (, int lbrPrice, , , ) = lbrPriceFeed.latestRoundData();
            biddingFee = biddingFee * uint256(lbrPrice) / 1e8;
            bool success = EUSD.transferFrom(msg.sender, address(owner()), biddingFee);
            require(success, "TF");
        } else {
            IesLBR(LBR).burn(msg.sender, biddingFee);
        }
        IesLBR(esLBR).mint(msg.sender, reward);
        emit ClaimedOtherEarnings(msg.sender, user, reward, biddingFee, useEUSD, block.timestamp);
    }

    function buyOthersEarnings(address[] memory users, bool useEUSD) external {
        for(uint256 i; i < users.length; i++) {
            _buyOtherEarnings(users[i], useEUSD);
        }
    }

    function notifyRewardAmount(
        uint256 amount
    ) external onlyOwner updateReward(address(0)) {
        require(amount != 0, "amount = 0");
        if (block.timestamp >= finishAt) {
            rewardRatio = amount / duration;
        } else {
            uint256 remainingRewards = (finishAt - block.timestamp) * rewardRatio;
            rewardRatio = (amount + remainingRewards) / duration;
        }

        require(rewardRatio != 0, "reward ratio = 0");

        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;
        emit NotifyRewardChanged(amount, block.timestamp);
    }

    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }
}