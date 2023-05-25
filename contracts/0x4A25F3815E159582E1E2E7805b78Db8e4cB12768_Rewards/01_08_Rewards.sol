// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IBarn.sol";

contract Rewards is Ownable {
    using SafeMath for uint256;

    uint256 constant decimals = 10**18; // Same as SWINGBY token's decimal
    uint256 constant oneYear = 31536000;

    address public source;
    uint256 public lastPullTs;
    uint256 public apr;

    uint256 public balanceBefore;
    uint256 public currentMultiplier;

    mapping(address => uint256) public userMultiplier;
    mapping(address => uint256) public owed;

    IBarn public barn;
    IERC20 public rewardToken;

    event Claim(address indexed user, uint256 amount);

    constructor(
        address _owner,
        address _swingby,
        uint256 _apr,
        address _source
    ) {
        require(_swingby != address(0), "reward token must not be 0x0");
        transferOwnership(_owner);
        rewardToken = IERC20(_swingby);
        apr = _apr;
        source = _source;
    }

    // setBarn sets the address of the BarnBridge Barn into the state variable
    function setBarn(address _barn, uint256 _startTs) public {
        require(_barn != address(0), "barn address must not be 0x0");
        require(msg.sender == owner(), "!owner");
        barn = IBarn(_barn);
        lastPullTs = _startTs;
    }

    function setNewAPR(uint256 _apr) public {
        require(msg.sender == owner(), "!owner");
        apr = _apr;
    }

    function emergencyWithdraw() public {
        require(msg.sender == owner(), "!owner");
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
    }

    // registerUserAction is called by the Barn every time the user does a deposit or withdrawal in order to
    // account for the changes in reward that the user should get
    // it updates the amount owed to the user without transferring the funds
    function registerUserAction(address user) public {
        require(msg.sender == address(barn), "only callable by barn");

        _calculateOwed(user);
    }

    // claim calculates the currently owed reward and transfers the funds to the user
    function claim() public returns (uint256) {
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

        uint256 totalStakedBond = barn.bondStaked();
        // if there's no bond staked, it doesn't make sense to ackFunds because there's nobody to distribute them to
        // and the calculation would fail anyways due to division by 0
        if (totalStakedBond == 0) {
            return;
        }

        uint256 diff = balanceNow.sub(balanceBefore);
        uint256 multiplier = currentMultiplier.add(
            diff.mul(decimals).div(totalStakedBond)
        );

        balanceBefore = balanceNow;
        currentMultiplier = multiplier;
    }

    // _pullToken calculates the amount based on the time passed since the last pull relative
    // to the total amount of time that the pull functionality is active and executes a transferFrom from the
    // address supplied as `pullTokenFrom`, if enabled
    function _pullToken() internal {
        uint256 timeSinceLastPull = block.timestamp.sub(lastPullTs);

        uint256 totalStakedBond = barn.bondStaked();
        // use required amount instead of pullFeature.totalAmount for calculate SWINGBY static APY for stakers
        uint256 requiredAmountFor1Y = totalStakedBond.mul(apr).div(100);

        uint256 shareToPull = timeSinceLastPull.mul(decimals).div(oneYear);
        uint256 amountToPull = requiredAmountFor1Y.mul(shareToPull).div(
            decimals
        );

        lastPullTs = block.timestamp;
        rewardToken.transferFrom(source, address(this), amountToPull);
    }

    // _calculateOwed calculates and updates the total amount that is owed to an user and updates the user's multiplier
    // to the current value
    // it automatically attempts to pull the token from the source and acknowledge the funds
    function _calculateOwed(address user) internal {
        _pullToken();
        ackFunds();

        uint256 reward = _userPendingReward(user);

        owed[user] = owed[user].add(reward);
        userMultiplier[user] = currentMultiplier;
    }

    // _userPendingReward calculates the reward that should be based on the current multiplier / anything that's not included in the `owed[user]` value
    // it does not represent the entire reward that's due to the user unless added on top of `owed[user]`
    function _userPendingReward(address user) internal view returns (uint256) {
        uint256 multiplier = currentMultiplier.sub(userMultiplier[user]);
        return barn.balanceOf(user).mul(multiplier).div(decimals);
    }
}