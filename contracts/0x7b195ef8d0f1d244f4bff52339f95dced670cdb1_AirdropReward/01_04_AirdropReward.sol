// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import {IERC20} from "./_external/IERC20.sol";
import "./_external/Ownable.sol";

interface IAirdropHelper {
    function userAirdrop(address user) external view returns (uint256);
}

interface IWFIRE {
    function deposit(uint256 fires) external returns (uint256);

    function burn(uint256 wfires) external returns (uint256);
}

/**
 * @title AirdropReward contract
 *
 * @notice Users can deposit upto their airdropped amount and receive 3x amount after endTime
 *
 */
contract AirdropReward is Ownable {
    IAirdropHelper public airdropHelper;
    IERC20 public WFIRE;
    IERC20 public FIRE;

    uint256 public startTime;
    uint256 public endTime;

    uint256 public multiplier; // 3e18 => 3x

    mapping(address => uint256) public userInfo; // WFIRE amount

    event Deposit(address indexed user, uint256 amount, uint256 wfireAmount);
    event Withdraw(address indexed user, uint256 amount, uint256 wfireAmount, uint256 fireAmount);

    uint8 entered;
    modifier nonReentrant() {
        require(entered == 0, "Already entered");
        entered = 1;
        _;
        entered = 0;
    }

    constructor() {
        initialize(msg.sender);
    }

    function setTokens(IERC20 _FIRE, IERC20 _WFIRE) external onlyOwner {
        FIRE = _FIRE;
        WFIRE = _WFIRE;
    }

    function setAirdropHelper(IAirdropHelper _airdropHelper) external onlyOwner {
        airdropHelper = _airdropHelper;
    }

    function setStartTime(uint256 time) external onlyOwner {
        startTime = time;
    }

    function setEndTime(uint256 time) external onlyOwner {
        endTime = time;
    }

    function setMultiplier(uint256 _multiplier) external onlyOwner {
        multiplier = _multiplier;
    }

    function adminWFIREWithdraw(uint256 amount) external onlyOwner {
        WFIRE.transfer(msg.sender, amount);
    }

    function adminFIREWithdraw(uint256 amount) external onlyOwner {
        FIRE.transfer(msg.sender, amount);
    }

    /**
     * @notice deposit FIRE
     *
     * amount {uint256} FIRE token amount
     */
    function deposit(uint256 amount) external nonReentrant {
        require(block.timestamp <= startTime, "Can't deposit");
        FIRE.transferFrom(msg.sender, address(this), amount);
        FIRE.approve(address(WFIRE), amount);
        uint256 wfireAmount = IWFIRE(address(WFIRE)).deposit(amount);
        require(
            userInfo[msg.sender] + wfireAmount <= airdropHelper.userAirdrop(msg.sender),
            "Reached Max"
        );

        userInfo[msg.sender] += wfireAmount;

        emit Deposit(msg.sender, amount, wfireAmount);
    }

    /**
     * @notice withdraw all
     */
    function withdraw() external nonReentrant {
        require(block.timestamp >= endTime, "Can't withdraw");
        require(userInfo[msg.sender] > 0, "Nothing");

        uint256 totalWFireAmount = (userInfo[msg.sender] * multiplier) / 1 ether;
        uint256 totalFireAmount = IWFIRE(address(WFIRE)).burn(totalWFireAmount);
        FIRE.transfer(msg.sender, totalFireAmount);

        emit Withdraw(msg.sender, userInfo[msg.sender], totalWFireAmount, totalFireAmount);

        userInfo[msg.sender] = 0;
    }
}