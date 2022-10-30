//SPDX-License-Identifier: MIT

/**
 * Staking Contract:
 * 1- holders of Radiate token can stake their tokens in this contract and receive an APY of 180%
 * 2- rewards are paid from staking vault
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity 0.8.8;

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

contract ForgeStaking is Ownable, DSMath {
    //  So we said were doing the tier system, so for the first tier no time limit, 2nd is 7 days, 3rd is 14 days, 4th is 30 days
    // ex : No unstake limit : 50% APY , 7 days : 75% APY , 14 days : 100% APY , 30 days : 160% APY ?
    //On the dapp/website for staking call the tiers of staking : 1. Electromagnetic Staking, 2. Neutron Staking, 3. Beta Staking, 4. Alpha Staking
    struct Pool {
        uint256 Id;
        uint256 APY;
        uint256 MinTime;
    }

    struct StakeProfile {
        uint256 totalStaked;
        uint256 stakeEnd;
        uint256 stakeId;
        uint256 paidRewards;
        uint256 stakeStart;
    }

    //Pool Electromagnetic
    Pool private Bronze = Pool(0, 50, 0);
    //Pool Neutron
    Pool private Gold = Pool(0, 75, 7 days);
    //Pool Beta
    Pool private Platinum = Pool(0, 100, 14 days);
    //Pool Alpha
    Pool private Diamond = Pool(0, 160, 30 days);

    mapping(uint256=>Pool) Pools;

    //Staking Settings
    IERC20 public stakingToken;
    address public stakingVault;

    //Stakers
    uint256 public totalStaked;
    mapping(uint256=>mapping(address=>StakeProfile)) stakers;


    constructor() {
        Pools[0] = Bronze;
        Pools[1] = Gold;
        Pools[2] = Platinum;
        Pools[3] = Diamond;
    }


    function stake(uint256 _stakeNumber, uint256 poolId) external {
        //Validating...
        require(_stakeNumber > 0, "can not stake 0 tokens!");
        require(poolId < 4, "Invalid Pool!");

        //Getting corresponding stake pool
        Pool memory targetPool = Pools[poolId];

        //updating staker profile:
        StakeProfile memory profile = stakers[poolId][msg.sender];
        //Adding tokens to staker profile
        profile.totalStaked += _stakeNumber;
        //Setting stake end time but first making sure that we are not overwriting it!
        if(profile.stakeEnd == 0){
            profile.stakeEnd = block.timestamp + targetPool.MinTime;
        }
        //Setting stake start time if not already set
        if(profile.stakeStart == 0){
            profile.stakeStart = block.timestamp;
        }
        //setting stake Id
        profile.stakeId = poolId;
 
        stakers[poolId][msg.sender] = profile;

        //Transfering tokens and increasing total staked amount
        totalStaked += _stakeNumber;
        stakingToken.transferFrom(msg.sender, address(this), _stakeNumber);
    }


    function unstake(uint256 _unstakeNumber, uint256 poolId) external {
        //getting corresponding stake profile
        StakeProfile memory profile = stakers[poolId][msg.sender];

        //Validating
        require(profile.totalStaked >= _unstakeNumber, "Can't unstake more than balance.");
        require(block.timestamp >= profile.stakeEnd, "Can't unstake before end time!");
        require(poolId < 4, "Invalid Pool!");

        //calculating rewards if there is any
        uint256 totalRewards = getRewards(msg.sender, poolId);

        //Updating staker profile
        //- Reducing unstake amount
        profile.totalStaked -= _unstakeNumber;

        if(totalRewards > 0){
            profile.paidRewards += totalRewards;
        }

        //- Reseting time if unstaked all
        if(profile.totalStaked == 0){
            profile.stakeEnd = 0;
            profile.stakeStart = 0;
            profile.paidRewards = 0;
        }
        //- Writing updated profile to storage
        stakers[poolId][msg.sender] = profile;

        //- Reducing from total staked
        totalStaked -= _unstakeNumber;

        //sending tokens to staker
        if(stakingToken.balanceOf(stakingVault) >= totalRewards && totalRewards > 0){
            stakingToken.transferFrom(stakingVault, msg.sender, totalRewards);
        }
        stakingToken.transfer(msg.sender, _unstakeNumber);
    }

    //Setters
    function setStakingVault(address newVault) external onlyOwner{
        stakingVault = newVault;
    }

    function setStakingToken(address newStakingToken) external onlyOwner{
        stakingToken = IERC20(newStakingToken);
    }

    //Getters
    function getRewards(address _staker, uint256 poolId) public view returns(uint256){
        //getting corresponding stake profile
        StakeProfile memory profile = stakers[poolId][_staker];
        if(profile.totalStaked == 0){
            return 0;
        }
        uint256 elapsedTime = block.timestamp - profile.stakeStart;
        uint256 apy = Pools[poolId].APY;
        uint256 Interest = calculateInteresetInSeconds(profile.totalStaked, apy, elapsedTime);
        if(Interest > profile.totalStaked + profile.paidRewards){
            return Interest - (profile.totalStaked + profile.paidRewards);
        }else{
            return 0;
        }
    }

    //put apy in %, example : 100% == 100, 160% = 160
    function calculateInteresetInSeconds(uint256 principal, uint256 apy, uint256 _seconds) public pure returns(uint256){
        //Calculating the ratio per second
        //ratio per seconds
        uint256 _ratio = ratio(apy);
        //Interest after _seconds
        return accrueInterest(principal, _ratio, _seconds);
    }

    function ratio(uint256 n) internal pure returns(uint256){
        uint256 numerator = n * 10 ** 25;
        uint256 denominator = 365 * 86400;
        uint256 result = uint256(10 ** 27) + uint256(numerator / denominator);
        return result;
    }

    function accrueInterest(uint _principal, uint _rate, uint _age) internal pure returns (uint) {
        return rmul(_principal, rpow(_rate, _age));
    }

    function getStakerProfile(address _staker, uint256 _poolId) public view returns(StakeProfile memory){
        return stakers[_poolId][_staker];
    }

    function getPoolInfo(uint256 poolId) public view returns(Pool memory){
        return Pools[poolId];
    }

    function getStakedInPool(address account, uint256 poolId) public view returns(uint256){
        return stakers[poolId][account].totalStaked;
    }
}