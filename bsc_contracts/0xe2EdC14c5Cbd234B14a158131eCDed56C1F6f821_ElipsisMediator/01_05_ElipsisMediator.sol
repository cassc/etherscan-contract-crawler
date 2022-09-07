// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

interface Elipsis {
    function addReward(address _rewardsToken, address _rewardsDistributor, uint256 _rewardsDuration) external;
    function setRewardsDistributor(address _rewardsToken, address _rewardsDistributor) external;
    function setDepositContract(address _account, bool _isDepositContract) external;
    function notifyRewardAmount(address _rewardsToken, uint256 reward) external;
    function setRewardsDuration(address _rewardsToken, uint256 _rewardsDuration) external;
}

contract ElipsisMediator is Initializable{

    using SafeERC20Upgradeable for IERC20Upgradeable;

    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external auth { require(live == 1, "Mediator/not-live"); wards[usr] = 1; }
    function deny(address usr) external auth { require(live == 1, "Mediator/not-live"); wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Mediator/not-authorized");
        _;
    }

    // --- Operators ---
    mapping (address => uint) public operators;
    function relyOperator(address usr) external auth { require(live == 1, "Mediator/not-live"); operators[usr] = 1; }
    function denyOperator(address usr) external auth { require(live == 1, "Mediator/not-live"); operators[usr] = 0; }
    modifier authOrOperator {
        require(wards[msg.sender] == 1 || operators[msg.sender] == 1, "Mediator/not-operator");
        _;
    }

    // --- Vars ---
    Elipsis public target;
    uint256 public live;  // Active Flag

    // --- Init ---
    function initialize(address targetContract) public initializer {
        wards[msg.sender] = 1;
        target = Elipsis(targetContract);
        live = 1;
    }

    // --- Admin ---
    function changeTargetContract(address targetContract) external auth {
        require(live == 1, "mediator/not-live");
        target = Elipsis(targetContract);
    }

    // --- Mediator Functions ---
    function notifyRewardAmount(address _rewardsToken, uint256 reward) external authOrOperator {
        require(live == 1, "mediator/not-live");
        IERC20Upgradeable(_rewardsToken).safeTransferFrom(msg.sender, address(this), reward);
        IERC20Upgradeable(_rewardsToken).approve(address(target), reward);
        target.notifyRewardAmount(_rewardsToken, reward);
    }
    function setRewardsDuration(address _rewardsToken, uint256 _rewardsDuration) external authOrOperator {
        require(live == 1, "mediator/not-live");
        target.setRewardsDuration(_rewardsToken, _rewardsDuration);
    }
}