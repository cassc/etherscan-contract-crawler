// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import {PEPAYFeeSplitter} from "./JayDerivFeeSplitter.sol";
import {PEPAY} from "./JayDeriv.sol";

contract PEPAYLiquidityStaking is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    PEPAYFeeSplitter public FEE_ADDRESS;


    uint256 private constant FACTOR = 10 ** 18;
    uint256 public immutable START_DATE;

    IERC20 public immutable liquidityToken;
    IERC20 public immutable rewardToken;
    PEPAY public immutable backingToken;

    struct UserInfo {
        uint256 shares; // shares of token staked
        uint256 rewardPerTokenOnEntry; // user reward per token paid
    }

    // Reward per token stored
    uint256 public rewardPerTokenStored;

    uint256 public totalAmountStaked;

    uint256 public previusRewardTotal;

    mapping(address => UserInfo) public userInfo;

    bool public init;

    bool public start;

    event Deposit(address indexed user, uint256 amount);
    event Harvest(address indexed user, uint256 harvestedAmount);
    event Withdraw(address indexed user, uint256 amount);

    constructor(address _liquidityToken, address _rewardToken, address _backingToken) {
        require(_liquidityToken != address(0x0), "cannot set to 0x0 address");
        require(_rewardToken != address(0x0), "cannot set to 0x0 address");
        require(_backingToken != address(0x0), "cannot set to 0x0 address");
        liquidityToken = IERC20(_liquidityToken);
        rewardToken = IERC20(_rewardToken);
        backingToken = PEPAY(payable(_backingToken));
        START_DATE = block.timestamp;
    }

    function setFeeAddress(address _address) external onlyOwner {
        require(_address != address(0x0), "cannot set to 0x0 address");
        FEE_ADDRESS = PEPAYFeeSplitter(payable(_address));
    }

    function initalize(
        uint256 _initialLPs,
        address[] memory _addresses,
        uint256[] memory _balances
    ) external onlyOwner {
        require(!init, "Contract already initialized");
        init = true;
        uint256 total = 0;
        uint256 _length = _addresses.length;
        for (uint256 i = 0; i < _length;) {
            userInfo[_addresses[i]] = UserInfo({
                shares: _balances[i],
                rewardPerTokenOnEntry: 0
            });

            total += _balances[i];
             unchecked {
                i++;
            }

        }
        require(total == _initialLPs, "Totals dont match");
        totalAmountStaked = total;
        liquidityToken.transferFrom(msg.sender, address(this), _initialLPs);
    }

        
    // start trading
    function setStart() external onlyOwner {
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
    function sendEth( uint256 _value) internal {
        rewardToken.safeTransfer(msg.sender, _value);
    }

    /**
     * @notice Claim reward tokens that are pending
     */
    function claim() private returns (uint256) {
        // Retrieve pending rewards
        FEE_ADDRESS.splitFees();

        // Get the balance of the contract
        uint256 contractBalance = rewardToken.balanceOf(address(this));

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
        require(start, "contract not initiated");
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
                ((rewardToken.balanceOf(address(this)) +
                    (rewardToken.balanceOf(address(FEE_ADDRESS)) * 2 / 4) -
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
        return rewardToken.balanceOf(address(this));
    }

    function getAPY() public view returns (uint256) {
        uint256 factor = 1 * 1 ** 4;
        uint256 totalSupply = liquidityToken.totalSupply();
        uint256 bal = backingToken.balanceOf(address(liquidityToken));

        uint256 valueOfToken = 2 * bal * factor / totalSupply;
        uint256 _days = (block.timestamp - START_DATE) / 60 / 60 / 24; 
        _days = _days + 1;
        uint256 apy = (36500 * backingToken.ETHtoJAY(getRewardPerTokenStored()) / valueOfToken / _days) / factor;
        return apy;
    }

    function getRewardPerTokenStored() public view returns (uint256) {
        if (totalAmountStaked > 0)
            return
                rewardPerTokenStored +
                ((rewardToken.balanceOf(address(this)) +
                    (rewardToken.balanceOf(address(FEE_ADDRESS)) * 2 / 4) -
                    (previusRewardTotal)) * (FACTOR)) /
                (totalAmountStaked);
        else return 0;
    }

    receive() external payable {}
}