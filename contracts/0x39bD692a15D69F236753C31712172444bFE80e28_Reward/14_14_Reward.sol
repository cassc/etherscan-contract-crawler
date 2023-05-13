// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/IReward.sol";
import "./interfaces/IAdmin.sol";
import "./Adminable.sol";
import "./lib/TransferHelper.sol";

contract Reward is IReward, Adminable, ReentrancyGuardUpgradeable {
    /**
     * @notice admin is address of admin contract
     */
    IAdmin public admin;

    /**
     * @notice Store budget of list collections in project
     * @dev adress of collection => budget of collection claim pool
     */
    mapping(address => mapping(address => uint256)) public rewardAmountOf;

    event Claimed(address indexed user, address paymentToken, uint256 reward);
    event RelaseReward(address paymentToken, address[] users, uint256[] rewards);

    /**
     * @notice Function initializer
     * @dev    Peplace for constructor
     * @param admin_ Address of the admin contract
     */
    function initialize(
        IAdmin admin_
    ) public initializer notZeroAddress(address(admin_)) {
        __Adminable_init();
        __ReentrancyGuard_init();
        admin = admin_;
        transferOwnership(admin.owner());
    }

    /**
     * @notice Receive function when contract receive native token from others
     */
    receive() external payable {}

    /**
     * @notice Release reward when user completed task
     * @dev    Only admin can call this  function
     * @param paymentToken Address of payment token (address(0) for native token)
     * @param users List of users
     * @param rewards List rewards of users
     *
     * emit {RelaseReward} events
     */
    function releaseReward(
        address paymentToken,
        address[] calldata users,
        uint256[] calldata rewards
    ) external onlyAdmin {
        require(users.length > 0 && users.length == rewards.length, "Invalid length");
        require(admin.isPermittedPaymentToken(paymentToken), "Payment token is not allowed");
        for (uint256 i = 0; i < users.length; ++i) {
            rewardAmountOf[users[i]][paymentToken] += rewards[i];
        }

        emit RelaseReward(paymentToken, users, rewards);
    }

    /**
     * @notice Claim reward
     */
    function claim(address paymentToken) external nonReentrant {
        uint256 reward = rewardAmountOf[_msgSender()][paymentToken];
        require(reward > 0, "Nothing to claim");

        rewardAmountOf[_msgSender()][paymentToken] = 0;

        TransferHelper._transferToken(paymentToken, reward, address(this), _msgSender());

        emit Claimed(_msgSender(), paymentToken, reward);
    }
}