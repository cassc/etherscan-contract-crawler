//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IUniswapPair.sol";
import "./LiquidityStakingV2.sol";

interface ILiquidityStaking {
    function setRewardRate(uint) external;

    function expandEndTime(uint) external;

    function endTime() external returns (uint);

    function availableRewards() external returns (uint, uint);

    function pause() external;

    function unpause() external;
}

// contract LiquidityPoolFactory is Ownable, AccessControl {
contract LiquidityPoolFactory is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    enum TokenType {
        UTILITY,
        NFT,
        GAME,
        REWARD,
        REFLECTION,
        DAO,
        MEME
    }
    enum PoolType {
        NORMAL,
        REFLECTION,
        DIVIDEND
    }

    struct PoolInfo {
        address pool;
        address lpToken;
        address rewardToken;
        string urls;
        address owner;
        bool revoked;
        bool launched;
        uint deployed;
    }

    mapping(address => PoolInfo) public poolMap;
    EnumerableSet.AddressSet pools;
    address public teamWallet = 0x89352214a56bA80547A2842bbE21AEdD315722Ca;
    uint public priceToStake = 1.55 ether;
    uint public priceToUpdate = 0.15 ether;
    uint public priceToLock = 0.31 ether;

    mapping(address => bool) public referrals;
    mapping(address => uint256) public referralReceived;

    uint public referralDiscountRate;
    uint public referralSendingRate;
    address private adminWallet;

    constructor() {
        adminWallet = msg.sender;
    }

    function poolCount() external view returns (uint) {
        return pools.length();
    }

    function deploy(
        address _lp,
        address _rewardToken,
        uint _period,
        string memory _urls,
        uint _tokenAmountForPool,
        address _referral
    ) external payable {
        uint price = priceToStake;
        if (_rewardToken == address(0)) {
            price = priceToLock;
        }
        if (referrals[_referral]) {
            price = price.mul(100 - referralDiscountRate).div(100);
        }
        require(msg.value >= price, "!payment");
        require(bytes(_urls).length <= 700, "invlid social urls size");
        require(_tokenAmountForPool > 0, "!enough token amount1");

        LiquidityStakingV2 pool = new LiquidityStakingV2(_lp, _rewardToken);
        pool.initialize(
            block.timestamp,
            block.timestamp.add(_period.mul(1 minutes))
        );

        if (_rewardToken != address(0)) {
            require(_tokenAmountForPool > 0, "!reward");
            pool.setRewardRate(_tokenAmountForPool.div(_period).div(1 minutes));
            IERC20(_rewardToken).safeTransferFrom(
                msg.sender,
                address(pool),
                _tokenAmountForPool
            );
        }

        pools.add(address(pool));
        pool.transferOwnership(adminWallet);

        poolMap[address(pool)] = PoolInfo({
            pool: address(pool),
            lpToken: _lp,
            rewardToken: _rewardToken,
            urls: _urls,
            owner: msg.sender,
            revoked: false,
            launched: false,
            deployed: block.timestamp
        });

        if (msg.value > 0) {
            if (msg.value > price)
                msg.sender.call{value: msg.value.sub(price)}("");

            uint referralAmount = 0;
            if (referrals[_referral]) {
                referralAmount = (
                    _rewardToken != address(0) ? priceToStake : priceToLock
                ).mul(referralSendingRate).div(100);
                address(_referral).call{value: referralAmount}("");
                referralReceived[_referral] =
                    referralReceived[_referral] +
                    referralAmount;
            }
            address(teamWallet).call{value: address(this).balance}("");
        }
    }

    function getPools(address _owner) external view returns (address[] memory) {
        uint count = _owner == address(0) ? pools.length() : 0;
        if (_owner != address(0)) {
            for (uint i = 0; i < pools.length(); i++) {
                if (poolMap[pools.at(i)].owner == _owner) count++;
            }
        }
        if (count == 0) return new address[](0);

        address[] memory poolList = new address[](count);
        uint index = 0;
        for (uint i = 0; i < pools.length(); i++) {
            if (_owner != address(0) && poolMap[pools.at(i)].owner != _owner) {
                continue;
            }
            poolList[index] = poolMap[pools.at(i)].pool;
            index++;
        }

        return poolList;
    }

    function updateRewardRate(address _pool, uint _rate) external payable {
        PoolInfo storage pool = poolMap[_pool];

        require(pool.owner == msg.sender, "!owner");
        require(pool.rewardToken != address(0), "!staking pool");
        require(msg.value >= priceToUpdate, "!payment");

        ILiquidityStaking(_pool).setRewardRate(_rate);

        if (msg.value > 0) address(teamWallet).call{value: msg.value}("");
    }

    function supplyRewardToken(address _pool, uint _amount) external payable {
        PoolInfo storage pool = poolMap[_pool];

        require(pool.owner == msg.sender, "!owner");
        require(pool.rewardToken != address(0), "!staking pool");
        require(msg.value >= priceToUpdate, "!payment");
        require(_amount > 0, "!reward");

        ILiquidityStaking poolInst = ILiquidityStaking(_pool);
        require(poolInst.endTime() > block.timestamp, "expired pool");

        (uint remain, uint insuff) = poolInst.availableRewards();
        if (insuff < _amount) {
            uint supply = _amount + remain - insuff;
            poolInst.setRewardRate(
                supply.div(poolInst.endTime().sub(block.timestamp))
            );
        }
        IERC20(pool.rewardToken).safeTransferFrom(
            msg.sender,
            address(_pool),
            _amount
        );

        if (msg.value > 0) address(teamWallet).call{value: msg.value}("");
    }

    function expandEndTime(address _pool, uint _mins) external payable {
        PoolInfo storage pool = poolMap[_pool];

        require(pool.owner == msg.sender, "!owner");
        require(pool.rewardToken != address(0), "!staking pool");
        require(msg.value >= priceToUpdate, "!payment");

        ILiquidityStaking(_pool).expandEndTime(_mins);

        if (msg.value > 0) address(teamWallet).call{value: msg.value}("");
    }

    function launch(address _pool) external {
        require(poolMap[_pool].owner == msg.sender, "!owner");
        ILiquidityStaking(_pool).unpause();
        poolMap[_pool].launched = true;
    }

    function revoke(address _pool, bool _flag) external onlyOwner {
        poolMap[_pool].revoked = _flag;
        _flag
            ? ILiquidityStaking(_pool).pause()
            : ILiquidityStaking(_pool).unpause();
        poolMap[_pool].launched = !_flag;
    }

    // function setAdmin(address _account, bool _flag) external onlyOwner {
    //     _flag ? grantRole(ADMIN_ROLE, _account) : revokeRole(ADMIN_ROLE, _account);
    // }

    function updatePrices(
        uint _stake,
        uint _lock,
        uint _update
    ) external onlyOwner {
        priceToStake = _stake;
        priceToLock = _lock;
        priceToUpdate = _update;
    }

    function updateTeamWallet(address _newWallet) external onlyOwner {
        teamWallet = _newWallet;
    }

    function setReferral(
        address[] memory _wallets,
        bool _flag
    ) external onlyOwner {
        for (uint i = 0; i < _wallets.length; i++) {
            referrals[_wallets[i]] = _flag;
        }
    }

    function setReferralRates(
        uint _discountRate,
        uint _sendingRate
    ) external onlyOwner {
        require(_discountRate <= 30 && _sendingRate <= 30, "exceeded rate");
        referralDiscountRate = _discountRate;
        referralSendingRate = _sendingRate;
    }
}