// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Staking {
    using SafeMath for uint256;

    address public tokenAddress;
    uint256 public totalStaked;
    IERC20 ERC20Interface;

    mapping(address => uint256) private stakedBalance;

    /**
     *  @dev Struct to store user's withdraw data
     */
    struct Withdraw {
        bool status;
        uint256 amount;
        uint256 withdrawTime;
    }
    mapping(address => Withdraw) private userWithdraw;

    /**
     *  @dev Emitted when user stake 'amount' value of tokens
     */
    event Staked(address indexed from, uint256 indexed amount);

    /**
     *  @dev Emitted when user unstake 'amount' value of tokens
     */
    event Unstaked(address indexed from, uint256 indexed amount);

    constructor(address _tokenAddress) {
        require(_tokenAddress != address(0), "Zero token address");
        tokenAddress = _tokenAddress;
    }

    /**
     *  @dev Prevent under value in allowance
     */
    modifier _hasAllowance(address allower, uint256 amount) {
        ERC20Interface = IERC20(tokenAddress);
        uint256 ourAllowance = ERC20Interface.allowance(allower, address(this));
        require(amount <= ourAllowance, "Make sure to add enough allowance");
        _;
    }

    /**
     *  Requirements:
     *  `_address` User wallet address
     *  @dev returns user staking data
     */
    function balanceOfStake(address _address) public view returns (uint256) {
        return (stakedBalance[_address]);
    }

    /**
     *  Requirements:
     *  `_address` User wallet address
     *  @dev returns user's withdraw data
     */
    function checkWithdrawInfo(address _address)
        public
        view
        returns (
            bool,
            uint256,
            uint256
        )
    {
        return (
            userWithdraw[_address].status,
            userWithdraw[_address].amount,
            userWithdraw[_address].withdrawTime
        );
    }

    /**
     *  Requirements:
     *  `amount` Amount to be staked
     /**
     *  @dev to stake 'amount' value of tokens 
     *  once the user has given allowance to the staking contract
     */
    function stake(uint256 amount) external _hasAllowance(msg.sender, amount) {
        require(
            amount >= 250 * 10**18,
            "Please increase your staking value!"
        );
        _stake(msg.sender, amount);

        uint256 totalAmount = stakedBalance[msg.sender].add(amount);
        stakedBalance[msg.sender] = totalAmount;
        totalStaked = totalStaked.add(amount);

        emit Staked(msg.sender, amount);
    }

    /**
     *  Requirements:
     *  `amount` Amount to be unstake
     /**
     *  @dev to unstake 'amount' value of tokens 
     */
    function unstake(uint256 amount) external {
        require(amount <= stakedBalance[msg.sender], "Insufficient stake");
        _unstake(amount);
    }

    /**
     *  @dev to claim the withdraw
     */
    function claimWithdraw() external {
        require(
            userWithdraw[msg.sender].status,
            "Not eligible to claim withdraw!"
        );
        require(
            userWithdraw[msg.sender].withdrawTime < block.timestamp,
            "Maturity date is not over!"
        );

        _transferToUser(msg.sender, userWithdraw[msg.sender].amount);

        userWithdraw[msg.sender] = Withdraw(false, 0, 0);
    }

    function _stake(address payer, uint256 amount) private {
        ERC20Interface = IERC20(tokenAddress);
        ERC20Interface.transferFrom(payer, address(this), amount);
    }

    function _unstake(uint256 amount) private {
        uint256 totalAmount = stakedBalance[msg.sender].sub(amount);
        stakedBalance[msg.sender] = totalAmount;
        totalStaked = totalStaked.sub(amount);

        uint256 prevAmountWithdraw = userWithdraw[msg.sender].amount;
        uint256 totalWithdrawAmount = prevAmountWithdraw.add(amount);

        userWithdraw[msg.sender] = Withdraw(
            true,
            totalWithdrawAmount,
            block.timestamp + 14 days
        );
        emit Unstaked(msg.sender, amount);
    }

    function _transferToUser(address to, uint256 amount) private {
        ERC20Interface = IERC20(tokenAddress);
        ERC20Interface.transfer(to, amount);
    }
}