// SPDX-License-Identifier: none

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Migration is Ownable {
	using SafeERC20 for ERC20;
	
	address public immutable token1;
	address public token2;
	address public immutable rewardToken;
	bool public finished;

    struct Config { 
		uint32 checkpoint1;
        uint16 checkpoint1Bonus;
        uint32 checkpoint2;
        uint16 checkpoint2Bonus;
        uint32 checkpoint3;
        uint16 checkpoint3Bonus;
    }

	uint256 public totalRewards;

    Config public config;
	uint256 private constant percentBase = 1000;

	mapping(address => uint256) public deposited;
    uint256 public totalDeposited;

	mapping(address => uint256) public toReceive;
    uint256 public totalToReceive;

    address[] public users;
 		
	// -------------------------------------- CONSTRUCT ----------------------------------------

	constructor(
		address token1_,        
		address rewardToken_,
		Config memory config_        
	) {
		token1 = token1_;        
        config = config_;
		rewardToken = rewardToken_;
    }

	// -------------------------------------- ADMIN -----------------------------------------

	// main contract config
	function setConfig(Config memory config_) public onlyOwner {
		config = config_;
	}

	function finishMigration() public onlyOwner {
		require(!finished, "Already finished");
		
		uint256 amount = ERC20(token1).balanceOf(address(this));
		ERC20(token1).safeTransfer(owner(), amount);

		totalRewards = ERC20(rewardToken).balanceOf(address(this));
		finished = true;
	}

	function setToken2(address token2_) public onlyOwner {
		token2 = token2_;
	}
	
	// airdrop to max 100 wallets at once
	function migrate(uint256 numberOfAccounts_, uint256 startIndex_) external onlyOwner {
		require(finished, "Not finished");
		require(token2 != address(0), "Not finished");

		for (uint256 i = startIndex_; i < numberOfAccounts_; i++) {
            if (i >= users.length) break;
            address account = users[i];
            uint256 amount = toReceive[account];
            if (amount == 0) continue;
            
			ERC20(token2).safeTransferFrom(msg.sender, account, amount);
            toReceive[account] = 0;

			uint256 rewardAmount = totalRewards * deposited[account] / totalDeposited;
			ERC20(rewardToken).safeTransfer(account, rewardAmount);

            emit Migrate(account, amount, rewardAmount);			
		}
	}

    function recover(address _token, uint256 _amount) external onlyOwner {
        if (_token != address(0)) {
			ERC20(_token).transfer(msg.sender, _amount);
		} else {
			(bool success, ) = payable(msg.sender).call{ value: _amount }("");
			require(success, "Can't send ETH");
		}        
	}
	
    // -------------------------------------- VIEWS -----------------------------------------

	// aggregated data for contract and account (by defauld provide ZERO address to get only contract data)
	// use it on UI to get all data in single request
	function aggregatedData(
		address account_
	)
		public
		view
		returns (
			// contract
			Config memory _config,
			address _token1,
			address _token2,
			address _rewardToken,
            uint256 _totalUsersDeposited,
            uint256 _totalAmountDeposited,	
            uint256 _totalAmountToReceive,	
			bool _finished,		
			// account
			uint256 _accountDeposited,
			uint256 _accountToReceive,
			uint256 _allowance
		)
	{
		// contract		
		_config = config;
        _token1 = token1;
		_token2 = token2;
		_rewardToken = rewardToken;
		_finished = finished;

        _totalUsersDeposited = users.length;
        _totalAmountDeposited = totalDeposited;
        _totalAmountToReceive = totalToReceive;
		
		// account
        _accountDeposited = deposited[account_];
        _accountToReceive = toReceive[account_];
        _allowance = ERC20(token1).allowance(account_, address(this));
	}

	// -------------------------------------- PUBLIC -----------------------------------------

	// stake all user tokens for predefined duration to get bonuses
	function deposit(uint256 amount_) public returns (uint256 toReceive_) {
        require(!finished, 'Migration disabled');
        require(amount_ > percentBase, 'Low amount');

        ERC20(token1).safeTransferFrom(msg.sender, address(this), amount_);
        
        if (deposited[msg.sender] == 0) {
            users.push(msg.sender);
        }

        deposited[msg.sender] += amount_;
        totalDeposited += amount_;

        if (block.timestamp < config.checkpoint1) {
            toReceive_ = amount_ + amount_ * config.checkpoint1Bonus / percentBase;
        } else if (block.timestamp < config.checkpoint2) {
            toReceive_ = amount_ + amount_ * config.checkpoint2Bonus / percentBase;
        } else if (block.timestamp < config.checkpoint3) {
            toReceive_ = amount_ + amount_ * config.checkpoint3Bonus / percentBase;
        } else {
            toReceive_ = amount_;
        }
		
        toReceive[msg.sender] += toReceive_;
        totalToReceive += toReceive_;   

		emit Deposit(_msgSender(), amount_, toReceive_);
	}
	
	receive() external payable {}
	
	// -------------------------------------- EVENTS -----------------------------------------

	event Deposit(address account, uint256 amount, uint256 toReceive);
    event Migrate(address account, uint256 amount, uint256 rewardAmount);
	    
}