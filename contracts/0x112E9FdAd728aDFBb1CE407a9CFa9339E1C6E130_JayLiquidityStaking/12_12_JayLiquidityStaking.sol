// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import {JayFeeSplitter} from "./JayFeeSplitter.sol";

contract JayLiquidityStaking is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    JayFeeSplitter FEE_ADDRESS;

    uint256 private constant FACTOR = 10 ** 18;

    IERC20 public immutable liquidityToken;

    struct UserInfo {
        uint256 shares; // shares of token staked
        uint256 rewardPerTokenOnEntry; // user reward per token paid
    }

    // Reward per token stored
    uint256 public rewardPerTokenStored;

    uint256 public totalAmountStaked;

    uint256 public previusRewardTotal;

    mapping(address => UserInfo) public userInfo;

    bool public init = false;

    bool public start = false;

    event Deposit(address indexed user, uint256 amount);
    event Harvest(address indexed user, uint256 harvestedAmount);
    event Withdraw(address indexed user, uint256 amount);

    constructor(address _liquidityToken) {
        liquidityToken = IERC20(_liquidityToken);
    }

    function setFeeAddress(address _address) external onlyOwner {
        require(_address != address(0x0));
        FEE_ADDRESS = JayFeeSplitter(payable(_address));
    }

    function initalize(
        uint256 _initialLPs,
        address[] memory _addresses,
        uint256[] memory _balances
    ) public onlyOwner {
        require(!init, "Contract already initialized");
        init = true;
        uint256 total = 0;
        for (uint256 i = 0; i < _addresses.length; i++) {
            userInfo[_addresses[i]] = UserInfo({
                shares: _balances[i],
                rewardPerTokenOnEntry: 0
            });

            total += _balances[i];
        }
        require(total == _initialLPs, "Totals dont match");
        totalAmountStaked = total;
        liquidityToken.transferFrom(msg.sender, address(this), _initialLPs);
    }

        
    // start trading
    function setStart() public onlyOwner {
        start = true;
    }

    /*
     * Name: sendEth
     * Purpose: Tranfer ETH tokens
     * Parameters:
     *    - @param 1: Address
     *    - @param 2: Value
     * Return: n/a
     */
    function sendEth(uint256 _value) private {
        (bool success, ) = msg.sender.call{value: _value}("");
        require(success, "ETH Transfer failed.");
    }

    /**
     * @notice Claim reward tokens that are pending
     */
    function claim() private returns (uint256) {
        // Retrieve pending rewards
        FEE_ADDRESS.splitFees();

        // Get the balance of the contract
        uint256 contractBalance = address(this).balance;

        // Update rewardPerTokenStored in contract state after rewards are added from FEE_ADDRESS
        rewardPerTokenStored =
            rewardPerTokenStored +
            ((contractBalance - previusRewardTotal) * (FACTOR)) /
            (totalAmountStaked);

        // Get the users pending rewards based on their current share balance
        uint256 pendingRewards = (userInfo[msg.sender].shares *
            (rewardPerTokenStored -
                userInfo[msg.sender].rewardPerTokenOnEntry)) / (FACTOR);

        // Save the contract balance so it equals the balaance AFTER the users eth is tranfered in deposit/withdraw
        previusRewardTotal = contractBalance - (pendingRewards);

        emit Harvest(msg.sender, pendingRewards);
        return pendingRewards;
    }

    /**
     * @notice Deposit staked tokens and collect reward tokens
     */
    function deposit(uint256 amount) external nonReentrant {
        // Get the users pending rewards and update contract state
        // If no tokens are currently staked reset the contract
        uint256 pendingRewards = 0;
        if (totalAmountStaked > 0) pendingRewards = claim();
        else {
            rewardPerTokenStored = 0;
            previusRewardTotal = 0;
        }

        // Update the users share information
        userInfo[msg.sender].shares += amount;
        _setUserEntry();

        // Increase totalAmountStaked
        totalAmountStaked += amount;

        // Transfer liquidity from user to contract
        liquidityToken.safeTransferFrom(msg.sender, address(this), amount);

        // Send pending eth reward to user
        if (pendingRewards > 0) {
            sendEth(pendingRewards);
        }
        emit Deposit(msg.sender, amount);
    }

    /**
     * @notice Withdraw staked tokens and collect reward tokens
     */
    function withdraw(uint256 amount) external nonReentrant {
        require(start);
        // Get the users pending rewards and update contract state
        uint256 pendingRewards = claim();

        // Update the users share information
        userInfo[msg.sender].shares -= amount;
        _setUserEntry();

        // Adjust total amount staked
        totalAmountStaked -= amount;

        // Transfer liquidity to user from contract
        liquidityToken.safeTransfer(msg.sender, amount);

        // Send pending eth reward to user
        if (pendingRewards > 0) {
            sendEth(pendingRewards);
        }

        emit Withdraw(msg.sender, amount);
    }

    function getReward(address _address) public view returns (uint256) {
        if (totalAmountStaked > 0) {
            uint256 _rewardPerTokenStored = rewardPerTokenStored +
                ((address(this).balance +
                    (address(FEE_ADDRESS).balance) -
                    (previusRewardTotal)) * (FACTOR)) /
                (totalAmountStaked);

            return
                (userInfo[_address].shares *
                    (_rewardPerTokenStored -
                        userInfo[_address].rewardPerTokenOnEntry)) / (FACTOR);
        } else {
            return 0;
        }
    }

    function _setUserEntry() internal {
        if (userInfo[msg.sender].shares == 0) {
            userInfo[msg.sender].rewardPerTokenOnEntry = 0;
        } else {
            userInfo[msg.sender].rewardPerTokenOnEntry = rewardPerTokenStored;
        }
    }

    function getStaked(address _address) public view returns (uint256) {
        return userInfo[_address].shares;
    }

    function getTotalStaked() public view returns (uint256) {
        return totalAmountStaked;
    }

    function getBal() public view returns (uint256) {
        return address(this).balance;
    }

    function getRewardPerTokenStored() public view returns (uint256) {
        if (totalAmountStaked > 0)
            return
                rewardPerTokenStored +
                ((address(this).balance +
                    (address(FEE_ADDRESS).balance) -
                    (previusRewardTotal)) * (FACTOR)) /
                (totalAmountStaked);
        else return 0;
    }

    receive() external payable {}
}