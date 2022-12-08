// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./PriceConsumerV3.sol";

contract GoldStaking is Ownable {
    PriceConsumerV3 internal priceConsumerV3;

    IERC20Metadata public goldToken;
    IUniswapV2Pair public goldLP;

    struct META_DATA {
        uint256 amount;
        uint256 stakeTime;
        uint256 claimTime;
    }

    mapping(address => mapping(uint8 => META_DATA[])) internal tokenStakeData;
    mapping(address => mapping(uint8 => META_DATA[])) internal lpStakeData;

    uint256[6] public tokenStakeAPR;
    uint256[6] public lpStakeAPR;
    uint256[6] public penaltyForEarlyClaim;
    uint256[6] public lockTerm;

    uint256[6] public tokenStakeAmount;
    uint256[6] public lpStakeAmount;

    uint256[6] public tokenMaxStakeAmount;

    constructor(address _goldToken, address _goldLP) {
        priceConsumerV3 = new PriceConsumerV3();
        goldToken = IERC20Metadata(_goldToken);
        goldLP = IUniswapV2Pair(_goldLP);

        tokenStakeAPR[0] = 10;
        tokenStakeAPR[1] = 15;
        tokenStakeAPR[2] = 20;
        tokenStakeAPR[3] = 25;
        tokenStakeAPR[4] = 35;
        tokenStakeAPR[5] = 45;

        lpStakeAPR[0] = 20;
        lpStakeAPR[1] = 25;
        lpStakeAPR[2] = 30;
        lpStakeAPR[3] = 35;
        lpStakeAPR[4] = 45;
        lpStakeAPR[5] = 55;

        penaltyForEarlyClaim[0] = 0;
        penaltyForEarlyClaim[1] = 50;
        penaltyForEarlyClaim[2] = 40;
        penaltyForEarlyClaim[3] = 30;
        penaltyForEarlyClaim[4] = 25;
        penaltyForEarlyClaim[5] = 20;

        lockTerm[0] = 0;
        lockTerm[1] = 1 * 7 days;
        lockTerm[2] = 1 * 30 days;
        lockTerm[3] = 3 * 30 days;
        lockTerm[4] = 6 * 30 days;
        lockTerm[5] = 12 * 30 days;

        tokenMaxStakeAmount[0] = 19750000 * 1e18;
        tokenMaxStakeAmount[1] = 7900000 * 1e18;
        tokenMaxStakeAmount[2] = 19750000 * 1e18;
        tokenMaxStakeAmount[3] = 15800000 * 1e18;
        tokenMaxStakeAmount[4] = 11285700 * 1e18;
        tokenMaxStakeAmount[5] = 8777777 * 1e18;
    }

    function updateTokenStakeAPR(uint256 lockType, uint256 apr)
        external
        onlyOwner
    {
        require(lockType < 6, "lockType should be less than 6");
        tokenStakeAPR[lockType] = apr;
    }

    function updateLpStakeAPR(uint256 lockType, uint256 apr)
        external
        onlyOwner
    {
        require(lockType < 6, "lockType should be less than 6");
        lpStakeAPR[lockType] = apr;
    }

    function updateTokenMaxStakeAmount(uint256 lockType, uint256 maxTokenAmount)
        external
        onlyOwner
    {
        require(lockType < 6, "lockType should be less than 6");
        tokenMaxStakeAmount[lockType] = maxTokenAmount;
    }

    function updatePenaltyAPR(uint256 lockType, uint256 penalty)
        external
        onlyOwner
    {
        require(lockType < 6, "lockType should be less than 6");
        penaltyForEarlyClaim[lockType] = penalty;
    }

    function updateLockTerm(uint256 lockType, uint256 month)
        external
        onlyOwner
    {
        require(lockType < 6, "lockType should be less than 6");
        lockTerm[lockType] = month * 30 days;
    }

    function getEthPrice() public view returns (uint256) {
        return uint256(priceConsumerV3.getLatestPrice());
    }

    function getTokenPrice() public view returns (uint256) {
        uint112 reserve0;
        uint112 reserve1;
        uint256 tokenPrice;

        (reserve0, reserve1, ) = goldLP.getReserves();

        uint256 ethPrice = getEthPrice();

        if (goldLP.token0() == address(goldToken))
            tokenPrice = ((ethPrice * reserve1) /
                reserve0 /
                (10**(18 - goldToken.decimals())));
        else
            tokenPrice = ((ethPrice * reserve0) /
                reserve1 /
                (10**(18 - goldToken.decimals())));

        return tokenPrice;
    }

    function getLpPrice() public view returns (uint256) {
        uint112 reserve0;
        uint112 reserve1;
        uint256 lpPrice;

        (reserve0, reserve1, ) = goldLP.getReserves();
        uint256 ethPrice = getEthPrice();
        uint256 lpTotalSupply = goldLP.totalSupply();
        if (goldLP.token0() == address(goldToken))
            lpPrice = ((ethPrice * reserve1 * 2) / lpTotalSupply);
        else lpPrice = ((ethPrice * reserve0 * 2) / lpTotalSupply);
        return lpPrice;
    }

    function getTokenStakeData(address user, uint8 lockType)
        external
        view
        returns (META_DATA[] memory)
    {
        return tokenStakeData[user][lockType];
    }

    function getLpStakeData(address user, uint8 lockType)
        external
        view
        returns (META_DATA[] memory)
    {
        return lpStakeData[user][lockType];
    }

    function tokenStake(uint256 amount, uint8 lockType) external {
        require(amount > 0 && lockType <= 6, "Invalid arguments.");
        require(
            tokenStakeAmount[lockType] < tokenMaxStakeAmount[lockType],
            "Full staked already."
        );

        uint256 stakeAmount = Math.min(
            amount,
            tokenMaxStakeAmount[lockType] - tokenStakeAmount[lockType]
        );
        goldToken.transferFrom(msg.sender, address(this), stakeAmount);

        META_DATA memory temp = META_DATA(
            stakeAmount,
            block.timestamp,
            block.timestamp
        );
        tokenStakeData[msg.sender][lockType].push(temp);

        tokenStakeAmount[lockType] = tokenStakeAmount[lockType] + stakeAmount;
    }

    function lpStake(uint256 amount, uint8 lockType) external {
        require(amount > 0 && lockType <= 6, "Invalid arguments.");
        goldLP.transferFrom(msg.sender, address(this), amount);

        META_DATA memory temp = META_DATA(
            amount,
            block.timestamp,
            block.timestamp
        );
        lpStakeData[msg.sender][lockType].push(temp);

        lpStakeAmount[lockType] = lpStakeAmount[lockType] + amount;
    }

    function tokenStakeReward(
        address user,
        uint8 lockType,
        uint256 index,
        bool claim
    ) public view returns (uint256) {
        require(
            index < tokenStakeData[user][lockType].length,
            "Invalid claim index"
        );
        META_DATA memory temp = tokenStakeData[user][lockType][index];

        uint256 lastTime = claim ? temp.claimTime : temp.stakeTime;
        return
            (((temp.amount * tokenStakeAPR[lockType]) / 100) *
                (block.timestamp - lastTime)) / 360 days;
    }

    function lpStakeReward(
        address user,
        uint8 lockType,
        uint256 index,
        bool claim
    ) public view returns (uint256) {
        require(
            index < lpStakeData[user][lockType].length,
            "Invalid claim index"
        );
        META_DATA memory temp = lpStakeData[user][lockType][index];

        uint256 tokenPrice = getTokenPrice();
        uint256 lpPrice = getLpPrice();

        uint256 lastTime = claim ? temp.claimTime : temp.stakeTime;
        return
            (((((temp.amount * lpPrice) / tokenPrice) * lpStakeAPR[lockType]) /
                100) * (block.timestamp - lastTime)) / 360 days;
    }

    function availableRewardAmount() internal view returns (uint256) {
        return
            goldToken.balanceOf(address(this)) -
            tokenStakeAmount[0] -
            tokenStakeAmount[1] -
            tokenStakeAmount[2] -
            tokenStakeAmount[3] -
            tokenStakeAmount[4] -
            tokenStakeAmount[5];
    }

    function tokenClaim(uint8 lockType, uint256 index) external {
        require(
            index < tokenStakeData[msg.sender][lockType].length,
            "Invalid claim index"
        );

        META_DATA storage temp = tokenStakeData[msg.sender][lockType][index];
        uint256 originReward = tokenStakeReward(
            msg.sender,
            lockType,
            index,
            true
        );

        uint256 nextClaimableTime = temp.claimTime + lockTerm[lockType];
        if (lockType == 0 || nextClaimableTime <= block.timestamp)
            goldToken.transfer(
                msg.sender,
                Math.min(originReward, availableRewardAmount())
            );
        else {
            goldToken.transfer(
                msg.sender,
                Math.min(
                    (originReward * penaltyForEarlyClaim[lockType]) / 100,
                    availableRewardAmount()
                )
            );
        }
        temp.claimTime = block.timestamp;
    }

    function lpClaim(uint8 lockType, uint256 index) external {
        require(
            index < lpStakeData[msg.sender][lockType].length,
            "Invalid claim index"
        );

        META_DATA storage temp = lpStakeData[msg.sender][lockType][index];
        uint256 originReward = lpStakeReward(msg.sender, lockType, index, true);

        uint256 nextClaimableTime = temp.claimTime + lockTerm[lockType];
        if (lockType == 0 || nextClaimableTime <= block.timestamp)
            goldToken.transfer(
                msg.sender,
                Math.min(originReward, availableRewardAmount())
            );
        else {
            goldToken.transfer(
                msg.sender,
                Math.min(
                    (originReward * penaltyForEarlyClaim[lockType]) / 100,
                    availableRewardAmount()
                )
            );
        }
        temp.claimTime = block.timestamp;
    }

    function tokenUnstake(
        uint256 amount,
        uint8 lockType,
        uint256 index
    ) external {
        require(amount > 0, "Amount should be not 0.");
        require(
            index < tokenStakeData[msg.sender][lockType].length,
            "Invalid claim index"
        );

        META_DATA storage temp = tokenStakeData[msg.sender][lockType][index];
        require(amount <= temp.amount, "Amount exceeds staking amount.");

        uint256 originReward = tokenStakeReward(
            msg.sender,
            lockType,
            index,
            false
        );
        originReward = (originReward * amount) / temp.amount;

        uint256 nextClaimableTime = temp.stakeTime + lockTerm[lockType];
        if (lockType == 0 || nextClaimableTime <= block.timestamp)
            goldToken.transfer(
                msg.sender,
                Math.min(originReward, availableRewardAmount()) + amount
            );
        else
            goldToken.transfer(
                msg.sender,
                Math.min(
                    (originReward * penaltyForEarlyClaim[lockType]) / 100,
                    availableRewardAmount()
                ) + amount
            );

        temp.amount = temp.amount - amount;
        tokenStakeAmount[lockType] = tokenStakeAmount[lockType] - amount;
    }

    function lpUnstake(
        uint256 amount,
        uint8 lockType,
        uint256 index
    ) external {
        require(amount > 0, "Amount should be not 0.");
        require(
            index < lpStakeData[msg.sender][lockType].length,
            "Invalid claim index"
        );

        META_DATA storage temp = lpStakeData[msg.sender][lockType][index];
        require(amount <= temp.amount, "Amount exceeds staking amount.");

        uint256 originReward = lpStakeReward(
            msg.sender,
            lockType,
            index,
            false
        );
        originReward = (originReward * amount) / temp.amount;

        uint256 nextClaimableTime = temp.stakeTime + lockTerm[lockType];
        if (lockType == 0 || nextClaimableTime <= block.timestamp)
            goldToken.transfer(
                msg.sender,
                Math.min(originReward, availableRewardAmount())
            );
        else
            goldToken.transfer(
                msg.sender,
                Math.min(
                    (originReward * penaltyForEarlyClaim[lockType]) / 100,
                    availableRewardAmount()
                )
            );

        temp.amount = temp.amount - amount;
        lpStakeAmount[lockType] = lpStakeAmount[lockType] - amount;

        goldLP.transfer(msg.sender, amount);
    }
}