// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IBarn.sol";
import "./interfaces/ISwapContract.sol";

contract NodeRewards is Ownable {
    using SafeMath for uint256;

    uint256 constant decimals = 10**18; // Same as SWINGBY token's decimal
    uint256 constant oneYear = 31536000;

    address public source;
    uint256 public lastPullTs;
    uint256 public apr;

    uint256 public balanceBefore;
    uint256 public currentMultiplier;

    uint256 public totalNodeStaked;

    mapping(address => uint256) public userMultiplier;
    mapping(address => uint256) public owed;

    IBarn public barn;
    IERC20 public immutable rewardToken;
    ISwapContract public swapContract;

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
        source = _source;
        apr = _apr;
    }

    function setNewAPR(uint256 _apr) public {
        require(msg.sender == owner(), "!owner");
        _pullToken();
        ackFunds();
        apr = _apr;
    }

    function emergencyWithdraw() public {
        require(msg.sender == owner(), "!owner");
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
    }

    // setBarn sets the address of the BarnBridge Barn into the state variable
    function setBarnAndSwap(
        address _barn,
        address _swap,
        uint256 _startTs
    ) public {
        require(_barn != address(0), "barn address must not be 0x0");
        require(_swap != address(0), "swap contract address must not be 0x0");
        require(msg.sender == owner(), "!owner");
        swapContract = ISwapContract(_swap);
        barn = IBarn(_barn);
        lastPullTs = _startTs;
    }

    function resetUnstakedNode(address _node) public {
        require(!swapContract.isNodeStake(_node), "node is staker");
        userMultiplier[_node] = currentMultiplier;
    }

    // check all active nodes to calculate current stakes.
    function updateNodes() public returns (bool isStaker) {
        address[] memory nodes = swapContract.getActiveNodes();
        uint256 newTotalNodeStaked;
        for (uint256 i = 0; i < nodes.length; i++) {
            newTotalNodeStaked = newTotalNodeStaked.add(
                barn.balanceOf(nodes[i])
            );
            if (msg.sender == nodes[i]) {
                isStaker = true;
            }
            if (userMultiplier[nodes[i]] == 0) {
                userMultiplier[nodes[i]] = currentMultiplier;
            }
        }
        // only change when stakers had actions.
        if (totalNodeStaked != newTotalNodeStaked) {
            totalNodeStaked = newTotalNodeStaked;
        }
    }

    // claim calculates the currently owed reward and transfers the funds to the user
    function claim() public returns (uint256) {
        require(updateNodes(), "caller is not node");

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

    function _pullToken() internal {
        uint256 timeSinceLastPull = block.timestamp.sub(lastPullTs);
        // use required amount instead of pullFeature.totalAmount for calculate SWINGBY static APY for stakers
        uint256 requiredAmountFor1Y = totalNodeStaked.mul(apr).div(100);

        uint256 shareToPull = timeSinceLastPull.mul(decimals).div(oneYear);
        uint256 amountToPull = requiredAmountFor1Y.mul(shareToPull).div(
            decimals
        );

        lastPullTs = block.timestamp;
        rewardToken.transferFrom(source, address(this), amountToPull);
    }

    function ackFunds() public {
        uint256 balanceNow = rewardToken.balanceOf(address(this));

        if (balanceNow == 0 || balanceNow <= balanceBefore) {
            balanceBefore = balanceNow;
            return;
        }
        if (totalNodeStaked == 0) {
            return;
        }

        uint256 diff = balanceNow.sub(balanceBefore);
        uint256 multiplier = currentMultiplier.add(
            diff.mul(decimals).div(totalNodeStaked)
        );

        balanceBefore = balanceNow;
        currentMultiplier = multiplier;
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