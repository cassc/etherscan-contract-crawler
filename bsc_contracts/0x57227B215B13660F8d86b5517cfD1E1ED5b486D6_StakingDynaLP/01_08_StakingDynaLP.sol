// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPancakePair.sol";
import "./interfaces/IPancakeRouter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract StakingDynaLP is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath for uint112;

    uint256 public apr = 4800;
    uint256 constant RATE_PRECISION = 10000;
    uint256 constant ONE_YEAR_IN_SECONDS = 365 * 24 * 60 * 60;
    uint256 constant ONE_DAY_IN_SECONDS = 24 * 60 * 60;

    uint256 constant PERIOD_PRECISION = 10000;
    IERC20 public token;
    IPancakeRouter public router;
    IPancakePair public pair;

    bool public enabled;

    modifier noContract() {
        require(
            tx.origin == msg.sender,
            "StakingDynaLP: Contract not allowed to interact"
        );
        _;
    }

    event Deposit(address indexed user, uint256 amount);
    event Redeem(address indexed user, uint256 amount);

    constructor(
        address _pair,
        address _router,
        address _token
    ) {
        pair = IPancakePair(_pair);
        router = IPancakeRouter(_router);
        token = IERC20(_token);
        enabled = false;
    }

    struct StakeDetail {
        uint256 principal;
        uint256 lastProcessAt;
        uint256 pendingReward;
        uint256 firstStakeAt;
    }

    mapping(address => StakeDetail) public stakers;

    function setEnabled(bool _enabled) external onlyOwner {
        enabled = _enabled;
    }

    function updateAPR(uint256 _apr) external onlyOwner {
        apr = _apr;
    }

    function emergencyWithdraw(uint256 _amount) external onlyOwner {
        token.transfer(msg.sender, _amount);
    }

    function getStakeDetail(address _staker)
        public
        view
        returns (
            uint256 principal,
            uint256 lastProcessAt,
            uint256 pendingReward,
            uint256 firstStakeAt
        )
    {
        StakeDetail memory stakeDetail = stakers[_staker];
        return (
            stakeDetail.principal,
            stakeDetail.lastProcessAt,
            stakeDetail.pendingReward,
            stakeDetail.firstStakeAt
        );
    }

    function getInterest(address _staker) public view returns (uint256) {
        StakeDetail memory stakeDetail = stakers[_staker];
        uint256 duration = block.timestamp.sub(stakeDetail.lastProcessAt);
        uint256 interest = stakeDetail
            .principal
            .mul(apr)
            .mul(duration)
            .div(ONE_YEAR_IN_SECONDS)
            .div(RATE_PRECISION);
        return interest;
    }

    function getTokenRewardInterest(address _staker)
        external
        view
        returns (uint256)
    {
        return
            getInterest(_staker).mul(getPairPrice()).div(1e18).add(
                stakers[_staker].pendingReward
            );
    }

    function deposit(uint256 _stakeAmount) external nonReentrant noContract {
        require(enabled, "Staking is not enabled");
        require(
            _stakeAmount > 0,
            "StakingDynaLP: stake amount must be greater than 0"
        );
        pair.transferFrom(msg.sender, address(this), _stakeAmount);
        StakeDetail storage stakeDetail = stakers[msg.sender];
        if (stakeDetail.firstStakeAt == 0) {
            stakeDetail.principal = stakeDetail.principal.add(_stakeAmount);
            stakeDetail.firstStakeAt = stakeDetail.firstStakeAt == 0
                ? block.timestamp
                : stakeDetail.firstStakeAt;
        } else {
            uint256 interest = getInterest(msg.sender);
            stakeDetail.principal = stakeDetail.principal.add(_stakeAmount).add(
                interest
            );
        }
        stakeDetail.lastProcessAt = block.timestamp;

        emit Deposit(msg.sender, _stakeAmount);
    }

    function getPairPrice() public view returns (uint256) {
        uint112 reserve0;
        uint112 reserve1;
        (reserve0, reserve1, ) = pair.getReserves();

        uint256 totalPoolValue = reserve1.mul(2);
        uint256 mintedPair = pair.totalSupply();
        uint256 pairPriceInETH = totalPoolValue.mul(1e18).div(mintedPair);
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(token);
        uint256[] memory amounts = router.getAmountsOut(pairPriceInETH, path);
        return amounts[1];
    }

    function redeem(uint256 _redeemAmount) external nonReentrant noContract {
        require(enabled, "Staking is not enabled");
        StakeDetail storage stakeDetail = stakers[msg.sender];
        require(stakeDetail.firstStakeAt > 0, "StakingDynaLP: no stake");
        uint256 interest = getInterest(msg.sender);
        uint256 claimAmount = interest.mul(_redeemAmount).div(
            stakeDetail.principal
        );
        uint256 claimAmountInToken = claimAmount.mul(getPairPrice()).div(1e18);

        uint256 remainAmount = interest.sub(claimAmount);
        uint256 remainAmountInToken = remainAmount.mul(getPairPrice()).div(
            1e18
        );

        stakeDetail.lastProcessAt = block.timestamp;
        require(
            stakeDetail.principal >= _redeemAmount,
            "StakingDynaLP: redeem amount must be less than principal"
        );
        stakeDetail.pendingReward = remainAmountInToken;
        stakeDetail.principal = stakeDetail.principal.sub(_redeemAmount);
        require(
            pair.transfer(msg.sender, _redeemAmount),
            "StakingDynaLP: transfer failed"
        );
        require(
            token.transfer(msg.sender, claimAmountInToken),
            "StakingDynaLP: reward transfer failed"
        );
        emit Redeem(msg.sender, _redeemAmount);
    }
}