// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IBarn.sol";
import "./interfaces/INodeRewards.sol";
import "./interfaces/ISwapContract.sol";

contract sbBTCPool is Ownable {
    using SafeMath for uint256;

    uint256 constant divisor = 10 ** 27;

    uint256 public balanceBefore;
    uint256 public currentMultiplier;

    mapping(address => uint256) public userMultiplier;
    mapping(address => uint256) public owed;

    IBarn public barn;
    IERC20 public rewardToken;
    INodeRewards public nodeRewards;
    ISwapContract public swapContract;

    event Claim(address indexed user, uint256 amount);

    // setup sets the contracts
    function setup(address _swap, address _barn, address _nodeRewards) public {
        require(_swap != address(0), "swapContract address must not be 0x0");
        require(_barn != address(0), "barn address must not be 0x0");
        require(msg.sender == owner(), "!owner");
        require(address(rewardToken) == address(0), "rewardToken must be 0x0");

        swapContract = ISwapContract(_swap);
        rewardToken = IERC20(swapContract.lpToken());
        nodeRewards = INodeRewards(_nodeRewards);
        barn = IBarn(_barn);
    }

    // claim calculates the currently owed reward and transfers the funds to the user
    function claim() public returns (uint256){
        require(swapContract.isNodeStake(msg.sender), "msg.sender is not staker");

        _calculateOwed(msg.sender);

        uint256 amount = owed[msg.sender];
        require(amount > 0, "nothing to claim");

        owed[msg.sender] = 0;

        rewardToken.transfer(msg.sender, amount);

        // acknowledge the amount that was transferred to the user
        ackFunds();

        emit Claim(msg.sender, amount);

        return amount;
    }

    // ackFunds checks the difference between the last known balance of `token` and the current one
    // if it goes up, the multiplier is re-calculated
    // if it goes down, it only updates the known balance
    function ackFunds() public {
        uint256 balanceNow = rewardToken.balanceOf(address(this));

        if (balanceNow == 0 || balanceNow <= balanceBefore) {
            balanceBefore = balanceNow;
            return;
        }

        uint256 totalStaked = nodeRewards.totalNodeStaked();
        // if there's no bond staked, it doesn't make sense to ackFunds because there's nobody to distribute them to
        // and the calculation would fail anyways due to division by 0
        if (totalStaked == 0) {
            return;
        }

        uint256 diff = balanceNow.sub(balanceBefore);
        uint256 multiplier = currentMultiplier.add(diff.mul(divisor).div(totalStaked));

        balanceBefore = balanceNow;
        currentMultiplier = multiplier;
    }

    // _calculateOwed calculates and updates the total amount that is owed to an user and updates the user's multiplier
    // to the current value
    // it automatically attempts to pull the token from the source and acknowledge the funds
    function _calculateOwed(address user) internal {
        ackFunds();

        uint256 reward = _userPendingReward(user);

        owed[user] = owed[user].add(reward);
        userMultiplier[user] = currentMultiplier;
    }

    // _userPendingReward calculates the reward that should be based on the current multiplier / anything that's not included in the `owed[user]` value
    // it does not represent the entire reward that's due to the user unless added on top of `owed[user]`
    function _userPendingReward(address user) internal view returns (uint256) {

        uint256 multiplier = currentMultiplier.sub(userMultiplier[user]);

        return barn.balanceOf(user).mul(multiplier).div(divisor);
    }
}