pragma solidity >=0.6.0 <0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../staking/RewardDistributor.sol";

interface IERC20Burnable {
    function burn(uint256 amount) external;
}

interface ITaxDistributor {
    function distributeTax(address token) external returns(bool);
}

contract TaxDistributor is ITaxDistributor, Ownable {
    using SafeMath for uint256;
    struct Distribution {
        uint8 stake;
        uint8 burn;
        uint8 future;
        uint8 dev;
    }

    Distribution distribution;
    IRewardDistributor rewardDistributor;
    address devAddress;
    address futureAddress;

    function setRewardDistributor(address _rewardDistributor)
    onlyOwner()
    external returns(bool) {
        IRewardDistributor rd = IRewardDistributor(_rewardDistributor);
        address someAddress = rd.rollAndGetDistributionAddress(msg.sender);
        require(someAddress != address(0), "StakeDevBurnTaxable: Bad reward distributor");
        rewardDistributor = rd;
        return true;
    }

    function setDevAddress(address _devAddress)
    onlyOwner()
    external returns(bool) {
        devAddress = _devAddress; // Allow 0
        return true;
    }

    function setFutureAddress(address _futureAddress)
    onlyOwner()
    external returns(bool) {
        futureAddress = _futureAddress; // Allow 0
        return true;
    }

    function setDefaultDistribution(uint8 stake, uint8 burn, uint8 dev, uint8 future)
    onlyOwner()
    external returns(bool) {
        require(stake+burn+dev+future == 100, "StakeDevBurnTaxable: taxes must add to 100");
        distribution = Distribution({ stake: stake, burn: burn, dev: dev, future: future });
    }

    /**
     * @dev Can be called by anybody, but make this contract is tax exempt.
     */
    function distributeTax(address token) external override returns(bool) {
        IERC20 _token = IERC20(token);
        return _distributeTax(_token, _token.balanceOf(address(this)));
    }

    function _distributeTax(IERC20 token, uint256 amount) internal returns(bool) {
        Distribution memory dist = distribution;
        uint256 remaining = amount;
        if (dist.burn != 0) {
            uint256 burnAmount = amount.mul(dist.burn).div(100);
            if (burnAmount != 0) {
                IERC20Burnable(address(token)).burn(burnAmount);
                remaining = remaining.sub(burnAmount);
            }
        }
        if (dist.dev != 0) {
            uint256 devAmount = amount.mul(dist.dev).div(100);
            if (devAmount != 0) {
                token.transfer(devAddress, devAmount);
                remaining = remaining.sub(devAmount);
            }
        }
        if (dist.future != 0) {
            uint256 futureAmount = amount.mul(dist.future).div(100);
            if (futureAmount != 0) {
                token.transfer(futureAddress, futureAmount);
                remaining = remaining.sub(futureAmount);
            }
        }
        if (dist.stake != 0) {
            uint256 stakeAmount = remaining;
            address stakeAddress = rewardDistributor.rollAndGetDistributionAddress(msg.sender);
            if (stakeAddress != address(0)) {
                token.transfer(stakeAddress, stakeAmount);
                bool res = rewardDistributor.updateRewards(stakeAddress);
                require(res, "StakeDevBurnTaxable: Error staking rewards");
            }
        }
        return true;
    }
}