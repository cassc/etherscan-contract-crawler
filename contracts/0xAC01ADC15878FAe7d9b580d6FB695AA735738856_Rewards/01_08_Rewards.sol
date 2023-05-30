// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IBarn.sol";

contract Rewards is Ownable {
    using SafeMath for uint256;

    uint256 constant decimals = 10 ** 18; // Same as SWINGBY token's decimal
    uint256 constant oneYear = 31536000;
    struct Pull {
        address source;
        uint256 startTs;
        uint256 endTs;
        uint256 totalDuration;
    }

    Pull public pullFeature;
    bool public disabled;
    uint256 public lastPullTs;
    uint256 public apr;

    uint256 public balanceBefore;
    uint256 public currentMultiplier;

    mapping(address => uint256) public userMultiplier;
    mapping(address => uint256) public owed;

    IBarn public barn;
    IERC20 public rewardToken;

    event Claim(address indexed user, uint256 amount);

    constructor(address _owner, address _swingby, address _barn, uint256 _apr) {
        require(_swingby != address(0), "reward token must not be 0x0");
        require(_barn != address(0), "barn address must not be 0x0");

        transferOwnership(_owner);

        rewardToken = IERC20(_swingby);
        barn = IBarn(_barn);
        apr = _apr;
    }

    // registerUserAction is called by the Barn every time the user does a deposit or withdrawal in order to
    // account for the changes in reward that the user should get
    // it updates the amount owed to the user without transferring the funds
    function registerUserAction(address user) public {
        require(msg.sender == address(barn), 'only callable by barn');

        _calculateOwed(user);
    }

    // claim calculates the currently owed reward and transfers the funds to the user
    function claim() public returns (uint256){
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
        uint256 multiplier = currentMultiplier.add(diff.mul(decimals).div(totalStakedBond));

        balanceBefore = balanceNow;
        currentMultiplier = multiplier;
    }

    // setupPullToken is used to setup the rewards system; only callable by contract owner
    // set source to address(0) to disable the functionality
    function setupPullToken(address source, uint256 startTs, uint256 endTs) public {
        require(msg.sender == owner(), "!owner");
        require(!disabled, "contract is disabled");

        require(endTs.sub(startTs) == oneYear, "endTs.sub(startTs) != 1year");

        if (pullFeature.source != address(0)) {
            require(source == address(0), "contract is already set up, source must be 0x0");
            disabled = true;
        } else {
            require(source != address(0), "contract is not setup, source must be != 0x0");
        }

        if (source == address(0)) {
            require(startTs == 0, "disable contract: startTs must be 0");
            require(endTs == 0, "disable contract: endTs must be 0");
        } else {
            require(endTs > startTs, "setup contract: endTs must be greater than startTs");
        }
        pullFeature.source = source;
        pullFeature.startTs = startTs;
        pullFeature.endTs = endTs;
        // duration must be 1Y always. (For calculate SWINGBY APY)
        pullFeature.totalDuration = endTs.sub(startTs);

        if (lastPullTs < startTs) {
            lastPullTs = startTs;
        }
    }

    // setBarn sets the address of the BarnBridge Barn into the state variable
    function setBarn(address _barn) public {
        require(_barn != address(0), 'barn address must not be 0x0');
        require(msg.sender == owner(), '!owner');

        barn = IBarn(_barn);
    }

    function setNewAPR(uint256 _apr) public {
        require(msg.sender == owner(), "!owner");
        apr = _apr;
        if (apr == 0) {
            // send all remain tokens to owner (expected governance contract.)
            uint256 amountToPull = rewardToken.balanceOf(address(pullFeature.source));
            rewardToken.transferFrom(pullFeature.source, owner(), amountToPull);
        }
    }

    // _pullToken calculates the amount based on the time passed since the last pull relative
    // to the total amount of time that the pull functionality is active and executes a transferFrom from the
    // address supplied as `pullTokenFrom`, if enabled
    function _pullToken() internal {
        if (
            pullFeature.source == address(0) ||
            block.timestamp < pullFeature.startTs
        ) {
            return;
        }

        uint256 timestampCap = pullFeature.endTs;
        if (block.timestamp < pullFeature.endTs) {
            timestampCap = block.timestamp;
        }

        if (lastPullTs >= timestampCap) {
            return;
        }

        uint256 timeSinceLastPull = timestampCap.sub(lastPullTs);
        // extends pullFeature.totalDuration
        pullFeature.totalDuration = pullFeature.totalDuration.add(timeSinceLastPull);

        uint256 totalStakedBond = barn.bondStaked();
        // use required amount instead of pullFeature.totalAmount for calculate SWINGBY static APY for stakers
        uint256 requiredAmountFor1Y = totalStakedBond.mul(apr).div(100);

        uint256 shareToPull = timeSinceLastPull.mul(decimals).div(pullFeature.totalDuration);
        uint256 amountToPull = requiredAmountFor1Y.mul(shareToPull).div(decimals);

        lastPullTs = block.timestamp;
        rewardToken.transferFrom(pullFeature.source, address(this), amountToPull);
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