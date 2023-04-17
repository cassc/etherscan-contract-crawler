// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DepositDistributor is ERC1155Holder, Ownable, ReentrancyGuard {
    // ERC1155 token and deposit-related state variables
    IERC1155 public erc1155Token; // ERC1155 token interface

    uint256 private daoTokenId; // DAO token ID

    // Staking-related state variables
    mapping(address => uint256) public stakedAt; // Timestamp when a user staked their tokens
    mapping(address => uint256) public stakedTokens; // Mapping of staked tokens per user
    address[] public stakedUsers; // Array of staked user addresses
    mapping(address => uint256) public stakedBalances; // Mapping of staked token balances per user
    mapping(address => uint256) public stakedUserIndexes; // Mapping of user indexes in the stakedUsers array
    uint256 public constant MINIMUM_STAKING_DURATION = 21 days; // Minimum staking duration

    // Deposit-related state variables
    mapping(uint256 => uint256) public depositTimestamps; // Mapping of deposit timestamps
    mapping(address => uint256) public balances; // Mapping of user balances
    mapping(address => mapping(uint256 => bool)) private claimed; // Mapping of claimed deposits per user
    mapping(address => bool) public allowList; // Mapping of allowed addresses for depositing
    uint256 private totalDeposits; // Total deposits for rewards distribution
    uint256 private totalDeposited; // Total deposited funds in the contract

    uint256 private daoTokenTotalSupply; // Total supply of the DAO token

    // Beneficiary state variable
    address public beneficiary; // Address of the beneficiary for unclaimed rewards

    // Events declaration
    event Deposited(
        address indexed depositor,
        uint256 amount,
        uint256 totalDeposited
    );
    event Distributed(uint256 totalDistributed);
    event Claimed(address indexed claimer, uint256 amount);
    event Staked(address indexed staker, uint256 amount);
    event Unstaked(address indexed unstaker, uint256 amount);

    constructor(
        address _erc1155Token,
        uint256 _daoTokenId,
        address _beneficiary,
        uint256 _initialTotalSupply
    ) Ownable() {
        erc1155Token = IERC1155(_erc1155Token);
        daoTokenId = _daoTokenId;
        beneficiary = _beneficiary;
        daoTokenTotalSupply = _initialTotalSupply;
    }

    // Function to deposit funds restricted to addresses on the allow list
    function deposit(
        uint256 amount
    ) external payable onlyAllowList {
        require(msg.value == amount, "Incorrect deposit amount");

        totalDeposited += amount;
        distribute();

        depositTimestamps[totalDeposits] = block.timestamp;

        totalDeposits += 1;

        emit Deposited(msg.sender, amount, totalDeposited);
    }

    // Function to stake tokens
    function distribute() private  {

        if (stakedUsers.length == 0) {
        return;
    }


        uint256 totalDistributed = 0;

        for (uint256 i = 0; i < stakedUsers.length; i++) {
            address member = stakedUsers[i];
            uint256 balance = stakedBalances[member];

            uint256 share = (balance * totalDeposited) / (daoTokenTotalSupply);
            balances[member] += share;
            totalDistributed += share;
        }

        uint256 unclaimedRewards = totalDeposited - totalDistributed;
        (bool success, ) = payable(beneficiary).call{value: unclaimedRewards}(
            ""
        );
        require(success, "Transfer failed.");
        totalDeposited = 0;

        emit Distributed(totalDistributed);
    }

    // Function to claim rewards restricted to DAO members
    function claim() external nonReentrant {
        require(balances[msg.sender] > 0, "No balance to claim");
        require(
            !claimed[msg.sender][totalDeposits],
            "Already claimed for this deposit"
        );
        require(isStaked(msg.sender), "Not staked");
        claimed[msg.sender][totalDeposits] = true;

        uint256 balance = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");

        emit Claimed(msg.sender, balance);
    }

    // Function to stake tokens
    function stake() external nonReentrant {
        uint256 userBalance = erc1155Token.balanceOf(msg.sender, daoTokenId);
        require(userBalance > 0, "Sender is not a member");
        require(stakedAt[msg.sender] == 0, "Already staked");

        erc1155Token.safeTransferFrom(
            msg.sender,
            address(this),
            daoTokenId,
            userBalance,
            ""
        );

        stakedAt[msg.sender] = block.timestamp;
        stakedTokens[msg.sender] = userBalance;
        stakedBalances[msg.sender] = userBalance;
        stakedUsers.push(msg.sender);
        stakedUserIndexes[msg.sender] = stakedUsers.length - 1;

        emit Staked(msg.sender, userBalance);
    }

    // Function to unstake tokens
    function unstake() external nonReentrant {
        require(stakedAt[msg.sender] > 0, "Not staked");
        uint256 stakedTime = block.timestamp - stakedAt[msg.sender];
        require(
            stakedTime >= MINIMUM_STAKING_DURATION,
            "Minimum staking duration not reached"
        );

        uint256 userStakedTokens = stakedTokens[msg.sender];
        erc1155Token.safeTransferFrom(
            address(this),
            msg.sender,
            daoTokenId,
            userStakedTokens,
            ""
        );

        stakedAt[msg.sender] = 0;
        stakedTokens[msg.sender] = 0;
        stakedBalances[msg.sender] = 0;

        uint256 userIndex = stakedUserIndexes[msg.sender];
        uint256 lastIndex = stakedUsers.length - 1;
        stakedUsers[userIndex] = stakedUsers[lastIndex];
        stakedUserIndexes[stakedUsers[userIndex]] = userIndex;
        stakedUsers.pop();

        emit Unstaked(msg.sender, userStakedTokens);
    }

    // Function to check whether a member is staked
    function isStaked(address member) public view returns (bool) {
        return stakedAt[member] > 0;
    }

    // Function to add an address to the allow list, restricted to the contract owner
    function addToAllowList(address _user) external onlyOwner {
        allowList[_user] = true;
    }

    // Function to remove an address from the allow list, restricted to the contract owner
    function removeFromAllowList(address _user) external onlyOwner {
        allowList[_user] = false;
    }

    // Modifier to restrict access to addresses on the allow list
    modifier onlyAllowList() {
        require(allowList[msg.sender], "Sender not on allow list");
        _;
    }

    fallback() external payable {
        revert("Direct transfers not allowed");
    }

    receive() external payable {
        revert("Direct transfers not allowed");
    }

    // Function to get the total number of deposits made to the contract
    function getTotalDeposits() external view returns (uint256) {
        return totalDeposits;
    }

    // Function to get the total amount of funds deposited to the contract
    function getTotalDeposited() external view returns (uint256) {
        return totalDeposited;
    }

    // Function to get the total supply of the DAO token
    function getDaoTokenTotalSupply() external view returns (uint256) {
        return daoTokenTotalSupply;
    }

    // Function to get the ID of the DAO token
    function getDaoTokenId() external view returns (uint256) {
        return daoTokenId;
    }

    function getStakedBalance(address user) public view returns (uint256) {
    return stakedBalances[user];

    }

    function getStakedTokens(address user) public view returns (uint256) {
    return stakedTokens[user];
    
    }

    function getBalance(address user) public view returns (uint256) {
    return balances[user];
    
    }

    // Function to check if a specific address has claimed rewards
    function hasClaimed(
        address user,
        uint256 depositIndex
    ) external view returns (bool) {
        return claimed[user][depositIndex];
    }

    // Function to check if a specific address has claimed rewards
}